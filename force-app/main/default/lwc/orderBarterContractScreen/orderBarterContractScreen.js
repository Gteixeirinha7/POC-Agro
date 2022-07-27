import { LightningElement, api, track, wire } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import AllJsFilesSweetAlert from '@salesforce/resourceUrl/AllJsFilesSweetAlert';
import Images from '@salesforce/resourceUrl/AllImagesScreenOrder';
import getPaymentFormPicklist from '@salesforce/apex/OrderScreenController.getPicklistValues';
import getCommercialMeasureUnit from '@salesforce/apex/OrderScreenController.getPicklistValues';
import getRecordFinancialDueDate from '@salesforce/apex/OrderScreenController.getRecordFinancialDueDate';
import queryCreditLimit from '@salesforce/apex/QueryCreditLimitController.queryCreditLimitScreen';
import IntegrationLimitCreditError from '@salesforce/label/c.IntegrationLimitCreditError';

export default class OrderBarterContractScreen extends LightningElement {
    cIMoneyCheck        = Images + '/AllImagesScreenOrder/ic-money-check-alt.svg';

    @api commUnitScreen          = false;
    @api showFinancialFields     = false;
    @api showTriangulationFields = false;
    @api checkedFreightCommCIF   = false;
    @api checkedFreightCommFOB   = false;
    @api disabledBarterFields    = false;
    @api loading                 = false;
    @api orderObject = new Object();
    @api clienteId;
    @api currencyScreen;
    @api checkedCurrencyReal;
    @api checkedCurrencyDol;
    @api creditLimitRequest;
    
    @track orderObjectBarter = new Object();

    @wire(getPaymentFormPicklist, {dependencyFieldKey: 'BarterType__c', dependencyField: 'PaymentForm__c'})
    getPaymentFormPicklistRefreshed;

    async refreshApexGetPaymentFormPicklist() {
        try {
            await refreshApex(this.getPaymentFormPicklistRefreshed);
        } catch(e) {
            console.log('Error: ' + JSON.stringify(e));
        }
    }

    @api allReqFieldsBarter  = [
        'BarterType',
        'Commodity',
        'ShippingCrop',
        'GrossUnitPrice',
        'CommUnitPrice',
        'TotalDeliveryQuantity',
        'CommFreigthMode',
        'InitialDeliveryDate',
        'EndDeliveryDate'
    ];

    @api allReqFieldsTriangulationBarter  = [
        'BarterType',
        'Trade',
        'Commodity',
        'ShippingCrop',
        'GrossUnitPrice',
        'CommUnitPrice',
        'TotalDeliveryQuantity',
        'CommFreigthMode',
        'InitialDeliveryDate',
        'EndDeliveryDate'
    ];

    @api allReqFieldsFinancialBarter  = [
        'BarterType',
        'StrikePrice',
        'FinancialDueDate',
        'Commodity',
        'ShippingCrop',
        'TotalDeliveryQuantity'
    ];


