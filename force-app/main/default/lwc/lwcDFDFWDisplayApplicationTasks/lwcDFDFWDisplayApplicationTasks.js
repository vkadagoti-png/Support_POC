import { LightningElement, api, wire } from "lwc";
import getColumns from "@salesforce/apex/DFDFW_INTOIC_GetAppTaskController.getColumns";
import getTasks from "@salesforce/apex/DFDFW_INTOIC_GetAppTaskController.getTasks";
import getErrorMessage from "@salesforce/apex/DFDFW_INTOIC_GetAppTaskController.getErrorMessage";
import getSubApplication from "@salesforce/apex/DFDFW_INTOIC_GetAppTaskController.getSubApplication";
import pubsub from "omnistudio/pubsub";
import { publish, MessageContext } from "lightning/messageService";
import REFRESH_FILES from "@salesforce/messageChannel/DFDFW_Permit_Response__c";
export default class LwcDFDFWDisplayApplicationTasks extends LightningElement {
  	@api recordId;
  	@api metadataName;
  	columns = [];
  	loading = true;
  	showError = false;
  	data;
  	errorMessage;

  	@wire(MessageContext)
  	messageContext;

  	connectedCallback() {
		this.getColumns();
		this.getTasks();
  	}

  	getColumns() {
  	  	getColumns({ metadataName: this.metadataName })
  	  	.then((result) => {
  	  	  	this.columns = result;
  	  	})
  	  	.catch((error) => {
  	  	  	console.error(error);
  	  	});
  	}

  	getTasks() {
  	  	getTasks({ recordId: this.recordId })
  	  	.then((result) => {
		
		this.loading = false;
	  	if(result.success){
			this.data = result.Tasks;

			pubsub.fire("ReloadChannel", "ReloadEvent", {});

		  	if(result.LinkedPermits && result.LinkedPermits.length > 0){
			  	this.getSubPermits(result.LinkedPermits);
		  	}
		  	else{
			  	const payload = {
				  	refreshFiles: true
			  	};
			  	publish(this.messageContext, REFRESH_FILES, payload);
		  	}
	  	}
	  	else{
		  	console.error('Error:', result.error);
		  	this.getErrorMessage();
		  	this.showError = true;
	  	}
			
	  })
  	  	.catch((error) => {
  	  	  	console.error('error', error);
  	  	  	this.getErrorMessage();
  	  	  	this.loading = false;
  	  	  	this.showError = true;
  	  	});
  	}


	getSubPermits(subApplications){

        Promise.all(subApplications.map(subApp => this.getEachPermit(subApp)))
        .then(results =>{
			const payload = {
				refreshFiles: true
		  	};
			publish(this.messageContext, REFRESH_FILES, payload);

        })
        .catch(error =>{
            console.error('promise error', error);
        })

    }

    getEachPermit(subApp){
        return new Promise((resolve, reject) => {
            getSubApplication({applicationId: subApp, serviceAppId: this.recordId})
			.then((result) => {
				if(result){
					resolve({ permitId: subApp, success: true});
				}
				else{
					console.error('unsuccessful: ' + subApp);
					resolve({ permitId: subApp, success: false});
				}
			})
			.catch((error) => {
				console.error('error: ' + subApp, error);
				resolve({ permitd: subApp, success: false, error });
			});

        });
    }


  	getErrorMessage() {
  	  	getErrorMessage().then((result) => {
  	  	  	this.errorMessage = result;
  	  	});
  	}
}