import { LightningElement, api, track, wire } from 'lwc';
import getRecordTypIds from '@salesforce/apex/CustomLookupController.getRecordTypeIds';

export default class CustomComboBoxGetRecordType extends LightningElement {
    @api objectName;
    @api filterpicklist;
    @api fieldName;
    @api filter;
    @api fieldLabel;
    @api value;
    @track options;
    @api disabledCustomLookup;

    @wire(getRecordTypIds, {objectApiName: '$objectName', fieldApiName: '$fieldName', filter: '$filter', filterSales: '$filterpicklist'})
    recordTypeProcess({error, data}) {
        if(data) {
            //console.log('data.values:' + JSON.stringify(data.values));
            console.log('recordType:' + JSON.stringify(data));
            this.options = data.map(plValue => {
                return {
                    label: plValue.Name,
                    value: plValue.DeveloperName
                };
            });
        }
        else if(error) {
            console.log('error: ' + JSON.stringify(error));
        }
    }
    @api getRecordTypeIds(filterSale) {
        this.filterpicklist = filterSale;
        this.dispatchEvent(new CustomEvent('showloading', {detail: {record: true}}));
        getRecordTypIds({objectApiName: this.objectName, fieldApiName: this.fieldName, filter: this.filter, filterSales: this.filterpicklist}).then(data => {
            if(data) {
                this.options = data.map(plValue => {
                    return {
                        label: plValue.Name,
                        value: plValue.DeveloperName
                    };
                });
                this.dispatchEvent(new CustomEvent('showloading', {detail: {record: false}}));
            }
        });
    }
    handleChange(event) {
        this.value = event.detail.value;
        //console.log('this.value:' + JSON.stringify(this.value));

        this.dispatchEvent(new CustomEvent('selectrecordtype', {detail: {record: this.value}}));
    }

    @api setRecordType(value) {
        this.value = value;

        this.dispatchEvent(new CustomEvent('selectrecordtype', {detail: {record: this.value}}));
    }

    connectedCallback() {

    }

    renderedCallback() {

    }
}