    connectedCallback() {
        //this.handleGetPaymentFormPicklistValues();
        Promise.all([loadScript(this, AllJsFilesSweetAlert + '/sweetalert-master/sweetalert.min.js')]).then(() => {console.log('Files loaded.');}).catch(error => {console.log('error: ' + JSON.stringify(error));});
        console.log(IntegrationLimitCreditError);
        console.log('connectedCallback: ' + JSON.stringify(this.orderObject));
        this.orderObjectBarter["BarterType"]                 = this.orderObject.BarterType;
        this.handleGetPaymentFormPicklistValues();
        if(this.orderObjectBarter.BarterType == 'Triangulação'){
            this.showFinancialFields = false;
            this.showTriangulationFields = true;
        }
        else if(this.orderObjectBarter.BarterType == 'Financeiro'){
            this.orderObjectBarter["FinancialDueDate"]       = this.orderObject.FinancialDueDate != undefined ? this.orderObject.FinancialDueDate : null;
            this.showFinancialFields = true;
            this.showTriangulationFields = false;
        }
        else{
            this.showFinancialFields = false;
            this.showTriangulationFields = false;
        }
        this.orderObjectBarter["PaymentForm"]                = this.orderObject.PaymentForm;
        this.orderObjectBarter["Trade"]                      = this.orderObject.Trade;
        this.orderObjectBarter["Commodity"]                  = this.orderObject.Commodity;
        this.orderObjectBarter["CommercialMeasureUnit"]      = this.orderObject.CommercialMeasureUnit;
        this.orderObjectBarter["ShippingCrop"]               = this.orderObject.ShippingCrop;
        this.orderObjectBarter["BillingCrop"]                = this.orderObject.BillingCrop;
        this.orderObjectBarter["StrikePrice"]                = this.orderObject.StrikePrice;
        this.orderObjectBarter["GrossUnitPrice"]             = this.orderObject.GrossUnitPrice;
        this.orderObjectBarter["CommUnitPrice"]              = this.orderObject.CommUnitPrice;
        this.orderObjectBarter["TotalDeliveryQuantity"]      = this.orderObject.TotalDeliveryQuantity;
        this.orderObjectBarter["ProductionDeliveryLocation"] = this.orderObject.ProductionDeliveryLocation;
        this.orderObjectBarter["ProductionPickupLocation"]   = this.orderObject.ProductionPickupLocation;
        this.orderObjectBarter["InitialDeliveryDate"]        = this.orderObject.InitialDeliveryDate;
        this.orderObjectBarter["EndDeliveryDate"]            = this.orderObject.EndDeliveryDate;

        this.orderObjectBarter["CommFreigthMode"]            = this.orderObject.CommFreigthMode;
        if(this.orderObjectBarter.CommFreigthMode == 'CIF') {
            this.checkedFreightCommCIF = true;
            this.checkedFreightCommFOB = false;
            this.showDelivery = true;
            this.showPickup = false;
        } else if (this.orderObjectBarter.CommFreigthMode == 'FOB') {
            this.checkedFreightCommCIF = false;
            this.checkedFreightCommFOB = true;
            this.showDelivery = false;
            this.showPickup = true;
        }

        if(this.orderObjectBarter.CommercialMeasureUnit != undefined){
            this.commUnitScreen = true;
        }else if(this.orderObjectBarter.Commodity != null){
            getCommercialMeasureUnit({dependencyFieldKey: 'Commodity__c', dependencyField: 'CommercialMeasureUnit__c', value: this.orderObjectBarter.Commodity}).then(data => {
                if(data) {
                    console.log('data: ' + JSON.stringify(data));
                    this.orderObjectBarter.CommercialMeasureUnit = data;
                    this.commUnitScreen = true;
                } else {
                    swal("A commodity selecionada não está com unidade de medida definida: " + this.orderObjectBarter.Commodity ,{ icon: "warning"});
                    console.log('data: ' + JSON.stringify(data));
                    this.commUnitScreen = false;
                }
            }).catch(error => {
                console.log('error: ' + JSON.stringify(error));
                swal("Erro: " + JSON.stringify(error.body.message) ,{ icon: "warning"})
                this.commUnitScreen = false;
            });
        }
        this.verifyUpdateTotalDeliveryQuantity();
        console.log('CONNECTED CALLBACK ORDERBARTERCONTRACTSCREEN');
        console.log('this.orderObjectBarter: ' + JSON.stringify(this.orderObjectBarter));
    }

    renderedCallback() {
        console.log('RENDERED CALLBACK ORDERBARTERCONTRACTSCREEN');
    }

    handlePicklistBarterType(event){
        var record                  = {};
        record                      = event?.detail || event?.detail?.value;
        this.orderObjectBarter.BarterType = record.record;
        this.dispatchEvent(
            new CustomEvent('receivebarterobject', {detail: {
                orderObjectBarter: this.orderObjectBarter}
            }));
        if(this.orderObjectBarter.BarterType == 'Triangulação'){
            this.showFinancialFields = false;
            this.showTriangulationFields = true;
        }
        else if(this.orderObjectBarter.BarterType == 'Financeiro'){
            this.showFinancialFields = true;
            this.showTriangulationFields = false;
        }
        else{
            this.showFinancialFields = false;
            this.showTriangulationFields = false;
        }
    }
    async handlePicklistBarterType(event){
        var record                  = {};
        record                      = event?.detail || event?.detail?.value;
        this.orderObjectBarter.BarterType = record.record;
        this.dispatchEvent(
            new CustomEvent('receivebarterobject', {detail: {
                orderObjectBarter: this.orderObjectBarter}
            }));
        if(this.orderObjectBarter.BarterType == 'Triangulação'){
            this.showFinancialFields = false;
            this.showTriangulationFields = true;
        }
        else if(this.orderObjectBarter.BarterType == 'Financeiro'){
            this.showFinancialFields = true;
            this.showTriangulationFields = false;
        }
        else{
            this.showFinancialFields = false;
            this.showTriangulationFields = false;
        }
        await this.handleGetPaymentFormPicklistValues();
    }

