// ...[imports remain exactly as you wrote them]...
import { LightningElement, track, wire } from "lwc";
import saveAccessToken from "@salesforce/apex/DFDFW_UserRegistrationFormController.saveAccessToken";
import getuserInfoFromAuth0 from "@salesforce/apex/DFDFW_UserRegistrationFormController.getuserInfoFromAuth0";
import checkExistingUser from "@salesforce/apex/DFDFW_UserRegistrationFormController.checkExistingUser";
//import loginUser from "@salesforce/apex/DFDFW_UserRegistrationFormController.loginUser";
import createAccount from "@salesforce/apex/DFDFW_UserRegistrationFormController.createAccountAndContact";
//import createExternalUser from "@salesforce/apex/DFDFW_UserRegistrationFormController.createExternalUser";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createPortalUser from "@salesforce/apex/DFDFW_UserRegistrationFormController.createPortalUser";
import getRedirectUrl from "@salesforce/apex/DFDFW_UserRegistrationFormController.getRedirectUrl";
import getRedirectURL2 from "@salesforce/apex/DFDFW_UserRegistrationFormController.getRedirectURL2";
import getErrorMessageFromMetadata from "@salesforce/apex/DFDFW_UserRegistrationFormController.getErrorMessageFromMetadata";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import CONTACT_OBJECT from "@salesforce/schema/Contact";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import COUNTRY_CODE from "@salesforce/schema/Contact.MailingCountryCode";
import MAILING_STATE_CODE from "@salesforce/schema/Contact.MailingStateCode";

export default class LwcDFDFWRegisterLoginUser extends LightningElement {
  /* ----- input values starts here ----- */
  @track value = "business";
  firstName = "";
  lastName = "";
  company = "";
  cellPhone = "";
  streetAddressLine1 = "";
  streetAddressLine2 = "";
  city = "";
  stateProvince = "";
  zipCode = "";
  password = "";
  selectedCountry = 'US';
  selectedState = 'MO';
  /* ----- input values ends here ----- */
  _countries = [];
  _countryToStates  = {};
  showBusiness = true;
  showIndividual = false;
  showForm = false;
  accId = "";
  fedralId = "";
  email = "";
  showSpinner = true;
  showErrMsg = false;
  @track errorMessage = "";
  accesstoken = "";
  fieldNullCheck = false;
  cellPhonePatternCheck = false;
  stateFullCheck = false;
  stateCodeCheck = false;
  stateProvinceCheck = false;
  redirectUrl = "";
  baseUrl = "";
  userId = "";
  isDisabled = false;
  @track showSpinner = false;

  get options() {
    return [
      { label: "Business", value: "business" },
      { label: "Individual", value: "individual" }
    ];
  }

  constructor() {
    super();
    this.accesstoken = this.getaccessToken();
    this.getUrls();
    this.getUserInfo();
  }

  getUrls() {
    getRedirectUrl()
      .then((result) => {
        this.baseUrl = result.home;
      })
      .catch((err) => {
        console.error(err);
        let message = err.body.message;
        message = message.replace(/^\[|\]$/g, "");
        this.showErrorMsg(message);
      });
  }

  getUrls2() {
    getRedirectURL2().then((result) => {
        if (result != null) {
          console.log('@@@@ result : '+result.home);
          //window.location.href = result.home;
          this.redirectUrl = result.home;
          this.saveAccessToken();
        } 
      })
      .catch((err) => {
        console.error('Error in checking for existing user==> ', err);
        let message = err.body.message;
        message = message.replace(/^\[|\]$/g, "");
        this.showErrorMsg(message);
      });
  }

  @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
  objectInfo;

  get recordTypeId() {
    const rtis = this.objectInfo.data.recordTypeInfos;
    return Object.keys(rtis).find((rti) => rtis[rti].name === "Master");
  }

  @wire(getPicklistValues, {
    recordTypeId: "$recordTypeId",
    fieldApiName: COUNTRY_CODE
  })
  wiredCountires({ data }) {
    this._countries = data?.values;
  }

