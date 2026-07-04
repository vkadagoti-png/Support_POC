import { LightningElement, api, track } from 'lwc';

function createRow( key, record ) {
    return { 
        Id : key,
        record : record
    };
}

export default class DynamicBudgetTable extends LightningElement {
    @api
    categoryData;

    @api
    minimumRows = 0;

    @track rows = [];
    fields = [];

    deletedRowIds = [];

    hasTotals = false;
    rowIndex = 0;

    showAddRowButton = false;
    
    get showDeleteButton(){
        return this.rows.length > 1;
    }

    @api
    focus() {
        let table = this.template.querySelector('table[data-id="mainTable"]');
        if( table ) {
            table.scrollIntoView({
                behavior : 'smooth',
                inline : 'start'
            });
        }
    }

    @api
    evaluateRows() {
        let tableData = {
            valid : true,
            rows : [],
            deletedRowIds : this.deletedRowIds 
        }
        let rowMap = new Map();

        let validationErrorSet = new Set();
        let inputs = this.template.querySelectorAll('c-custom-dynamic-input');
        for( let i = 0; i < inputs.length; ++i ) {
            let input = inputs[i];
            let { value, field, validity } = input.getFieldAndValue();
            let key = input.dataset.key;
            if( validity ) {
                if( value || value === 0 ) {
                    let row = rowMap.get( key );
                    if( row == null ) {
                        row = { 
                            Id : key,
                            BudgetCategoryId : this.categoryData.budgetCategoryId,
                            Amount : this.calculateRowTotal( key )
                        }
                    };
                    row[field] = value;
                    rowMap.set( key, row );
                }            
            } else {
                validationErrorSet.add( key );
            }
        }

        if( rowMap.size > 0 ) {
            let rowKeysIterator = rowMap.keys();
            let keysWithErrors = [];
            for (const key of rowKeysIterator ) {
                let rowValue = rowMap.get(key);
                let isEmptyRow = true;
                {//Check if row is empty
                    let fields = this.fields;
                    for( let i = 0; i < this.fields.length; ++i ) {
                        let field = fields[i];
                        let fieldAPI = field.fieldAPI;
                        let fieldValue = rowValue[fieldAPI];
                        if( fieldValue ) {
                            isEmptyRow = false;
                            console.log( fieldAPI, fieldValue );
                            break;
                        }
                    }
                }
                //Only Validate on non empty rows since we want to allow user to skip rows they don't need to set
                if( !isEmptyRow && validationErrorSet.has( key ) ) {
                    tableData.valid = false;
                    keysWithErrors.push( key ); 
                } else {
                    tableData.rows.push( rowValue );
                }
            }
            
            if( !tableData.valid ) {
                for( let i = 0; i < keysWithErrors.length; ++i ) {
                    let key = keysWithErrors[i];
                    let rowInputs = this.template.querySelectorAll(`c-custom-dynamic-input[data-key="${key}"]`);
                    for( let i = 0; i < rowInputs.length; ++i ) { 
                        let rowInput = rowInputs[i];
                        rowInput.reportValidity();
                    }
                }
            }
        }
        
        if( tableData.rows.length < this.minimumRows ) {
            tableData.rows.valid = false;
        }

        return tableData;
    }

    get Category() {
        return this.categoryData.category;
    }

    recalculateTotals = false;
    renderedCallback() {
        if( this.recalculateTotals ) {
            this.recalculateTotals = false;
            this.recalculateAll();
        }
    }

    connectedCallback() {
        if( this.minimumRows == null ) {
            this.minimumRows = 0;
        }
        this.showAddRowButton = this.categoryData.showAddRowButton;
        {//Determine if need to rollup any fields
            this.fields = this.categoryData.fields;
            for( let i = 0; i < this.fields.length; ++i ) {
                let field = this.fields[i];
                if( field.rollupTotal ) {
                    this.hasTotals = true;
                    break;
                }
            }
        }
        {//Handle Default Rows
            const records = this.categoryData.records;
            if( records?.length > 0 ) {
                for( let i = 0; i < records.length; ++i ) {
                    let record = records[i];
                    this.rows.push( createRow( record.Id, record ) );
                }
                this.recalculateTotals = true;
            } else {
                this.addRow();
            }
        }
    }
    
    addRow() {
        let key = `_tempRow${this.rowIndex++}`;
        let row = createRow( key ); 
        this.rows.push( row );
    }

    calculateRowTotal( key ) {
        let rowTotal = 0;
        {//Row Rollup
            let rowInputs = this.template.querySelectorAll(`c-custom-dynamic-input[data-key="${key}"][data-roll-up="true"]`);
            for( let i = 0; i < rowInputs.length; ++i ) { 
                let rowInput = rowInputs[i];
                let value = rowInput.currentValue();
                if( value ) {
                    rowTotal += value;
                }
            }
            let rowTotalOutput = this.template.querySelector(`lightning-formatted-number[data-tag="rowTotal"][data-key="${key}"]`);
            if( rowTotalOutput ) {
                rowTotalOutput.value = rowTotal;
            }
        }
        return rowTotal;
    }

    calculateColumnTotal( fieldAPI ) {
        {//Column Rollup
            let grandTotal = 0;
            let columnInputs = this.template.querySelectorAll(`c-custom-dynamic-input[data-api="${fieldAPI}"][data-roll-up="true"]`);
            for( let i = 0; i < columnInputs.length; ++i ) { 
                let columnInput = columnInputs[i];
                let value = columnInput.currentValue();
                if( value ) {
                    grandTotal += value;
                }
            }
            let grandTotalOutput = this.template.querySelector(`lightning-formatted-number[data-tag="columnTotal"][data-api="${fieldAPI}"]`);
            if( grandTotalOutput ) {
                grandTotalOutput.value = grandTotal;
            }
        }
    }

    calculateGrandTotal() {
        {//Grand Total Rollup
            let grandTotal = 0;
            let rowTotals = this.template.querySelectorAll(`lightning-formatted-number[data-tag="rowTotal"]`);
            for( let i = 0; i < rowTotals.length; ++i ) { 
                let rowTotal = rowTotals[i];
                let value = rowTotal.value;
                if( value ) {
                    grandTotal += Number(value);
                }
            }
        
            let grandTotalOutput = this.template.querySelector(`lightning-formatted-number[data-tag="grandTotal"]`);
            if( grandTotalOutput ) {
                grandTotalOutput.value = grandTotal;
            }
        }
    }

    recalculateAll() {
        for( let i = 0; i < this.rows.length; ++i ) {
            let row = this.rows[i];
            let key = row.Id;
            this.calculateRowTotal( key );
        }
        for( let i = 0; i < this.fields.length; ++i ) {
            let field = this.fields[i];
            let fieldAPI = field.fieldAPI;
            this.calculateColumnTotal( fieldAPI );
        }
        this.calculateGrandTotal();
    }

    handleDynamicFieldInputChange( event ) {
        event.stopPropagation();
        const { key, fieldAPI } = event.detail;
        if( key && fieldAPI ) {
            this.calculateRowTotal( key );
            this.calculateColumnTotal( fieldAPI );
            this.calculateGrandTotal();
        }
    }

    clearRow( event ) {
        const key = event.currentTarget.dataset.key;
        let isRealId = !key.startsWith('_');
        if( isRealId ) {
            this.deletedRowIds.push( key );
        }
        this.recalculateTotals = true;
        this.rows = this.rows.filter( row => row.Id !== key );
    }

}