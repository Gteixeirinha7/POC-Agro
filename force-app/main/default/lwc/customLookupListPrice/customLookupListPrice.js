import { LightningElement, api, track, wire } from 'lwc';
import getRecordsProduct from '@salesforce/apex/CustomLookupController.getRecordsProduct';

export default class CustomLookupListPrice extends LightningElement {
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
    @api recordActivityChannel;
    @api idsProducts;
    @api selectedRecord = null;
  
    
    @track searchValue = null;
    @track recordsList = null;
    @track isLoading = false;
    @track recordsPropList = null;
    @track showCustomLookup = true;
  
    renderedCallback() {
      //console.log('RENDEREDCALLBACK CUSTOMLOOKUP ID: ' + JSON.stringify(this.recordId));
    }
  
    connectedCallback() {
    }
  
    handleTyping(event) {
      const { value } = event.target;
  
      if (value.length < 1) {
        this.recordsList = null;
        return;
      }
  
      this.searchValue = value;
      this.isLoading = true;
  
      this.byWhat = false;
      this.handleGetRecords();
    }
  
    handleGetRecords() {
      console.log('this.idsProducts: ' + this.idsProducts);
        getRecordsProduct({
        objectApiName: this.objectApiName,
        fieldApiName: this.fieldApiName,
        searchTerm: this.searchValue,
        filter: this.filter,
        familyId: this.familyId,
        fieldApiNames: this.fieldApiNames,
        idsProducts: this.idsProducts
      }).then(data => {
          console.log(data);
          this.recordsList = data;
          this.isLoading = false;
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
  
      this.selectedRecord = record;
  
      console.log('this.selectedRecord: ' + JSON.stringify(this.selectedRecord));
  
      this.dispatchEvent(new CustomEvent('selectrecordproduct2', {detail: {record: this.selectedRecord, name: this.customLookupName}}));
    }
  
    handleClearSelected() {
  
      this.selectedRecord = null;
        this.dispatchEvent(
          new CustomEvent('selectrecordproduct2', {detail: {
            record: this.selectedRecord, 
            name: this.customLookupName}
          }));
    }
  
    @api setRecordId(recordListPrice) {

        console.log('VALUE SETRECORD: ' + JSON.stringify(recordListPrice));

        this.selectedRecord = recordListPrice;
    }
}