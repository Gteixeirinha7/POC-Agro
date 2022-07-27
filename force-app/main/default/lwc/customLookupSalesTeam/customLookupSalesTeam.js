import { LightningElement, api, track, wire } from 'lwc';
import getRecordSalesTeam from '@salesforce/apex/CustomLookupController.getRecordSalesTeam';

export default class CustomLookupSalesTeam extends LightningElement {
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
  @api salesTeamList;
  @api fieldApiNames;
  @api disabledCustomLookup;
  
  @track changeColorSelectedRecord = 'slds-var-p-vertical_xx-small slds-var-p-horizontal_small selected-record slds-list_horizontal slds-media_center slds-grid_align-spread';
        
  @api byFocus;
  @track blurTimeout;
    
  @track searchValue = null;
  @track recordsList = null;
  @track isLoading = false;
  @api selectedRecord = null;
  @track recordsPropList = null;
  @track showCustomLookup = true;

  renderedCallback() {
    console.log('RENDEREDCALLBACK CUSTOMLOOKUP ID: ' + JSON.stringify(this.recordId));
  }
  
  connectedCallback() {

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

  handleOnFocus(event) {
    this.byFocus = true;
    this.searchValue = '';
    this.handleGetRecords();
  }

  handleOnFocusOut(event) {
    this.blurTimeout = setTimeout(() => { this.recordsList = false }, 300);
  }
    
  handleGetRecords() {
    console.log('this.salesTeamList: ' + JSON.stringify(this.salesTeamList));
    getRecordSalesTeam({
      objectApiName: this.objectApiName,
      fieldApiName: this.fieldApiName,
      searchTerm: this.searchValue,
      filter: this.filter,
      fieldApiNames: this.fieldApiNames,
      recordId: this.recordId,
      salesTeamList: this.salesTeamList,
      byFocus: this.byFocus
    }).then(data => {
        console.log(data);
        this.recordsList = data;
        this.isLoading = false;
      }).catch(error => {
        console.log(error);
      });
  }
    
  handleSelectRecord(event) {
    const { value } = event.target.dataset;

    console.log('VALUE:' + JSON.stringify(value));
    const record = this.recordsList.find(item => item.Id === value);
    console.log('RECORD:' + JSON.stringify(record));
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

  @api setFieldNull() {
    this.handleClearSelected();
  }
  
  @api changeSelectedRecord(selectedRecordValue) {
    this.selectedRecord = selectedRecordValue;
  }

  @api
  initialSetupOrder() {
    console.log('disabledCustomLookup: ' + this.disabledCustomLookup)
    this.changeColorSelectedRecord = 'slds-var-p-vertical_xx-small slds-var-p-horizontal_small selected-record-blocked slds-list_horizontal slds-media_center slds-grid_align-spread';
  }
}