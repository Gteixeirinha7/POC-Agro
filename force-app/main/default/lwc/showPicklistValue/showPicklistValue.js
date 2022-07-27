import { LightningElement, wire, api, track } from 'lwc';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import {refreshApex} from '@salesforce/apex';

export default class ShowPicklistValue extends LightningElement {
    @api disabledCustomLookup;
    @api picklistName;
    @api objectName;
    @api fieldName;
    @api fieldLabel;
    @api recordTypeId;
    @api value;
    @api showAllOption;
    @track options;
    apiFieldName;
    allOptions;

    @wire(getObjectInfo, { objectApiName: '$objectName' })
    getObjectData({ error, data }) {
        if (data) {
            //console.log('data.fields: ' + JSON.stringify(data.fields))
            if (this.recordTypeId == null)
                this.recordTypeId = data.defaultRecordTypeId;
                //console.log('this.recordTypeId: ' + JSON.stringify(this.recordTypeId));
            this.apiFieldName = this.objectName + '.' + this.fieldName;
            //console.log('this.apiFieldName: ' + JSON.stringify(this.apiFieldName));
            //this.fieldLabel = data.fields[this.fieldName].label;
            //console.log('this.fieldLabel: ' + JSON.stringify(this.fieldLabel));
            
        } else if (error) {
            // Handle error
            console.log('==============Error1  ');
            console.log(JSON.stringify(error));
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: '$apiFieldName' })
    getPicklistValues({ error, data }) {
        if (data) {
            // Map picklist values
            console.log('data.values picklist: ' + JSON.stringify(data.values));
            console.log('data picklist: ' + JSON.stringify(data));
            this.options = data.values.filter(item => item.label != 'ALL' && item.label != '18').map(plValue => {
                return { label: plValue.label, value: plValue.value };
            });
            this.allOptions = this.options;
            if(this.showAllOption){
                this.allOptions.unshift({label:'Todos', value: 'All'});
            }
            console.log('this.options: ' + JSON.stringify(this.options));
        } else if (error) {
            // Handle error
            console.log('==============Error2  ' + error);
            console.log(JSON.stringify(error));
        }
    }

    handleChange(event) {
        this.value = event.detail.value;
        this.dispatchEvent(new CustomEvent('selectpicklist', {detail: {record: this.value}}));
    }
    @api async setPaymentForm(paymentform) {
        this.value = paymentform;
        console.log('this.value  ' + this.value);
    }
    @api async setPickListOptions(valueOptions) {
        console.log('this.picklistName: ' + JSON.stringify(this.picklistName));
        if(this.picklistName == "activitySectorPickList" || this.picklistName == "paymentFormPickList") {
            this.options = this.allOptions;
            console.log('valueOptions: ' + JSON.stringify(valueOptions));
            console.log('this.options: ' + JSON.stringify(this.options));

            if(valueOptions == null && this.picklistName =="paymentFormPickList") {
                this.options = null; 
            } else if(valueOptions.includes(";") == true) {
                var listSplit = valueOptions.split(";");
                console.log('listSplit: ' + JSON.stringify(listSplit));
                var options2  = [];
                for(var i = 0; i < listSplit.length ;i++) {
                    console.log('options.find(element => element.value == splitList[0]): ' + JSON.stringify(this.options.find(element => element.value == listSplit[i])));
                    options2.push(this.options.find(element => element.value == listSplit[i]));
                }
                this.options = options2;
            } else {
                var options2  = [];
                options2.push(this.options.find(element => element.value == valueOptions));
                this.options = options2;
            }
        }
    }
    cloneObj(obj) {
        return JSON.parse(JSON.stringify(obj));
    }
} 