    async handleGetPaymentFormPicklistValues(){
        this.showLoading(true);

        //await this.refreshApexGetPaymentFormPicklist();
        if(this.orderObject.BarterType == undefined) this.orderObject.BarterType = null;
        await getPaymentFormPicklist({dependencyFieldKey: 'BarterType__c', dependencyField: 'PaymentForm__c', value: this.orderObjectBarter.BarterType}).then(data => {
            if(data) {
                console.log('data: ' + JSON.stringify(data));
                this.template.querySelectorAll('c-show-picklist-value').forEach(element => {
                    if(element.picklistName == 'paymentFormPickList') element.setPickListOptions(data)});
                if(data.length == 1){
                    this.orderObjectBarter.PaymentForm = data;
                    this.dispatchEvent(
                        new CustomEvent('receivebarterobject', {detail: {
                            orderObjectBarter: this.orderObjectBarter}
                        }));
                }
                else{
                    this.orderObjectBarter.PaymentForm = null;
                    this.dispatchEvent(
                        new CustomEvent('receivebarterobject', {detail: {
                            orderObjectBarter: this.orderObjectBarter}
                        }));
                }
            } else {
                swal("O Tipo de Barter Selecionado não está definido para nenhuma forma de pagamento: " + this.orderObjectBarter.BarterType ,{ icon: "warning"});
                console.log('data: ' + JSON.stringify(data));
                this.orderObjectBarter.BarterType = null;
                this.dispatchEvent(
                    new CustomEvent('receivebarterobject', {detail: {
                        orderObjectBarter: this.orderObjectBarter}
                    }));
            }
        }).catch(error => {
            console.log('error: ' + JSON.stringify(error));
            swal("Erro: " + JSON.stringify(error.body.message) ,{ icon: "warning"})
            this.orderObjectBarter.BarterType = null;
            this.dispatchEvent(
                new CustomEvent('receivebarterobject', {detail: {
                    orderObjectBarter: this.orderObjectBarter}
                }));
        });
        this.showLoading(false);
    }

    handlePicklistPaymentForm(event) {
        var record                   = {};
        record                       = event?.detail || event?.detail?.value;
        this.orderObjectBarter.PaymentForm = record.record;
    }

    /*handleChangeTrade(event) {
        var record = {};
        record = event?.detail || event?.detail?.value;
        this.orderObjectBarter.Trade = record.record;
    }*/

    handleChangeStrikePrice(event) {
    }

    handleChangeStrikePriceOnFocusOut(event) {
        var value = event.target.value;
        if(value != null && value != ''){
            var erro = false;
            if(Number(parseFloat(value).toFixed(2)) >= Number(parseFloat(0).toFixed(2))){
                console.log('1');
                this.orderObjectBarter.StrikePrice = value;
            }
            else{
                console.log('2');
                erro = true;
                var oldvalue = this.orderObjectBarter.StrikePrice;
                this.orderObjectBarter.StrikePrice = null;
                swal("Preço Strike deve ser maior do que 0.",{ icon: "warning"}).then((action) => {
                    this.orderObjectBarter.StrikePrice = oldvalue;
                });
            }
            console.log('3');
            if(this.orderObjectBarter.StrikePrice != null && !erro){
                console.log('4');
                if((parseFloat(this.orderObjectBarter.StrikePrice).toFixed(2)/Number(parseFloat(this.orderObject.TotalPriceOrder).toFixed(2))) > 0){
                    console.log('5');
                    console.log('this.orderObject.TotalPriceOrder/value: ' + Number(parseFloat(this.orderObject.TotalPriceOrder).toFixed(2))/parseFloat(value).toFixed(2));
                    var finalValue = Math.ceil(Number(parseFloat(this.orderObject.TotalPriceOrder).toFixed(2))/parseFloat(value).toFixed(2));
                    console.log('finalValue: ' + JSON.stringify(finalValue));
                    this.orderObjectBarter.TotalDeliveryQuantity = finalValue;
                }
                else{
                    console.log('6');
                    this.orderObjectBarter.TotalDeliveryQuantity = null;
                    swal("Valor do Preço Strike: " + this.orderObjectBarter.StrikePrice + ', causou um valor invalido na quantidade da Commodity.', { icon: "warning"})
                }
                console.log('this.orderObject.TotalDeliveryQuantity: ' + JSON.stringify(this.orderObjectBarter.TotalDeliveryQuantity));
            }
        }
        else{
            this.orderObjectBarter.StrikePrice = value;
            this.orderObjectBarter.TotalDeliveryQuantity = value;
        }
    }

