import { LightningElement, api, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import AllJsFilesSweetAlert from '@salesforce/resourceUrl/AllJsFilesSweetAlert';
import getStock from '@salesforce/apex/StockListScreenController.getStock';
import getRTVSalesTeamListPrice from '@salesforce/apex/GetAccountTeam.getRTVSalesTeamListPrice';
import getProfileCheck from '@salesforce/apex/StockListScreenController.getProfileCheck';
import saveStockController from '@salesforce/apex/StockListScreenController.activeList';

import { updateRecord } from 'lightning/uiRecordApi';
import TOLERANCE_FIELD from '@salesforce/schema/ProductManagement__c.Tolerance__c';
import ID_FIELD from '@salesforce/schema/ProductManagement__c.Id';
export default class StockTableScreen extends LightningElement {
    @api LoadingText = false;
    @api showAllOptions = false;
    @api loading = false;
    @track selectedRecordsListPrice = [];
    @track productRecords = [];
    @track productCropRecords = [];
    @track productCenterRecords = [];
    @track salesTeamList = {};
    @track filterObject = {};
    @track hasActive = false;

    @api currencyActive = false;
    @api currencyInactive = false;

    @track selectedRecords = [];

    setSelectedRecordCenter(event) {
        var record = {};

        record = event?.detail || event?.detail?.value;

        if(!this.productRecords.includes(record.record.Id)){
            this.productRecords.push(record.record.Id);
            this.productCenterRecords.push(record.record.Id);

            this.selectedRecords.push({ 'recId' : record.record.Id ,'recName' : record.record.Name });
        }
        
		this.template.querySelectorAll('c-custom-lookup-for-table-screen').forEach(each => {
            each.setSelectedFieldNull();
            each.value = '';
        });
    }
    setSelectedRecordCrop(event) {
        var record = {};

        record = event?.detail || event?.detail?.value;

        if(!this.productRecords.includes(record.record.Id)){
            this.productRecords.push(record.record.Id);
            this.productCropRecords.push(record.record.Id);

            this.selectedRecords.push({ 'recId' : record.record.Id ,'recName' : record.record.Name });
        }
        
		this.template.querySelectorAll('c-custom-lookup-for-table-screen').forEach(each => {
            each.setSelectedFieldNull();
            each.value = '';
        });
    }
    setSelectedRecord(event) {
        var record = {};

        record = event?.detail || event?.detail?.value;

        if(!this.productRecords.includes(record.record.Id)){
            this.productRecords.push(record.record.Id);

            this.selectedRecords.push({ 'recId' : record.record.Id ,'recName' : record.record.Name });
        }
        
		this.template.querySelectorAll('c-custom-lookup-for-table-screen').forEach(each => {
            each.setSelectedFieldNull();
            each.value = '';
        });
    }
    removeRecord (event){
        var record = {};
        record = event?.detail || event?.detail?.value;
        var removeFromArray = this.productRecords;

        const index = removeFromArray.indexOf(event.detail.name);
        if(index > -1) removeFromArray.splice(index, 1);
        
        this.productRecords = removeFromArray;

        var removeFromArrayCrop = this.productCropRecords;
        const indexCroop = removeFromArrayCrop.indexOf(event.detail.name);
        if(indexCroop > -1) removeFromArrayCrop.splice(indexCroop, 1);
        this.productCropRecords = removeFromArrayCrop;


        var removeFromArrayCenter = this.productCenterRecords;
        const indexCenter = removeFromArrayCenter.indexOf(event.detail.name);
        if(indexCenter > -1) removeFromArrayCenter.splice(indexCenter, 1);
        this.productCenterRecords = removeFromArrayCenter;
        
        let selectRecId = [];
        for(let i = 0; i < this.selectedRecords.length; i++){
            if(event.detail.name !== this.selectedRecords[i].recId)
                selectRecId.push(this.selectedRecords[i]);
        }
        this.selectedRecords = [...selectRecId];
    }

    handleNewRecordAccount(event) {
        this.handleNewRecord(event, 'account');
    }
    handleNewRecordCluster(event) {
        this.handleNewRecord(event, 'cluster');
    }
    handleNewRecordSalesTeam(event) {
        this.handleNewRecord(event, 'salesTeam');
    }
    handleNewRecordCrop(event) {
        this.handleNewRecord(event, 'crop');
    }
    handleNewRecordProduct(event) {
        this.handleNewRecord(event, 'product');
    }

    handleNewRecordFamily(event) {
        this.handleNewRecord(event, 'family');
    }

    handleActivePrincible(event) {
        if(this.filterObject.activePrincible == null){
            var record = {};
            record = event?.detail || event?.detail?.value;
            this.filterObject.activePrincible = record.record.ActivePrinciple__c;
        }
        else{  
            this.filterObject.activePrincible = null;
        }
    }

    handleNewRecord(event, param) {
        if(!this.filterObject[param]){
            var record = {};
            record = event?.detail || event?.detail?.value;
            this.filterObject[param] = {Id: record.record?.Id, Name: record.record?.Name};
        }else{  
            this.filterObject[param] = null;
        }
    }

    connectedCallback(){
        Promise.all([loadScript(this, AllJsFilesSweetAlert + '/sweetalert-master/sweetalert.min.js')]).then(() => { }).catch(error => { });
        this.LoadingTextForCards = true;
        this.currencyActiveAll = true;
        this.filterObject['isActive'] = null;
        this.showAllOptions = true;      
        
        
        getProfileCheck().then(result =>{
            this.hasActive = result;
        });
        
        this.handleGetRTVSalesTeam();
    }
    
    cloneObj(obj) {
        return JSON.parse(JSON.stringify(obj));
    }

    async handleGetRTVSalesTeam() {
        await getRTVSalesTeamListPrice({accId: null}).then(data => {
            console.log(data);
            if(data != null) {
                this.mapIdRtvToSalesTeams = this.cloneObj(JSON.parse(data));
                if (this.mapIdRtvToSalesTeams[this.recordId]) {
                    this.salesTeamList = this.mapIdRtvToSalesTeams[this.recordId];
                } else {
                    var map = this.mapIdRtvToSalesTeams;
                    this.salesTeamList = [];
                    Object.values(map).forEach(item => this.salesTeamList = this.salesTeamList.concat(item));
                }
            }
        }).catch(error => {});
    }

    handleCurrency(event) {
        var value = event.target.value;
        this.currencyActive = value == 'true' ? true : false;
        this.currencyInactive  = value == 'true' ? false : true;
        this.filterObject['isActive'] = this.currencyActive;
    }
    handleCurrencyAll(event){
        this.currencyActive = false;
        this.currencyInactive = false;
        this.filterObject['isActive'] = null;
    }


    async search(event) {
        // var idsSet = [];
        // this.selectedRecords.forEach(function(item){
        //     idsSet.push(item.recId);
        // }, {idsSet})
        
        this.showLoading(true);

        getStock({isActive: this.filterObject['isActive'], clusterId : this.filterObject.cluster?.Id,  principleActive : this.filterObject.activePrincible, idsSet : this.productRecords, centerSet : this.productCenterRecords, cropIdSet : this.productCropRecords}).then(result =>{
            this.showLoading(false);
            this.LoadingTextForCards = result.length === 0;
            this.selectedRecordsListPrice = result;
            // this.hasActive = result.filter(item => item.showActive).length > 0;
        })
    }
    async activeList(event) {
        this.handleList(event, true);
    }
    async inactiveList(event) {
        this.handleList(event, false);
    }
    async handleList(event, isBlocked) {
        swal({
            title: `Deseja ${isBlocked ? ' bloquear ' : ' liberadas '} venda para todos os estoques?`,
            icon: "warning",
            buttons: ["Confirmar", "Cancelar"],
            dangerMode: true,
          })
          .then((result) => {
            if (!result) {
                this.showLoading(true);
                let prodRecords = [];
                
                this.selectedRecordsListPrice.forEach(function(item){
                    prodRecords.push(item.recordId);
                }, {prodRecords})
                
                saveStockController({priceIdList :prodRecords, actualValue: isBlocked }).then(result =>{
                    swal(`Todas as listas foram ${isBlocked ? ' bloqueadas ' : ' liberadas '}  com sucesso`, {icon: "success"});
                    this.search();
                })
            }
          });
    }
    async saveStock(event) {
        this.showLoading(true);
        var priceListSet = [];
        priceListSet.push(event.currentTarget.dataset.recordsId);
        saveStockController({priceIdList :priceListSet, actualValue: event.target.checked}).then(result =>{
            this.showLoading(false);
        })
    }    

    showLoading(show) {
		this.loading = show;
	}

    getToleranceValue(stockId, tolerancePercent) {
        let stockBaseCalc = this.selectedRecordsListPrice.find(item => item.recordId = stockId)?.stockBaseCalc;
        let toleranceValue = (stockBaseCalc * parseFloat(tolerancePercent)) / 100;           
        return toleranceValue;
    }

    updateTolerance(event) {
            // Create the recordInput object
            const fields = {};
            fields[ID_FIELD.fieldApiName] = event.currentTarget.dataset.recordsId;
            fields[TOLERANCE_FIELD.fieldApiName] = this.getToleranceValue(event.currentTarget.dataset.recordsId, event.currentTarget.value);

            const recordInput = { fields };

            updateRecord(recordInput)
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Sucesso!!',
                            message: 'Registro Atualizado',
                            variant: 'success'
                        })
                    );
                    this.search();
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Erro ao salvar o Registro',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });
    }

}