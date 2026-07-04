import { LightningElement, api } from 'lwc';

import {
    FlowNavigationNextEvent,
    FlowNavigationBackEvent,
    FlowNavigationFinishEvent 
} from 'lightning/flowSupport';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import GetData from '@salesforce/apex/OperatingBudgetTablesController.GetData';
export default class OperatingBudgetTables extends LightningElement {
    
    @api
    availableActions = [];

    @api
    budgetCategories = [];

    @api
    budgetCategoryDetails = [];

    @api
    newDetails = [];

    @api
    existingDetails = [];

    @api
    detailsToDelete = [];

    @api 
    readOnly = false;

    @api
    subCategoryTemplate;

    showSpinner = false;   

    handlePrevious() {
        this.dispatchEvent(new FlowNavigationBackEvent());
    }

    handleConfirm() {
        if( !this.readOnly ) {
            //Clear out Arrays
            this.newDetails.length = 0;
            this.existingDetails.length = 0;
            this.detailsToDelete.length = 0;

            let tables = this.template.querySelectorAll('c-dynamic-budget-table');
            for( let i = 0; i < tables.length; ++i ) {
                let table = tables[i];
                let evaluation = table.evaluateRows();
                if( !evaluation.valid ) {
                    table.focus();
                    return;
                }
            
                let rows = evaluation.rows;
                for( let i = 0; i < rows.length; ++i ) {
                    let row = rows[i];
                    const fakeId = row.Id.startsWith('_');
                    if( fakeId ) {
                        delete row.Id;
                        this.newDetails.push( row );
                    } else {
                        this.existingDetails.push( row );
                    }
                } 
            
                let deletedRowIds = evaluation.deletedRowIds;
                if( deletedRowIds?.length > 0 ) {
                    for( let i = 0; i < deletedRowIds.length; ++i ) {
                        let recordId = deletedRowIds[i];
                        this.detailsToDelete.push({ Id : recordId });
                    }
                }
            }
        
        }
        {//Flow Navigation
            let availableActions = this.availableActions;
            for( let i = 0; i < availableActions.length; ++i ) {
                let action = availableActions[i];
                if( action === 'NEXT' ) {
                    this.dispatchEvent(new FlowNavigationNextEvent());
                } else if( action === 'FINISH' ) {
                    this.dispatchEvent(new FlowNavigationFinishEvent());
                }
            }
        }
    }

    tables = [];
    renderPage = false;
    showNextButton = false;
    showPreviousButton = false;    

    connectedCallback() {
        this.showSpinner = true;
        {//Enable Flow Buttons
            let availableActions = this.availableActions;
            for( let i = 0; i < availableActions.length; ++i ) {
                let action = availableActions[i];
                if( action === 'NEXT' || action === 'FINISH' ) {
                    this.showNextButton = true;
                } else if( action === 'BACK') {
                    this.showPreviousButton = true;
                }
            }
        }

        let categoryToBudgetCategory = new Map();
        let categoryList = [];
        {
            const budgetCategories = this.budgetCategories;
            for( let i = 0; i < budgetCategories.length; ++i ) {
                let budgetCategory = budgetCategories[i]; 
                categoryToBudgetCategory.set( budgetCategory.Name, budgetCategory );
                categoryList.push( budgetCategory.Name );
            }
        }
        GetData({ 
            template : this.subCategoryTemplate,
            categories : categoryList
        })
        .then( response => {
            let categoryMap = new Map();
            {
                let fieldMap = new Map();
                const fieldMetadata = response.fields;
                for( let i = 0; i < fieldMetadata.length; ++i ) {
                    let fieldData = fieldMetadata[i];
                    fieldMap.set( fieldData.api, fieldData ); 
                }
                const budgetFields = response.budgetFields;
                for( let i = 0; i < budgetFields.length; ++i ) {
                    let budgetField = budgetFields[i];
                    const category = budgetField.category;
                    let currentList = categoryMap.get( category );
                    if( currentList == null ) {
                        currentList = [];
                    }
                    let data = {...budgetField};
                    data.disabled = this.readOnly;
                    data.fieldInfo = {...fieldMap.get( budgetField.fieldAPI )};
                    currentList.push( data );
                    categoryMap.set( category, currentList );
                }
            }

            let categoryDetailMap = new Map();
            {//Pre-populate category details
                let categoryDetails = this.budgetCategoryDetails;
                if( categoryDetails?.length ) {
                    for( let i = 0; i < categoryDetails.length; ++i ) {
                        let categoryDetail = categoryDetails[i];
                        let budgetCategoryId = categoryDetail.BudgetCategoryId;
                        let categoryDetailList = categoryDetailMap.get( budgetCategoryId );
                        if( categoryDetailList == null ) {
                            categoryDetailList = [];
                        }
                        categoryDetailList.push( categoryDetail ); 
                        categoryDetailMap.set( budgetCategoryId, categoryDetailList );
                    }
                }
            }

            categoryMap.forEach( (value, key, map) => {
                let categoryData = categoryToBudgetCategory.get( key );

                let fields = value;
                let readOnlyFieldsStringList = categoryData.Read_Only_Detail_Fields__c;
                if( readOnlyFieldsStringList?.length > 0 ) {
                    let disabledFields = readOnlyFieldsStringList.split(',');
                    for( let i = 0; i < fields.length; ++i ) {
                        let field = fields[i];
                        let fieldApi = field.fieldAPI;
                        if( disabledFields.includes( fieldApi ) ) {
                            field.disabled = true;
                        }                    
                    }
                }

                let showAddRowButton = categoryData.Can_Add_More_Details__c;
                if( this.readOnly === true ) {
                    showAddRowButton = false;
                }
                let table = {
                    showAddRowButton : showAddRowButton,
                    budgetCategoryId : categoryData.Id,
                    category : key,
                    fields : fields,
                    records : categoryDetailMap.get( categoryData.Id )
                }
                this.tables.push( table );
            });
            this.renderPage = true;
        })
        .catch( error => {
            console.error( error );
            const event = new ShowToastEvent({
                title: 'Server Error',
                message: 'Ensure that you have the correct Apex Permissions',
                variant:'error',
                mode : 'sticky'
            });
            this.dispatchEvent(event);
        })
        .finally( () => {
            this.showSpinner = false;
        });
    }
}