import { api, LightningElement, track } from "lwc";
import { OmniscriptBaseMixin } from "omnistudio/omniscriptBaseMixin";
import userId from "@salesforce/user/Id";
import createCommentOnOIC from "@salesforce/apex/DFDFW_INTOIC_AddCommentController.createCommentOnOIC";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getErrorMessageFromMetadata from "@salesforce/apex/DFDFW_INTOIC_AddCommentController.getErrorMessageFromMetadata";
import checkApplicationStatus from '@salesforce/apex/DFDFW_INTOIC_AddCommentController.checkApplicationStatus';

export default class LwcDFDFWAddComment extends OmniscriptBaseMixin(
  LightningElement
) {
  userId = userId;
  @api recordId;
  @track commentString;
  showModal = false;
  showSpinner = false;
  showButton = false;

  connectedCallback() {    
    checkApplicationStatus({
      recordId: this.recordId
    })
      .then(result => {
        this.showButton = result;
      }).catch((err) => {
        console.error('error getting application status==> ',err);
      });
  }

  handlebutton() {
    this.showModal = true;
  }
  handlecommentchange(event) {
    this.commentString = event.target.value;
  }
  handleCloseModal() {
    this.showModal = false;
  }
  handleSubmitComment() {
    this.showSpinner = true;
    createCommentOnOIC({
      commentString: this.commentString,
      applicationId: this.recordId,
      userId: userId
    })
      .then((result) => {
        if (result) {
          this.showToast("Success", "Comment Saved", "success");
          this.showModal = false;
          this.showSpinner = false;
          window.location.reload();
        } else {
          this.getErrorMessage();
          this.showSpinner = false;
        }
      })
      .catch((err) => {
        this.getErrorMessage();
        console.error(err);
      });
  }

  showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(event);
  }

  getErrorMessage() {
    getErrorMessageFromMetadata({ component: "dfdAddServiceComment" })
      .then((result) => {
        if (result != null && result !== "") {
          this.showToast("Error", result, "error");
        }
      })
      .catch((err) => {
        console.error(err);
      });
  }
}