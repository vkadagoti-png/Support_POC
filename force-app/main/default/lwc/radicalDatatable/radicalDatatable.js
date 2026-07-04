import { api, track, LightningElement } from 'lwc';

export default class RadicalRelatedList extends LightningElement {
    @api recordId
    @api records = []
    @api fields = []
    @api lastSavedRecords = []
    @api childSobject = ''
    @api showDeleteButton = false

    @api get tableSettings() {
        return this._tableSettings;
    }
    set tableSettings( newSettings ) {
        this._tableSettings = JSON.parse(JSON.stringify(newSettings));
        this.updateTableSettings();
    } 
    _tableSettings = {
        columnWidths : {}
    }
    // fixedWidth = 'fit-content'
    thStyle = 'width:15rem; background: #F3F3F3; position: sticky; top: 0px; z-index: 9999;'

    tableCol
    mouseDown = false
    _x = 0

    updateSettingsOnRerender = false;

    updateTableSettings() {
        this.updateSettingsOnRerender = false;
        const settings = this.tableSettings; 
        if( !settings ) return;
        const columnWidths = settings.columnWidths;
        if( !columnWidths ) return;
        const tableIndexes = Object.keys( columnWidths );
        const tableIndexCount = tableIndexes.length;
        if( tableIndexCount !== 0 ) {
            this.updateSettingsOnRerender = true;
        } 
        for( let i = 0; i < tableIndexCount; ++i ) {
            const tableIndex = tableIndexes[i];
            let columnElement = this.template.querySelector( `th[data-tag="tableColumn"][data-index="${tableIndex}"]`);
            if( columnElement ) {
                columnElement.style.width = columnWidths[tableIndex];
                this.updateSettingsOnRerender = false;
            }
        }
    }

    renderedCallback() {
        if( this.updateSettingsOnRerender ) {
            this.updateTableSettings();
        }
    }

    handleMouseUp(element) {
        this.mouseDown = false
        if( this.tableCol ) {//Save Widths
            const index = this.tableCol.dataset.index;
            const width = this.tableCol.style.width;
            if( !this.tableSettings ) return;
            this.tableSettings.columnWidths[index] = width; 
            console.log("save");
            this.dispatchEvent(
                new CustomEvent('savetablesettings', {
                    bubbles: false,
                    detail: {
                        settings : this.tableSettings
                    }
                })
            )
        }
    }
 
    handleMouseDown(element) {
        
        const currentElement = element.target

        if (!currentElement.className.includes('radical_resizable__divider')) {
            return
        }

        let col = currentElement
        while (col.tagName !== "TH") {
            col = col.parentNode;
        }

        this.tableCol = col

        this.mouseDown = true
        this._x = element.clientX
    }
 
    handleMouseMove(element) {

        if (!element.which === 1 || !this.mouseDown) {
            return 
        }

        const diff = element.clientX - this._x

        if (diff === 0) {
            return 
        }

        const prevWidth = Number(this.tableCol.offsetWidth)
        
        const w = prevWidth + diff

        if (w <= 150) {
            return
        }
        
        this.tableCol.style.width = w + 'px'

        this._x = element.clientX 
    }
 
    handleDBLClickResizable() {
        console.log('dblclick')
    }
}