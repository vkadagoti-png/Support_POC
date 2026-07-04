import { LightningElement, api, wire } from 'lwc';
import getRelatedSubApplications from '@salesforce/apex/DFDFW_APP_GetSubAppController.getRelatedSubApplications';
import { subscribe, MessageContext } from "lightning/messageService";
import REFRESH_FILES from "@salesforce/messageChannel/DFDFW_Permit_Response__c";
import { refreshApex } from "@salesforce/apex";

export default class LwcDFDFWRelatedApplicationsList extends LightningElement {
    @api recordId; // The Service_Application_Detail__c ID passed to the component
    subApplications = [];
    error;
    wiredSubInfo;
    subscription = null;

    columns = [
        //{
        //   label: 'Name',
        //    fieldName: 'recordLink',
        //    type: 'url',
        //   typeAttributes: { label: { fieldName: 'Name' }, target: '_self' }
        //},
        //{
        //    label: 'Case #',
        //    fieldName: 'Case_Number__c'
        //},
        {
          label: 'Case #',
          fieldName: 'recordLink',
          type: 'url',
          typeAttributes: { label: { fieldName: 'Case_Number__c' }, tooltip: 'Click to view', target: '_self' }
        },
        {
            label: 'Type',
            fieldName: 'Permit_Type__c'
        },
        {
            label: 'Status',
            fieldName: 'Status__c'
        },
        {
            label: 'Fee',
            fieldName: 'Fee__c',
            type: 'currency',
            typeAttributes: {
                currencyCode: 'USD'
              },
        }
    ];

    @wire(MessageContext)
    messageContext;


    connectedCallback(){
        this.subscribeToMessageChannel();
    }

    @wire(getRelatedSubApplications, { serviceApplicationId: '$recordId' })
    wiredSubApplications(value) {

        this.wiredSubInfo = value;
        const { data, error } = value;

        if (data) {
            // Create links for navigation
            this.subApplications = data.map((subApp) => ({
                ...subApp,
                //recordLink: `/sub-application/${subApp.Id}`
                recordLink: subApp.Case_Number__c ? `/sub-application/${subApp.Id}` : '', // If no Case_Number__c, leave it blank
                Case_Number__c: subApp.Case_Number__c || '' // Ensure Case_Number__c is blank if it's not set
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.subApplications = [];
        }
    }

    subscribeToMessageChannel() {
        this.subscription = subscribe(
            this.messageContext,
            REFRESH_FILES,
            (message) => this.triggerRefresh(message)
        );
    }


    triggerRefresh(message){
        //console.log('LMS Message Received! Refreshing data.');
        //console.log('Message Payload:', message);
        refreshApex(this.wiredSubInfo);

    }


}