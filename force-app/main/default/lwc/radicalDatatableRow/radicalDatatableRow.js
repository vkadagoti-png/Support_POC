import { api, track, LightningElement } from 'lwc';
import LightningConfirm from 'lightning/confirm';
import { deleteRecord } from 'lightning/uiRecordApi';
// import updateSobs from '@salesforce/apex/RadicalRelatedListHelper.updateSobs';
import { updateRecord } from "lightning/uiRecordApi";
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class RadicalDatatableRow extends NavigationMixin(LightningElement) {
    @api recordId = ''
    @api fields = []
    @api record = {}
    @api childSobject = ''
    @api showDeleteButton = false
    // _record = {}
    updatedRecord = {}

    @track error = {}

    isSaving = false
    editState = false

    get rowTds() {
        return this.fields.filter(x => x?.value != 'edit') || []
    }

    async handleSaveClick(event) {

        this.editState = false
        this.isSaving = true

        this.updatedRecord.Id = this.record.Id

        try {
            await updateRecord({
                fields: this.updatedRecord
            });

            this.dispatchEvent(
                new CustomEvent('refresh', {
                    bubbles: true,
                    composed: true,
                    detail: {
                        value: this.record.Id
                    }
                })
            )

        } catch (error) {
            console.error(error);
            const fieldErrors = error?.body?.output?.fieldErrors;
            let errorMessage = '';
            if( fieldErrors ) {
                let fields = Object.keys( fieldErrors );
                for( let i = 0; i < fields.length; ++i ) {
                    const field = fields[i];
                    const errors = fieldErrors[field];
                    for( let errorIndex = 0; errorIndex < errors.length; ++errorIndex ) {
                        const errorInfo = errors[errorIndex];
                        if( errorMessage != '' ) errorMessage += '; '
                        errorMessage += errorInfo.message;
                    }
                }
                const evt = new ShowToastEvent({
                    title: 'Server Error',
                    message: errorMessage,
                    variant: 'error' 
                });
                this.dispatchEvent(evt);
            } else {
                const evt = new ShowToastEvent({
                    title: 'Server Error',
                    message: '',
                    variant: 'error' 
                });
                this.dispatchEvent(evt);
            }
        } finally {
            this.isSaving = false
        }
    }
    
    handleCancelClick(event) {
        // this.editState = this.editState ? false : true   
        this.editState = false
        console.log('cancel')

        this.record = Object.assign({}, this.record);

        // console.log(JSON.parse(JSON.stringify(this.record)))
    }

    handleEditClick(event) {
        this.editState = true
        console.log('edit');
    }

    handleCellChange(event) {
        const { 
            fieldName, 
            rowId,
            value
        } = event.detail

        this.updatedRecord[fieldName] = value;
        // console.log(JSON.parse(JSON.stringify(this.updatedRecord)))
    }

    handleCellBlur( event ) {
        console.log('cell blur');
        const { 
            fieldName, 
            rowId,
            value
        } = event.detail

        let newValue = value;
        //Update Fields to prevent save failure due to validation rule 
        if( this.childSobject === 'Scoring_Detail__c' ) {
            if( fieldName === 'Awarded_Points__c' ) {
                let updatedMax = this.updatedRecord.Max_Points__c;
                let maxPoints;
                if( updatedMax !== undefined ) {
                    maxPoints = updatedMax; 
                } else {
                    maxPoints = this.record.Max_Points__c;
                }
                if( maxPoints ) {
                    newValue = Number( newValue );
                    if( newValue > maxPoints ) {
                        newValue = maxPoints;
                        let search = `c-radical-datatable-cell[data-field="${fieldName}"]`;
                        const cell = this.template.querySelector( search );
                        if( cell ) {
                            cell.updateValue( newValue );
                        } else {
                            console.log("can't find radical number");
                        }
                    }
                }
            } else if (fieldName === 'Max_Points__c' ) {
                newValue = Number(newValue);
                let updatedAwardedPoints = this.updatedRecord.Awarded_Points__c;
                let awardedPoints;
                if( updatedAwardedPoints !== undefined ) {
                    awardedPoints = updatedAwardedPoints; 
                } else {
                    awardedPoints = this.record.Awarded_Points__c;
                }
                if( awardedPoints > newValue ) {
                    let search = `c-radical-datatable-cell[data-field="Awarded_Points__c"]`;
                    const cell = this.template.querySelector( search );
                    if( cell ) {
                        cell.updateValue( newValue );
                    } else {
                        console.log("can't find radical number");
                    }
                    this.updatedRecord.Awarded_Points__c = newValue;
                }
            }
        }
        this.updatedRecord[fieldName] = newValue;
    }

    async handleDeleteClick() {
        
        try {

            if (!await LightningConfirm.open({
                message: `Are you sure you want to delete ${this.record.Id}?`,
                // variant: 'headerless',
                label: 'Confirm deletion',
                theme: 'alt-inverse'
                // setting theme would have no effect
            })) {
                return
            }

            console.log('delete ', this.record.Id)

            this.isSaving = true
            
            await deleteRecord(this.record.Id)

            this.dispatchEvent(
                new CustomEvent('delete', {
                    bubbles: true,
                    composed: true,
                    detail: {
                        value: this.record.Id
                    }
                })
            )
        } catch (error) {
            console.error(error)
        } finally {
            this.isSaving = false
        }
    }

    get isEdit() {
        return this.editState
    }

    handleClone() {
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                actionName: 'clone',
                recordId : this.record.Id 
            },
        });
    }
}