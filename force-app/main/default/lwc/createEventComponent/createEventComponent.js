import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getUserDetails from '@salesforce/apex/CreateEventComponentController.getUserDetails';
import createEvents from '@salesforce/apex/CreateEventComponentController.createEvent';
import getCaseDetails from '@salesforce/apex/CreateEventComponentController.getCaseDetails';

export default class CreateEventComponent extends NavigationMixin(LightningElement) {
	@track loading				= false;

    @api accIdParam;
    @api accNameParam;
    @api cropIdParam;
    @api cropNameParam;
    @api csIdParam;
    @api csNumberParam;
    @api subjectParam;
    @api descriptionParam;

    @track CropLookupData;
    @track UserLookupData;
    @track EventTypeLookupData;
    @track AccountLookupData;
    @track CaseLookupData;

    @track eventData;

    @track showDisabled = true;

    @track filterCase;
    @track filterCrop;

    @track maxValue;
    @track minValue;

    @track filterUser;

    @track selectedRecords = [];
    @track productRecords = [];

	connectedCallback() {
		this.handleGetBaseData();
	}

    async handleGetBaseData(){
        
        this.EventTypeLookupData = null;
        this.AccountLookupData = null;
        this.CropLookupData = null;
        this.CaseLookupData = null;

        this.filterUser = " AND isActive = true ";
        
        this.selectedRecords = [];

        this.filterCase = ' ';
        this.filterCrop = ' ';

        this.showDisabled = true;

        this.eventData= {
            OwnerId: null,
            AccountId: null,
            WhatId: null,
            Subject: '',
            Description: '',
            EventType__c: null,
            Case__c: null,
            Crop__c: null,
            StartDateTime: this.getCurrentDateTime(),
            EndDateTime: this.getCurrentDateTime()
        };
        

        this.maxValue = null;
        this.minValue = null;
        
        getUserDetails().then(data => {
        	if(data) this.UserLookupData = {Id : data.Id, Name: data.Name};
            if(data) this.eventData['OwnerId'] = data.Id;       	
            if(data) this.filterUser += data.Profile.Name.includes('RTV') || data.Profile.Name.includes('ATV') ? ' AND Id = \''+data.Id+'\'' : '';       	
        })

        if(this.csIdParam)
            await this.setCaseParam();

        if(this.accIdParam)
            this.setApiParam();
    }

    setApiParam(){
        this.AccountLookupData = {Id: this.accIdParam, Name: this.accNameParam };
        this.CropLookupData = {Id: this.cropIdParam, Name: this.cropNameParam };
        this.CaseLookupData = {Id: this.csIdParam, Name: this.csNumberParam+' - '+this.subjectParam };
        this.eventData['Subject'] = this.subjectParam;
        this.eventData['Description'] = this.descriptionParam;
    }

    async setCaseParam(){
        await getCaseDetails({caseId: this.csIdParam}).then(data => {
            if(data) {
                this.accIdParam         = data.AccountId;
                this.accNameParam       = data.Account.Name;
                this.cropIdParam         = data.Crop__c;
                this.cropNameParam       = data.Crop__r.Name;
                this.csNumberParam      = data.CaseNumber;
                this.subjectParam       = data.Subject;
                this.descriptionParam   = data.Description;
                this.setField('AccountId', data.AccountId);
                this.setField('Account__c', data.AccountId);
                this.setField('WhatId', data.AccountId);
                this.setField('Case__c', this.csIdParam);
                this.setField('Crop__c', this.cropIdParam);
                this.setApiParam();
            }
        });
    }

    getCurrentDateTime(){
        var dt = new Date();
        return dt.getUTCFullYear()+'-'+this.formatNumber(dt.getUTCMonth()+1)+'-'+this.formatNumber(dt.getUTCDate());
    }

    formatNumber(val){
        return (val <= 9 ? '0' : '') +val;
    }

    setSelectedRecordCrop(event) {
        var record = event?.detail?.record;

        if(!this.productRecords.includes(record.Id)){
            this.productRecords.push(record.Id);
            this.selectedRecords.push({ 'Id' : record.Id ,'Name' : record.Name });
        }
        
		this.template.querySelectorAll('c-custom-lookup-for-table-screen').forEach(each => {
            each.setSelectedFieldNull();
            each.value = '';
        });
    }

    removeRecord (event){
        var removeFromArray = this.productRecords;
        const index = removeFromArray.indexOf(event.detail.name);
        if(index > -1) removeFromArray.splice(index, 1);
        this.productRecords = removeFromArray;
        
        this.selectedRecords = this.selectedRecords.filter(item => event.detail.name !== item.Id);
    }
    
