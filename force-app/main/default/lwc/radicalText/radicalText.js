import { api, track, LightningElement } from 'lwc';

export default class RadicalText extends LightningElement {
    @api fieldName = ''
    // @api record = {}
    @api isEdit = false
    @track _record = {}
    
    connectedCallback() {
        console.log(JSON.parse(JSON.stringify(this.record)))
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
                    value,
                    rowId: this.record.Id,
                    fieldName: this.fieldName
                }
            })
        )
    }
}