  @wire(getPicklistValues, {
    recordTypeId: "$recordTypeId",
    fieldApiName: MAILING_STATE_CODE
  })
  wiredStates({ data }) {
    if (!data) return;

    const validForNumberToCountry = Object.fromEntries(
      Object.entries(data.controllerValues || {}).map(([key, value]) => [value, key])
    );

    this._countryToStates = (data.values || []).reduce((accumulatedStates, state) => {
      const validForIndex = state.validFor?.[0];
      const countryIsoCode = validForIndex ? validForNumberToCountry[validForIndex] : 'US';
      if (!countryIsoCode) return accumulatedStates;

      return {
        ...accumulatedStates,
        [countryIsoCode]: [
          ...(accumulatedStates[countryIsoCode] || []),
          state
        ]
      };
    }, {});
  }

  get countries() {
    return this._countries;
  }

  get states() {
    return this._countryToStates[this.selectedCountry] || [];
  }

  handleCountry(e) {
    this.selectedCountry = e.detail.value;
    this.selectedState = ''; // reset state when country changes
  }

  handleState(e) {
    this.selectedState = e.detail.value;
  }

  getUserInfo() {
    getuserInfoFromAuth0({ accessToken: this.accesstoken })
      .then((result) => {
        if (!Object.prototype.hasOwnProperty.call(result, "Error")) {
          this.fedralId = result.fedrationId;
          this.email = result.email;
          this.checkExistingUser();
        }
      })
      .catch((err) => {
        console.error('Error in getting user info from auth0==> ', err);
        let message = err.body.message;
        message = message.replace(/^\[|\]$/g, "");
        this.showErrorMsg(message);
      });
  }

  checkExistingUser() {
    checkExistingUser({ fedId: this.fedralId })
      .then((result) => {
        if (result != null) {
          this.userId = result;
          //this.loginUser();
          this.getUrls2();
        } else {
          this.showForm = true;
          this.showSpinner = false;
        }
      })
      .catch((err) => {
        console.error('Error in checking for existing user==> ', err);
        let message = err.body.message;
        message = message.replace(/^\[|\]$/g, "");
        this.showErrorMsg(message);
      });
  }

  applicationId;
  contextId;

  loginUser() {
    loginUser({
      email: this.email,
      password: this.fedralId,
      baseUrl: this.baseUrl
    })
      .then((result) => {
        this.redirectUrl = result;
        this.saveAccessToken();
      })
      .catch((err) => {
        let message = err.body.message;
        message = message.replace(/^\[|\]$/g, "");
        this.showErrorMsg(message);
        this.isDisabled = true;
      });
  }

  getaccessToken() {
    const hash = window.location.hash;
    const firstPart = hash.indexOf("access_token=");
    if (firstPart > -1) {
      const secondPart = hash.indexOf("&", firstPart);
      if (secondPart > -1) {
        return hash.substring(firstPart + 13, secondPart);
      } else {
        return hash.substring(firstPart + 13);
      }
    } else {
      return null;
    }
  }

  handleRadioChange(event) {
    this.value = event.target.value;
    if (this.value === "business") {
      this.showBusiness = true;
      this.showIndividual = false;
    } else {
      this.showIndividual = true;
      this.showBusiness = false;
    }
  }

  handleInputChange(event) {
    const name = event.target.name;
    const value = event.target.value;
    if (name === "firstName") {
      this.firstName = value;
    } else if (name === "lastName") {
      this.lastName = value;
    } else if (name === "company") {
      this.company = value;
    } else if (name === "cellPhone") {
      this.cellPhone = value;
    } /*else if(name === "LIGHTNING-INPUT-ADDRESS"){
      this.streetAddressLine1 = event.detail.street;
      this.streetAddressLine2 = event.detail.subpremise;
      this.strAddressCity = event.detail.city;
      this.strAddressProvince = event.detail.province;
      this.strAddressPostalCode = event.detail.postalCode;
      this.strAddressCountry = event.detail.country;
      console.log('Street Value',this.strAddressProvince);
      console.log('Country Value',this.strAddressCountry);
    }*/ 
    else if (name === "streetAddressLine1") {
      this.streetAddressLine1 = value;
    } else if (name === "streetAddressLine2") {
      this.streetAddressLine2 = value;
    } else if (name === "state") {
      this.stateProvince = value;
    } else if (name === "city") {
      this.city = value;
    } else if (name === "zipCode") {
      this.zipCode = value;
    } else if (name === 'radio') this.value = value;
  }

