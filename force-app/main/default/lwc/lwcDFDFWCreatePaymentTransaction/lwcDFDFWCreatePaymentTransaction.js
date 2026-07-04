import { LightningElement, api} from 'lwc';
import updateTransactionId from "@salesforce/apex/DFDFW_INTPAYMENT_CalloutController.updateTransactionId";
import pubsub from "omnistudio/pubsub";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LwcDFDFWCreatePaymentTransaction extends LightningElement{


    @api recordId;
    @api serviceApp = false;

    connectedCallback(){
        const urlObj = new URL(window.location.href);
        const searchParams = new URLSearchParams(urlObj.search);
        const transactionId = searchParams.get("transactionId");
        if (transactionId != null){
            updateTransactionId({recordId: this.recordId, transactionId: transactionId, serviceApp: this.serviceApp})
            .then((data) => {
                if (data == true){
                    pubsub.fire("ReloadChannel", "ReloadEvent", {});
                    const event = new ShowToastEvent({
                        variant: 'success',
                        title: 'Payment Successfully Submitted',
                        message:
                            'Thank you! Your payment has been successfully submitted. We will contact you once it has been processed.',
                        mode: 'sticky'
                    });
                    this.dispatchEvent(event);
                }
            })
            .catch((error) => {
                console.error(error);
                
            });
        }
    }

}