    handlePicklistCommodity(event){
        var record                  = {};
        record                      = event?.detail || event?.detail?.value;
        this.orderObjectBarter.Commodity  = record.record;

        if(this.orderObjectBarter.Commodity != null){
            getCommercialMeasureUnit({dependencyFieldKey: 'Commodity__c', dependencyField: 'CommercialMeasureUnit__c', value: this.orderObjectBarter.Commodity}).then(data => {
                if(data) {
                    console.log('data: ' + JSON.stringify(data));
                    this.orderObjectBarter.CommercialMeasureUnit = data;
                    this.commUnitScreen = true;
                } else {
                    swal("A commodity selecionada não está com unidade de medida definida: " + this.orderObjectBarter.Commodity ,{ icon: "warning"});
                    this.commUnitScreen = false;
                }
            }).catch(error => {
                console.log('error: ' + JSON.stringify(error));
                swal("Erro ao procurar por uma Unidade de Medida Valida" ,{ icon: "warning"})
                this.commUnitScreen = false;
            });
            if(this.orderObjectBarter.BarterType == 'Financeiro'){
                getRecordFinancialDueDate({crop: this.orderObject.Crop.Id, commodity: this.orderObjectBarter.Commodity}).then(data => {
                    if(data) {
                        console.log('data: ' + JSON.stringify(data));
                        this.orderObjectBarter.FinancialDueDate = data.FinancialDueDate__c;
                    } else {
                        swal("A commodity selecionada não contém um registro de Vencimento Financeiro Valido: " + this.orderObjectBarter.Commodity ,{ icon: "warning"})
                    }
                }).catch(error => {
                    console.log('error: ' + JSON.stringify(error));
                    swal("Erro ao procurar por um Vencimento Financeiro Valido" ,{ icon: "warning"})
                });
            }
        }
    }

    handleNewRecordShippingCrop(event) {
        var record = {};
        record     = event?.detail || event?.detail?.value;
        if(record.record == null) {
            this.orderObjectBarter.ShippingCrop = undefined;
        } else { 
            this.orderObjectBarter.ShippingCrop = record.record;
        }
    }

    handleNewRecordBillingCrop(event) {
        var record = {};
        record     = event?.detail || event?.detail?.value;
        this.orderObjectBarter.BillingCrop = record.record;
    }

    handleChangeGrossUnitPrice(event) {
    }

    handleChangeGrossUnitPriceOnFocusOut(event) {
        var value = event.target.value;
        if(value != null && value != ''){
            if(Number(parseFloat(value).toFixed(2)) > Number(parseFloat(0).toFixed(2)) && (this.orderObjectBarter.CommUnitPrice == null || Number(parseFloat(value).toFixed(2)) > Number(parseFloat(this.orderObjectBarter.CommUnitPrice).toFixed(2)))){
                console.log('1');
                this.orderObjectBarter.GrossUnitPrice = value;
            }
            else{
                console.log('2');
                var oldvalue = this.orderObjectBarter.GrossUnitPrice;
                this.orderObjectBarter.GrossUnitPrice = null;
                if(this.orderObjectBarter.CommUnitPrice != null){
                    console.log('3');
                    swal("Valor Unitario Bruto da Commodity não pode ser menor do que o valor Unitario Liquido da Commodity: " + parseFloat(this.orderObjectBarter.CommUnitPrice).toFixed(2) + ", nem menor do que 0. ",{ icon: "warning"}).then((action) => {
                        this.orderObjectBarter.GrossUnitPrice = oldvalue;
                    });
                }
                else{
                    console.log('4');
                    swal("Valor Unitario Bruto da Commodity não pode ser menor do que 0.",{ icon: "warning"}).then((action) => {
                        this.orderObjectBarter.GrossUnitPrice = oldvalue;
                    });
                }
            }
        }
        else{
            if(value == ''){
                this.orderObjectBarter.GrossUnitPrice = null;    
            }
            else{
                this.orderObjectBarter.GrossUnitPrice = value;
            }
            
        }
    }

