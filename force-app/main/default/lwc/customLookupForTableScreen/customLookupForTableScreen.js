import { LightningElement, api, track, wire } from 'lwc';
import getRecords from '@salesforce/apex/CustomLookupController.getRecords';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import AllCssScreenOrder from '@salesforce/resourceUrl/AllCssScreenOrder';
import getBaseData from '@salesforce/apex/OrderScreenController.getBaseData';
//import getAccountRecord from '@salesforce/apex/CustomLookupController.getAccountRecord';
//import getRecordsByCLName from '@salesforce/apex/CustomLookupController.getRecordsByCLName';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { updateRecord, getRecord } from 'lightning/uiRecordApi';

export default class CustomLookupForTableScreen extends LightningElement {
  @api objectApiName;
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
  @api activePrinciple = '';
  @api productFamily = '';
  @api recordType;
  @api disabledCustomLookup;
  @track changeColorSelectedRecord = 'slds-var-p-vertical_xx-small slds-var-p-horizontal_small selected-record slds-list_horizontal slds-media_center slds-grid_align-spread';

  @api byFocus;
  @track blurTimeout;


  @track searchValue = null;
  @track recordsList = null;
  @track isLoading = false;
  @api selectedRecord;
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
    this.filter = '';
    if(this.recordType == 'BarterSale' && this.objectApiName == 'PaymentCondition__c'){
      this.filter += 'AND ExternalId__c = \'CFIX\'';
    }else if(this.objectApiName == 'PaymentCondition__c'){
      this.filter = ' AND Active__c = true ';
    }

    
    if(this.activePrinciple && this.objectApiName == 'Product2'){
      this.filter += ' AND ActivePrinciple__c = \''+this.activePrinciple+'\' ';
    }


    if(this.productFamily && this.objectApiName == 'Product2'){
      this.filter += ' AND Family__c = \''+this.productFamily+'\' ';
    }


    if(this.objectApiName == 'Product2' || this.objectApiName == 'User'){
      this.filter += ' AND isActive = true ';
    }
    console.log('this.objectApiName: ' + JSON.stringify(this.objectApiName));
    console.log('this.fieldApiName: ' + JSON.stringify(this.fieldApiName));
    console.log('this.searchValue: ' + JSON.stringify(this.searchValue));
    console.log('this.filter: ' + JSON.stringify(this.filter));
    console.log('this.recordId: ' + JSON.stringify(this.recordId));
    console.log('this.recordType:' + JSON.stringify(this.recordType));
    console.log('this.objectApiName:' + JSON.stringify(this.objectApiName));

    getRecords({
      objectApiName: this.objectApiName,
      fieldApiName: this.fieldApiName,
      searchTerm: this.searchValue,
      filter: this.filter, 
      recordId: this.recordId,
      fieldApiNames: this.fieldApiNames,
      byFocus: this.byFocus
    }).then(data => {
        console.log('data: ' + JSON.stringify(data));
        this.recordsList = data;
        this.isLoading = false;
      })
      .catch(error => {
        console.log('error: ' + JSON.stringify(error));
      });
  }
  handleSelectRecord(event) {
    const { value } = event.target.dataset;
    const record = this.recordsList.find(item => item.Id === value);
    console.log('RECORD:' + JSON.stringify(record));
    this.familyName = record.Name;
    this.selectedRecord = record;

    this.dispatchEvent(new CustomEvent('selectrecord', {detail: {record: this.selectedRecord, name: this.customLookupName}}));
  }

  handleClearSelected() {
    this.selectedRecord = null;
      this.dispatchEvent(
        new CustomEvent('selectrecord', {detail: {
          record: this.selectedRecord, 
          name: this.customLookupName}
        }));
  }

  @api setSelectedFieldNull(){
    this.selectedRecord = null;
  }
  @api setFieldNull(){
    this.handleClearSelected();
  }

  @api
  initialSetup(recordIdInput) {

    this.recordId = recordIdInput.AccountObj.Id;

    if(recordIdInput.StatusOrder == '_isedit_') {
      if(this.customLookupName == "customLookupAccount") {
        this.selectedRecord = recordIdInput.AccountObj;
      }
    }
    if(recordIdInput.StatusOrder == '_iscreate_') {
      if(this.customLookupName == "customLookupAccount") {
        this.selectedRecord = recordIdInput.AccountObj;
      }
    }

    this.handleGetRecords();
  }

  @api
  initialSetupOrder() {
    console.log('disabledCustomLookup: ' + this.disabledCustomLookup)
    if(this.customLookupName == "customLookupAccount" || this.customLookupName == "customLookupShippingAccount" || this.customLookupName == "customLookupCrop") {
      this.changeColorSelectedRecord = 'slds-var-p-vertical_xx-small slds-var-p-horizontal_small selected-record-blocked slds-list_horizontal slds-media_center slds-grid_align-spread';
    }
  }
}