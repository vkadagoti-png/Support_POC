import { LightningElement,wire,track } from 'lwc';
import USER_ID from '@salesforce/user/Id';
import getUserDetails from '@salesforce/apex/VolunteerShiftsUploadController.getUserDetails';
import parseCSVFromContentVersion from '@salesforce/apex/VolunteerShiftsUploadController.parseCSVFromContentVersion';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class TornadoShiftsUpload extends NavigationMixin(LightningElement) {
   userId = USER_ID;
    isModalOpen = false;
    contentVersionId;
   disasterEvent
  submissionDate
  @track submittedBy
 @track phone
 @track email
 accountId;
 campaignId;
 initial;
 parnetcampaignId;
 fileType;
 totalHours;
 totalAttendees;
 manualInput=false;
 isFileCSV;

    @wire(getUserDetails, { userId: '$userId' })
    wiredUserDetails({ error, data }) {
      console.log(JSON.stringify(data)+ 'data')
        if (data) {
          this.disasterEvent=data.disasterEvent;
            this.submissionDate=data.submissionDate;
      this.submittedBy=data.submittedBy;
      this.phone=data.phone;
      this.email=data.email;
      this.campaignId=data.campaignId;
      this.accountId=data.accountId;
      this.contactId=data.contactId;
      this.parnetcampaignId=data.parnetcampaignId;

        } else if (error) {
            this.userName = 'Unknown User';
            console.error('User fetch error:', error);
        }
    }

  async handleUploadFinished(event) {
    const uploadedFile = event.detail.files[0];
     this.fileType=uploadedFile.mimeType;
     if(this.fileType!='text/csv'){
      this.isFileCSV=false;
     }else{
      this.isFileCSV=true;
     }
    this.isModalOpen = true;
    this.contentVersionId=uploadedFile.contentVersionId;
    this.fileType=uploadedFile.mimeType;
    console.log('MB, uploadedFile:'+JSON.stringify(uploadedFile));
   // await parseCSVFromContentVersion({ contentVersionId: uploadedFile.contentVersionId});
  }
  

   handleInitialChange(event) {
        this.initial = event.target.value;
    }
      handleTotalHours(event) {
        this.totalHours = event.target.value;
    }
      handleTotalAttendees(event) {
        this.totalAttendees = event.target.value;
    }
  closeModal() {
        this.isModalOpen = false;
        this.comment = '';
    }
  initialAndSubmit(){
    const inputField = this.template.querySelector('.initial-input');

    if (!this.initial || this.initial.trim() === '') {
        if (inputField) {
            inputField.setCustomValidity('Initial is required.');
            inputField.reportValidity();
        }
        return; // Stop submission
    }

    if (inputField) {
        inputField.setCustomValidity('');
        inputField.reportValidity();
    }

parseCSVFromContentVersion({ 
    contentVersionId: this.contentVersionId, accountId: this.accountId,campaignId: this.campaignId,contactId : this.contactId, userId:this.userId , initials:this.initial, parnetcampaignId:this.parnetcampaignId,disasterEvent: this.disasterEvent,totalAttendees:this.totalAttendees,totalHours:this.totalHours,isFileCSV:this.isFileCSV})
      .then((result) => {
        if (result.isSuccess) {
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'Success',
              message: 'Volunteer Shift Report created successfully!',
              variant: 'success'
            })
          );

          // Navigate to the record page in the community
          this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
              recordId: result.shiftReportId,
              objectApiName: 'Volunteer_Shift_Report__c',
              actionName: 'view'
            }
          });

          this.isModalOpen = false;
          this.initial = '';
        } else {
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'Error',
              message: result.errorMessage || 'An unknown error occurred.',
              variant: 'error'
            })
          );
        }
      })
      .catch((error) => {
        let message = 'An error occurred';
        if (error.body && error.body.message) {
          message = error.body.message;
        }
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Error',
            message,
            variant: 'error'
          })
        );
        console.error('Submission error:', error);
      });
  }
}