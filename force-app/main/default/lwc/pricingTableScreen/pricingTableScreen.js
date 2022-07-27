import { LightningElement, api, track, wire } from 'lwc';
import getListPrice from '@salesforce/apex/PricingTableScreenController.getListPrice';
import getUserInfo from '@salesforce/apex/PricingTableScreenController.getUserInfo';
import getRTVSalesTeamListPrice from '@salesforce/apex/GetAccountTeam.getRTVSalesTeamListPrice';
import getRecordSalesTeam from '@salesforce/apex/CustomLookupController.getRecordSalesTeam';
export default class PricingTableScreen extends LightningElement {
    @api Label;
    @track mapIdRtvToSalesTeams;
    @track searchRecords = [];
    @api productRecords = [];
    @track selectedRecords = [];
    @api LoadingText = false;
    @api account = null;
    @api crop = null;
    @track hiddenSalesTeam = true;
    @api showAllOptions = false;
    @api initialDate = null;
    @api calculatedUnitPrice = null;
    @api isActive = null;
    @api effectiveDate = null;
    @api activitySector = '10';
    @api productFamily = null;
    @api loading = false;
    @api idsRtvs;
    @track hiddenRTV = true
    @api currencyReal = false;
    @api currencyDolar = false;
    @api unitPrice = null;
    @api paymentDate = null;
    @api salesCondition = 'All';
    @api productName = null;
    @api salesTeamList;
    @api salesTeamId = null;
    @api salesOfficeId = null;
    @api activePrincible = null;
    @api orderObject            = new Object();
    @track Dates                = new Object();
    @track selectedRecordsListPrice = [];
    @api recordId;

    handleCurrency(event) {
        var value = event.target.value;
        if(value == 'BRL' && this.orderObject.SalesCondition == '02') {
            this.currencyReal = false;
            this.currencyDolar  = true;
            swal(this.toastInfoErrorCurrencyDol.Message ,{ icon: "warning"}).then((action) => {
            });
        } else {
            this.currencyReal = value == 'BRL' ? true : false;
            this.currencyDolar  = value == 'BRL' ? false : true;
            this.orderObject.Currency = value;
        }
    }

    handleActivePrincible(event) {
        if(this.activePrincible == null){
            var record = {};
            record = event?.detail || event?.detail?.value;
            this.activePrincible = record.record.ActivePrinciple__c;
        }
        else{  
            this.activePrincible = null;
        }
    }

    connectedCallback(){
        this.currencyReal = true;
        this.LoadingTextForCards = true;
        this.showAllOptions = true;
        this.getUserInfo();
        this.handleGetRTVSalesTeam();
    }

    handlePaymentDate(event) {
        this.paymentDate = event.target.value;
        if(this.paymentDate == '' || this.paymentDate == null){
            return;
        }
    }

    convertDateToCorrectFormatDateToCreate(dateStr) {
        var dateList = dateStr.split("-");
        var dateListCorrect = [];
        dateListCorrect.push(dateList[1]);
        dateListCorrect.push(dateList[2]);
        dateListCorrect.push(dateList[0]);
        var date = dateListCorrect.join('/');
        return date;
    }

    async handleNewRecordAccount(event) {
        if(this.account == null){
            var record = {};
            record = event?.detail || event?.detail?.value;
            this.account = record.record.Id;
            this.handleGetRTVSalesTeam();
        }
        else{  
            this.account = null;
            this.handleGetRTVSalesTeam();
            this.template.querySelector('c-custom-lookup-sales-team').setFieldNull();
        }
    }

    async handleNewRecordActivitySector(event) {
        var record = {};
        record = event?.detail || event?.detail?.value;
        this.activitySector = record.record;
    }

    async search(event) {
        if(this.productRecords.length === 0 && this.activePrincible == null && this.productFamily == null){
            alert("Para filtrar, escolha ao menos um Produto, Princípio Ativo ou Família de Produto");
            return;
        }

        if(this.salesTeamId == null){
            alert("Para filtrar, escolha uma Equipe de Vendas");
            return;
        }

        if(this.paymentDate == null){
            alert("Para filtrar, escolha uma data de pagamento");
            return;
        }

        if(this.crop == null){
            alert("Para filtrar, escolha uma Safra");
            return;
        }

        this.showLoading(true);
        getListPrice({userId: this.recordId,crop: this.crop,account: this.account, initialDate: this.initialDate, calculatedUnitPrice: this.calculatedUnitPrice, isActive: this.isActive, effectiveDate: this.effectiveDate,
        activitySector: this.activitySector, productFamily: this.productFamily,currencyReal: this.currencyReal, currencyDolar: this.currencyDolar,unitPrice: this.unitPrice,endDate: this.paymentDate,productIdList: this.productRecords,
        salesTeamId: this.salesTeamId,salesOfficeId: this.salesOfficeId,salesCondition: this.salesCondition, activePrincible: this.activePrincible, salesTeamAccessIdList: this.salesTeamList})
        .then(result =>{
            this.showLoading(false);
            this.LoadingTextForCards = false;
            if(result.length === 0){
                this.LoadingTextForCards = true;
            }
            else {
                this.LoadingTextForCards = false;
            }
            this.selectedRecordsListPrice = result;
        })
    }

