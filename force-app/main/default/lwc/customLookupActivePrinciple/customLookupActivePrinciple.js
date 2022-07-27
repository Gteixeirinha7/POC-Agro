import { LightningElement, api, track, wire } from 'lwc';
import getRecords from '@salesforce/apex/CustomLookupController.getRecords';
import getRecordPrincipleAgregate from '@salesforce/apex/CustomLookupController.getRecordPrincipleAgregate';
import getRecordPrincipleName from '@salesforce/apex/CustomLookupController.getRecordPrincipleName';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import AllCssScreenOrder from '@salesforce/resourceUrl/AllCssScreenOrder';
import getBaseData from '@salesforce/apex/OrderScreenController.getBaseData';
//import getAccountRecord from '@salesforce/apex/CustomLookupController.getAccountRecord';
//import getRecordsByCLName from '@salesforce/apex/CustomLookupController.getRecordsByCLName';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { updateRecord, getRecord } from 'lightning/uiRecordApi';
export default class CustomLookupActivePrinciple extends LightningElement {
    @api objectApiName;
    @api searchVal = '';
    @api fieldApiName = '';
    @api objectIconName = '';
    @api inputLabel = '';
    @api recordId;
    @api filter;
    @api customLookupName = '';
    @api searchTerm;
    @api byWhat;
    @api statusOrder;
    @api fieldApiNames;
    @api disabledCustomLookup;
    @api family;
    @track changeColorSelectedRecord = 'slds-var-p-vertical_xx-small slds-var-p-horizontal_small selected-record slds-list_horizontal slds-media_center slds-grid_align-spread';
  
    @api byFocus;
    @track blurTimeout;
  
  
    @track searchValue = null;
    @track recordsList = null;
    @track recordsSecondList = null;
    @track isLoading = false;
    @api selectedRecord;
    @track secondRecord;
    @api selectedFamily = false;
    @track recordsPropList = null;
    @track showCustomLookup = true;
  
  
    renderedCallback() {
  
    }
  
    connectedCallback() {
  
    }
  
    handleOnFocus(event) {
      this.byFocus = true;
      this.isLoading = true
      this.searchValue = '';
      this.handleGetRecords();
    }
  
    handleOnFocusOut(event) {
      this.blurTimeout = setTimeout(() => { this.recordsList = false }, 300);
    }
  
    handleTyping(event) {
      const { value } = event.target;
  
      /*if (value.length < 1) {
        this.recordsList = null;
        return;
      }*/
      this.byFocus = false;
      this.searchValue = value;
      this.isLoading = true;
  
      this.byWhat = false;
      this.handleGetRecords();
    }
  
    handleGetRecords() {
      console.log('this.objectApiName: ' + JSON.stringify(this.objectApiName));
      console.log('this.fieldApiName: ' + JSON.stringify(this.fieldApiName));
      console.log('this.searchValue: ' + JSON.stringify(this.searchValue));
      console.log('this.filter: ' + JSON.stringify(this.filter));
      console.log('this.recordId: ' + JSON.stringify(this.recordId));
      console.log('this.family: ' + JSON.stringify(this.family));
      if(this.searchValue != ''){
        this.searchVal = this.searchValue;
      }else{
        this.searchVal = null;
      }
      if(this.family == null){
        getRecordPrincipleAgregate({
        objectApiName: 'Product2',
        fieldApiName: 'ActivePrinciple__c',
        filter: 'ActivePrinciple__c != null GROUP BY ActivePrinciple__c LIMIT 5',
        searchValue: this.searchVal
      }).then(data => {
          console.log('data: ' + JSON.stringify(data));
          this.recordsList = data;
          this.isLoading = false;
          this.recordsSecondList = null;
          console.log(' this.recordsList: ' + JSON.stringify(this.recordsList));
        })
        .catch(error => {
          console.log('error: ' + JSON.stringify(error));
        });
      }else{
        if(this.searchValue != '') this.searchVal = '%'+this.searchValue+'%';
        getRecordPrincipleName({
          familyName: this.family,
          searchValue: this.searchVal
        }).then(data => {
            console.log('data: ' + JSON.stringify(data));
            this.recordsList = data;
            this.isLoading = false;
            this.recordsSecondList = null;
            console.log(' this.recordsList: ' + JSON.stringify(this.recordsList));
          })
          .catch(error => {
            console.log('error: ' + JSON.stringify(error));
          });
      }
      console.log(' this.recordsList2: ' + JSON.stringify(this.recordsList));
    }
    handleSelectRecord(event) {
      const { value } = event.target.dataset;
      const record = this.recordsList.find(item => item.ActivePrinciple__c === value);
      console.log('RECORD:' + JSON.stringify(record));
      this.selectedRecord = record;
      this.secondRecord = this.selectedRecord;
      this.dispatchEvent(new CustomEvent('selectrecord', {detail: {record: this.selectedRecord, name: this.customLookupName}}));
    }
  
    handleClearSelected() {
  
      this.selectedRecord = null;
      this.secondRecord = this.selectedRecord;
        this.dispatchEvent(
          new CustomEvent('selectrecord', {detail: {
            record: this.selectedRecord, 
            name: this.customLookupName}
          }));
    }
  
    @api
    initialSetup(recordIdInput) {
      this.recordId = recordIdInput.AccountObj.Id;
      console.log('this.recordId:' + JSON.stringify(this.recordId));
      if(recordIdInput.StatusOrder == '_isedit_') {
        if(this.customLookupName == "customLookupAccount") {
          this.selectedRecord = recordIdInput.AccountObj;
          this.secondRecord = this.selectedRecord;
        }
      }
      if(recordIdInput.StatusOrder == '_iscreate_') {
        if(this.customLookupName == "customLookupAccount") {
          this.selectedRecord = recordIdInput.AccountObj;
          this.secondRecord = this.selectedRecord;
        }
      }
      this.handleGetRecords();
    }
    @api setFamilyPrincipleProduct(family) {
      console.log('family1: ' + JSON.stringify(family));
      if(family != null){
        if(family.ActivePrinciple__c != null){
          this.selectedRecord = family;
          this.secondRecord = this.selectedRecord;
        }else{
          this.selectedRecord = null;
          this.secondRecord = this.selectedRecord;
        }
      }   
      else{
        this.handleClearSelected();
      } 
      if(family != null && family.Family__r != null){
        console.log('Entrou: ' + JSON.stringify(family));
        this.family = family.Family__r.Name;
      }else{
        this.family = null;
      }
      
    }
    @api setFamilyPrinciple(family) {
      if(family == null){
        this.handleClearSelected();
      }
      if(family != null && family.Name != null){
        console.log('Entrou: ' + JSON.stringify(family));
        this.family = family.Name;
      }else{
        this.family = null;
      }
    }

    @api setValor(valor) {
      this.selectedRecord = valor;
      this.secondRecord = this.selectedRecord;
    }
    
    @api
    initialSetupOrder() {
      console.log('disabledCustomLookup: ' + this.disabledCustomLookup)
      if(this.customLookupName == "customLookupAccount" || this.customLookupName == "customLookupShippingAccount" || this.customLookupName == "customLookupCrop") {
        this.changeColorSelectedRecord = 'slds-var-p-vertical_xx-small slds-var-p-horizontal_small selected-record-blocked slds-list_horizontal slds-media_center slds-grid_align-spread';
      }
    }
}