import { api, LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class NavToRecord extends NavigationMixin(
    LightningElement
) {
    @api recordId
    @api objectAPIName = ''
    
    connectedCallback() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: this.objectAPIName,
                actionName: 'view',
            },
        }).then((url) => {
            window.location.href = url;
        });
    }
}