    handleChangeCommUnitPrice(event) {
    }


    verifyUpdateTotalDeliveryQuantity(){
        if(this.orderObject.CommUnitPrice != null){
            console.log('Entrou na função para atualizar o TotalDeliveryQuantity');
            console.log(parseFloat(this.orderObject.CommUnitPrice).toFixed(2) <= parseFloat(this.orderObject.TotalPriceOrder).toFixed(2));
            if((parseFloat(this.orderObject.CommUnitPrice).toFixed(2)/Number(parseFloat(this.orderObject.TotalPriceOrder).toFixed(2))) > 0){
                console.log('5');
                console.log('this.orderObject.TotalPriceOrder/value: ' + Number(parseFloat(this.orderObject.TotalPriceOrder).toFixed(2))/parseFloat(this.orderObject.CommUnitPrice).toFixed(2));
                var finalValue = Math.ceil(Number(parseFloat(this.orderObject.TotalPriceOrder).toFixed(2))/parseFloat(this.orderObject.CommUnitPrice).toFixed(2));
                console.log('finalValue: ' + JSON.stringify(finalValue));
                this.orderObjectBarter.TotalDeliveryQuantity = finalValue;
            }
            else{
                console.log('6');
                this.orderObjectBarter.TotalDeliveryQuantity = null;
                swal("Valor do Preço da Commodity Líquido: " + this.orderObject.CommUnitPrice + ', causou um valor invalido na quantidade da Commodity.', { icon: "warning"})
            }
            console.log('this.orderObject.TotalDeliveryQuantity: ' + JSON.stringify(this.orderObjectBarter.TotalDeliveryQuantity));
        }
    }


    handleChangeCommUnitPriceOnFocusOut(event) {
        var value = event.target.value;
        if(value != null && value != ''){
            var erro = false;
            if(Number(parseFloat(value).toFixed(2)) > Number(parseFloat(0).toFixed(2)) && (this.orderObjectBarter.GrossUnitPrice == null || Number(parseFloat(value).toFixed(2)) <= Number(parseFloat(this.orderObjectBarter.GrossUnitPrice).toFixed(2)))){
                console.log('1');
                this.orderObjectBarter.CommUnitPrice = value;
            }
            else{
                console.log('2');
                erro = true;
                var oldvalue = this.orderObjectBarter.CommUnitPrice;
                this.orderObjectBarter.CommUnitPrice = null; 
                if(this.orderObjectBarter.GrossUnitPrice != null){
                    swal("Valor Unitario Liquido da Commodity não pode ser maior do que o valor Unitario Bruto da Commodity: " + parseFloat(this.orderObjectBarter.GrossUnitPrice).toFixed(2) + ", nem menor do que 0. ",{ icon: "warning"}).then((action) => {
                        this.orderObjectBarter.CommUnitPrice = oldvalue;
                    });
                }
                else{
                    swal("Valor Unitario Liquido da Commodity não pode ser menor do que 0.",{ icon: "warning"}).then((action) => {
                        this.orderObjectBarter.CommUnitPrice = oldvalue;
                    });
                }
            }
            console.log('3');

            if(this.orderObjectBarter.CommUnitPrice != null && !erro){
                console.log('4');
                console.log(parseFloat(this.orderObjectBarter.CommUnitPrice).toFixed(2) <= parseFloat(this.orderObject.TotalPriceOrder).toFixed(2));
                if((parseFloat(this.orderObjectBarter.CommUnitPrice).toFixed(2)/Number(parseFloat(this.orderObject.TotalPriceOrder).toFixed(2))) > 0){
                    console.log('5');
                    console.log('this.orderObject.TotalPriceOrder/value: ' + Number(parseFloat(this.orderObject.TotalPriceOrder).toFixed(2))/parseFloat(value).toFixed(2));
                    var finalValue = Math.ceil(Number(parseFloat(this.orderObject.TotalPriceOrder).toFixed(2))/parseFloat(value).toFixed(2));
                    console.log('finalValue: ' + JSON.stringify(finalValue));
                    this.orderObjectBarter.TotalDeliveryQuantity = finalValue;
                }
                else{
                    console.log('6');
                    this.orderObjectBarter.TotalDeliveryQuantity = null;
                    swal("Valor do Preço da Commodity Líquido: " + this.orderObjectBarter.CommUnitPrice + ', causou um valor invalido na quantidade da Commodity.', { icon: "warning"})
                }
                console.log('this.orderObject.TotalDeliveryQuantity: ' + JSON.stringify(this.orderObjectBarter.TotalDeliveryQuantity));
            }
        }
        else{
            if(value == ''){
                this.orderObjectBarter.CommUnitPrice = null;
                this.orderObjectBarter.TotalDeliveryQuantity = null;    
            }
            else{
                this.orderObjectBarter.CommUnitPrice = value;
                this.orderObjectBarter.TotalDeliveryQuantity = value;
            }
        }
    }

