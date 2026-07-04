import { api, LightningElement } from "lwc";
import getDataFromOIC from "@salesforce/apex/DFDFW_INTOIC_GetPermitsController.getDataFromOIC";
import getColumnNamesFromMetadata from "@salesforce/apex/DFDFW_INTOIC_GetPermitsController.getColumnNamesFromMetadata";
import getErrorMessageFromMetadata from "@salesforce/apex/DFDFW_INTOIC_GetPermitsController.getErrorMessageFromMetadata";
import userId from "@salesforce/user/Id";
import CLOSEICON from '@salesforce/resourceUrl/DFD_Close_Icon';
// Example :- import TRAILHEAD_LOGO from '@salesforce/resourceUrl/trailhead_logo';
export default class LwcDFDFWPermitHistory extends LightningElement {
  accessToken = "";
  data = [];
  columns = [];
  @api metadataLabel;
  showTable = false;
  showNoHistory = false;
  showSpinner = true;
  userId = userId;
  errorMessage = "";
  closeIcon = CLOSEICON;

  getColumns() {
    getColumnNamesFromMetadata({ metadataLabel: this.metadataLabel })
      .then((result) => {
        console.log("label==> " + this.metadataLabel + " result==> " + result);
        const fields = result.split(",");
        console.log("fields==> ", fields);

        fields.forEach((field) => {
          console.log("field==> ", field);

          //TODO : currentItem
          let obj = { label: field.split("_").join(" "), fieldName: field };
          this.columns.push(obj);
        });
        //this.columns = arrCol;
        console.log("columns==> ", this.columns);
      })
      .catch((err) => {
        console.error(err);
      });
  }

  connectedCallback() {
    this.getColumns();

    this.getDataFromOIC();
    // this.getErrorMessage();
    /*this.data = [
      {
        CA_OBJECT_ID: 80616,
        CASE_NUMBER: "BPS24-0116",
        CASE_NAME: "",
        LOCATION:
          "Locust between 8th and 9th, and 9th between Locust & St. Charles (parking lanes",
        CASE_STATUS: "OPEN",
        CASE_TYPE_DESC: "BPS Permits",
        SUB_TYPE_DESC: "Special Event",
        BUS_CASE_ID: 161,
        BUS_CASE_DESC: "Special Event",
        DATE_CREATED: "2024-02-02T10:35:36.663Z",
        DATE_EXPIRATION: "3023-02-02T10:35:36.000Z",
        BLICENSE_FLAG: "N"
      },
      {
        CA_OBJECT_ID: 94165,
        CASE_NUMBER: "STR24-0127",
        CASE_NAME: "",
        LOCATION:
          "Locust between 8th and 9th, and 9th between Locust & St. Charles (parking lanes",
        CASE_STATUS: "REVIEW",
        CASE_TYPE_DESC: "Street Permits and Cases",
        SUB_TYPE_DESC: "Streets Special Event",
        BUS_CASE_ID: 183,
        BUS_CASE_DESC: "Streets Special Event Permit",
        DATE_CREATED: "2024-09-20T08:16:30.287Z",
        DATE_EXPIRATION: "2025-09-20T08:16:30.303Z",
        BLICENSE_FLAG: "N"
      }
    ]; */
    console.log("data==> ", JSON.parse(JSON.stringify(this.data)));
  }

  getDataFromOIC() {
    console.log("access token on getting data==> ", this.accessToken);
    console.log('OUTPUT : ',this.userId);
    getDataFromOIC({ userId: this.userId })
      .then((result) => {
        if (result.length > 0 && result[0].CA_OBJECT_ID != null) {
          console.log("result==> ", result);
          this.data = result;
          this.showTable = true;
          this.showSpinner = false;
          this.showNoHistory = false;
          console.log("data frrom OIC==> ", this.data);
        } else {
          this.getErrorMessage();
        }
      })
      .catch((err) => {
        this.getErrorMessage();
        console.error("Error in getting data from OIC==> ", err);
        this.showSpinner = false;
        this.showTable = false;
        this.showNoHistory = true;
      });
  }

  getErrorMessage() {
    getErrorMessageFromMetadata({ component: "dfdMyApplications" })
      .then((result) => {
        console.log(
          "Error Message from GetErrorMessageFromMetadataController==> ",
          result
        );
        //this.errorMessage = result;
        
        if (result != null && result !== "") {
          this.errorMessage = result;
          this.showSpinner = false;
          this.showTable = false;
          this.showNoHistory = true;
        }
      })
      .catch((err) => {
        console.error(err);
      });
  }
}