  phoneRegex = /^\d{10}$/;

  stateCodeRegex =
    /\b(?:AL|AK|AZ|AR|CA|CO|CT|DE|FL|GA|HI|ID|IL|IN|IA|KS|KY|LA|ME|MD|MA|MI|MN|MS|MO|MT|NV|NH|NJ|NM|NY|NC|ND|OH|OK|OR|PA|RI|SC|SD|TN|TX|UT|VT|VA|WA|WV|WI|WY|NE)\b/;

  stateFullRegex =
    /\b(?:Alabama|Alaska|Arizona|Arkansas|California|Colorado|Connecticut|Delaware|Florida|Georgia|Hawaii|Idaho|Illinois|Indiana|Iowa|Kansas|Kentucky|Louisiana|Maine|Maryland|Massachusetts|Michigan|Minnesota|Mississippi|Missouri|Montana|Nevada|New\s+Hampshire|New\s+Jersey|New\s+Mexico|New\s+York|North\s+Carolina|North\s+Dakota|Ohio|Oklahoma|Oregon|Pennsylvania|Rhode\s+Island|South\s+Carolina|South\s+Dakota|Tennessee|Texas|Utah|Vermont|Virginia|Washington|West\s+Virginia|Wisconsin|Wyoming|Nebraska)\b/i;

 handleButtonClick() {
    this.showSpinner = true;

    // Validate required fields
    if (
      this.firstName === "" ||
      this.lastName === "" ||
      this.cellPhone === "" ||
      this.streetAddressLine1 === "" ||
      this.city === "" ||
      this.zipCode === "" ||
      this.selectedState === "" ||
      (this.value === "business" && this.company === "")
    ) {
      this.fieldNullCheck = false;
      this.getErrorMessage("registerdUserFormRequiredField");
      this.showSpinner = false;
      return;
    } 

    // Validate phone number
    if (!this.phoneRegex.test(this.cellPhone)) {
      this.cellPhonePatternCheck = false;
      this.getErrorMessage("registerUserFormCellPhonePattern");
      this.showSpinner = false;
      return;
    }

    // All validations passed → call the method
    this.createPortalUser();
    }

  //save the access token to custom settings
  saveAccessToken() {
    saveAccessToken({ accessToken: this.accesstoken, userId: this.userId })
      .then(() => {
        console.log('MB, then saveAccessToken:');
        this.showSpinner = false;
        this.navigateToHome();
      })
      .catch((err) => {
        console.error('Error in saving access token==> ',err);
        let message = err.body.message;
        message = message.replace(/^\[|\]$/g, "");
        this.showErrorMsg(message);
      });
  }

  //redirect user to respective URL
  navigateToHome() {
    window.location.href = this.redirectUrl;
  }

  //create account and contact for user
  creatAccountContact() {
    let completeStreet = "";
    if (this.streetAddressLine2 !== "") {
      completeStreet = this.streetAddressLine1 + ", " + this.streetAddressLine2;
    } else {
      completeStreet = this.streetAddressLine1;
    }
    const inputParms = JSON.stringify({
      firstName: this.firstName,
      lastName: this.lastName,
      email: this.email,
      company: this.company,
      radioValue: this.value,
      cellPhone: this.cellPhone,
      street: completeStreet,
      streetLine1: this.streetAddressLine1,
      streetLine2: this.streetAddressLine2,
      city: this.city,
      state: this.selectedState,
      zipCode: this.zipCode
    });
    createAccount({ dataObject: inputParms })
      .then((result) => {
        this.accId = result;
        if (this.accId) {
          // this.createAuth0User();
          //this.createExternaluser();
          this.createPortalUser();
        } else {
          this.getErrorMessage("registerUserFormCreateAccount");
        }
      })
      .catch((err) => {
        console.error('Error in creating account contact==>',err);
        let message = err.body.message;
        message = message.replace(/^\[|\]$/g, "");
        this.showErrorMsg(message);
      });
  }