    handleFreightBarter(event) {
        var value = event.target.value;

        if(value == 'CIF') {
            this.checkedFreightCommCIF = true;
            this.checkedFreightCommFOB = false;
            this.showDelivery = true;
            this.showPickup = false;
            this.orderObjectBarter.CommFreigthMode = 'CIF';
        } else if (value == 'FOB') {
            this.checkedFreightCommCIF = false;
            this.checkedFreightCommFOB = true;
            this.showDelivery = false;
            this.showPickup = true;
            this.orderObjectBarter.CommFreigthMode = 'FOB';
        }
    }

    handleTextAreaDelivery(event) {
        this.orderObjectBarter.ProductionDeliveryLocation = event.target.value;
    }

    handleTextAreaPickup(event) {
        this.orderObjectBarter.ProductionPickupLocation = event.target.value;
    }

    async handleInitialDeliveryDate(event) {
        if(event.target.value == null){
            this.orderObjectBarter.InitialDeliveryDate = null;
        }
        var dateToday       = new Date().setHours(0,0,0,0);
        var dateCurrent     = new Date(this.convertDateToCorrectFormatDateToCreate(event.target.value) + ' 00:00:00');
        var endDeliveryDate = this.orderObjectBarter.EndDeliveryDate != undefined ? this.orderObjectBarter.EndDeliveryDate != null ? new Date(this.convertDateToCorrectFormatDateToCreate(this.orderObjectBarter.EndDeliveryDate)) : null : null;
        if(dateToday <= dateCurrent.getTime() && (endDeliveryDate == null || endDeliveryDate.getTime() >= dateCurrent.getTime())) {
            this.orderObjectBarter.InitialDeliveryDate = event.target.value;
        } else {
            this.orderObjectBarter.InitialDeliveryDate = event.target.value;
            if(endDeliveryDate != null){
                await swal("Data Inicial da Entrega não pode ser maior do que a Data Final da Entrega: " + endDeliveryDate + ", nem menor do que a data de hoje. ",{ icon: "warning"}).then((action) => {
                    this.orderObjectBarter.InitialDeliveryDate = undefined;
                });
            }
            else{
                await swal("Data Inicial da Entrega não pode ser menor do que a data de hoje.",{ icon: "warning"}).then((action) => {
                    this.orderObjectBarter.InitialDeliveryDate = undefined;
                });
            }
        }
    }

