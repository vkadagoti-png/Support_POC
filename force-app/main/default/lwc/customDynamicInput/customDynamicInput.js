import { LightningElement, api } from 'lwc';
 
export default class CustomDynamicInput extends LightningElement {
    @api
    fieldInfo;

    @api
    required;

    @api
    customKey;

    setValue = false;

    @api 
    disabled;

    @api
    get record() {
        return this._record;
    } set record( value ) {
        this._record = value;
        this.setValue = true;
    }
    _record;

    @api
    reportValidity() {
        if( this.IsTextArea ) {
            let textArea = this.template.querySelector('lightning-textarea');
            if( textArea ) {
                return textArea.reportValidity();
            }
        } else {
            let inputField = this.template.querySelector('lightning-input');
            if( inputField ) {
                return inputField.reportValidity();
            }
        }
        return true;
    }

    @api
    resetField() {
        if( this.IsTextArea ) {
            let textArea = this.template.querySelector('lightning-textarea');
            if( textArea ) {
                textArea.value = null;
            }
        } else {
            let inputField = this.template.querySelector('lightning-input');
            if( inputField ) {
                inputField.value = null;
            }
        }
    }

    @api
    currentValue() {
        if( this.IsTextArea ) {
            let textArea = this.template.querySelector('lightning-textarea');
            if( textArea ) {
                return textArea.value;
            }
            return null;
        }

        let inputField = this.template.querySelector('lightning-input');
        if( inputField ) {
            if( this.IsCurrency || this.IsDouble ) {
                return Number( inputField.value );
            }
            if( this.IsPercent ) {
                return Number( inputField.value ) / 100;
            }
            return inputField.value;
        }
        return null;
    }

    get Validity() {
        if( this.IsTextArea ) {
            let textArea = this.template.querySelector('lightning-textarea');
            if( textArea ) {
                return textArea.checkValidity();
            }
        } else {
            let inputField = this.template.querySelector('lightning-input');
            if( inputField ) {
                return inputField.checkValidity();
            }
        }
        return true;
    }

    @api
    getFieldAndValue() {
        return {
            value : this.currentValue(),
            field : this.fieldInfo.api,
            validity : this.Validity
        }
    }

    get Label() {
        return this.fieldInfo.label;
    }

    get Type() {
        return this.fieldInfo.type;
    }

    get IsCurrency() {
        return this.Type === 'CURRENCY';
    }
    
    get IsText() {
        return this.Type === 'STRING';
    }

    get IsTextArea() {
        return this.Type === 'TEXTAREA';
    }

    get IsDouble() {
        return this.Type === 'DOUBLE';
    }

    get IsPercent() {
        return this.Type === 'PERCENT';
    }
    
    get Step() {
        const scale = this.fieldInfo.scale;
        if( scale ) {
            let scaleString = '1'; 
            for( let i = 1; i < scale; ++i ) {
                scaleString = '0' + scaleString;
            }
            scaleString = '.' + scaleString;
            return scaleString;
        }
        return null;
    }

    get MaxNumberString() {
        const precision = this.fieldInfo.precision;
        const scale = this.fieldInfo.scale;
        const MAX_WHOLE_NUMBERS = precision - scale;
        
        let maxNumberString = '';
        for( let i = 0; i < MAX_WHOLE_NUMBERS; ++i ) {
            maxNumberString += '9';
        }
        if( scale ) {
            maxNumberString += '.'; 
            for( let i = 0; i < scale; ++i ) {
                maxNumberString += '9';
            }
        }
        return maxNumberString;
    }

    renderedCallback() {
        if( this.setValue ) {
            this.setValue = false;
            if( this.record ) {
                let value = this.record[this.fieldInfo.api];
                if( value != null ) {
                    if( this.IsTextArea ) {
                        let textArea = this.template.querySelector('lightning-textarea');
                        if( textArea ) {
                            textArea.value = value;
                        }
                    } else {
                        let inputField = this.template.querySelector('lightning-input');
                        if( inputField ) {
                            if( this.IsPercent ) {
                                inputField.value = value * 100;
                            } else {
                                inputField.value = value;
                            }
                        }
                    }
                }
            }
        }
    }

    handleInputChange( event ) {
        event.stopPropagation();
        this.dispatchEvent( new CustomEvent("change", {
            detail : {
                key : this.customKey,
                fieldAPI : this.fieldInfo.api
            }
        }));
    }
}