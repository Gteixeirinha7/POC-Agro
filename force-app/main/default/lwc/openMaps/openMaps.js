import { LightningElement, api, track, wire } from 'lwc';
import getLocalization from '@salesforce/apex/OpenMapsController.getLocalization';

export default class OpenMaps extends LightningElement {
@api mapMarkers;
@api markersTitle;
@api center;
@api recordId;
@api locationInfo;

async connectedCallback(){

await getLocalization({eventId: this.recordId})
    .then(data => {
        if (data) {
            this.locationInfo = data;
        }
    })
    .catch(error => {
        console.log(error);
    });

    this.mapMarkers = [
        {
            location: {
                Latitude: this.locationInfo.Checkin__c.latitude,
                Longitude: this.locationInfo.Checkin__c.longitude
            },
            title: 'Local de check-in',
        },
    ];

    this.markersTitle = 'Coordenadas';

    this.center = {
        location: { Latitude: this.locationInfo.Checkin__c.latitude, Longitude: this.locationInfo.Checkin__c.longitude},
    };
}


}