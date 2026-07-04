import { LightningElement } from "lwc";
import getComments from "@salesforce/apex/DFDFW_INTOIC_GetCommentsController.getComment";
import USERID from "@salesforce/user/Id";

export default class LwcDFDFWGetAllComments extends LightningElement {
  recordId;
  userId = USERID;
  connectedCallback() {
    const url = window.location.href;
    const match = url.match(/service-application-detail\/(.*?)\//);
    this.recordId = match ? match[1] : null;
    this.getAllComments();
  }

  getAllComments() {
    getComments({ applicationId: this.recordId, userId: this.userId })
      .then((result) => {
        if (result.length !== 0) {
          window.location.reload();
        }
      })
      .catch((err) => {
        console.error("error in getting comments==>", err);
      });
  }
}