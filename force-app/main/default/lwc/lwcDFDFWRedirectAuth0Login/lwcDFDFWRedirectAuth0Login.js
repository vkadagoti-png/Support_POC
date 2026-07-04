import { LightningElement } from "lwc";
import getRedirectUrls from "@salesforce/apex/DFDFW_INTAUTH0_LoginController.getRedirectUrl";
export default class LwcDFDFWRedirectAuth0Login extends LightningElement {
  redirect_home_token = "";
  redirect_register_token = "";
  accessToken = "";

  constructor() {
    super();
    this.getBaseUrl();
  }
  getBaseUrl() {
    getRedirectUrls()
      .then((result) => {
        window.location.href = result.register + "&state=";
      })
      .catch((err) => {
        console.error(err);
      });
  }
}