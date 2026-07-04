import { LightningElement, api } from 'lwc';
import {FlowNavigationNextEvent} from 'lightning/flowSupport';
import {FlowNavigationBackEvent} from 'lightning/flowSupport';
import {FlowNavigationFinishEvent} from 'lightning/flowSupport';
import {NavigationMixin} from "lightning/navigation";

export default class FlowCustomNavigationButton extends NavigationMixin(
    LightningElement
) {
	//Declare variables
	@api
	label = '';

	@api
	divStyle = '';

	@api
	buttonVariant = '';

	@api 
	buttonStyle = '';

	@api 
	buttonClass = '';

	@api 
	redirectURL = '';

	@api
	standardButton = false;

	@api
	disabled = false;

	@api
	previous = false;

	@api
	finish = false;

	@api
	redirect = false;
		
	@api
	openNewTab = false;

	@api
	flag;

	navigate() {
		this.flag = true;
		if(this.previous) {
			const backNavigationEvent = new FlowNavigationBackEvent();
			this.dispatchEvent(backNavigationEvent);
		} else if(this.finish) {
			const finishNavigationEvent = new FlowNavigationFinishEvent();
			this.dispatchEvent(finishNavigationEvent); 
		} else if(this.redirect) {
				const config = {
						type: 'standard__webPage',
						attributes: {
								url: this.redirectURL
						}
				};
				this[NavigationMixin.Navigate](config).then(( url ) => { 
console.warn( url);
window.open( url ); 
});
				// this[NavigationMixin.Navigate](config);
		} else if(this.openNewTab && this.redirectURL != null) {
				window.open(this.redirectURL, '_blank');
		} else {
			const nextNavigationEvent = new FlowNavigationNextEvent();
			this.dispatchEvent(nextNavigationEvent);
		}
	}
}