import { LightningElement, track, wire, api } from 'lwc';
import getTVREventTiles from '@salesforce/apex/DFDFW_TILECONFIG_TVRServicesController.getTVREventTiles';
import TILES from '@salesforce/resourceUrl/DFDFW_Service_Tiles';
import { NavigationMixin } from 'lightning/navigation';

export default class lwcDFDFWServiceTileMenuTornado extends NavigationMixin(LightningElement) {
    @track tiles = [];

    URL;
    connectedCallback() {
        this.URL = window.location.origin;
        console.log('URL ' + this.URL);
    }


    @wire(getTVREventTiles, {})
    wiredEventTiles({ error, data }) {
        if (data) {
            console.log('Data--> : ',data);
            this.tiles = data.map(tile => {
                return {
                    id: tile.Id,
                    label: tile.DFDFW_Tile_Title__c,
                    eventImageURL: TILES + '/' + tile.DFDFW_Icon_File_Name__c,
                    subheading: tile.DFDFW_Tile_Subheading__c,
                    communityURL: tile.DFDFW_Service_URL__c
    
                };
            });
           
        } else if (error) {
            // Handle error
            console.error('Error fetching event tiles:', error);
        }
        console.log('titles ' + JSON.stringify(this.tiles) );
    }

    handleTileClick(event) {
        const eventtype = event.currentTarget.dataset.label;
        const tileId = event.currentTarget.dataset.id; 
        const selectedTile = this.tiles.find(tile => tile.id === tileId);
        const communityURL = selectedTile.communityURL;

        // Navigate to the community page with the checkbox parameter
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                  url: `${communityURL}?eventType=${eventtype}`
                  //url: {communityURL} + `?eventType=${eventtype}&uploadCheckbox=${uploadCheckbox}&addressCheckbox=${addressCheckbox}`
            }
        });
        // Dispatch a custom event with the selected event type
        this.dispatchEvent(new CustomEvent('tileclick', {
            detail: { eventtype }
        }));
    
}
}