import { LightningElement, api } from "lwc";
import { OmniscriptBaseMixin } from "omnistudio/omniscriptBaseMixin";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import viewApplicationButton from "@salesforce/apex/DFDFW_APPFILE_DownloadController.getFileId";
import getErrorMessageFromMetadata from "@salesforce/apex/DFDFW_APPFILE_DownloadController.getErrorMessageFromMetadata";

export default class LwcDFDFWViewPDFApplication extends OmniscriptBaseMixin(
  LightningElement
) {
  @api recordId;
  @api fileTitle;
  // Method to call the payment API when button is clicked
  handlebutton() {
    console.log("record Id==> ", this.recordId);
    console.log("fieltitle==> ", this.fileTitle);

    viewApplicationButton({
      recordId: this.recordId,
      fileTitle: this.fileTitle
    })
      .then((result) => {
        console.log("result==> ", result);

        if (result) {
          window.open(result, "_blank").focus();
        } else {
          this.showToast("Error", "No document found.", "error");
        }
      })
      .catch((err) => {
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
    getErrorMessageFromMetadata({ component: "dfdViewApplicationButton" })
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