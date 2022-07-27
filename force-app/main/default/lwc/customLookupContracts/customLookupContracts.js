import { LightningElement, api, track, wire } from 'lwc';
import getRecordContracts from '@salesforce/apex/CustomLookupController.getRecordContracts';
import getRecordContractsProducts from '@salesforce/apex/CustomLookupController.getRecordContractsProducts';
export default class CustomLookupProduct2 extends LightningElement {
  @api objectApiName;
  @api fieldApiName = '';
  @api objectIconName = '';
  @api inputLabel = '';
  @api recordId;
  @api parentAccountId;
  @api filter;
  @api customLookupName = '';
  @api searchTerm;
  @api byWhat;
  @api statusOrder;
  @api familyId;
  @api fieldApiNames;
  @api idsProducts;
  @api disabledProduct2;
  @api activitySector;
  @api recordsOrderIdList;
  @api productWithContract;
  @api product;
  @api recordType;
  @api byFocus;
  @api selectedRecordContract = null;
  @track blurTimeout;
  @api value;
  @track searchValue = null;
  @track productList = null;
  @track recordsList = null;
  @track isLoading = false;
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
    console.log('this.objectApiName: ' + this.objectApiName);
    console.log('this.fieldApiNames: ' + this.fieldApiNames);
    console.log('cliente-id: ' + this.recordId);
    if(this.recordType == 'FutureSale'){
      this.recordType = 'ZCEF';
    }
    if(this.recordType == 'AccountOrder'){
      this.recordType = 'ZCCO';
    }
    if(this.recordType == 'CurrencySale'){
      this.recordType = 'ZCNO';
    }
    if(this.recordType == 'ZVTR'){
      this.recordType = 'BarterSale';
    }
    getRecordContracts({
      searchTerm: this.searchValue,
      client: this.recordId,
      parentAccountId: this.parentAccountId,
      recordType: this.recordType
    }).then(data => {
        console.log('data: ' + data);
        this.recordsList = data;
        this.recordsOrderIdList = data.Id;
      })
      .catch(error => {
        console.log(error);
      });
  }

  handleGetProducts(contract) {
    getRecordContractsProducts({
      ordersIds: contract.Id
    }).then(data => {
        console.log('data: ' + data);
        this.productList = data;
        console.log('this.productList: ' + this.productList);
        this.isLoading = false;
        this.dispatchEvent(new CustomEvent('selectedcontractquantity1', {detail: {product: this.productList}}));
        
      })
      .catch(error => {
        console.log(error);
      });
      
  }

  handleSelectRecord(event) {
    const { value } = event.target.dataset;
    
    console.log('VALUE:' + JSON.stringify(value));

    const record = this.recordsList.find(item => item.Id === value);

    console.log('RECORD:' + JSON.stringify(record));

    this.selectedRecordContract = record;

    console.log('this.selectedRecordcontract2: ' + JSON.stringify(this.selectedRecordContract));

    this.dispatchEvent(new CustomEvent('selectrecordcontract2', {detail: {record: this.selectedRecordContract, name: this.customLookupName}}));
    this.dispatchEvent(new CustomEvent('selectedwithcontract', {detail: true})); 
    this.handleGetProducts(this.selectedRecordContract);
  }

  handleClearSelected() {
    this.productList = null;
    this.selectedRecordContract = null;
    this.dispatchEvent(new CustomEvent('selectedwithcontract', {detail: false}));   
  }
  @api setContractNull() {
    this.handleClearSelected();
  }
/*
  @api setContractRecord(record) {
    console.log('ContractRecordType: ' + JSON.stringify(record));
    if(record != null){
      if(record == 'FutureSale'){
        this.recordType = 'ZCEF';
      }
      if(record == 'AccountOrder'){
        this.recordType = 'ZCCO'
      }
      if(record == 'CurrencySale'){
        this.recordType = 'ZCNO'
      }
    }
  }*/
  @api setSelectedRecord(record) {
    console.log('setSelectedRecord record: ' + JSON.stringify(record));
    this.selectedRecordContract = record;

    this.dispatchEvent(
      new CustomEvent('selectrecordcontract2', {detail: {
        record: this.selectedRecordContract, 
        name: this.customLookupName}
      }));
  }
}