    async handleEndDeliveryDate(event) {
        if(event.target.value == null){
            orderObjectBarter.EndDeliveryDate = null;
        }
        var dateToday       = new Date().setHours(0,0,0,0);
        var dateCurrent     = new Date(this.convertDateToCorrectFormatDateToCreate(event.target.value) + ' 00:00:00');
        var initialDeliveryDate = this.orderObjectBarter.InitialDeliveryDate != undefined ? this.orderObjectBarter.InitialDeliveryDate != null ? new Date(this.convertDateToCorrectFormatDateToCreate(this.orderObjectBarter.InitialDeliveryDate)) : null : null;
        if(dateToday <= dateCurrent.getTime() && (initialDeliveryDate == null || initialDeliveryDate.getTime() <= dateCurrent.getTime())) {
            this.orderObjectBarter.EndDeliveryDate = event.target.value;
        } else {
            this.orderObjectBarter.EndDeliveryDate = event.target.value;
            if(initialDeliveryDate != null){
                await swal("Data Final da Entrega não pode ser menor do que a Data Inicial da Entrega: " + initialDeliveryDate + ", nem menor do que a data de hoje. ",{ icon: "warning"}).then((action) => {
                    this.orderObjectBarter.EndDeliveryDate = undefined;
                });
            }
            else{
                await swal("Data Final da Entrega não pode ser menor do que a data de hoje.",{ icon: "warning"}).then((action) => {
                    this.orderObjectBarter.EndDeliveryDate = undefined;
                });
            }
        }
    }

    checkAllFieldsBarter(orderObjectBarter) {
        var returnVal = true;
        console.log('orderObject: ' + orderObjectBarter);
        if(orderObjectBarter["BarterType"] == 'Triangulação'){
            if (this.orderObjectBarter.Trade == null) {
                return returnVal = false;
            }
            this.allReqFieldsTriangulationBarter.forEach(function(item) {
                console.log('BarterField Ok?: ' + !orderObjectBarter[item]);
                if(!orderObjectBarter[item]) {
                    returnVal = false;
                    return;
                }
            });
            if((orderObjectBarter["CommFreigthMode"] == 'CIF'   && !orderObjectBarter["ProductionDeliveryLocation"]) 
            || (orderObjectBarter["CommFreigthMode"] == 'FOB'   && !orderObjectBarter["ProductionPickupLocation"])){
                returnVal = false;
                return;
            }
        }else if(orderObjectBarter["BarterType"] == 'Financeiro'){
            this.allReqFieldsFinancialBarter.forEach(function(item) {
                console.log('BarterField Ok?: ' + !orderObjectBarter[item]);
                if(!orderObjectBarter[item]) {
                    returnVal = false;
                    return;
                }
            });
        }else{
            this.allReqFieldsBarter.forEach(function(item) {
                console.log('BarterField Ok?: ' + !orderObjectBarter[item]);
                if(!orderObjectBarter[item]) {
                    returnVal = false;
                    return;
                }
            });
            if((orderObjectBarter["CommFreigthMode"] == 'CIF'   && !orderObjectBarter["ProductionDeliveryLocation"]) 
            || (orderObjectBarter["CommFreigthMode"] == 'FOB'   && !orderObjectBarter["ProductionPickupLocation"])){
                returnVal = false;
                return;
            }
        }        
        return returnVal;
    }

    createCreditLimitRequest() {
        let externalId;
        if (this.orderObject.Account.ParentExternalId != null) {
            externalId = this.orderObject.Account.ParentExternalId
        }
        else{
            externalId =  this.orderObject.Account.ExternalId__c
        }
        this.creditLimitRequest = {
            "Moeda": this.orderObject.Currency, 
            "Cliente": externalId,
            "Cultura": this.orderObject.OrderItem[0].Culture.ExternalId__c

        };
    }

