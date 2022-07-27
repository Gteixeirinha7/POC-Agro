import { LightningElement, api, track, wire } from 'lwc';
import getRecordsProduct from '@salesforce/apex/CustomLookupController.getRecordsProduct';
import getRecordsProductWithContract from '@salesforce/apex/CustomLookupController.getRecordsProductWithContract';
import getRecordTypePrincipleName from '@salesforce/apex/CustomLookupController.getRecordTypePrincipleName';
import getRecordTypePrincipleNameWithContract from '@salesforce/apex/CustomLookupController.getRecordTypePrincipleNameWithContract';
import getRecordPrincipleAndFamilyName from '@salesforce/apex/CustomLookupController.getRecordPrincipleAndFamilyName';
import getRecordPrincipleAndFamilyNameWithContract from '@salesforce/apex/CustomLookupController.getRecordPrincipleAndFamilyNameWithContract';

export default class CustomLookupProduct2 extends LightningElement {
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
  @api familyId;
  @api fieldApiNames;
  @api idsProducts;
  @api familyName;
  @api disabledProduct2;
  @api activitySector;
  @api principleName;
  @api productContract;
  @api productWithContract;
  @api contractQuantity;
  @api byFocus;
  @track blurTimeout;

  @track searchValue = null;
  @track recordsList = null;
  @track isLoading = false;
  @api selectedRecordProducts = null;
  @track recordsPropList = null;
  @track showCustomLookup = true;

  renderedCallback() {
    //console.log('RENDEREDCALLBACK CUSTOMLOOKUP ID: ' + JSON.stringify(this.recordId));
  }

  connectedCallback() {

  }

  handleOnFocus(event) {
    this.byFocus = true;
    this.searchValue = '';
    this.handleGetRecords();
  }

  handleOnFocusOut(event) {
    this.blurTimeout = setTimeout(() => { this.recordsList = false }, 300);
  }

  handleTyping(event) {
    const { value } = event.target;

    if (value.length < 1) {
      this.recordsList = null;
      return;
    }
    this.byFocus = false;
    this.searchValue = value;
    this.isLoading = true;

    this.byWhat = false;
    this.handleGetRecords();
  }

  handleGetRecords() {
    console.log('this.productContract: ' + this.productContract);
    //console.log('this.productContractIds: ' + Object.keys(this.productContract));
    console.log('this.productWithContract: ' + this.productWithContract);
    console.log('this.idsProducts: ' + this.idsProducts);
    console.log('this.activitySector: ' + this.activitySector);
    console.log('this.objectApiName: ' + this.objectApiName);
    console.log('this.fieldApiName: ' + this.fieldApiName);
    console.log('this.filter: ' + this.filter);
    console.log('this.familyId: ' + this.familyId);
    this.isLoading = true;
    
    if(this.productWithContract == true && this.productContract == null){
      console.log('contrato sem produto');
      this.recordsList = null;
      this.isLoading = false;
    }else {
        if(this.productWithContract == true && this.productContract != null){
          this.idsProducts = this.idsProducts.filter(item => Object.keys(this.productContract).includes(item));
        }
        var filterreq = this.filter;
        if(this.principleName != null){
          filterreq += ' AND ActivePrinciple__c = \''+this.principleName+'\' ';
        }
        if(this.familyName != null){
          filterreq += ' AND Family__r.Name = \''+this.familyName+'\' ';
        }
        getRecordsProduct({
          objectApiName: this.objectApiName,
          fieldApiName: this.fieldApiName,
          searchTerm: this.searchValue,
          filter: filterreq,
          familyId: this.family,
          fieldApiNames: this.fieldApiNames,
          idsProducts: this.idsProducts,
          activitySector: this.activitySector,
          byFocus: this.byFocus
        }).then(data => {
          console.log(data);
          this.recordsList = data;
          this.isLoading = false;
        })
        .catch(error => {
          console.log(error);
        });
    }
    this.isLoading = false;
  }

  handleSelectRecord(event) {
    const { value } = event.target.dataset;
    
    console.log('VALUE:' + JSON.stringify(value));

    const record = this.recordsList.find(item => item.Id === value);

    console.log('RECORD:' + JSON.stringify(record));

    this.selectedRecordProducts = record;

    if(this.productWithContract == true && this.productContract != null){
      const dataQtd = this.productContract[this.selectedRecordProducts.Id];
      this.contractQuantity = dataQtd;
        this.dispatchEvent(new CustomEvent('selectrecordproduct3', {detail: {record: dataQtd, name: this.customLookupName}}));
    }
    
    console.log('this.selectedRecordProducts: ' + JSON.stringify(this.selectedRecordProducts));

    this.dispatchEvent(new CustomEvent('selectrecordproduct2', {detail: {record: this.selectedRecordProducts, name: this.customLookupName}}));
  }

  handleClearSelected() {
    this.selectedRecordProducts = null;
      this.dispatchEvent(
        new CustomEvent('selectrecordproduct2', {detail: {
          record: this.selectedRecordProducts, 
          name: this.customLookupName}
        }));
  }
  @api setFamilyName(family) {
    this.familyName = family;
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

  @api setFamilyId(familyId) {
    this.family = familyId;

    this.selectedRecordProducts = null;

    this.dispatchEvent(
      new CustomEvent('selectrecordproduct2', {detail: {
        record: this.selectedRecordProducts, 
        name: this.customLookupName}
      }));

    this.searchValue = '';
    this.recordsList = null;
  }

  @api setSelectedRecord(record) {
    console.log('setSelectedRecord record: ' + JSON.stringify(record));
    this.selectedRecordProducts = record;

    this.dispatchEvent(
      new CustomEvent('selectrecordproduct2', {detail: {
        record: this.selectedRecordProducts, 
        name: this.customLookupName}
      }));
  }
}