    handleChangeAccount(event){
        event.target.name = 'AccountId';
        this.setField('WhatId', event?.detail?.record?.Id);
        this.setField('AccountId', event?.detail?.record?.Id);
        this.setField('Account__c', event?.detail?.record?.Id);

        if(!event?.detail?.record?.Id){
            this.filterCase = ' ';

            this.setField('Case__c', null);
            this.CaseLookupData =  null;
        }else{
            this.filterCase = ' AND AccountId = \''+event?.detail?.record?.Id+'\' ';
            this.setField('Case__c', null);
            this.CaseLookupData =  null;
        }
        
        this.handleChangeLookup(event, 'AccountLookupData');
    }
    handleChangeLookupUser(event){
        event.target.name = 'OwnerId';
        this.handleChangeLookup(event, 'UserLookupData');
    }
    handleChangeLookupCrop(event){
        event.target.name = 'Crop__c';
        this.handleChangeLookup(event, 'CropLookupData');
    }

    handleChangeLookupEvent(event){
        event.target.name = 'EventType__c';
        this.handleChangeLookup(event, 'EventTypeLookupData');
    }

    handleChangeLookupCase(event){
        event.target.name = 'Case__c';
        if(event?.detail?.record?.Id){
            this.inputAccountFromCase(event?.detail?.record?.AccountId, event?.detail?.record?.Account.Name);
            this.inputCropFromCase(event?.detail?.record?.Crop__c, event?.detail?.record?.Crop__r.Name);
            this.filterCrop = ' AND Id = \''+event?.detail?.record?.Crop__c+'\' ';
        }else{
            this.inputAccountFromCase(null, null);
            this.filterCrop = ' ';
        }

        this.handleChangeLookup(event, 'CaseLookupData');
    }

    inputCropFromCase(Ids, Names){
        this.setField('Crop__c', Ids);
        this.CropLookupData = Ids ? {Id: Ids, Name: Names} : null;
    }
    inputAccountFromCase(Ids, Names){
        this.setField('WhatId', Ids);
        this.setField('AccountId', Ids);
        this.setField('Account__c', Ids);

        this.AccountLookupData = Ids ? {Id: Ids, Name: Names} : null;
    }

    handleChangeLookup(event, lookup){
        this[lookup] = this.getLookupData(event);
        this.eventData[event.target.name] = this[lookup]?.Id;
        this.handleInputData();
    }

    handleChange(event){
        this.eventData[event.target.name] = event?.detail?.value;
        this.handleInputData();
    }  
    handleChangeTime(event){
        this.handleChange(event);
        this.maxValue = this.eventData.endTime;
        this.minValue = this.eventData.initTime;

    }   

    getLookupData(event){
        return event?.detail?.record?.Id ? {Id: event?.detail?.record?.Id, Name: event?.detail?.record?.Name }: null;
    }    

    setField(field, val){
        this.eventData[field] = val;
    }

    handleInputData(){
        this.showDisabled = (this.checkEvent());
    }

    checkEvent(){
        let fieldSet = [
            'AccountId',
            'OwnerId',
            'StartDateTime',
            'WhatId',
            'endTime',
            'initTime',
            'Subject',
            'Crop__c',
            'EventType__c'
        ];

        let result = false;
        var t = this;
        fieldSet.forEach(function(item){
            if(!t.checkField(t.eventData[item])) result = true;
        }, {fieldSet, t, result});

        return result;
    }

    checkField(field){
        return field != null && field != ''; 
    }
    async closeEvent(){
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Event',
                actionName: 'home'
            }
        });
        this.showLoading(false);
    }
    conclude(){
        this.showLoading(true);
        this.createEvent();
    }
    createEvent(){
        let fields = this.formatData();
        createEvents({evt: JSON.stringify(fields)}).then(response => { 
            if(this.productRecords.length){
                this.createRelativeEvent(0, response.Id);
            }else{
                this.alertToast("success", 'Sucesso', "Visita Criada!");
                this.handleGetBaseData();
                this.navigateToView(response.Id);
            }

        }).catch(error => {
            this.alertToast("warning", 'Erro', 'Error: ' +JSON.stringify(error?.body?.message ? error?.body?.message :  error));
        });
    }

    createRelativeEvent(initialIndex, redId){
        let fields = this.formatData();
        fields.OwnerId = this.productRecords[initialIndex];
        createEvents({evt: JSON.stringify(fields)}).then(response => {
            if(initialIndex < this.productRecords.length-1){
                initialIndex += 1; 
                this.createRelativeEvent(initialIndex, redId);
            }else{
                this.alertToast("success", 'Sucesso', "Visita Criada!");
                this.handleGetBaseData();
                this.navigateToView(redId);
            }
        }).catch(error => {
            this.alertToast("warning", 'Erro', 'Error: ' +JSON.stringify(error?.body?.message ? error?.body?.message :  error));
        });
    }

    formatData(){
        var fields = JSON.parse(JSON.stringify(this.eventData));
        fields.EndDateTime = fields.StartDateTime +'T'+ fields.endTime+'-0300';
        fields.StartDateTime = fields.StartDateTime +'T'+ fields.initTime+'-0300';
        
        delete fields['endTime'];
        delete fields['initTime'];

        return fields
    }
	
    async navigateToView(evntId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: evntId,
                objectApiName: 'Event',
                actionName: 'view'
            }
        });
        this.showLoading(false);
    }

    alertToast(statusCode, title, errors){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: errors,
                variant: statusCode
            })
        );
    }

	showLoading(show) {
		this.loading = show;
	}

}