    async onClickShowBarterStepB(){

        var hasError = false;
        var Messages;
        if(this.checkAllFieldsBarter(this.orderObjectBarter)){
            this.createCreditLimitRequest();
            console.log('CreditLimitRequest: ' + JSON.stringify(this.creditLimitRequest));
            //this.creditLimitRequest.Cliente = '0000000079';
            //this.creditLimitRequest.Cultura = '015';
            //this.creditLimitRequest.Moeda = 'BRL';
            //console.log('CreditLimitRequestForTest: ' + JSON.stringify(this.creditLimitRequest));
            this.showLoading(true);
            await queryCreditLimit({payload: JSON.stringify(this.creditLimitRequest)}).then(data => {
                this.orderObjectBarter.Rating = data.Rating;
                this.orderObjectBarter.Bloqued = data.Bloqueio;
                Messages = data.Mensagens;
                console.log('Rating: ' + JSON.stringify(this.orderObjectBarter.Rating));
                console.log('Bloqueio: ' + this.orderObjectBarter.Bloqued);
                console.log('Messages: ' + JSON.stringify(Messages));
            }).catch(error => {
                console.log('error: ' + JSON.stringify(error));
                this.showLoading(false);
                hasError = true;
                swal("Error: " + JSON.stringify(error.body.message),{ icon: "error"}).then((action) => {});
            });
            this.showLoading(false);
            if(!hasError && (Messages == null || Messages.length == 0)){
                this.dispatchEvent(
                    new CustomEvent('clickshowbarterstepb', {detail: {
                        orderObjectBarter: this.orderObjectBarter}
                    }));
            }
            else if(Messages != null && Messages.length > 0){
                //Messages.forEach(function(item) {
                //    if(item.Tipo == 'E') {
                //        swal("Erro: " + item.Mensagem ,{ icon: "error"});
                //    }
                //    else if(item.Tipo == 'W'){
                //        swal("Warning: " + item.Mensagem ,{ icon: "warning"});
                //    }
                //});
                swal(IntegrationLimitCreditError ,{ icon: "warning"});
            }
        }
        else {
            this.checkEachFieldBarter();
        }
    }

    handleChangeTrade(event) {
        this.orderObjectBarter.Trade =  event?.detail?.value;
    }

    checkEachFieldBarter() {
        var financialBarter = this.orderObjectBarter.BarterType == 'Financeiro' ? true : false;
        if (this.orderObjectBarter.BarterType == null) {
            swal("Para prosseguir preencha o campo obrigatório: BarterType.",{ icon: "warning"});
        } else if (this.orderObjectBarter.BarterType == 'Triangulação' && this.orderObjectBarter.Trade == null) {
            swal("Para prosseguir preencha o campo obrigatório: Trade.",{ icon: "warning"});
        }  else if (financialBarter && this.orderObjectBarter.StrikePrice == null) {
            swal("Para prosseguir preencha  o campo obrigatório: Preço Strike.",{ icon: "warning"});
        } else if (financialBarter && this.orderObjectBarter.FinancialDueDate == null) {
            swal("Para prosseguir preencha o campo obrigatório: Vencimento Financeiro.",{ icon: "warning"});
        } else if (this.orderObjectBarter.Commodity == null) {
            swal("Para prosseguir preencha  o campo obrigatório: Commodity.",{ icon: "warning"});
        } else if (this.orderObjectBarter.ShippingCrop == null) {
            swal("Para prosseguir preencha o campo obrigatório: Safra de Entrega do Grão.",{ icon: "warning"});
        } else if (!financialBarter && this.orderObjectBarter.GrossUnitPrice == null) {
            swal("Para prosseguir preencha  o campo obrigatório: Preço Comm. Bruto.",{ icon: "warning"});
        } else if (!financialBarter && this.orderObjectBarter.CommUnitPrice == null) {
            swal("Para prosseguir preencha  o campo obrigatório: Preço Comm. Líquido.",{ icon: "warning"});
        } else if (!financialBarter && this.orderObjectBarter.CommFreigthMode == null){
            swal("Para prosseguir preencha  o campo obrigatório: Tipo de Frete Commodities.",{ icon: "warning"});
        } else if (!financialBarter && this.orderObjectBarter.CommFreigthMode == 'CIF' && this.orderObjectBarter.ProductionDeliveryLocation == null) {
            swal("Para prosseguir preencha  o campo obrigatório: Local de Entrega.",{ icon: "warning"});
        } else if (!financialBarter && this.orderObjectBarter.CommFreigthMode == 'FOB' && this.orderObjectBarter.ProductionPickupLocation == null) {
            swal("Para prosseguir preencha  o campo obrigatório: Local de Retirada.",{ icon: "warning"});
        } else if (!financialBarter && this.orderObjectBarter.InitialDeliveryDate == null) {
            swal("Para prosseguir preencha  o campo obrigatório: Data Inicial da Entrega do Grão.",{ icon: "warning"});
        } else if (!financialBarter && this.orderObjectBarter.EndDeliveryDate == null) {
            swal("Para prosseguir preencha  o campo obrigatório: Data Final da Entrega do Grão.",{ icon: "warning"});
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

    showLoading(show) {
		this.loading = show;
	}
}