  //create external user
  /*createExternaluser() {
    const inputParms = JSON.stringify({
      firstName: this.firstName,
      lastName: this.lastName,
      email: this.email,
      company: this.company,
      radioValue: this.value,
      fedralId: this.fedralId
    });

    createExternalUser({
      accId: this.accId,
      inputParms: inputParms,
      baseUrl: this.baseUrl
    })
      .then((result) => {
        if (result) {
          this.showForm = false;
          this.showSpinner = false;
          this.showErrMsg = false;
          this.errorMessage = "";
          this.redirectUrl = result.redirectUrl;
          this.userId = result.userId;
          if (this.state != null) {
            this.linkApplication();
          }
          this.saveAccessToken();
        } else {
          this.getErrorMessage("registerUserFormCreateUser");
        }
      })
      .catch((err) => {
        console.error('Error in creating external user==> ',err);
        let message = err.body.message;
        message = message.replace(/^\[|\]$/g, "");
        this.showErrorMsg(message);
      });
  }*/

  createPortalUser() {
    console.log('createPortalUser triggered');
    this.showSpinner = true;

    // Combine street address
    const street = this.streetAddressLine2 
        ? `${this.streetAddressLine1}, ${this.streetAddressLine2}` 
        : this.streetAddressLine1;

    // Prepare input for Apex
    const inputParams = JSON.stringify({
        firstName: this.firstName,
        lastName: this.lastName,
        email: this.email,
        company: this.company,
        radioValue: this.value,
        fedralId: this.fedralId,
        cellPhone: this.cellPhone,
        street: street,
        streetLine1: this.streetAddressLine1,
        streetLine2: this.streetAddressLine2,
        city: this.city,
        state: this.selectedState,
        zipCode: this.zipCode,
        accessToken: this.accesstoken,
    });

    createPortalUser({ inputParams: inputParams, baseUrl: this.baseUrl })
        .then(result => {
            console.log('Apex result:', result);
            this.showSpinner = false;

            /*if (result && result.redirectUrl) {
                // Redirect user to Auth0 login page
                window.location.href = result.redirectUrl;
            } else {
                this.getErrorMessage("registerUserFormCreateUser");
            }*/
            if (result && result.status === 'error') {
                // Display the error message returned from Apex.
                this.showErrorMsg(result.message);
                this.showErrMsg = true;
            } else if (result && result.redirectUrl) {
                // Redirect user to Auth0 login page for new users.
                window.location.href = result.redirectUrl;
            } else {
                this.getErrorMessage("registerUserFormCreateUser");
            }
        })
        .catch(err => {
            this.showSpinner = false;
            console.error('Apex error:', err);

            let message = err?.body?.message || err?.message || 'Unknown error during registration';
            this.showErrorMsg(message);
        });
    }

                // Save the access token if available
               /* if (this.accesstoken) {
                    saveAccessToken({ accessToken: this.accesstoken, userId: this.userId })
                        .then(() => console.log('Access token saved'))
                        .catch(err => console.error('Error saving access token:', err));
                } */

               

  showErrorMsg(message) {    
    this.showForm = true;
    this.showSpinner = false;
    this.errorMessage = message;
    this.showErrMsg = true;
  }

  //get error message according to component
  getErrorMessage(componenetName) {
    getErrorMessageFromMetadata({ component: componenetName })
      .then((result) => {        
        if (result != null && result !== "") {
          this.showErrorMsg(result);
        }
      })
      .catch((err) => {
        console.error("Error in getting error message==>",err);
      });
  }
}