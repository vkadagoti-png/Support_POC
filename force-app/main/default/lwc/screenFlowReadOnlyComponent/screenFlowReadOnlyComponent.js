import { LightningElement, wire, api, track } from 'lwc';

export default class ScreenFlowReadOnlyField extends LightningElement {
    @api fieldLabel;
    @api fieldValue;
    @api fieldType;
    @api fieldLevelHelp;

   isCheckboxField = false;
   isPhoneField = false;

   connectedCallback() {

    if (this.fieldType != null && (this.fieldType=='toggle' ||  this.fieldType=='checkbox' )) {
        this.isCheckboxField = true;
    }
    else if (this.fieldType != null && this.fieldType=='tel'){
        this.isPhoneField = true;
    }
}
}