import { LightningElement, track, api } from "lwc";
import getAddressCandidate from "@salesforce/apex/DFDFW_INTGEO_GetAddressController.getAddressCandidate";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { OmniscriptBaseMixin } from "omnistudio/omniscriptBaseMixin";

export default class LwcDFDFWAddressSearch extends OmniscriptBaseMixin(
  LightningElement
) {
  @track street = "";
  @track selectedAddress;
  @track addressList = [];
  @track error;
  @api location = [];
  @api addselected;
  metadataName = "Address_Candidate_Composite";
  handleSearchChange(event) {
    this.street = event.target.value;
    if (this.street.length >= 4) {
      this.fetchAddressList();
    } else if (this.street.length === 0) {
      this.selectedAddress = null;
      this.addressList = [];
      this.omniApplyCallResp({ selectedStreet: null });
    }
  }

  connectedCallback() {
    console.log("this.metadataName==>", this.metadataName);

    if (this.addselected) {
      this.street = this.addselected;
      this.fetchAddressList(); // Fetch address list if addselected has a value
    }
  }

  fetchAddressList() {
    getAddressCandidate({
      street: this.street,
      metadataName: this.metadataName
    })
      .then((result) => {
        if (Array.isArray(result)) {
          if (result.length == 0 && result[0].error) {
            this.showToast("No Results", result[0].error, "warning");
          } else {
            this.addressList = result.map((item) => ({
              address: item.address,
              location: item.location,
              x: item.x,
              y: item.y,
              key: item.x ? item.x : Math.random()
            }));
            const dropdown = this.template.querySelector(".slds-dropdown");
            if (dropdown) {
              dropdown.style.display = this.addressList.length
                ? "block"
                : "none";
            }
          }
        }
        console.log("addressList >> " + JSON.stringify(this.addressList));
      })
      .catch((error) => {
        console.error("Error fetching address list:", error);
      });
  }

  handleAddressSelect(event) {
    const selectedAddress = event.currentTarget.dataset.address;
    if (selectedAddress) {
      const selectedAddressObj = this.addressList.find(
        (item) => item.address === selectedAddress
      );
      if (selectedAddressObj) {
        this.selectedAddress = selectedAddressObj;
        this.populateAddressFields(selectedAddressObj);
      } else {
        console.error("Selected address not found:", selectedAddressObj);
      }
    }
  }

  showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(event);
  }

  handleSearch() {
    console.log("inside search");
    if (!this.street) {
      this.error = "Search address is required.";
      return;
    }
    this.error = null;
  }

  populateAddressFields(selectedAddress) {
    this.street = selectedAddress.address;
    this.x = selectedAddress.x;
    this.y = selectedAddress.y;
    const dropdown = this.template.querySelector(".slds-dropdown");
    if (dropdown) {
      dropdown.style.display = "none";
    }
    console.log(selectedAddress);
    this.omniUpdateDataJson(selectedAddress);
    this.omniApplyCallResp({ selectedStreet: this.street });
  }
}