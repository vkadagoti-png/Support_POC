import { LightningElement, track, wire, api } from 'lwc';
import omniscriptSaveForLaterAcknowledge from 'omnistudio/omniscriptSaveForLaterAcknowledge';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';
import { NavigationMixin } from 'lightning/navigation';
import tmpl from './lwcDFDFWSaveForLater.html';

export default class LwcDFDFWSaveForLater extends OmniscriptBaseMixin(NavigationMixin(omniscriptSaveForLaterAcknowledge)) {
    @track isModalOpen = false;
    @api individualApplicationId;
    profileName;
    applnName;
    applnId;
    indvlApplId;
    indvlApplName;
    instanceId;
    baseUrl;
    mutableResult;
    modalHeader = "Application saved";
    modalText = 'Thank you, the application has been saved and has not been submitted. Click the button below to review and submit your application.'
        + ' If you need to return later, go to My applications to review the application and submit.';
    render() {
        return tmpl;
    }

    connectedCallback() {
        if (this.result) {
            this.mutableResult = Object.assign({}, this.result);
            this.baseUrl = window.location.origin;
            const searchParams = new URLSearchParams(window.location.search);
            if (searchParams.has('c__instanceId') && searchParams.get('c__instanceId') != this.mutableResult?.instanceId) {
                this.mutableResult.oldInstanceId = searchParams.get('c__instanceId');
            }
            if (searchParams.has('preInquiryId')) {
                this.mutableResult.preInquiryId = searchParams.get('preInquiryId');
            }
            // const subtype  = this.extractType(JSON.stringify(this.result));

            let mName = 'DFDFW_CreateDraftServiceApplication';

            let inputParam = JSON.stringify(this.mutableResult);
            //inputParam = this.addContextId(JSON.stringify(this.mutableResult));
            console.log('inputParam:-' + inputParam);
            const params = {
                input: inputParam,
                sClassName: 'omnistudio.IntegrationProcedureService',
                sMethodName: mName,
                options: '{}',
            }
            this.omniRemoteCall(params, true).then(response => {
                const ipResponse = JSON.parse(JSON.stringify(response));
                console.log('inside remote call ' + JSON.stringify(ipResponse));
                this.indvlApplId = ipResponse.result.IPResult.indvlApplnResponse.IndividualApplication.Id;
                this.indvlApplName = ipResponse.result.IPResult.indvlApplnResponse.IndividualApplication.Name;
                this.isModalOpen = true;
            }).catch(error => {
                console.log(error, 'error');
            });

        }
    }

    handleRequestClick() {
        this.navigateToCommunityPage(this.indvlApplId, this.indvlApplName);
    }

    goToMyApplication() {
        const url = `${this.baseUrl}/permits/s/my-recent-applications`;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
    }

    navigateToCommunityPage(indvlApplId, indvlApplName) {
        const url = `${this.baseUrl}/permits/s/service-application-detail/${this.indvlApplId}/${this.indvlApplName}`;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
    }

}