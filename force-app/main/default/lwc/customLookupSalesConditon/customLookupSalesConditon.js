import { LightningElement, wire, api, track } from 'lwc';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import {refreshApex} from '@salesforce/apex';

import getSalesConditionValues from '@salesforce/apex/OrderScreenController.getSalesConditionValues';

export default class CustomLookupSalesConditon extends LightningElement {
    
    @api disabledCustomLookup;
    @api picklistName;
    @api objectName;
    @api fieldName;
    @api fieldLabel;
    @api recordTypeId;
    @api showAllOption;
    @api value;
    @track options;
    apiFieldName;
    allOptions;
    connectedCallback() {
        this.handleGetRecords();
    }
    handleGetRecords() {
        getSalesConditionValues({
        }).then(data => {
            if (data) {
                // Map picklist values
                console.log('data picklist: ' + JSON.stringify(data));
                this.options = data.filter(item => item.Name != 'ALL').map(plValue => {
                    return { label: plValue.Name, value: plValue.ExternalId__c };
                });
                this.allOptions = this.options;
                if(this.showAllOption){
                    this.allOptions.unshift({label:'Todos', value: 'All'});
                }
                console.log('this.options: ' + JSON.stringify(this.options));
            }

          })
          .catch(error => {
            console.log(error);
          });
        }

    handleChange(event) {
        console.log('Aqui2 ');
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