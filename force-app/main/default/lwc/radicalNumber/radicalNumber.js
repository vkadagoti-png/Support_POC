import { api, track, LightningElement } from 'lwc';

export default class RadicalNumber extends LightningElement {
    @api fieldName = ''
    // @api record = {}
    @api isEdit = false
    @track _record = {}

    @api updateValue( newValue ) {
        if( !this.disabled ) {
            this.record[this.fieldName] = newValue;
            
            let inputField = this.template.querySelector('lightning-input');
            if( inputField ) {
                inputField.value = newValue;
            }
        }
    }    

    @api get record() {
        return this._record
    }
    set record(value) {
        this._record = Object.assign({}, value)
    }
    
    get recordValue() {
        return this.record[this.fieldName]
    }
    get disabled() {
        return !this.isEdit
    }

    handleChange(event) {

        const value = event.detail.value

        this.record[this.fieldName] = value

        this.dispatchEvent(
            new CustomEvent('cellchange', {
                bubbles: true,
                composed: true,
                detail: {
                    value: value,
                    rowId: this.record.Id,
                    fieldName: this.fieldName
                }
            })
        )
    }

    handleBlur( event ) {
        console.log("cell blur");
        event.stopPropagation();
        const value = event.currentTarget.value;

        this.record[this.fieldName] = value;

        this.dispatchEvent(
            new CustomEvent('cellblur', {
                bubbles: true,
                composed: true,
                detail: {
                    value: value,
                    rowId: this.record.Id,
                    fieldName: this.fieldName
                }
            })
        )
    }
}