    async handleNewRecordSalesCondiction(event) {
            var record = {};
            record = event?.detail || event?.detail?.value;
            this.salesCondition = record.record;
    }

    showLoading(show) {
		this.loading = show;
	}

    handleNewRecordCrop(event) {
        if(this.crop == null){
            var record = {};
            record = event?.detail || event?.detail?.value;
            this.crop = record.record?.Id;
        }
        else{  
            this.crop = null;
        }
    }

    handleFamily(event) {
        if(this.productFamily == null){
            var record = {};
            record = event?.detail || event?.detail?.value;
            this.productFamily = record.record?.Id;
        }
        else{  
            this.productFamily = null;
        }
    }

    handleNewSalesTeam(event) {
        if (this.salesTeamId == null) {
            var record = {};
            record = event?.detail || event?.detail?.value;
            this.salesTeamId = record.record?.Id;
        }
        else {
            this.salesTeamId = null;
            this.orderObject["SalesTeam"] = null;
        }
    }

    handleNewRecordProduct(event) {
        if(this.productName == null){
            var record = {};
            record = event?.detail || event?.detail?.value;
            this.productName = record.record?.Id;
            this.setSelectedRecord(event);
            this.template.querySelector('c-custom-lookup-for-table-screen').setFieldNull();
        }
        else{  
            this.productName = null;
        }
    }

    async handleNewRecordSalesCondition(event) {
        if(this.salesCondition == null){
            var record = {};
            record = event?.detail || event?.detail?.value;
            this.salesCondition = record.record.Id;
        }
        else{  
            this.salesCondition = null;
        }
    }

    setSelectedRecord(event) {
        var record = {};
        record = event?.detail || event?.detail?.value;
        var selectName = record.record.Name;
        var recId = record.record.Id;
        if(!this.productRecords.includes(recId)){
            this.productRecords.push(recId);
            let newsObject = { 'recId' : recId ,'recName' : selectName };
            this.selectedRecords.push(newsObject);
            let selRecords = this.selectedRecords;
		    this.template.querySelectorAll('c-custom-lookup-for-table-screen').forEach(each => {
                each.value = '';
            });
            const selectedEvent = new CustomEvent('selected', { detail: {selRecords}, });
            // Dispatches the event.
            this.dispatchEvent(selectedEvent);
        }
    }

    removeRecord (event){
        var record = {};
        record = event?.detail || event?.detail?.value;
        var removeFromArray = this.productRecords;
        var indexToGet = event.detail.name;
        const index = removeFromArray.indexOf(indexToGet);
        if(index > -1){
            removeFromArray.splice(index, 1);
        }
        this.productRecords = removeFromArray;
        let selectRecId = [];
        for(let i = 0; i < this.selectedRecords.length; i++){
            if(event.detail.name !== this.selectedRecords[i].recId)
                selectRecId.push(this.selectedRecords[i]);
        }
        this.selectedRecords = [...selectRecId];
        let selRecords = this.selectedRecords;
        const selectedEvent = new CustomEvent('selected', { detail: {selRecords}, });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }

    showLoading(show) {
		this.loading = show;
	}

    async handleGetRTVSalesTeam() {
        await getRTVSalesTeamListPrice({accId: this.account}).then(data => {
            if(data == null) {
            } else {
                console.log('this.recordId ->' + this.recordId);
                const obj = JSON.parse(data);
                this.mapIdRtvToSalesTeams = this.cloneObj(obj);
                if (this.mapIdRtvToSalesTeams[this.recordId]) {
                    this.salesTeamList = this.mapIdRtvToSalesTeams[this.recordId];
                } else {
                    var map = this.mapIdRtvToSalesTeams;
                    this.salesTeamList = [];
                    Object.values(map).forEach(item => this.salesTeamList = this.salesTeamList.concat(item));
                }
                console.log('this.salesTeamList: ' + this.salesTeamList);
                if (this.salesTeamList && this.salesTeamList.length == 1) {
                    this.showLoading(true);
                    getRecordSalesTeam({
                        objectApiName: 'SalesTeam__c',
                        fieldApiName: 'Name',
                        searchTerm: '',
                        filter: ' AND Id IN (replace) ',
                        fieldApiNames: '',
                        recordId: null,
                        salesTeamList: this.salesTeamList,
                        byFocus: true
                    }).then(data => {
                        this.orderObject["SalesTeam"] = data[0];
                        this.salesTeamId = this.orderObject.SalesTeam.Id;
                        this.showLoading(false);
                    });
                }
            }
        }).catch(error => {
          console.log('error: ' + JSON.stringify(error));
        });
    }

    async getUserInfo(){
        await getUserInfo({}).then(data => {this.recordId = data;})
    }

    cloneObj(obj) {
        return JSON.parse(JSON.stringify(obj));
    }

}