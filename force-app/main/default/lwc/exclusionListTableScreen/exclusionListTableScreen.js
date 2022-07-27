import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import AllJsFilesSweetAlert from '@salesforce/resourceUrl/AllJsFilesSweetAlert';
import getListPrice from '@salesforce/apex/ExcludedListScreenController.getListPrice';
import saveListController from '@salesforce/apex/ExcludedListScreenController.saveList';
import activeListController from '@salesforce/apex/ExcludedListScreenController.activeList'
import createListController from '@salesforce/apex/ExcludedListScreenController.createList';


import CROP_FIELD from '@salesforce/schema/ProductManagement__c.Crop__c';
import PRODUCT_FIELD from '@salesforce/schema/ProductManagement__c.Product2__c';
import SALES_FIELD from '@salesforce/schema/ProductManagement__c.SalesTeam__c';
import ACTIVE_FIELD from '@salesforce/schema/ProductManagement__c.IsActive__c';
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
    @api currencyActive = false;
    @api currencyInactive = false;
    @api currencyPriceActive = false;
    @api currencyPriceInactive = false;
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

    fields = [CROP_FIELD, PRODUCT_FIELD, SALES_FIELD, ACTIVE_FIELD];

    async createPrice(event) {
        if(!this.listObject.crop || !this.listObject.product  || !this.listObject.salesTeam){
            const evt = new ShowToastEvent({
                title: 'Campos obrigatorios ausentes!!',
                message: 'Favor preencher todos os campos necessarios',
                variant: 'error',
            });
            this.dispatchEvent(evt);
            return;
        }
        this.showLoading(true);
        await createListController({crop: this.listObject.crop.Id, product: this.listObject.product.Id, salesTeam: this.listObject.salesTeam.Id, isActive: this.listObject.isActive}).then(result =>{
            this.showLoading(false);
            const evt = new ShowToastEvent({
                title: 'Lista Criada!!',
                message: 'Lista de exclusão criada com sucesso',
                variant: 'success',
            });
            this.dispatchEvent(evt);

            this.listObject.crop = null;
            this.listObject.product = null;
            this.listObject.salesTeam = null;
            
            this.search();
        })
    }

    @track filterObject = {};
    @track listObject = {};

    handleNewRecordCropPrice(event) {
        this.handleNewRecordPrice(event, 'crop');
    }

    handleNewRecordProductPrice(event) {
        this.handleNewRecordPrice(event, 'product');
    }

    handleNewRecordSalesPrice(event) {
        this.handleNewRecordPrice(event, 'salesTeam');
    }

    handleNewRecordPrice(event, param) {
        if(!this.listObject[param]){
            var record = {};
            record = event?.detail || event?.detail?.value;
            this.listObject[param] = {Id: record.record?.Id, Name: record.record?.Name};
        }else{  
            this.listObject[param] = null;
        }
    }
    handlePriceCurrency(event) {
        var value = event.target.value;
        this.currencyPriceActive = value == 'true' ? true : false;
        this.currencyPriceInactive  = value == 'true' ? false : true;
        this.listObject['isActive'] = this.currencyActive;
    }

    handleNewRecordCrop(event) {
        this.handleNewRecord(event, 'crop');
    }

    handleNewRecordSalesTeam(event) {
        this.handleNewRecord(event, 'salesTeam');
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

    connectedCallback(){
        Promise.all([loadScript(this, AllJsFilesSweetAlert + '/sweetalert-master/sweetalert.min.js')]).then(() => { }).catch(error => { });
        this.currencyActive = true;
        this.filterObject['isActive'] = this.currencyActive;
        this.currencyPriceActive = true;
        this.LoadingTextForCards = true;
        this.showAllOptions = true;
        this.search();                
    }

    async search(event) {
        /*if(this.productRecords.length === 0 && this.filterObject.activePrincible == null && this.filterObject.family == null){
            alert("Para filtrar, escolha ao menos um Produto, Princípio Ativo ou Família de Produto");
            return;
        }

        if(this.filterObject.salesTeam == null){
            alert("Para filtrar, escolha uma Equipe de Vendas");
            return;
        } 

        if(this.filterObject.crop == null){
            alert("Para filtrar, escolha uma Safra");
            return;
        }
        */
        this.showLoading(true);

        getListPrice({productIdList :this.productRecords, crop: this.filterObject.crop?.Id, salesTeamId : this.filterObject.salesTeam?.Id, principleActive : this.filterObject.activePrincible, productFamily : this.filterObject.family?.Id, isActive : this.filterObject.isActive }).then(result =>{
            this.showLoading(false);
            this.LoadingTextForCards = result.length === 0;
            this.selectedRecordsListPrice = result;
        })
    }

    showLoading(show) {
		this.loading = show;
	}

    async savePrice(event) {
        this.showLoading(true);
        saveListController({priceId :event.currentTarget.dataset.recordsId, actualValue: event.target.checked}).then(result =>{
            this.showLoading(false);
        })
    }    
    //Métodos criados para ter a funcionalidade visual nos botões (ativar/desativar) na tela de exclusão de lista    
    async activeList(event) {
        swal({
            title: "Deseja ativar todas as listas?",
            icon: "warning",
            buttons: ["Confirmar", "Cancelar"],
            dangerMode: true,
          })
          .then((result) => {
            if (result) {
              
            } else {
                swal("Todas as listas foram ativadas com sucesso", {
                    icon: "success",
                  });
                this.showLoading(true);
                activeListController({productIdList :this.productRecords, crop: this.filterObject.crop?.Id, salesTeamId : this.filterObject.salesTeam?.Id, principleActive : this.filterObject.activePrincible, productFamily : this.filterObject.family?.Id, isActive : this.filterObject.isActive, active: true }).then(result =>{
                    this.selectedRecordsListPrice = result;
                    this.showLoading(false);
                })
            }
          });
    }
    async inactiveList(event) {
        swal({
            title: "Deseja inativar todas as listas?",
            icon: "warning",
            buttons: ["Confirmar", "Cancelar"],
            dangerMode: true,
          })
          .then((result) => {
            if (result) {
              
            } else {
                swal("Todas as listas foram inativadas com sucesso", {
                    icon: "success",
                  });
                this.showLoading(true);
                activeListController({productIdList :this.productRecords, crop: this.filterObject.crop?.Id, salesTeamId : this.filterObject.salesTeam?.Id, principleActive : this.filterObject.activePrincible, productFamily : this.filterObject.family?.Id, isActive : this.filterObject.isActive, active: false }).then(result =>{
                    this.selectedRecordsListPrice = result;
                    this.showLoading(false);
                })
            }
          });
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

}