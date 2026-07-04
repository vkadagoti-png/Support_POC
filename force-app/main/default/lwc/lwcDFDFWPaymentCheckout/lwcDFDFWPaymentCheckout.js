import { LightningElement, wire, track, api } from 'lwc';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import payFees from "@salesforce/apex/DFDFW_INTPAYMENT_CalloutController.payFees";

export default class LwcDFDFWPaymentCheckout extends OmniscriptBaseMixin(LightningElement) {

    @api permitId;
    @api returnUrl = window.location.href;
    @api email;
    @api searchFeeCode;
    @api getAllFees;
    @api buttonLabel = 'Make Payment';
    @api nextButton = false;
    @api nextButtonLabel;

    @track paymentResponse; // Track payment response

    loading = false;

    // Method to call the payment API when button is clicked
    handlePaymentCheckout() {
        this.loading = true;
        console.log('permitId: ' + this.permitId);
        if(Number.isInteger(this.permitId)){
            payFees({permitId: this.permitId, returnUrl: this.returnUrl, email: this.email, searchFeeCode: this.searchFeeCode, getAllFees: this.getAllFees})
            .then(result => {
                this.loading = false;
                if(result.success){
                    this.paymentResponse = result.url;
                    window.location.href =  this.paymentResponse;
                }
                else{
                    console.error('Error in payment:', result.error);
                    const showError = new ShowToastEvent({
                        title: 'Error!',
                        message: result.error,
                        variant: 'error',
                        mode: 'sticky'
                    });
                    this.dispatchEvent(showError);
                }
            })
            .catch(error => {
                console.error('Error in payment callout:', error);
                this.loading = false;
                const showError = new ShowToastEvent({
                    title: 'Error!',
                    message: error.body.message,
                    variant: 'error',
                    mode: 'sticky'
                });
                this.dispatchEvent(showError);
            });
        }
        else{
            this.loading = false;
            const showError = new ShowToastEvent({
                title: 'Error!',
                message: 'Looks like your application may not have been submitted properly. Please contact the special events team to confirm.',
                variant: 'error',
                mode: 'sticky'
            });
            this.dispatchEvent(showError);
        }
    }

    handleNext(){
        this.omniNextStep();
    }

}