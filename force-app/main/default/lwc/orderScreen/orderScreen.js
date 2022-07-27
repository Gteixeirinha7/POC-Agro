import { LightningElement, api, track, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import Images from '@salesforce/resourceUrl/AllImagesScreenOrder';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getBaseData from '@salesforce/apex/OrderScreenController.getBaseData';
import getPaymentFormPicklistValues from '@salesforce/apex/OrderScreenController.getPaymentFormPicklistValues';
import getAllProp from '@salesforce/apex/OrderScreenController.getAllProp';
import getRTVSalesTeam from '@salesforce/apex/GetAccountTeam.getRTVSalesTeam';
import AllJsFilesSweetAlert from '@salesforce/resourceUrl/AllJsFilesSweetAlert';
import { NavigationMixin} from 'lightning/navigation';
import {refreshApex} from '@salesforce/apex';
import getCustomerPerOrg from '@salesforce/apex/CustomerPerOrgController.getCustomerPerOrg';
import getPaymentFormPicklist from '@salesforce/apex/OrderScreenController.getPicklistValues';
import getContractInformation from '@salesforce/apex/OrderScreenController.getContractInformation';
import getPaymentConditionBarter from '@salesforce/apex/OrderScreenController.getPaymentConditionBarter';
import getRecordSalesTeam from '@salesforce/apex/CustomLookupController.getRecordSalesTeam';
import FiscalDomicileAlert from '@salesforce/label/c.FiscalDomicileAlert';
import StockAlert from '@salesforce/label/c.StockAlert';
import handleInventory from '@salesforce/apex/OrderScreenController.handleInventory';
import getCampaign from '@salesforce/apex/CampaignController.getCampaign';

import getClientState from '@salesforce/apex/OrderScreenController.getClientState';
import getListPriceData from '@salesforce/apex/PriceListController.getListPriceData';
import getInterestListData from '@salesforce/apex/InterestListController.getInterestListData';
import getFreigth from '@salesforce/apex/GetFreigthController.getFreigth';

import { getBaseDataUtils } from './utils2';
import { findAuth } from './orderScreenutils';
import { fillOrderBarter, nullOrderItemObjectUtils, fillAxOrd, fillNewOrderItem, dateTodayFormat, dateTodayWithoutFormat, handleFreigth, handleDiscount, handleAddition, handleInventoryCheck, handleNullStock, validateCampaign, fillOrderItemCampaignObject, applyCampaignDiscounts, removeCampaignFromItem, validateAccumulativeAndIndustryCampaign, updateOrderTotalValues, applyCampaignDiscountsAndValidation  } from './utils';
export default class OrderScreen extends NavigationMixin(LightningElement) {
	cIBack		 = Images + '/AllImagesScreenOrder/ic-arrow-left.svg';
	cIContinueBlue = Images + '/AllImagesScreenOrder/ic-arrow-right-blue.svg';
	cIEmissionDate = Images + '/AllImagesScreenOrder/ic-calendar-alt.svg';
	cIContinue	 = Images + '/AllImagesScreenOrder/ic-arrow-right.svg';
	cISumWhite	 = Images + '/AllImagesScreenOrder/ic-plus-white.svg';
	cIDel		  = Images + '/AllImagesScreenOrder/ic-delele.svg';
	cIEdit		 = Images + '/AllImagesScreenOrder/ic-edit.svg';
	cIPlusCircle   = Images + '/AllImagesScreenOrder/ic-plus-circle-white.svg';
	cIPaper		= Images + '/AllImagesScreenOrder/ic-paper.svg';
	cIView		 = Images + '/AllImagesScreenOrder/ic-eye.svg';
	cICheck		= Images + '/AllImagesScreenOrder/ic-check-ball.svg';
	cIMoneyCheck   = Images + '/AllImagesScreenOrder/ic-money-check-alt.svg';
	cICheckSquare  = Images + '/AllImagesScreenOrder/ic-check-square-pink.svg';
	cIfoto		 = Images + '/AllImagesScreenOrder/ic-image-foto.svg';
	cICamera	 = Images + '/AllImagesScreenOrder/ic-camera.svg';

	disabledProduct2;
	@api isRefuseReason = false;
	@track options;
	@track valueDataValidade;
	@track mapIdRtvToSalesTeams;
	@track FileName;
	@track orderObjectDueDate;
	@track countEnabled			= false;
	@track hiddenRTV			   = true;
	@track hiddenProps			 = true;
	@track hiddenSalesTeam		 = true;
	@track hasAttachment		   = false;
	@track showBarterContractField = false;
	@track showDateContractField   = false;
	@track showOrderContractField  = false;
	@track showPedidoStep2b		= false;
	@track showPedidoStep03		= false;
	@track showBarterStepA		 = false;
	@track showBarterStepB		 = false;
	@track showPedidoStep01		= true;
	@track checkedSales			= false;
	@track checkedContract		 = false;
	@track shippingDivision		= new Object();
	@track orderItemObject		 = new Object();
	@track Dates				   = new Object();
	@track authArray = [];
	@track finAuth;
	@track mktAuth;
		
	@track ordItemList =[];

	@track contractProducts;
	@track filtersales = null;
	@api salesTeamList;
	@api idsRtvs;
	@api quantity;
	@api priceList;
	@api maxValueUnitPrice;
	@api activitySector;
	@api currencyScreen;
	@api currencyScreenFormat;
	@api recordId;
	@api parentAccountId;
	@api orderTypeMP;
	@api contractId;
	@api orderRequest;
	@api creditLimitRequest;
	@api toastInfoErrorDatePlusThirty;
	@api toastInfoErrorCurrencyDol;
	@api clienteId;
	@api parentId;
	@api productId;
	@api priceListData;
	@api priceListDataJsonStrg;
	@api strProductsName;
	@api creditLimitBloqued;
	@api documentId;
	@api campaignList;
	@api containInventoryError = false;
	@api showInventoryMessage = false;
	@api checkAllInventory = false;
	@api disabledReturnSap	  = false;
	@api productWithContract	= false;
	@api freigthValue		   = 0;
	@api itemContext			= '_isNew_';
	@api clientDebtNegativeMessage = false;
	@api checkedCurrencyDol	 = false;
	@api checkedCurrencyReal	= false;
	@api showPedidoStep2a	   = false;
	@api hiddenCity			 = false;
	@api loading				= false;
	@api hiddenSalesSector1	 = false;
	@api viewProduct			= false;
	@api disabledCustomLookup   = false;
	@api disabledContract   = false;
	@api disabledSalesCondition = false;
	@api disabledBarterFields   = false;
	@api disabledAllFields	  = false;
	@api disableLastPageProducts = false;
	@api disableConclude		= false;
	@api disableLastPageEdit	= false;
	@api disablefreight		 = false;
	@api disabledAllObservation = false;
	@api disabledPaymentForm	= false;
	@api disabledNegotiationType = false;
	@api checkedFreightFOB	  = false;
	@api checkedFreightCIF	  = false;
	@api checkedFreightFCA	  = false;
	@api checkedFreightCommCIF  = false;
	@api checkedFreightCommFOB  = false;
	@api hiddenShippingDivision = false;
	@api hideConclude		   = false;
	@api hideSave			   = false;
	@api showDelivery		   = false;
	@api showPickup			 = false;
	@api showTotalQuantity	  = false;
	@api orderObject			= new Object();
	@api contractCulture		= new Object();
	@api axOrd				  = new Object();
	@api orderItem			  = [];
	@api mapShippingDivisionObj = new Object();
	@api dateToday			  = dateTodayFormat();
		
	@api allReqFieldsHeader  = ['Account','BillingAccount','ShippingAccount','SalesTeam','SalesCondition','RecordType','PaymentForm','Currency','ExpirationDate','Crop','Rtv','PaymentCondition','DueDate','ActivitySector'];

	@api allReqFieldsScreenProduct  = ['Product2','ListPrice','Quantity','UnitValue','PriceList','TotalValueItem','Family','Culture'];

	@api acceptedFormats = ['.xlsx', '.xls', '.jpg', '.csv', '.png', '.doc', '.docx', '.pdf', '.txt']

	connectedCallback() {
		this.checkAllInventory = true;
		Promise.all([loadScript(this, AllJsFilesSweetAlert + '/sweetalert-master/sweetalert.min.js')]).then(() => { }).catch(error => { });
		this.handleGetBaseData();
		if(window.sessionStorage.getItem('OrderType') == null)
			window.sessionStorage.setItem('OrderType', 'SFOR');
	}

	renderedCallback() {
		if(window.sessionStorage.getItem('OrderType') == null)
			window.sessionStorage.setItem('OrderType', 'SFOR');
	}

	@wire(getBaseData, {recordId: '$recordId'})
	getBaseDataRefreshed;

	@wire(getRTVSalesTeam,{accId: '$clienteId'})
	salesTeamProcess;

	@wire(getCustomerPerOrg, {accountId: '$orderObject.Account.Id', ordgId: '$orderObject.SalesTeam.SalesOrg__c'})
	getCustomerPerOrgRefreshed;

	@wire(getPaymentFormPicklist, {dependencyFieldKey: 'BarterType__c', dependencyField: 'PaymentForm__c'})
	getPaymentFormPicklistRefreshed;

	@wire(getAllProp, {accId: '$clienteId'})
	getAllPropRefreshed;

	@wire(getPaymentFormPicklistValues, {pcId: null})
	getPaymentFormPicklistValues;

	async refreshApexGetAllPropRefreshed() {
		try {
			await refreshApex(this.getAllPropRefreshed);
		} catch(e) {
		}
	}

	async refreshApexGetPaymentFormPicklistValues() {
		try {
			await refreshApex(this.getPaymentFormPicklistValues);
		} catch(e) {
		}
	}

	async refreshApexGetPaymentFormPicklist() {
		try {
			await refreshApex(this.getPaymentFormPicklistRefreshed);
		} catch(e) {
		}
	}

	async refreshApexGetCustomerPerOrg() {
		try {
			await refreshApex(this.getCustomerPerOrgRefreshed);
		} catch(e) {
		}
	}

	async refreshApexGetRTVSalesTeam() {
		try {
			await refreshApex(this.salesTeamProcess);
		} catch(e) {
		}
	}

	async refreshApexGetBaseData() {
		try {
			await refreshApex(this.getBaseDataRefreshed);
		} catch(e) {
		}
	}

	checkHasErrorDate(record){
		this.HasErrorDate = record.NCDDate__c < dateTodayWithoutFormat();
	}

		

	async handleGetBaseData() {
		this.showLoading(true);
		this.checkAllInventory = true;
		await this.refreshApexGetBaseData();
		await getBaseData({recordId: this.recordId}).then(data => {
			getBaseDataUtils(this, data);
			}).catch(error => {
			  this.showLoading(false);
			  swal("Erro: " + JSON.stringify(error.body.message),{ icon: "error"}).then((action) => {this.navigateToView(this.recordId);});
			getClientState({clientId: this.clienteId}).then(data => {
			  this.clientDebtNegativeMessage = data;
			})
			});
	}

	changeColorCustomLookups() {
		this.template.querySelectorAll('c-custom-lookup').forEach(element => {element.initialSetupOrder();});
		this.template.querySelector('c-custom-lookup-rtv').initialSetupOrder();
		this.template.querySelector('c-custom-lookup-sales-team').initialSetupOrder();
	}

	setOrderItems(orderItems) {
		try {
			this.orderObject.OrderItem = [];
			for(var i = 0; i < orderItems.length; i++) {
				var orderItemObj = fillNewOrderItem(orderItems[i], this.orderObject);
				orderItemObj.ShippingDivision = this.setShippingDivision(this.mapShippingDivisionObj[orderItems[i].Id]);
				this.orderObject.OrderItem.push(this.cloneObj(orderItemObj));
			}
			
		} catch(e) {
			this.showLoading(false);
			swal("Erro ao realizar a busca pelos produtos do pedido: " + e,{ icon: "error"}).then((action) => {this.navigateToView(this.recordId);});
		}
	}

	setOrderItemCampaign(campaigns) {
		var containCampaign;
		this.orderObject.OrderItem.forEach(function(ordItem) {
			if(campaigns.length > 0) {
				campaigns.forEach(function(campaign) {
					if(ordItem.Id == campaign.OrderItem__c) {
						if(!ordItem.Campaign.find(oiCampaign => oiCampaign.campaign == campaign.CampaignId)) {
							var newCampaign = {};
							newCampaign = fillOrderItemCampaignObject(newCampaign, campaign);
							ordItem.Campaign.push(newCampaign);
							ordItem.hasCampaign = true;
							containCampaign = true;
						}
					}
				});
			}
		});

		if(containCampaign) {
			this.orderObject.hasCampaign = true;
		}
	}

	setShippingDivision(shippingDivisions) {
		try {
			var shippingDivisionArray = [];
			for(var i = 0; i < shippingDivisions.length; i++) {
				var shipObj			   = {};
				shipObj.SD				= {};
				shipObj.Iterator		  = parseInt(i);
				shipObj.SD.Quantity	   = shippingDivisions[i].Quantity__c;
				shipObj.SD.DueDate		= shippingDivisions[i].DeliveryDate__c;
				shipObj.SD.DueDateShowBrl = this.convertDateToDateBrlStr(shippingDivisions[i].DeliveryDate__c);
				shipObj.SD.Id			 = shippingDivisions[i].Id;
				shippingDivisionArray.push(this.cloneObj(shipObj));
			}
			return shippingDivisionArray;
		} catch(error) {
			this.showLoading(false);
			swal("Erro ao realizar a busca pelas divisões de remessa: " + e,{ icon: "error"}).then((action) => {this.navigateToView(this.recordId);});
		}
	}

	async handleNewRecordAccount(event) {
		var record = {};
		record	 = event?.detail || event?.detail?.value;
		let recs = record?.record;
		console.log('recs => ' + recs);

		this.showLoading(true);
		if(recs != null && recs.InternShippingCity__c) {
			this.orderObject["Account"] = recs;
			var data = await this.handleGetAllProp();
			if(data == null) {
				this.hiddenProps					= false;
				this.hiddenSalesTeam				= true;
				this.orderObject["BillingAccount"]  = recs;
				this.orderObject["ShippingAccount"] = recs;
				this.clienteId					  = recs.Id;
				this.parentId                     = recs.ParentId;
				console.log('this.parentId => ' + this.parentId);
			} else {
				this.hiddenProps					 = true;
				this.hiddenSalesTeam				 = true;
				this.orderObject.Account			 = recs;
				this.clienteId					   = recs.Id;
				this.parentId                      = recs.ParentId;
				console.log('this.parentId => ' + this.parentId);
			}
			await this.handleGetRTVSalesTeam();
			this.checkHasErrorDate(recs);
		} else if (recs == null || !(recs?.InternShippingCity__c)) {
			this.hiddenSalesTeam				= false;
			this.hiddenProps					= false;
			this.orderObject["Account"]		 = null;
			this.orderObject["BillingAccount"]  = null;
			this.orderObject["ShippingAccount"] = null;
			this.clienteId					  = null;
			this.orderObject["SalesTeam"]	   = null;
			this.orderObject["Rtv"]			 = this.orderObject.IsUserRtv == true ? this.orderObject.Rtv : null;
			if(!this.orderObject.IsUserRtv){
				this.salesTeamList				  = null;
			}
			this.nullShippingDivisionObject();
			if(recs != null && !(recs.InternShippingCity__c)) {
				swal(FiscalDomicileAlert ,{ icon: "warning"});
				await this.handleNewRecordAccount(null);
				this.template.querySelectorAll('c-custom-lookup').forEach(element => {element.initialSetupOrderEmpty();});
			}
		}

		if(recs != null && recs.Blocked__c){
			this.hiddenSalesTeam				= false;
			this.hiddenProps					= false;
			this.orderObject["Account"]		 = null;
			this.orderObject["BillingAccount"]  = null;
			this.orderObject["ShippingAccount"] = null;
			this.clienteId					  = null;
			this.orderObject["SalesTeam"]	   = null;
			this.orderObject["Rtv"]			 = this.orderObject.IsUserRtv == true ? this.orderObject.Rtv : null;
			if(!this.orderObject.IsUserRtv){
				this.salesTeamList				  = null;
			}
			this.nullShippingDivisionObject();
			swal('Cliente bloqueado. Em caso de dúvida, contatar a Central de Cadastro.' ,{ icon: "warning"});
			await this.handleNewRecordAccount(null);
			this.template.querySelectorAll('c-custom-lookup').forEach(element => {element.initialSetupOrderEmpty();});
		}
		this.showLoading(false);
	}

	async handleGetAllProp() {
		await this.refreshApexGetAllPropRefreshed();
		var result;
		await getAllProp({accId: this.orderObject.Account.Id}).then(data => {
			if(data) {
				result = this.cloneObj(data); 
			} else {
				result = null;
			}
		}).catch(error => {
			result = null;
		});
		return result;
	}

	async handleGetRTVSalesTeam() {
		await this.refreshApexGetRTVSalesTeam();

		await getRTVSalesTeam({accId: this.clienteId}).then(data => {
			if(data == null) {
			} else {
				const obj				 = JSON.parse(data);
				this.mapIdRtvToSalesTeams = this.cloneObj(obj);
		
				if(this.hiddenRTV == false) {
					this.salesTeamList = this.mapIdRtvToSalesTeams[this.orderObject.Rtv.Id];
					if (this.salesTeamList && this.salesTeamList.length == 1) {
						this.selectRecordSalesTeam(this.salesTeamList);
					}
				} else {
					this.hiddenSalesTeam = true;
					this.idsRtvs		 = Object.keys(this.mapIdRtvToSalesTeams);
				}
			}
		}).catch(error => {
		});
	}

	handleNewRecordBillingAccount(event) {
		var record = {};
		record	 = event?.detail || event?.detail?.value;

		if(record.record == null) {
			this.orderObject.BillingAccount = null;
		}
		if(record.name == "customLookupBillingAccount" && record.record != null) {
			this.orderObject.BillingAccount = record.record;
		}
	}

	handleNewRecordShippingAccount(event) {
		var record = {};
		record = event?.detail || event?.detail?.value;

		if(record.record == null) {
			this.orderObject.ShippingAccount = null;
		}
		if(record.name == "customLookupShippingAccount" && record.record != null) {
			this.orderObject.ShippingAccount = record.record;

			if((!this.orderObject["ShippingAccount"].InternShippingCity__c)) {
				swal(FiscalDomicileAlert ,{ icon: "warning"});
				this.orderObject["ShippingAccount"] = null;

				this.template.querySelectorAll('c-custom-lookup.shippingCustomLookup').forEach(function(element){
					element.initialSetupOrderShipEmpty();
				});
			}
			
			this.checkHasErrorDate(record.record);
		}
	}

	handleNewRecordRTV(event) {
		var record = {};
		record	 = event?.detail || event?.detail?.value;
		if(record.record == null) {
			this.orderObject.Rtv = null;
			this.salesTeamList   = null;
		} else {
			this.orderObject.Rtv = record.record;
			this.hiddenSalesTeam = true;
			var mapRtv		   = JSON.parse(JSON.stringify(this.mapIdRtvToSalesTeams));
			this.salesTeamList   = mapRtv[record.record.UserId];
			if (this.salesTeamList && this.salesTeamList.length == 1) {
				this.selectRecordSalesTeam(this.salesTeamList);
			}
		}
	}

	async handleNewRecordSalesTeam(event) {
		var record				 = {};
		record					 = event?.detail || event?.detail?.value;
		this.orderObject.SalesTeam = record.record;
		if(this.orderObject.SalesTeam != null) {
			await this.handleGetCPO();
		} else {
			this.hiddenSalesSector1 = false;
		}
	}
	selectRecordSalesTeam(salesTeamList) {
		this.showLoading(true);
		getRecordSalesTeam({
			objectApiName: 'SalesTeam__c',
			fieldApiName: 'Name',
			searchTerm: '',
			filter: ' AND Id IN (replace) ',
			fieldApiNames: ', DistributionCenter__r.City__c, SalesOrg__c, SalesOrg__r.Name, SalesOrg__r.Director__r.Name, ParentId__c, Manager__r.Name',
			recordId: null,
			salesTeamList: salesTeamList,
			byFocus: true
		}).then(data => {
			this.orderObject["SalesTeam"] = data[0];
			if(this.orderObject.Account != null)
				this.handleGetCPO()
		});
	}

	async handleGetCPO() {
		this.showLoading(true);

		await this.refreshApexGetCustomerPerOrg();

		await getCustomerPerOrg({accountId: this.orderObject.Account.Id, orgId: this.orderObject.SalesTeam.SalesOrg__c, activitySector: null}).then(data => {
			if(data) {
				if(data.IsBlock == false && data.HaveCustomer) {
					this.hiddenSalesSector1 = true;
					if(data.HaveSector == true) {
						this.template.querySelectorAll('c-show-picklist-value').forEach(element => {
							if(element.picklistName == 'activitySectorPickList') element.setPickListOptions(data.ActivitySectorList)});
						this.orderObject.CustomerPerOrg = this.cloneObj(data.CustPerOrgObj);
						this.orderObject.CustomerGroup  = this.orderObject.CustomerPerOrg.ClientGroup__c;
						if(!data.ActivitySectorList.includes(this.orderObject.ActivitySector)){
							this.orderObject.ActivitySector = null;
						}
					} else {
						this.orderObject.CustomerGroup = null;
					}
				} else if (data.IsBlock == true) {
					swal("O cliente selecionado está bloqueado para a organização de vendas: " + this.orderObject.SalesTeam.SalesOrg__r.Name ,{ icon: "warning"}).then((action) => {
						this.orderObject.SalesTeam	 = null;
						this.hiddenSalesSector1		= false;
						this.orderObject.CustomerGroup = null;
					});
				}
			} else {
				swal("O cliente selecionado não foi expandido para a organização de vendas: " + this.orderObject.SalesTeam.SalesOrg__r.Name ,{ icon: "warning"}).then((action) => {
					this.orderObject.SalesTeam	 = null;
					this.hiddenSalesSector1		= false;
					this.orderObject.CustomerGroup = null;
				});
			}
		}).catch(error => {
			swal("Erro: " + JSON.stringify(error.body.message) ,{ icon: "warning"}).then((action) => {
				this.orderObject.SalesTeam	 = null;
				this.hiddenSalesSector1		= false;
				this.orderObject.CustomerGroup = null;
			});
		});
		this.showPedidoStep01 = false;
		this.showPedidoStep01 = true;
		this.showLoading(false);
	}

	handlePicklistSalesCondition(event) {
		var record = {};
		record	 = event?.detail || event?.detail?.value;
		if(record.record == '02') {
			this.checkedCurrencyReal  = false;
			this.checkedCurrencyDol   = true;
			this.orderObject.Currency = 'USD';
		}
		this.orderObject.SalesCondition = record.record;
	}

	async handleLoading(event) {
		var rec = event?.detail || event?.detail?.value;
		this.showLoading(rec.record)
	}
	async handleNewRecordType(event) {
		this.showOrderContractField = false;
		this.orderObject.PaymentForm = null;
		this.orderObject.PaymentCondition = null;
		var record				  = {};
		record					  = event?.detail || event?.detail?.value;
		if(record.record == 'BarterSale'){
			getPaymentConditionBarter({exId : 'CFIX'}).then(data => {
				if(data) {
					this.orderObject.PaymentCondition = data;
				}
			})
			this.handleGetPaymentFormPicklistValues();
		}
		else{
			this.handleGetPaymentForm();
		}

		if(record.record == "IndustryBonification" || record.record == "Bonification") {
			this.orderObject.SalesCondition = '24';
			this.template.querySelectorAll('c-show-picklist-value').forEach(element => {
			if(element.picklistName == 'paymentFormPickList') element.setPickListOptions('#')});
			this.orderObject.PaymentForm = '#';
		}else{
			this.disabledSalesCondition = false;
			this.disabledPaymentForm = false;
		}
		if((this.orderObject.RecordType == "IndustryBonification" || this.orderObject.RecordType == "Bonification") && (record.record != "IndustryBonification" && record.record != "Bonification")) {
			this.orderObject.SalesCondition = null;
		}
		if((this.orderObject.RecordType != "IndustryBonification" || this.orderObject.RecordType != "Bonification") && (record.record == "IndustryBonification" || record.record == "Bonification") && (this.orderObject.OrderItem.length == 0)) {
			this.orderObject.RecordType = record.record;
		} else if((this.orderObject.RecordType != "IndustryBonification" || this.orderObject.RecordType != "Bonification") && (record.record == "IndustryBonification" || record.record == "Bonification") && (this.orderObject.OrderItem.length > 0)) {
			var oldRecordType		   = this.orderObject.RecordType;
			this.orderObject.RecordType = null;
			swal("Os valores dos produtos serão modificados, tem certeza que deseja mudar o tipo de negociação?",{ icon: "warning", buttons: true }).then((action) => {
				if(action) {
					this.disabledSalesCondition = true;
					this.disabledPaymentForm = true;
					this.orderObject.RecordType = record.record;
					this.changeDiscountValueInAllProducts();
				} else {
					this.orderObject.RecordType = oldRecordType;
				}
			});
		} else {
			this.orderObject.RecordType = record.record;
		}
		if(this.orderObject.RecordType == "BarterSale" || this.orderObject.RecordType == 'ZCNO' || this.orderObject.RecordType == 'ZCEF' || this.orderObject.RecordType == 'ZCCO'){
			this.selectContract();
		}else{
			this.selectSales();
		}
	}
	selectContract(){
		this.checkedContract = true;
		this.checkedSales = false;
		this.hideConclude				 = false;
		this.showDateContractField		= true;
		this.orderObject.PaymentCondition = null;
		this.showPedidoStep01			 = false;
		this.showPedidoStep01			 = true;
		this.showOrderContractField	   = false;
		if(this.orderObject.RecordType == "BarterSale") {
			this.hideSave					 = true;
			this.showBarterContractField	  = true;
			this.hideConclude				 = true;
		}else{
			this.showBarterContractField	  = false;
		}
	}
	selectSales(){
		this.checkedSales = true;
		this.checkedContract = false;
		this.showDateContractField   = false;
		if(this.orderObject.RecordType == "AccountOrder" || this.orderObject.RecordType == 'CurrencySale' || this.orderObject.RecordType == 'FutureSale' || this.orderObject.RecordType == 'ZVTR'|| this.orderObject.RecordType == 'ZVTF'|| this.orderObject.RecordType == 'ZVTS') this.showOrderContractField = true;
		this.showBarterContractField = false;
		this.hideConclude			= false;
		this.hideSave				= false;
	}

	async handlePicklistBarterType(event){
		var record				  = {};
		record					  = event?.detail || event?.detail?.value;
		this.orderObject.BarterType = record.record;
		await this.handleGetPaymentFormPicklistValues();
	}

	async handleGetPaymentFormPicklistValues(barterType){
		this.showLoading(true);

		await this.refreshApexGetPaymentFormPicklist();
		if(this.orderObject.BarterType == undefined) this.orderObject.BarterType = null;
		await getPaymentFormPicklist({dependencyFieldKey: 'BarterType__c', dependencyField: 'PaymentForm__c', value: (typeof barterType === 'string' && barterType ? barterType : this.orderObject.BarterType)}).then(data => {
			if(data) {
				this.template.querySelectorAll('c-show-picklist-value').forEach(element => {
					if(element.picklistName == 'paymentFormPickList') element.setPickListOptions(data)});
				if(data.length == 1){
					this.orderObject.PaymentForm = data;
				}
				else if((this.orderObject.RecordType == "IndustryBonification" || this.orderObject.RecordType == "Bonification")){
					this.template.querySelectorAll('c-show-picklist-value').forEach(element => {
						if(element.picklistName == 'paymentFormPickList') element.setPickListOptions('#')});
					this.orderObject.PaymentForm = '#';
				}
				else{
					this.orderObject.PaymentForm = this.orderObject.PaymentForm ? this.orderObject.PaymentForm : null;
				}
			} else {
				swal("O Tipo de Barter Selecionado não está definido para nenhuma forma de pagamento: " + this.orderObject.BarterType ,{ icon: "warning"});
				this.orderObject.BarterType = null
			}
		}).catch(error => {
			swal("Erro: " + JSON.stringify(error.body.message) ,{ icon: "warning"})
		});
		this.showLoading(false);
	}

	async handlePicklistActivitySector(event) {
		var record					  = {};
		record						  = event?.detail || event?.detail?.value;
		this.orderObject.ActivitySector = record.record;
		if(this.orderObject.SalesTeam != null) {
			this.showLoading(true);
			await this.handleGetCPOByAS();
			this.showLoading(false);
		}
	}

	async handleGetCPOByAS() {
		await this.refreshApexGetCustomerPerOrg();
		await getCustomerPerOrg({accountId: this.orderObject.Account.Id, orgId: this.orderObject.SalesTeam.SalesOrg__c, activitySector: this.orderObject.ActivitySector}).then(data => {
			if(data) {
				this.orderObject.CustomerGroup = this.cloneObj(data.CustPerOrgObj.ClientGroup__c);
			} else {
				swal("Não foi encontrado um grupo de clientes para este Setor de Atividade.",{ icon: "warning"}).then((action) => {
					this.orderObject.ActivitySector = null;
					this.showPedidoStep01		   = false;
					this.showPedidoStep01		   = true;
				});
			}
		}).catch(error => {
			swal("Erro: " + JSON.stringify(error.body.message),{ icon: "warning"}).then((action) => {
				this.orderObject.ActivitySector = null;
			 });
		});
	}

	changeDiscountValueInAllProducts() {
		var orderItemList = this.cloneObj(this.orderObject.OrderItem);
		this.orderObject.OrderItem = [];
		for(var i = 0; i < orderItemList.length; i++) { 
			var ordItemObj = {};
			ordItemObj	 = orderItemList[i];
			if(Number(ordItemObj.DiscountValue) != 0) {
				ordItemObj.UnitValue	   = parseFloat(Number(ordItemObj.PriceList).toFixed(2) + Number(ordItemObj.DiscountValue)).toFixed(2);
				ordItemObj.TotalValueItem  = parseFloat(Number(ordItemObj.UnitValue) * Number(ordItemObj.Quantity)).toFixed(2);
				ordItemObj.DiscountPercent = parseFloat(Number(0)).toFixed(3);
				ordItemObj.DiscountPercentWithSixDecimalCases = parseFloat(Number(0)).toFixed(6);
				ordItemObj.DiscountValueWithSevenDecimalCases = parseFloat(Number(0)).toFixed(7);
				ordItemObj.DiscountValue   = parseFloat(Number(0)).toFixed(2);
			}
			if(ordItemObj.FreigthMode == 'CIF') {
				ordItemObj.FreigthMode		= 'FOB';
				ordItemObj.Freigth			= parseFloat(0).toFixed(2);
			}
			this.orderObject.OrderItem.push(this.cloneObj(ordItemObj));
		}
	}

	handleCurrency(event) {
		var value = event.target.value;
		if(value == 'BRL' && this.orderObject.SalesCondition == '02') {
			this.checkedCurrencyReal = false;
			this.checkedCurrencyDol  = true;
			swal(this.toastInfoErrorCurrencyDol.Message ,{ icon: "warning"}).then((action) => {
			});
		} else {
			this.checkedCurrencyReal = value == 'BRL';
			this.checkedCurrencyDol  = value != 'BRL';
			this.orderObject.Currency = value;
		}
	}

	handleFilter(event) {
		this.filtersales = event.target.value;
		this.orderObject.RecordType = null;
		if(this.filtersales == 'Sales')
			this.selectSales();
		else
			this.selectContract();
		this.template.querySelector("c-custom-combo-box-get-record-type").getRecordTypeIds(this.filtersales);
	}

	handleDataValidade(event) {
		var dateToday   = new Date();
		var dateCurrent = new Date(event.target.value);
		dateToday.setUTCHours(0,0,0,0);
		if(dateCurrent.getTime() < dateToday.getTime()) {
			swal(this.toastInfoErrorDatePlusThirty.Message ,{ icon: "warning"}).then((action) => {});
			this.valueDataValidade		  = null;
			this.orderObject.ExpirationDate = null;
		} else {
			this.valueDataValidade		  = event.target.value;
			this.orderObject.ExpirationDate = this.valueDataValidade;
		}
	}

	handleNewRecordCrop(event) {
		var record = {};
		record	 = event?.detail || event?.detail?.value;
		this.orderObject.Crop = record.record == null ? undefined : record.record;
	}

	async handleNewRecordPaymentCondition(event) {
		var record = {};
		record	 = event?.detail || event?.detail?.value;
		if(record.record == null) {
			this.orderObject.PaymentCondition = null;
			if(this.orderObject.RecordType == 'BarterSale' && this.orderObject.BarterType != null){
				await this.handleGetPaymentFormPicklistValues();
			}
			else{
				await this.handleGetPaymentForm(null);
			}
		} else { 
			this.orderObject.PaymentCondition = record.record;
			if(this.orderObject.PaymentCondition != null){
				if(this.orderObject.RecordType == 'BarterSale' && this.orderObject.BarterType != null){
					await this.handleGetPaymentFormPicklistValues();
				}
				else{
					await this.handleGetPaymentForm(record.record.Id);
				}
			}
		}
	}

	async handleGetPaymentForm(idRecord) {
		this.showLoading(true);
		await this.refreshApexGetPaymentFormPicklistValues();
		await getPaymentFormPicklistValues({pcId: this.returnDetailValue(idRecord)}).then(data => {
			if(data) {
				if(data.length < 2){
					this.orderObject.PaymentForm = data;
				}
				this.template.querySelectorAll('c-show-picklist-value').forEach(element => {
					if(element.picklistName == 'paymentFormPickList') element.setPickListOptions(data)});
				}else {
				this.template.querySelectorAll('c-show-picklist-value').forEach(element => {
					if(element.picklistName == 'paymentFormPickList') element.setPickListOptions(null)});
				}
				
				if((this.orderObject.RecordType == "IndustryBonification" || this.orderObject.RecordType == "Bonification")) {
					this.template.querySelectorAll('c-show-picklist-value').forEach(element => {
						if(element.picklistName == 'paymentFormPickList') element.setPickListOptions('#')});
					this.orderObject.PaymentForm = '#';
					this.disabledPaymentForm = true;
				}
				
				this.showLoading(false);

			}).catch(error => {
			swal("Erro: " + JSON.stringify(error.body.message),{ icon: "error"}).then((action) => {this.navigateToView(this.recordId);});
		});
	}

	handlePicklistPaymentForm(event) {
		var record				   = event?.detail || event?.detail?.value;
		this.orderObject.PaymentForm = record.record;
	}

	callHandleDatesEvent(event) {
        if (this.orderObject.RecordType == "BarterSale" ) {
			this.handleBusinessDay(event);
		}
		else{
			this.handleDataVencimento(event);
		}        
    }

	formatDate(strDate) {
			var formatDate = '',
			gmtDate = new Date(strDate),
			utcDate = gmtDate.getUTCDate() < 10 ? ('0' + gmtDate.getUTCDate()) : gmtDate.getUTCDate(),
			utcMonth = (gmtDate.getUTCMonth() + 1) < 10 ? '0' + (gmtDate.getUTCMonth() + 1) : (gmtDate.getUTCMonth() + 1),
			utcYear = gmtDate.getUTCFullYear();
		formatDate = `${utcDate}/${utcMonth}/${utcYear}`;
		return formatDate;	
	}

    async handleBusinessDay(event) {
        let businessDayCheck = new Date(event.target.value);
        this.Dates.DueDate = event.target.value;
        businessDayCheck.setMinutes(businessDayCheck.getMinutes() + businessDayCheck.getTimezoneOffset())
        if (businessDayCheck.getDay() == 0 || businessDayCheck.getDay() == 6) {
            this.Dates.DueDate = event.target.value;
            await swal("A data de pagamento " + this.formatDate(this.Dates.DueDate) + " não é um dia útil. Insira uma data válida", {icon: "warning"}).then((action) => {
                this.Dates.DueDate = undefined;
            });    
            return;
		}
		this.orderObject.DueDate = this.Dates.DueDate;   
	}

    async handleDataVencimento(event) {
		var dateToday   = new Date().setHours(0,0,0,0);
		var dateCurrent = new Date(this.convertDateToCorrectFormatDateToCreate(event.target.value) + ' 00:00:00');
		this.Dates.DueDate = event.target.value;
		if(dateToday > dateCurrent.getTime()) {
			this.Dates.DueDate = event.target.value;
			await swal("Insira uma Data de pagamento maior ou igual a data de hoje.",{ icon: "warning"}).then((action) => {
				this.Dates.DueDate = undefined;
			});
		}
		this.orderObject.DueDate = this.Dates.DueDate;
	}

	async handleInitialContractDate(event) {
		if(event.target.value == null){
			this.orderObject.InitialContractDate = null;
		}
		this.Dates.InitialContractDate = event.target.value;
		this.orderObject.InitialContractDate = this.Dates.InitialContractDate;
		if(this.Dates.EndContractDate == undefined || this.Dates.EndContractDate == null) this.Dates.EndContractDate = this.Dates.InitialContractDate;
		if(this.Dates.InitialContractDate == this.Dates.EndContractDate) this.orderObject.EndContractDate = this.Dates.EndContractDate;
	}

	async handleEndContractDate(event) {
		if(event.target.value == null){
			this.orderObject.EndContractDate = null;
			this.Dates.EndContractDate = null;
		}
		var dateToday	   = new Date().setHours(0,0,0,0);
		var dateCurrent	 = new Date(this.convertDateToCorrectFormatDateToCreate(event.target.value) + ' 00:00:00');
		var initialContractDate = this.orderObject.InitialContractDate != undefined ? this.orderObject.InitialContractDate != null ? new Date(this.convertDateToCorrectFormatDateToCreate(this.orderObject.InitialContractDate)) : null : null;
		if(dateToday <= dateCurrent.getTime() && (initialContractDate == null || initialContractDate.getTime() <= dateCurrent.getTime())) {
			this.Dates.EndContractDate = event.target.value;
		} else {
			this.Dates.EndContractDate = event.target.value;
			if(initialContractDate != null){
				await swal("Data Final do Contrato de Insumos não pode ser menor do que a Data Inicial do Contrato de Insumos: " + initialContractDate + ", nem menor do que a data de hoje. ",{ icon: "warning"}).then((action) => {
					this.Dates.EndContractDate = undefined;
				});
			}
			else{
				await swal("Data Final do Contrato de Insumos não pode ser menor do que a data de hoje.",{ icon: "warning"}).then((action) => {
					this.Dates.EndContractDate = undefined;
				});
			}
		}
		this.orderObject.EndContractDate = this.Dates.EndContractDate;
	}
	handleTextAreaObservacoes(event) {
		this.orderObject.Notes = event.target.value;
	}

	handleFreight(event) {
		var value = event.target.value;

		if(this.orderObject.RecordType != "IndustryBonification" && this.orderObject.RecordType != "Bonification") {
			this.setFreigthValues(value);
		} else {
			swal("Bonificações não possuem frete!",{ icon: "warning"});
		}
	}

	setFreigthValues(value) {
		this.checkedFreightCIF				  = value == 'CIF';
		this.checkedFreightFOB				  = value == 'FOB';
		this.checkedFreightFCA				  = value == 'FCA';
		this.orderItemObject.FreigthMode		= value;
		this.orderItemObject.Freigth			= value == 'CIF' ? this.freigthValue : parseFloat(0).toFixed(2);
		this.orderItemObject.TotalValueItem	 = parseFloat((Number(this.orderItemObject.UnitValueWithSevenDecimalCases) * Number(this.orderItemObject.Quantity)) + Number(this.orderItemObject.Freigth)).toFixed(2);
	}

	isDecimal(num) {
		return (num % 1) !== 0;
	}

	handleChangeQuantityFocusOut(event) {
		var value = parseFloat(event.target.value);
		var isDecimal = this.isDecimal(parseFloat((value/this.orderItemObject.Multiplicity).toFixed(3)));

		if(!isDecimal) {
			if((parseFloat((value).toFixed(3)) > parseFloat((0).toFixed(3)))) {
				this.orderItemObject.Quantity		= parseFloat((value).toFixed(3));
				this.orderItemObject.TotalValueItem  = parseFloat(this.orderItemObject.UnitValueWithSevenDecimalCases * this.orderItemObject.Quantity).toFixed(2);
				this.orderItemObject.DiscountPercent = parseFloat(100 - ((this.orderItemObject.UnitValueWithSevenDecimalCases * 100) / this.orderItemObject.PriceList)).toFixed(3);
				this.orderItemObject.DiscountPercentWithSixDecimalCases = parseFloat(100 - ((this.orderItemObject.UnitValueWithSevenDecimalCases * 100) / this.orderItemObject.PriceList)).toFixed(6);
				this.orderItemObject.DiscountValue   = parseFloat(this.orderItemObject.PriceList - this.orderItemObject.UnitValueWithSevenDecimalCases).toFixed(2);
				this.orderItemObject.DiscountValueWithSevenDecimalCases = parseFloat(this.orderItemObject.PriceList - this.orderItemObject.UnitValueWithSevenDecimalCases).toFixed(7);
				this.setFreigthValueByQuantity();
			} else {
				var oldvalue = parseFloat(JSON.parse(JSON.stringify(this.orderItemObject.Quantity)));
				this.orderItemObject.Quantity = null;
				swal("Quantidade não pode ser menor ou igual 0.",{ icon: "warning"}).then((action) => {this.orderItemObject.Quantity = oldvalue;});
			}
		} else {
			var oldqtd = parseFloat(JSON.parse(JSON.stringify(this.orderItemObject.Quantity)));
			this.orderItemObject.Quantity = null;
			swal("Insira um valor múltiplo de " + this.orderItemObject.Multiplicity,{ icon: "warning"}).then((action) => {this.orderItemObject.Quantity = oldqtd;});
		}
	}

	handleCommitUnitPriceFocusOut(event) {
		var value = event.target.value;
		if(Number(parseFloat(value).toFixed(2)) >= Number(parseFloat(0).toFixed(2))) {
			this.orderItemObject.UnitValue = value;
			this.orderItemObject.UnitValueWithSevenDecimalCases = value;
			this.orderItemObject.TotalValueItem = parseFloat((Number(this.orderItemObject.UnitValueWithSevenDecimalCases) * Number(this.orderItemObject.Quantity)) + Number(this.orderItemObject.Freigth)).toFixed(2);
			if((Number(this.orderItemObject.UnitValueWithSevenDecimalCases) >= Number(this.orderItemObject.PriceList)) == true) {
				this.orderItemObject.DiscountPercent = '0';
				this.orderItemObject.DiscountPercentWithSixDecimalCases = '0';
				this.orderItemObject.DiscountValue = '0';
				this.orderItemObject.DiscountValueWithSevenDecimalCases = '0';
				this.orderItemObject.AdditionPercent = parseFloat(-1*(100 - ((this.orderItemObject.UnitValueWithSevenDecimalCases * 100) / this.orderItemObject.PriceList))).toFixed(3);
				this.orderItemObject.AdditionValue = parseFloat(this.orderItemObject.UnitValueWithSevenDecimalCases - this.orderItemObject.PriceList).toFixed(2);
			} else{
				this.orderItemObject.DiscountPercent = parseFloat(100 - ((this.orderItemObject.UnitValueWithSevenDecimalCases * 100) / this.orderItemObject.PriceList)).toFixed(3);
				this.orderItemObject.DiscountPercentWithSixDecimalCases = parseFloat(100 - ((this.orderItemObject.UnitValueWithSevenDecimalCases * 100) / this.orderItemObject.PriceList)).toFixed(6);
				this.orderItemObject.DiscountValue   = parseFloat(this.orderItemObject.PriceList - this.orderItemObject.UnitValueWithSevenDecimalCases).toFixed(2);
				this.orderItemObject.DiscountValueWithSevenDecimalCases = parseFloat(this.orderItemObject.PriceList - this.orderItemObject.UnitValueWithSevenDecimalCases).toFixed(7);
				this.orderItemObject.AdditionPercent = '0';
				this.orderItemObject.AdditionValue = '0';
			}
		} else {
			var oldvalue									= parseFloat(JSON.parse(JSON.stringify(this.orderItemObject.UnitValue))).toFixed(2);
			this.orderItemObject.UnitValue				  = null;
			this.orderItemObject.UnitValueWithSevenDecimalCases = null;
			swal("Valor Unitário não pode ser menor do que 0. ",{ icon: "warning"}).then((action) => {
				this.orderItemObject.UnitValue				  = oldvalue;
				this.orderItemObject.UnitValueWithSevenDecimalCases = oldvalue;
			});
		}
	}

	handleCommitDiscountPercentFocusOut(event) {
		var value = event.target.value;

		if(parseFloat(this.orderItemObject.AdditionPercent) > 0) {
			var event = {"target": {"value": "0"}};
			this.handleCommitAdditionPercent(event);
		}

		if(Number(parseFloat(value).toFixed(3)) >= Number(parseFloat(0).toFixed(3)) && Number(parseFloat(value).toFixed(3)) <= Number(parseFloat(100).toFixed(3))) {
			this.orderItemObject.DiscountPercent = parseFloat(value).toFixed(3);
			this.orderItemObject.DiscountPercentWithSixDecimalCases = parseFloat(value).toFixed(6);
			this.orderItemObject.UnitValue	   = parseFloat(this.orderItemObject.PriceList - ((this.orderItemObject.DiscountPercent / 100) * this.orderItemObject.PriceList)).toFixed(2);
			this.orderItemObject.UnitValueWithSevenDecimalCases = parseFloat(this.orderItemObject.PriceList - ((this.orderItemObject.DiscountPercent / 100) * this.orderItemObject.PriceList)).toFixed(7);
			this.orderItemObject.TotalValueItem  = parseFloat((Number(this.orderItemObject.UnitValueWithSevenDecimalCases) * Number(this.orderItemObject.Quantity)) + Number(this.orderItemObject.Freigth)).toFixed(2);
			this.orderItemObject.DiscountValue   = parseFloat(this.orderItemObject.PriceList - this.orderItemObject.UnitValueWithSevenDecimalCases).toFixed(2);
			this.orderItemObject.DiscountValueWithSevenDecimalCases = parseFloat(this.orderItemObject.PriceList - this.orderItemObject.UnitValueWithSevenDecimalCases).toFixed(7);
		} else {
			var oldvalue = parseFloat(JSON.parse(JSON.stringify(this.orderItemObject.DiscountPercent))).toFixed(3);
			this.orderItemObject.DiscountPercent = null;
			swal("Percentual de Desconto não pode ser maior do que 100% nem menor que 0%.",{ icon: "warning"}).then((action) => {this.orderItemObject.DiscountPercent = oldvalue;});
		}
	}

	handleCommitDiscountValueFocusOut(event) {
		var value = event.target.value;
		if(parseFloat(this.orderItemObject.AdditionPercent) > 0) {
			var event = {"target": {"value": "0"}};
			this.handleCommitAdditionPercent(event);
		}
		if(Number(parseFloat(value).toFixed(2)) > Number(parseFloat(this.orderItemObject.PriceList).toFixed(2)) || Number(parseFloat(value).toFixed(2)) < Number(parseFloat(0).toFixed(2))) {
			var oldvalue = parseFloat(JSON.parse(JSON.stringify(this.orderItemObject.DiscountValue))).toFixed(2);
			var oldValue7DecimalCases = parseFloat(this.cloneObj(this.orderItemObject.DiscountValueWithSevenDecimalCases));
			this.orderItemObject.DiscountValue = null;
			swal("Valor de Desconto não pode ser maior do que o Preço de Tabela: " + parseFloat(this.orderItemObject.PriceList).toFixed(2) + ", nem menor do que 0. ",{ icon: "warning"}).then((action) => {
				this.orderItemObject.DiscountValue = oldvalue;
				this.this.orderItemObject.DiscountValueWithSevenDecimalCases = oldValue7DecimalCases;
			});
		} else {
			this.orderItemObject.DiscountValue   = value;
			this.orderItemObject.DiscountValueWithSevenDecimalCases = value;
			this.orderItemObject.UnitValue	   = parseFloat(this.orderItemObject.PriceList - this.orderItemObject.DiscountValue).toFixed(2);
			this.orderItemObject.UnitValueWithSevenDecimalCases = parseFloat(this.orderItemObject.PriceList - this.orderItemObject.DiscountValue).toFixed(7);
			this.orderItemObject.DiscountPercent = parseFloat(((100 * this.orderItemObject.DiscountValue) / this.orderItemObject.PriceList)).toFixed(3);
			this.orderItemObject.DiscountPercentWithSixDecimalCases = parseFloat(((100 * this.orderItemObject.DiscountValue) / this.orderItemObject.PriceList)).toFixed(6);
			this.orderItemObject.TotalValueItem  = parseFloat((Number(this.orderItemObject.UnitValueWithSevenDecimalCases) * Number(this.orderItemObject.Quantity)) + Number(this.orderItemObject.Freigth)).toFixed(2);
		}
	}
	async handleOnClickContract(event) {
		var checkIfcontinues = false;
		var record = {};
		record	 = event?.detail || event?.detail?.value;
		await swal("Deseja realmente usar este contrato?",
		{ icon: "warning", buttons: true }).then((action) => {
			if (action) {
				checkIfcontinues = true;
			}
		});
		if(checkIfcontinues){
			this.orderObject.ContractProduct = record.record;
			this.contractId = this.orderObject.ContractProduct.Id;
			this.showLoading(true);
			await getContractInformation({contractId: this.orderObject.ContractProduct.Id}).then(data => {
			this.orderObject.Crop			 = {Id:data.Crop__c, Name: data.Crop__r.Name};
			this.orderObject.ActivitySector   = data.ActivitySector__c;
			this.orderObject.SalesCondition   = data.SalesCondition__c;
			this.orderObject.Rtv			  = {UserId:data.RTV__c, User:{ Name: data.RTV__r.Name}};
			this.orderObject.SalesTeam		= {Id:data.SalesTeam__c, Name: data.SalesTeam__r.Name,ParentId__c: data.SalesTeam__r.ParentId__c ,DistributionCenter__r:{City__c: data.SalesTeam__r.DistributionCenter__r.City__c} };
			
			let today = new Date();
			today.setMonth(today.getMonth() + 1);

			this.valueDataValidade			= data.EndDate;
			this.orderObject.ExpirationDate   = data.EndDate;
			this.orderObject.Currency		 = data.Currency__c;
			//this.orderObject.ShippingAccount  = {Id:data.ShippingAccount__c, Name: data.ShippingAccount__r.Name, InternShippingCity__c: data.ShippingAccount__r.InternShippingCity__c ,InternShippingCity__r: {Id: data.ShippingAccount__r.InternShippingCity__c, Name : data.ShippingAccount__r.InternShippingCity__r.Name} };
			this.orderObject.BillingAccount   = {Id:data.BillingAccount__c, Name: data.BillingAccount__r.Name};
			this.Dates.DueDate				= data.PaymentDate__c;
			this.orderObject.DueDate		  = data.PaymentDate__c;
			this.orderObject.PaymentCondition = {Id:data.PaymentCondition__c, Name: data.PaymentCondition__r.Name};
			
			if(this.orderObject.ContractProduct.RecordType.Name?.includes('Barter')){ 
				this.handleGetPaymentFormPicklistValues(data.BarterType__c); 
			}else{ 
				this.handleGetPaymentForm(this.orderObject.PaymentCondition.Id);
			}
			this.orderObject.PaymentForm	  = data.PaymentForm__c;
			this.showPedidoStep01 = false;
			this.showPedidoStep01 = true;
			if (this.orderObject.Currency == 'BRL') {
				this.checkedCurrencyReal = true;
				this.checkedCurrencyDol  = false;
			} else {
				this.checkedCurrencyReal = false;
				this.checkedCurrencyDol  = true;
			}
			})
			.catch(error => {
			});
			this.disabledCustomLookup	= true;
			this.disabledContract = false;
			this.disabledAllFields	   = true;
			this.disableLastPageProducts = true;
			this.disableConclude		 = true;
			this.disableLastPageEdit	= true;
			this.disabledSalesCondition  = true;
			this.disabledNegotiationType = true;
			this.disabledPaymentForm	 = true;
			this.hiddenCity = true;
			this.showLoading(false);
		}else{
			this.template.querySelector('c-custom-lookup-contracts').setContractNull();
			this.orderObject.ContractProduct = null;
		}

	}

	handleOnClickSomar(event) {
		var isDecimal = this.isDecimal(parseFloat((this.orderItemObject.Quantity/this.orderItemObject.Multiplicity).toFixed(3)));


		if(!isDecimal) {
			this.orderItemObject.Quantity = parseFloat((parseFloat(this.orderItemObject.Quantity) + parseFloat(this.orderItemObject.Multiplicity)).toFixed(3));
		} else {
			swal("Insira um valor múltiplo de " + this.orderItemObject.Multiplicity,{ icon: "warning"});
		}
		this.orderItemObject.TotalValueItem = parseFloat(Number(this.orderItemObject.Quantity) * parseFloat(this.orderItemObject.UnitValueWithSevenDecimalCases)).toFixed(2);

		this.setFreigthValueByQuantity();
	}

	handleOnClickSubtrair(event) {
		var differenceValue = parseFloat((this.orderItemObject.Quantity - this.orderItemObject.Multiplicity).toFixed(3));

		if(differenceValue > 0) {
			this.orderItemObject.Quantity = differenceValue;
		}
		this.orderItemObject.TotalValueItem = parseFloat(Number(this.orderItemObject.Quantity) * parseFloat(this.orderItemObject.UnitValueWithSevenDecimalCases)).toFixed(2);
		this.setFreigthValueByQuantity();
	}

	handleNewRecordCulture(event) {
		var record = event?.detail || event?.detail?.value;
		this.orderItemObject.Culture = record.record != null ? record.record : null;
	}

	async handleFreight(event) {
		var value = event.target.value;
		if(value == 'CIF' && this.checkedFreightFOB && this.orderItemObject.Product2 == null) {
			swal("Você não pode trocar o tipo de frete, pois o seu produto não possui frete!",{ icon: "warning"});
			this.checkedFreightCIF				  = false;
			this.checkedFreightFOB				  = true;
			this.checkedFreightFCA				  = false;
			this.hiddenCity						 = this.orderObject.ShippingAccount.hasOwnProperty("InternShippingCity__c") ? true : false;;
			this.orderItemObject.InternShippingCity = {"Id": this.orderObject.ShippingAccount.InternShippingCity__r.Id, "Name": this.orderObject.ShippingAccount.InternShippingCity__r.Name};
			this.orderItemObject.FreigthMode		= 'FOB';
			this.orderItemObject.TotalValueItem  = parseFloat((Number(this.orderItemObject.UnitValueWithSevenDecimalCases) * Number(this.orderItemObject.Quantity)) + Number(this.orderItemObject.Freigth)).toFixed(2);
		} else if (value == 'CIF' && this.orderItemObject.Product2 != null) {
			if(this.orderItemObject.FreigthMode != 'CIF'){
				this.showLoading(true);
				if(this.orderObject.RecordType != "IndustryBonification" && this.orderObject.RecordType != "Bonification") {
					if(this.orderObject.ShippingAccount.hasOwnProperty("InternShippingCity__c")) {
						await getFreigth({destinationCityId: this.orderObject.ShippingAccount.InternShippingCity__c, sourceCityId: this.orderObject.SalesTeam.DistributionCenter__r.City__c, product2Id: this.orderItemObject.Product2.Id}).then(data => {
							if(data != null) {
								this.orderItemObject = handleFreigth(this.orderItemObject, this.orderObject.Currency, data);
							} else {
								this.orderItemObject.Freigth = parseFloat(0).toFixed(2);
							}
						}).catch(error => {
							swal("Erro: " + JSON.stringify(error.body.message),{ icon: "warning"}).then((action) => {});
						});
					} else {
						this.orderItemObject.Freigth = parseFloat(0).toFixed(2);
					}
					this.orderItemObject.FreigthMode = 'CIF';
				} else {
					this.orderItemObject.TotalValueItem = parseFloat((Number(this.orderItemObject.UnitValueWithSevenDecimalCases) * Number(this.orderItemObject.Quantity)) + Number(this.orderItemObject.Freigth)).toFixed(2);
					this.orderItemObject.Freigth		= parseFloat(0).toFixed(2);
					if(!this.orderItemObject.Product2.RemoveFreightValue__c){
						this.orderItemObject.FreigthMode	= 'CIF';
					} else{
						swal("Bonificações não possuem frete!",{ icon: "warning"});
						this.orderItemObject.FreigthMode	= 'FOB';
					}
				}
				this.orderItemObject.InternShippingCity = this.orderObject.ShippingAccount.hasOwnProperty("InternShippingCity__c") ? {"Id": this.orderObject.ShippingAccount.InternShippingCity__r.Id, "Name": this.orderObject.ShippingAccount.InternShippingCity__r.Name} : null;
				this.showLoading(false);
			}
			this.checkedFreightCIF = true;
			this.checkedFreightFOB = false;
			this.checkedFreightFCA = false;
			this.hiddenCity		= this.orderObject.ShippingAccount.hasOwnProperty("InternShippingCity__c") ? true : false;;
			this.orderItemObject.InternShippingCity = {"Id": this.orderObject.ShippingAccount.InternShippingCity__r.Id, "Name": this.orderObject.ShippingAccount.InternShippingCity__r.Name};
			this.orderItemObject.FreigthMode		= 'CIF';
			this.orderItemObject.TotalValueItem  = parseFloat((Number(this.orderItemObject.UnitValueWithSevenDecimalCases) * Number(this.orderItemObject.Quantity)) + Number(this.orderItemObject.Freigth)).toFixed(2);
		}
		else if (value == 'FOB' && this.orderItemObject.Product2 != null) {
			this.checkedFreightCIF				  = false;
			this.checkedFreightFOB				  = true;
			this.checkedFreightFCA				  = false;
			this.orderItemObject.Freigth			= parseFloat(0).toFixed(2);
			this.orderItemObject.FreigthMode		= 'FOB';
			this.orderItemObject.TotalValueItem	 = parseFloat((Number(this.orderItemObject.UnitValue) * Number(this.orderItemObject.Quantity)) + Number(this.orderItemObject.Freigth)).toFixed(2);
			this.hiddenCity						 = this.orderObject.ShippingAccount.hasOwnProperty("InternShippingCity__c") ? true : false;;
			this.orderItemObject.InternShippingCity = {"Id": this.orderObject.ShippingAccount.InternShippingCity__r.Id, "Name": this.orderObject.ShippingAccount.InternShippingCity__r.Name};
		}
		else if (value == 'FCA' && this.orderItemObject.Product2 != null) {
			this.checkedFreightCIF				  = false;
			this.checkedFreightFOB				  = false;
			this.checkedFreightFCA				  = true;
			this.orderItemObject.Freigth			= parseFloat(0).toFixed(2);
			this.orderItemObject.FreigthMode		= 'FCA';
			this.orderItemObject.TotalValueItem	 = parseFloat((Number(this.orderItemObject.UnitValueWithSevenDecimalCases) * Number(this.orderItemObject.Quantity)) + Number(this.orderItemObject.Freigth)).toFixed(2);
			this.hiddenCity						 = this.orderObject.ShippingAccount.hasOwnProperty("InternShippingCity__c") ? true : false;;
			this.orderItemObject.InternShippingCity = {"Id": this.orderObject.ShippingAccount.InternShippingCity__r.Id, "Name": this.orderObject.ShippingAccount.InternShippingCity__r.Name};
		}
	}

	async handleChangeQuantityShippingDivisionOnFocusOut(event) {
		var isDecimal = this.isDecimal(((parseFloat(event.target.value)/parseFloat(this.orderItemObject.Multiplicity)).toFixed(3)));
		if(isDecimal && Number(this.shippingDivision.Quantity) != Number(0)) {
			var oldvalue = this.shippingDivision.Quantity;
			this.shippingDivision.Quantity = null;
			await swal("Insira um valor múltiplo de " + this.orderItemObject.Multiplicity,{ icon: "warning"}).then((action) => {this.shippingDivision.Quantity = oldvalue;});
		} else {
			this.shippingDivision.Quantity = parseFloat(parseFloat(event.target.value).toFixed(3));
		}
	}

	handleChangeDueDateShippingDivision(event) {
		var dateToday   = new Date().setHours(0,0,0,0);
		var dateCurrent = new Date(this.convertDateToCorrectFormatDateToCreate(event.target.value) + ' 00:00:00');

		if(dateToday <= dateCurrent.getTime()) {
			this.shippingDivision.DueDate = event.target.value;
			this.shippingDivision.DueDateShowBrl = this.convertDateToDateBrlStr(this.shippingDivision.DueDate);
		} else {
			swal("Insira uma data maior ou igual a data de hoje.",{ icon: "warning"}).then((action) => {this.shippingDivision.DueDate = null;});
		}
	}

	convertDateToDateBrlStr(dateStr) {
		var dateList = dateStr.split("-");
		dateList = dateList.reverse();
		var date = dateList.join('/');
		return date;
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
	contractQuantity(product) {
		this.contractProducts = product.detail.product;
	}
	handleHavingContract(record) {
		this.disabledSalesCondition = false;
		this.disabledCustomLookup = false;
		this.disabledContract = false;
		this.disabledAllFields = false;
		this.disableLastPageProducts = false;
		this.disableConclude		 = false;
		this.disableLastPageEdit	= false;
		this.disabledPaymentForm = false;
		this.disabledNegotiationType = false;
		this.productWithContract = record.detail;
		if(this.orderObject.ContractProduct != null && this.orderObject.ContractProduct != undefined){
			this.contractId = this.orderObject.ContractProduct.Id;
		}
		if(!this.productWithContract){
			this.orderObject.ContractProduct = null;
		}
	}

	async handleAddShippingDivision(event) {
		var sum = this.shippingDivision ? parseFloat(this.shippingDivision.Quantity) : 0;

		this.orderItemObject.ShippingDivision.forEach(function(item) {sum += parseFloat(item.SD.Quantity);});

		if(this.shippingDivision.Quantity == null || this.shippingDivision.DueDate == null || this.shippingDivision.Quantity == undefined || this.shippingDivision.DueDate == undefined) {
			swal("Quantidade ou Data de Entrega vazios",{ icon: "warning"});
		} else {
			if(parseFloat((sum).toFixed(3)) < parseFloat(this.orderItemObject.Quantity)) {
				if(!this.checkContainsDueDateShippingDivision(this.cloneObj(this.shippingDivision))) {
					this.addShippingDivision(this.cloneObj(this.shippingDivision));
					this.shippingDivision.DueDate  = null;
				}
				this.setShippinngDivisonQuantity();
			} else if(parseFloat((sum).toFixed(3)) == parseFloat(this.orderItemObject.Quantity)) {
				if(!this.checkContainsDueDateShippingDivision(this.cloneObj(this.shippingDivision))) {
					this.addShippingDivision(this.cloneObj(this.shippingDivision));
					this.shippingDivision.Quantity = null;
					this.shippingDivision.DueDate  = null;
				}
				this.hiddenShippingDivision = false;
				let orderItems =[];
				orderItems.push(this.orderItemObject);
				this.authArray = [];
				await findAuth(orderItems, this).then((action) => {		 
					var showMessage =false;
					if ('familyMargin' in this.orderItemObject &&
						'projectedMargin' in this.orderItemObject &&
						parseFloat(this.orderItemObject.familyMargin)
						<parseFloat(this.orderItemObject.projectedMargin)){
							showMessage =true;
					}
					// if ('familyMargin' in this.orderItemObject ==false ||
					//	 this.orderItemObject.familyMargin ==null){
					//		 showMessage =true;
					//	 }
					//Inactive Margin
					/*if (showMessage){
							var evt =new ShowToastEvent({
								title: 'Atenção',
								message: 'Margem em risco nessa negociação. Pedido será aprovado pelo Diretor de Cluster.',
								variant: 'warning',
								});
							this.dispatchEvent(evt);				
						}	 */
				});
			} else {
				var quantityExc = parseFloat((parseFloat(this.shippingDivision.Quantity) - parseFloat(this.orderItemObject.Quantity)).toFixed(3));
				swal("A quantidade da remessa não deve ser maior que a vendida. Quantidade Excedida: " + parseFloat(quantityExc) ,{ icon: "warning"});
			}
		}


	}

	setShippinngDivisonQuantity() {
		var sum = 0;
		this.orderItemObject.ShippingDivision.forEach(function(item) {sum += parseFloat(item.SD.Quantity);});
		this.shippingDivision.Quantity = parseFloat((this.orderItemObject.Quantity - sum).toFixed(3));
	}

	addShippingDivision(value) {
		if(this.orderItemObject.ShippingDivision.length != 0) {
			var maxNumberId = Math.max.apply(Math, this.orderItemObject.ShippingDivision.map(function(item) { return item.Iterator; }));
			this.orderItemObject.ShippingDivision.push({"Iterator": maxNumberId + 1, "SD": value});
		} else {
			this.orderItemObject.ShippingDivision.push({"Iterator": Number(this.orderItemObject.ShippingDivision.length + 1), "SD": value});
		}
	}
		
	checkContainsDueDateShippingDivision(value) {
		var boolean		   = false;
		var shippingDivEquals = this.orderItemObject.ShippingDivision.find(element => element.SD.DueDate == value.DueDate);
		if(shippingDivEquals != undefined && shippingDivEquals != null) {
			boolean = true;
			shippingDivEquals.SD.Quantity = parseFloat((parseFloat(shippingDivEquals.SD.Quantity) + parseFloat(value.Quantity)).toFixed(3));
			this.orderItemObject.ShippingDivision  = this.orderItemObject.ShippingDivision.filter(element => element.SD.DueDate != value.DueDate);
			this.orderItemObject.ShippingDivision.push(shippingDivEquals);
			this.showPedidoStep2b		  = false;
			this.showPedidoStep2b		  = true;
			this.shippingDivision.Quantity = null;
			this.shippingDivision.DueDate  = null;
		}
		return boolean;
	}

	handleClickButtonShippingDivision(event) {
		var value = event.currentTarget.dataset.index;
		this.orderItemObject.ShippingDivision = this.orderItemObject.ShippingDivision.filter(element => element.Iterator != value);
		this.showPedidoStep2b = false;
		this.showPedidoStep2b = true;
		var sum = 0;
		this.orderItemObject.ShippingDivision.forEach(function(item) {sum += parseFloat(parseFloat(item.SD.Quantity).toFixed(3));});
		if(parseFloat((sum).toFixed(3)) != this.orderItemObject.Quantity) {
			this.hiddenShippingDivision	= true;
			this.shippingDivision.Quantity = parseFloat((parseFloat(this.orderItemObject.Quantity) - parseFloat((sum).toFixed(3))).toFixed(3));
		} else {
			this.shippingDivision.Quantity = parseFloat(this.orderItemObject.Quantity);
		}
	}

	showScreen(value){
		this.showPedidoStep01 = this.returnDetailValue(value) == "Step01";
		this.showPedidoStep2a = this.returnDetailValue(value) == "Step2a";
		this.showPedidoStep2b = this.returnDetailValue(value) == "Step2b";
		this.showPedidoStep03 = this.returnDetailValue(value) == "Step03";
		this.showBarterStepA  = this.returnDetailValue(value) == "StepA" ;
		this.showBarterStepB  = this.returnDetailValue(value) == "StepB" ;
		// this.showScreenCheckout = this.returnDetailValue(value) == "StepCheckoutBarter";
	}

	async onClickShowPedidoStep1(event) {
		var t = this;
		if (t.orderObject.OrderItem.length > 0) {
			t.disabledCustomLookup = true;
			t.disabledContract =  true;
			t.disabledSalesCondition = true;
			t.disabledPaymentForm = false;
			t.disabledAllFields = false;
			t.disabledNegotiationType = true;
			t.disabledBarterFields = false;
		}
		if(t.orderObject.RecordType == "IndustryBonification" || t.orderObject.RecordType == "Bonification"){
			t.disabledSalesCondition = true;
			t.disabledPaymentForm = true;
		}
		if ((t.orderItemObject.Product2 != null || t.orderItemObject.Product2 != undefined) && (t.itemContext == '_isNew_' || t.itemContext == '_isEdit_' || t.disabledAllFields == false)) {
			swal("Deseja descartar as alterações do item?", { icon: "warning", buttons: true }).then((action) => {
			if (action) {
				t.itemContext = '_isNew_';
				if(t.orderObject.RecordType == 'BarterSale') t.handleGetPaymentFormPicklistValues();
				t.showScreen("Step01");
				}
			});
		} else{
			if(t.orderObject.RecordType == 'BarterSale') t.handleGetPaymentFormPicklistValues();
			t.showScreen("Step01");
		}

		await t.refreshApexGetCustomerPerOrg();

		await getCustomerPerOrg({accountId: t.orderObject.Account.Id, orgId: t.orderObject.SalesTeam.SalesOrg__c, activitySector: null}).then(data => {
			if(data) {
				if(data.HaveSector == true) {
					t.template.querySelectorAll('c-show-picklist-value').forEach(element => {
						if(element.picklistName == 'activitySectorPickList') element.setPickListOptions(data.ActivitySectorList)});
					}
			}
		}).catch(error => {
			swal("Erro: " + JSON.stringify(error.body.message) ,{ icon: "warning"}).then((action) => {
				t.orderObject.SalesTeam	 = null;
				t.hiddenSalesSector1		= false;
				t.orderObject.CustomerGroup = null;
			});
		});

		window.scrollTo(0, 0);
	}

	returnDetailValue(value) {
		if(value && this.cloneObj(value).hasOwnProperty("detail")) {
			return value.detail;
		} else {
			return value;
		}
	}
	
	async clickShowStepByPriceCar(value) {
		if (this.isRefuseReason) {
			this.disabledCustomLookup = true;
			this.disabledSalesCondition = true;
			this.disabledPaymentForm = true;
		}

		if(this.orderObject.OrderItem.length > 0){
			this.disabledCustomLookup = true;
			this.disabledContract =  true;
			this.disabledSalesCondition = true;
			this.disabledPaymentForm = false;
			this.disabledAllFields = false;
			this.disabledNegotiationType = true;
			this.disabledBarterFields = false;
		} else {
			this.disabledCustomLookup = false;
			this.disabledContract =  false;
			this.disabledSalesCondition = false;
			this.disabledPaymentForm = false;
			this.disabledAllFields = false;
			this.disabledNegotiationType = false;
			this.disabledBarterFields = false;
		}

		//if ((this.orderObject.Status == 'Em digitação' || this.orderObject.Status == 'Recusado' || this.orderObject.Status == 'Retorna RTV') && !this.isRefuseReason) {
		//	if(!(this.orderObject.DeletedProductProcessSap == true && this.orderObject.Status == 'Retorna RTV')){
		//		this.disabledCustomLookup = false;
		//		this.disabledSalesCondition = false;
		//		this.disabledNegotiationType = false;
		//		this.disabledPaymentForm = false;
		//		this.disabled
		//		if(this.orderObject.OrderContractObj != null){
		//			this.disabledContract = true;
		//		}
		//		else{
		//			this.disabledContract = false;
		//		}
		//		this.disabledSalesCondition = false;
		//	}
		//}

		/*if ((this.orderObject.Status == 'Em digitação' || this.orderObject.Status == 'Recusado' || this.orderObject.Status == 'Retorna RTV') && !this.isRefuseReason) {
			if(!(this.orderObject.DeletedProductProcessSap == true && this.orderObject.Status == 'Retorna RTV')){
				this.disabledCustomLookup = false;
				this.disabledSalesCondition = false;
				this.disabledNegotiationType = false;
				this.disabledPaymentForm = false;
				this.disabled
				if(this.orderObject.OrderContractObj != null){
					this.disabledContract = true;
				}
				else{
					this.disabledContract = false;
				}
				this.disabledSalesCondition = false;
			}
		}*/
	}

	onClickShowPedidoStep1ByPriceCar(event) {
		if (this.isRefuseReason) {
			this.disabledCustomLookup = true;
			this.disabledSalesCondition = true;
			this.disabledPaymentForm = true;
		}

		if(this.orderObject.OrderItem.length > 0){
			this.disabledCustomLookup = true;
			this.disabledContract =  true;
			this.disabledSalesCondition = true;
			this.disabledPaymentForm = false;
			this.disabledAllFields = false;
			this.disabledNegotiationType = false;
			this.disabledBarterFields = false;
		} else {
			this.disabledCustomLookup = false;
			this.disabledContract =  false;
			this.disabledSalesCondition = false;
			this.disabledPaymentForm = false;
			this.disabledAllFields = false;
			this.disabledNegotiationType = false;
			this.disabledBarterFields = false;
		}

		//if ((this.orderObject.Status == 'Em digitação' || this.orderObject.Status == 'Recusado' || this.orderObject.Status == 'Retorna RTV' || this.orderObject.DeletedProductProcessSap == true) && !this.isRefuseReason) {
		//	this.disabledCustomLookup = false;
		//	this.disabledSalesCondition = false;
		//	this.disabledNegotiationType = false;
		//	this.disabledPaymentForm = false;
		//	this.disabled
		//	if(this.orderObject.OrderContractObj != null){
		//		this.disabledContract = true;
		//	}
		//	else{
		//		this.disabledContract = false;
		//	}
		//	this.disabledSalesCondition = false;
		//}
	}

	async onClickShowPedidoStep2a(event) {
		var dateToday   = new Date().setHours(0,0,0,0);
		var endContractDate = this.orderObject.EndContractDate != undefined ? this.orderObject.EndContractDate != null ? new Date(this.convertDateToCorrectFormatDateToCreate(this.orderObject.EndContractDate)) : null : null;
		if(this.HasErrorDate) {
			if(this.clientDebtNegativeMessage)
				swal('Este cliente está com a data de certidão negativa vencida' ,{ icon: "warning"});
		} 
		if(this.checkAllFields(this.orderObject)) {
			if (this.showDateContractField && (this.Dates.InitialContractDate == null || this.Dates.InitialContractDate == undefined || this.Dates.EndContractDate == null || this.Dates.EndContractDate == undefined )) {
				swal("Para prosseguir preencha  o campo obrigatório: Janela do Contrato de Insumos.",{ icon: "warning"});
			}else{
				if (this.showDateContractField && (this.Dates.InitialContractDate == this.Dates.EndContractDate)) {
					swal("Para prosseguir a data inicial deve ser diferente da data final na Janela do Contrato de Insumos.",{ icon: "warning"});
				}  else{
					if (this.showDateContractField) var dateCurrent = new Date(this.convertDateToCorrectFormatDateToCreate(this.Dates.InitialContractDate) + ' 00:00:00');
					if (this.showDateContractField && (this.Dates.InitialContractDate > this.Dates.EndContractDate)) {
						swal("Data Inicial do Contrato de Insumos não pode ser maior do que a Data Final do Contrato de Insumos: " + endContractDate + ", nem menor do que a data de hoje. ",{ icon: "warning"});
					}  else{
						if (this.showDateContractField && (dateToday > dateCurrent.getTime())) {
							swal("Data Inicial do Contrato de Insumos não pode ser menor do que a data de hoje.",{ icon: "warning"})
						}  else{
							if (this.orderObject.RecordType == "ZVTR" && this.productWithContract == false) {
								swal("Não é possível realizar uma Venda Barter, sem antes selecionar um Contrato de Negociação Barter.",{ icon: "warning"});
							}else{
								if(this.orderObject.OrderItem.length == 0){
									this.axOrd["Rtv"]			  = this.orderObject["Rtv"];
									this.axOrd["Account"]		  = this.orderObject["Account"];
									this.axOrd["ShippingAccount"]  = this.orderObject["ShippingAccount"];
									this.axOrd["SalesCondition"]   = this.orderObject["SalesCondition"];
									this.axOrd["Currency"]		 = this.orderObject["Currency"];
									this.axOrd["DueDate"]		  = this.orderObject["DueDate"];
									this.axOrd["Crop"]			 = this.orderObject["Crop"];
									this.axOrd["SalesTeam"]		= this.orderObject["SalesTeam"]; 
									this.axOrd["ActivitySector"]   = this.orderObject["ActivitySector"];

									this.itemContext = '_isNew_';

									if (this.isRefuseReason) {
										this.showScreen("Step03");
									} else {
										this.showScreen("Step2a");
									}
								} else {
									if(this.orderObject["Account"].Id != this.axOrd["Account"].Id ||
										this.orderObject["ShippingAccount"].Id != this.axOrd["ShippingAccount"].Id ||
										this.orderObject["Rtv"].Id != this.axOrd["Rtv"].Id ||
										this.orderObject["SalesTeam"].Id != this.axOrd["SalesTeam"].Id ||
										this.orderObject["SalesCondition"] != this.axOrd["SalesCondition"] ||
										this.orderObject["ActivitySector"] != this.axOrd["ActivitySector"] ||
										this.orderObject["Currency"] != this.axOrd["Currency"] ||
										this.orderObject["Crop"].Id != this.axOrd["Crop"].Id ||
										this.orderObject["DueDate"] != this.axOrd["DueDate"]) {
										swal("A edição poderá alterar os valores dos itens no carrinho. Deseja prosseguir?", { icon: "warning", buttons: true }).then((action) => {
											if (action) {
												this.simulateNewDataEdit();
											}
										});
									}
									else {
										this.showLoading(true);
										this.showPedidoStep03 = false;
										this.authArray = [];
										await findAuth(this.orderObject.OrderItem, this);
										var callCampaignCalc = false;
										this.orderObject.OrderItem.forEach(function(ordItem) {
											if (ordItem.Campaign.length > 0) {
												callCampaignCalc = true;
											}
										});
										if (callCampaignCalc)
											await this.getAvailableCampaign();
										if(this.checkAllInventory)
											await this.checkInventoryAll();
										this.showPedidoStep03 = true;
										this.normalizeOrderItemList();
										this.showLoading(false);
										this.showScreen("Step03");
									}
								}
								this.setLabelCurrency();
							}   
						}
					}
				} 
			}
		}else {
			this.checkEachField();
		}
		window.scrollTo(0, 0);
	}

	async simulateNewDataEdit(){
		this.simulationCount = 0;
		this.showLoading(true);
		this.priceListData = {
		"customerGroup": this.orderObject.CustomerGroup,
		"activitySector": this.orderObject.ActivitySector,
		"accountId": this.orderObject.Account.Id,
		"salesTeamId": this.orderObject.SalesTeam.Id,
		"cropId": this.orderObject.Crop.Id,
		"salesCondition": this.orderObject.SalesCondition,
		"currencys": this.orderObject.Currency};
		var orderObjectVar = this.orderObject;
		
		await getListPriceData({priceDatas: JSON.stringify(this.priceListData)}).then(data => {
			if(data) {
				this.priceData   = this.cloneObj(data.priceData);
				var x = null;
				x = this;
				this.idsProducts = Object.keys(this.priceData);
				var idsProductsVar = this.idsProducts;
				var priceDataVar = this.priceData;
				this.orderObject.OrderItem.forEach(function (ordItem){
					ordItem.InternShippingCity = {"Id": x.orderObject.ShippingAccount.InternShippingCity__r.Id, "Name": x.orderObject.ShippingAccount.InternShippingCity__r.Name};
					ordItem.ShowDetails = true;
					if(idsProductsVar.includes(ordItem.Product2.Id)){
						ordItem.invalidProduct = false;
						ordItem.invalidListPrice = false;
						ordItem.BorderColor = 'card card-lista-pedido border-primary';
						if(x.priceData[ordItem.Product2.Id].Id != ordItem.ListPrice.Id){
							ordItem.DiscountPercent = 0;
							ordItem.AdditionPercent = 0;
							ordItem.AdditionValue = 0;
							ordItem.DiscountValue = 0;
							if(priceDataVar[ordItem.Product2.Id].Id != ordItem.ListPrice.Id){
								ordItem.ListPrice = priceDataVar[ordItem.Product2.Id];
								ordItem.PriceListWithoutInterest = priceDataVar[ordItem.Product2.Id].UnitPrice; 
								ordItem.InterestListValue = 0;
							}
						}

						var paymentDate		= new Date(orderObjectVar.DueDate);
						var effectiveDate	  = new Date(ordItem.ListPrice.EffectiveDate);
						var listPriceTypeVar;
						var Difference_In_Time = 0;
						var valueDatesBetween = 0;

						if(paymentDate.getTime() < effectiveDate.getTime()) {
							Difference_In_Time = Number(effectiveDate.getTime() - paymentDate.getTime());
							valueDatesBetween = Number(Difference_In_Time / (1000 * 3600 * 24));
						}
						else if(paymentDate.getTime() > effectiveDate.getTime()) {
							Difference_In_Time = Number(paymentDate.getTime() - effectiveDate.getTime());
							valueDatesBetween = Number(Difference_In_Time / (1000 * 3600 * 24));
						} else if(paymentDate.getTime() == effectiveDate.getTime()) {
							valueDatesBetween = 0;
						}

						var totalMonths = parseFloat(valueDatesBetween/30).toFixed(2);

						if(paymentDate.getTime() < effectiveDate.getTime()) {
							listPriceTypeVar = 'ZDJ1';
						}
						else if(paymentDate.getTime() > effectiveDate.getTime()) {
							listPriceTypeVar = 'ZJ01';
						} else {
							listPriceTypeVar ='ZJ01';
						}

						var interestListData = {
							"productFamilyId": ordItem.Product2.Family__r.Id,
							"productId": ordItem.Product2.Id,
							"salesTeamId": orderObjectVar.SalesTeam.Id,
							"cropId": orderObjectVar.Crop.Id, 
							"salesCondition": orderObjectVar.SalesCondition, 
							"listPriceType": listPriceTypeVar
						};

						interestListData = JSON.stringify(x.cloneObj(interestListData));
						getInterestListData({priceData: interestListData}).then(data => {
							if(data && x.orderObject.RecordType != "IndustryBonification" && x.orderObject.RecordType != "Bonification") {
								ordItem.InterestList = x.cloneObj(data);
								if(listPriceTypeVar == 'ZDJ1'){
									if(parseFloat(totalMonths) > 12){
										totalMonths = 12;
									}
									ordItem = handleDiscount(ordItem, totalMonths);
								}
								else{
									ordItem = handleAddition(ordItem, totalMonths);
								}
							} else {
								if(x.orderObject.RecordType == "IndustryBonification" || x.orderObject.RecordType == "Bonification"){
									ordItem.DiscountPercent = 0;
									ordItem.AdditionPercent = 0;
								}
								ordItem.InterestList = null;
								ordItem.InterestListValue = 0;
								ordItem.UnitValue = ordItem.PriceListWithoutInterest;
								ordItem.TotalValueItem = ordItem.UnitValue * ordItem.Quantity;
							}
							if(ordItem.FreigthMode == 'CIF'){
								getFreigth({destinationCityId: orderObjectVar.ShippingAccount.InternShippingCity__c, sourceCityId: orderObjectVar.SalesTeam.DistributionCenter__r.City__c, product2Id: ordItem.Product2.Id}).then(data => {
									if(orderObjectVar.RecordType != "IndustryBonification" && orderObjectVar.RecordType != "Bonification"){
										if(data){
											ordItem.FreigthData = data;
											if(ordItem.Product2.RemoveFreightValue__c){
												ordItem.FreigthMode = 'CIF';
												ordItem.Freigth = 0;
											}
											else{
												ordItem.FreigthMode = 'CIF';
												ordItem.Freigth = orderObjectVar.Currency == 'USD' ? data.ValuePerTonDolar__c : data.ValuePerTon__c;
												if(ordItem.Product2.GrossWeightUnity__c == 'KG') {
													ordItem.Freigth = parseFloat((Number(ordItem.Product2.GrossWeight__c) * Number(ordItem.Quantity) * Number(ordItem.Freigth)) / 1000).toFixed(2);
												} else if (ordItem.Product2.GrossWeightUnity__c == 'TO') {
													ordItem.Freigth = parseFloat(Number(ordItem.Product2.GrossWeight__c) * Number(ordItem.Quantity) * Number(ordItem.Freigth)).toFixed(2);
												} else if (ordItem.Product2.GrossWeightUnity__c == 'L') {
													ordItem.Freigth = parseFloat((Number(ordItem.Product2.GrossWeight__c) * Number(ordItem.Quantity) * Number(ordItem.Freigth)) / 1000).toFixed(2);
												}
												ordItem.TotalValueItem = parseFloat(ordItem.TotalValueItem) + parseFloat(ordItem.Freigth);

											}
										}
										else{
											ordItem.FreigthMode = 'FOB';
											ordItem.Freigth = 0;
										}
									}
									else{
										ordItem.FreigthMode = 'FOB';
										ordItem.Freigth = 0;
									}
									x.finishSimulateOrder();
								})	  
							}
							else {
								x.finishSimulateOrder();
							}
						}).catch(error => {
							ordItem.InterestList = null;
						});
					}
					else{
						ordItem.DiscountPercent = 0;
						ordItem.ShowDetails = false;
						ordItem.invalidProduct = true;
						x.finishSimulateOrder();
						ordItem.BorderColor = 'card card-lista-pedido border-danger';
					}
				});
			} else {
				this.orderObject.OrderItem.forEach(function (ordItem){
					ordItem.invalidListPrice = true;
					ordItem.ShowDetails = false;
					x.finishSimulateOrder();
					ordItem.BorderColor = 'card card-lista-pedido border-danger';
				});
			}
		}).catch(error => {
			this.showLoading(false);
			if(error != null){
				swal("Erro: " + JSON.stringify(error.body.message),{ icon: "warning"}).then((action) => {});
			}
		});
	}

	async finishSimulateOrder(){
		this.simulationCount++;
		this.showPedidoStep03 = false;
		if(this.simulationCount == this.orderObject.OrderItem.length){
			this.axOrd = fillAxOrd(this.axOrd, this.orderObject);
			var totalPrice = this.orderObject.OrderItem.reduce((sum, item) => Number(sum) + Number(item.TotalValueItem), 0);
			this.orderObject.TotalPriceOrder = parseFloat(totalPrice).toFixed(2);
			this.authArray = [];
			await findAuth(this.orderObject.OrderItem, this);
			await this.getAvailableCampaign();
			this.showPedidoStep03 = true;
			this.normalizeOrderItemList();
			if(this.checkAllInventory){
				await this.checkInventoryAll();
			}
			this.showLoading(false);
			this.showScreen("Step03");
		}

	}

	normalizeOrderItemList(){
		let orderItemMap = {};
		this.orderObject.OrderItem.forEach(function(item){
			orderItemMap[item.Product2.Id] = item;
		}, {orderItemMap});
		this.orderObject.OrderItem = Object.values(orderItemMap);
	}

	setLabelInterest(value) {
		if(value.RecordType.DeveloperName == 'ZDJ1') {
			this.orderItemObject.InterestListValueName = 'Desconto de Antecipação (Unitário)';
		} else {
			this.orderItemObject.InterestListValueName = 'Juros Unitário';
		}
	}

	setLabelCurrency() {
		if (this.orderObject.Currency == 'BRL') {
			this.currencyScreen = 'R$';
			this.currencyScreenFormat = 'BRL';
		} else {
			this.currencyScreen = 'US$';
			this.currencyScreenFormat = 'USD';
		}
	}

	checkEachField() {
		var msg = 'Para prosseguir preencha o campo obrigatório: ';
		if (this.orderObject.Account == null) {
			swal( msg+"Cliente.",{ icon: "warning"});
		} else if (this.orderObject.ShippingAccount == null) {
			swal( msg+"Cliente cobrança.",{ icon: "warning"});
		} else if (this.orderObject.BillingAccount == null) {
			swal( msg+"Cliente entrega.",{ icon: "warning"});
		}  else if (this.orderObject.Rtv == null) {
			swal( msg+"RTV.",{ icon: "warning"});
		} else if (this.orderObject.SalesTeam == null) {
			swal( msg+"Equipe de vendas.",{ icon: "warning"});
		} else if (this.orderObject.SalesCondition == null) {
			swal( msg+"Condição de venda.",{ icon: "warning"});
		} else if (this.orderObject.RecordType == null) {
			swal( msg+"Tipo de negociação.",{ icon: "warning"});
		} else if (this.orderObject.Currency == null) {
			swal("Para prosseguir escolha um tipo de moeda.",{ icon: "warning"});
		} else if (this.orderObject.ExpirationDate == null) {
			swal( msg+"Data de validade.",{ icon: "warning"});
		} else if (this.orderObject.Crop == null) {
			swal( msg+"Safra.",{ icon: "warning"});
		} else if (this.orderObject.PaymentCondition == null) {
			swal( msg+"Condição de Pagamento.",{ icon: "warning"});
		} else if (this.orderObject.PaymentForm == null) {
			swal( msg+"Forma de pagamento.",{ icon: "warning"});
		} else if (this.orderObject.DueDate == null) {
			swal( msg+"Data de Pagamento.",{ icon: "warning"});
		}else if (this.orderObject.ActivitySector == null) {
			swal( msg+"Setor de Atividade.",{ icon: "warning"});
		}
	}

	onClickShowPedidoStep2aDivisao(event) {
		// this.itemContext	  = '_isReturn_';
		this.checkAllInventory = true;
		this.showScreen("Step2a");
		window.scrollTo(0, 0);
	}

	onClickShowPedidoStep2aByCarScreen() {
		this.itemContext = '_isNew_';
		this.checkAllInventory = true;
		this.disabledProduct2 = false;
	}

	onClickShowPedidoStep2aByCarScreenEdit(value) {
		this.productId		= this.returnDetailValue(value);
		this.checkAllInventory = true;
		this.itemContext	  = '_isEdit_';
		this.orderItemObject  = this.orderObject.OrderItem.find(element => element.Product2.Id == this.productId);
	}

	onClickShowPedidoStep2aByCarScreenView(value) {
		this.productId		= this.returnDetailValue(value);
		this.itemContext	  = '_isView_';
		this.orderItemObject  = this.orderObject.OrderItem.find(element => element.Product2.Id == this.productId);
	}

	onClickShowPedidoStep2aByCarScreenExclude(event) {
		var value = event.currentTarget.dataset.productId;
		swal("Deseja realmente excluir este produto?",
		{ icon: "warning", buttons: true }).then((action) => {
			if (action) {
				this.deleteProduct(value);
			}
		});
	}

	 onClickShowPedidoStep2aByCarScreenExcludeBarter(event){
		 var value = event.currentTarget.dataset.productId;
		 swal("Deseja realmente excluir este produto?",
		 { icon: "warning", buttons: true }).then((action) => {
			 if (action) {
				 this.deleteProductConcludeBarter(value);
			 }
		 });
	 }

	deleteProduct(value) {
		var t = this;
		t.orderObject.OrderItem = t.orderObject.OrderItem.filter(element => element.Product2.Id != value.detail);
		t.authArray = [];
		findAuth(t.orderObject.OrderItem, this);
		var containCampaign = t.orderObject.OrderItem.filter(element => element.Campaign.length > 0);
		if (containCampaign.length > 0) {
			this.getAvailableCampaign();
			validateAccumulativeAndIndustryCampaign(this);
		}
		t.returnTotalValue();
		t.showPedidoStep03	  = false;
		t.showPedidoStep03	  = true;
		window.scrollTo(0, 0);
	}

	deleteProductConcludeBarter(value){
		var t = this;
		t.orderObject.OrderItem = t.orderObject.OrderItem.filter(element => element.Product2.Id != value.detail);
		t.authArray = [];
		findAuth(t.orderObject.OrderItem, this);
		var containCampaign = t.orderObject.OrderItem.filter(element => element.Campaign.length > 0);
		if (containCampaign.length > 0) {
			this.getAvailableCampaign();
			validateAccumulativeAndIndustryCampaign(this);
		}
		t.returnTotalValue();
		t.showBarterStepB	  = false;
		t.showBarterStepB	  = true;
		window.scrollTo(0, 0);
	}

	async onClickShowPedidoStep2b(event) {
		this.showLoading(true);
		var orderItem = this.template.querySelector('c-order-item-screen').getOrderItemObject();
		var productContractQuantity = this.contractProducts != null ? this.contractProducts[orderItem.Product2.Id] : 90000;
		this.orderItemObject = JSON.parse(JSON.stringify(orderItem))
		if(this.checkAllInventory && (this.orderItemObject.ShippingDivision.length == 0 || this.orderItemObject.ShippingDivision == null)){
			await this.checkInventoryUnit();
		}
		if(this.orderItemObject.DiscountPercent != 0 && this.orderItemObject.AdditionPercent == 0){
			this.orderItemObject.IsDiscount = true;
		}
		else{
			this.orderItemObject.IsDiscount = false;
		}
		this.freigthValue = this.orderItemObject.Freigth;
		if(this.freigthValue != 0){
		this.orderItemObject.calculatedFreigth = this.freigthValue;
		}
		this.setFreigthValues(this.orderItemObject.FreigthMode);
		this.hiddenCity = this.orderItemObject.InternShippingCity != undefined;
		if(this.itemContext == '_isEdit_'){
			this.orderObject.OrderItem = this.orderObject.OrderItem.filter(element => element.Product2.Id != this.productId);
			if(this.orderItemObject.Product2.Id != this.productId || this.orderItemObject.ShippingDivision.length == 0){
				this.nullShippingDivisionObject();
			}
		}else if(this.itemContext == '_isNew_'){
			this.itemContext = '_isEdit_'
			this.nullShippingDivisionObject();
		}
		if(this.checkAllFieldsProduct(this.orderItemObject)) {
			if(this.orderObject.OrderItem.find(element => element.Product2.Id == this.orderItemObject.Product2.Id) && (this.disabledAllFields == false || this.productWithContract)) {
				swal("Já existe um item no carrinho com o mesmo produto selecionado.",{ icon: "warning"});
			} else {
				if(this.isDecimal(parseFloat(Number((this.orderItemObject.Quantity))/Number(this.orderItemObject.Multiplicity)).toFixed(3))) {
					swal("Você só pode inserir um valor múltiplo de " + this.orderItemObject.Multiplicity,{ icon: "warning"});
				} else {
					if(this.contractProducts != null && this.productWithContract && Number(this.orderItemObject.Quantity) > productContractQuantity){
						swal("A quantidade máxima disponível para este produto para o contrato selecionado é de: "+productContractQuantity,{ icon: "warning"});
					}else{
						if(this.containInventoryError){
							var message = StockAlert;
							message = message.replaceAll('\\n', '\n');
							message = message.replaceAll('{stock}', this.orderItemObject.stockQuantity + ' ' + this.orderItemObject.QuantityUnitOfMeasure)
							swal(message,
							{ icon: "warning" }).then(() => {
								if(this.containInventoryError){
									this.checkAllInventory = true;
									return;
								} else {
									this.showScreen("Step2b");
								}
							});
						} else {
							this.showScreen("Step2b");
						}

						if(this.orderItemObject.ShippingDivision.length > 0) {
							var totalQuantity = this.orderItemObject.ShippingDivision.reduce((sum, item) => Number(sum) + Number(item.SD.Quantity), 0);
							this.shippingDivision.Quantity = Number(this.orderItemObject.Quantity) - Number(totalQuantity);
							if(Number(totalQuantity) == Number(this.orderItemObject.Quantity)) {
								this.hiddenShippingDivision = false;
							} else {
								this.hiddenShippingDivision = true;
							}
						} else {
							this.hiddenShippingDivision = true;
							this.shippingDivision.Quantity = Number(this.orderItemObject.Quantity);
						}
						this.setShippingDivisionByChange();
					}
				}
			}
		} else {
			swal("Para prosseguir preencha todos os campos obrigatórios.",{ icon: "warning"});
		}
		this.showLoading(false);
		window.scrollTo(0, 0);
	}

	setShippingDivisionByChange() {
		if(this.orderItemObject.ShippingDivision.length > 0) {
			var totalQuantity = this.orderItemObject.ShippingDivision.reduce((sum, item) => sum + item.SD.Quantity, 0);
			this.shippingDivision.Quantity = parseFloat((this.orderItemObject.Quantity - parseFloat((totalQuantity).toFixed(3))).toFixed(3));
			if(parseFloat((totalQuantity).toFixed(3)) == this.orderItemObject.Quantity) {
				this.hiddenShippingDivision = false;
			} else if(parseFloat(this.shippingDivision.Quantity) > 0) {
				this.hiddenShippingDivision = true;
			} else if(parseFloat(this.shippingDivision.Quantity) < 0) {
				this.hiddenShippingDivision = false;
			}
		} else if (this.shippingDivision.Quantity == undefined || parseFloat(this.shippingDivision.Quantity) > 0) {
			this.hiddenShippingDivision	= true;
			this.shippingDivision.Quantity = parseFloat(this.orderItemObject.Quantity);
		} else if (parseFloat(this.shippingDivision.Quantity) < 0) {
			this.hiddenShippingDivision	= false;
			this.shippingDivision.Quantity = parseFloat(this.orderItemObject.Quantity);
		} else {
			this.hiddenShippingDivision	= true;
			this.shippingDivision.Quantity = parseFloat(this.orderItemObject.Quantity);
		}
		window.scrollTo(0, 0);
	}

	async onClickShowPedidoStep3(event) {
		var showNextScreen = true;
		if(this.orderItemObject.ShippingDivision.length == 0 || this.orderItemObject.ShippingDivision == null) {
			swal("Por favor selecione uma divisão de remessa!",{ icon: "warning"});
		} else {
			if(this.checkAllInventory){
				await this.checkInventoryUnit();
				if(this.containInventoryError){
					var message = StockAlert;
					message = message.replaceAll('\\n', '\n');
					message = message.replaceAll('{stock}', this.orderItemObject.stockQuantity + ' ' + this.orderItemObject.QuantityUnitOfMeasure)
					swal(message,
					{ icon: "warning" }
					 );
				}
				if(this.containInventoryError){
					this.checkAllInventory = true;
					return;
				}
			}
			var sum = 0;
			if(this.productWithContract){
				this.disableLastPageProducts = false;
				this.disableConclude		 = false;
				if(this.orderObject.Status == 'Em digitação' || this.orderObject.Status == 'Retorna RTV'){
					this.disableLastPageEdit	= false;
				}
			}
			this.orderItemObject.ShippingDivision.forEach(function(item) {sum += parseFloat(item.SD.Quantity);});
			if(Number(sum) == Number(this.orderItemObject.Quantity)) {
				let checkDuplicated = this.orderObject.OrderItem.filter(item => item.Product2.Id == this.orderItemObject.Product2.Id)[0] ? true : false;
				if (!checkDuplicated && this.orderItemObject.Product2 != null && (this.orderObject.Status == 'Em digitação' || this.orderObject.Status == 'Recusado' || this.orderObject.Status == 'Retorna RTV') || this.isRefuseReason) {
					this.orderItem = this.cloneObj(this.orderItemObject);
					this.orderObject.OrderItem.push(this.orderItem);
					this.nullShippingDivisionObject();
				}
				checkDuplicated = this.orderObject.OrderItem.filter(item => item.Product2.Id == this.orderItemObject.Product2.Id)[0] ? true : false;
				
				if(!checkDuplicated && this.orderItemObject.Product2 != null && this.productWithContract) {
					this.orderItem = this.cloneObj(this.orderItemObject);
					this.orderObject.OrderItem.push(this.orderItem);
					this.nullShippingDivisionObject();
				}
				if(this.orderObject.OrderItem.length > 0) {
					var totalPrice				   = this.orderObject.OrderItem.reduce((sum, item) => Number(sum) + Number(item.TotalValueItem), 0);
					this.orderObject.TotalPriceOrder = parseFloat(totalPrice).toFixed(2);
					if (this.isRefuseReason) {
						this.orderObject.TotalCredit = parseFloat(parseFloat(this.orderObject.RefusalReasonCredit.toFixed(2)) - parseFloat(this.orderObject.TotalPriceOrder)).toFixed(2);
					}
				}
				this.showScreen("Step03");

				var callCampaignCalc = false;
				this.orderObject.OrderItem.forEach(function (ordItem) {
					if (ordItem.Campaign.length > 0)
						callCampaignCalc = true;
				});

				if (callCampaignCalc && !this.disableLastPageEdit)
					await this.getAvailableCampaign();
				
			} else {
				var quantityShippingDivision = parseFloat(this.orderItemObject.Quantity) - parseFloat(sum);
				if(quantityShippingDivision > 0) {
					swal("Insira a quantidade de divisões de remessa restante: " + quantityShippingDivision,{ icon: "warning"});
					showNextScreen = false;
					return;
				} else {
					swal("Remova a quantidade de divisões de remessa excedente: " + Math.abs(quantityShippingDivision),{ icon: "warning"});
					showNextScreen = false;
					return;
				}
			}
		}
		if(showNextScreen) {
			this.showLoading(true);
			this.showPedidoStep03 = false;
			if(this.orderObject.Status == 'Em digitação' || this.orderObject.Status == 'Retorna RTV') await findAuth(this.orderObject.OrderItem, this);
			this.showPedidoStep03 = true;
			this.normalizeOrderItemList();
			this.showLoading(false);
			window.scrollTo(0, 0);
		} else {
			return;
		}
	}

	
	async checkInventoryAll(){
		this.checkAllInventory = false;
		var productIds;
		var measure;
		productIds = this.orderObject.OrderItem.map((elem) => {return elem.Product2.Id;});
		measure = this.orderObject.OrderItem.map((elem) => {return elem.QuantityUnitOfMeasure;});
		await handleInventory({productIds: productIds, salesTeamId: this.orderObject.SalesTeam.Id, measureList: measure, cropId: this.orderObject.Crop.Id}).then(data => {
			if (data) {
				var x = null;
				x = this;
				var error;
				if(this.orderObject.OrderItem.length != 0){
					this.orderObject.OrderItem.forEach(function(ordItem) {
						var inventory = data.find(element => element.ProductId == ordItem.Product2.Id && (element.UnitMeasurement == ordItem.QuantityUnitOfMeasure || element.UnitMeasurement == null));
						if (inventory.HasInventory) {
							ordItem = handleInventoryCheck(ordItem, inventory, x.orderObject.Status);
							if(ordItem.Block){
								error = true;
							}
							if(ordItem.hasInventoryError || ordItem.hasInventoryErrorRTV){
								x.showInventoryMessage = true;
							}
							else {
								x.showInventoryMessage = false;
							}
						}
						else {
							ordItem = handleNullStock(ordItem);
						}
					});
				}
				if(error){
					this.containInventoryError = true;
				}
				else {
					this.containInventoryError = false;
				}
			}
		}).catch(error => {
			this.showLoading(false);
			if (error != null) {
				swal("Erro: " + JSON.stringify(error.body.message),{ icon: "warning"}).then((action) => {});
			}
		});
	}

	async checkInventoryUnit(){
		this.checkAllInventory = false;
		var productIds = [];
		var measure = [];
		productIds.push(this.orderItemObject.Product2.Id);
		measure.push(this.orderItemObject.QuantityUnitOfMeasure);
		await handleInventory({productIds: productIds, salesTeamId: this.orderObject.SalesTeam.Id, measureList: measure, cropId: this.orderObject.Crop.Id}).then(data => {
			if (data) {
				var x = null;
				x = this;
				var inventory = data.find(element => element.ProductId == this.orderItemObject.Product2.Id);
				if (inventory.HasInventory) {
					this.orderItemObject = handleInventoryCheck(this.orderItemObject, inventory, this.orderObject.Status);
					if(this.orderItemObject.Block){
						this.containInventoryError = true;
					}
					else {
						this.containInventoryError = false;
					}
				}
				else {
					this.orderItemObject = handleNullStock(this.orderItemObject);
				}
			}
		}).catch(error => {
			this.showLoading(false);
			if (error != null) {
				swal("Erro: " + JSON.stringify(error.body.message),{ icon: "warning"}).then((action) => {});
			}
		});
	}
		
	onClickShowBarterStepA(){
		this.orderObject.BillingCrop = this.cloneObj(this.orderObject.Crop);
	}

	onClickShowBarterStepB(event){
		var object = {};
		object	 = event?.detail || event?.detail?.value;
		if(object.orderObjectBarter != null && (object.orderObjectBarter.Rating != null || object.orderObjectBarter.Bloqued != null)) {
			this.orderObject  = fillOrderBarter(this.orderObject, object);
			
			this.creditLimitBloqued = this.checkCredit();
			this.returnEachTotalValue();
			
			let msg = 'Rating de Credito '+(!this.creditLimitBloqued ? 'Aprovado' : 'Reprovado ou Bloqueado');
			msg += '\n' + this.orderObject.Rating;

			swal(msg, { icon: !this.creditLimitBloqued ? "success" : "warning" }).then(() => {

				if (!this.creditLimitBloqued) {
					this.showScreen("StepB");
					if (this.orderObject.Status   != 'Em aprovação' ||
						this.orderObject.Status != 'Retorna RTV') {
						this.disabledAllFields = true;
					}
				}

			});
		}
		else{
			swal("Não foi possível encontrar o limite de crédito do cliente.",{ icon: "error"});
		}
	}

	onReceiveBarterObject(event){
		var object = {};
		object	 = event?.detail || event?.detail?.value;
		if(object.orderObjectBarter != null) {
			this.orderObject["PaymentForm"]				= object.orderObjectBarter.PaymentForm;
			this.orderObject["BarterType"]				 = object.orderObjectBarter.BarterType;
		}
	}

	onClickWindowBack(event) {
		if(this.recordId) {
			this.navigateToView(this.recordId);
		} else {
			this.navigateToOrderHome();
		}
		window.scrollTo(0, 0);
	}

	showLoading(show) {
		this.loading = show;
	}

	convertDate(value) {
		var paymentDate = new Date(value);
		paymentDate.setHours();
	}

	navigateToView(id) {
		this[NavigationMixin.Navigate]({ type:'standard__recordPage', attributes:{ recordId: this.returnDetailValue(id), objectApiName:'Order', actionName:'view' } });
	}

	navigateToOrderHome() {
		this[NavigationMixin.Navigate]({type:'standard__objectPage',attributes:{ objectApiName:'Order', actionName:'home'}});
	}

	showToast(toastInfo) {
		this.dispatchEvent(new ShowToastEvent({title: toastInfo.Title,message: toastInfo.Message,variant: toastInfo.Type}));
	}

	checkAllFields(orderObject) {
		var returnVal = true;
		this.allReqFieldsHeader.forEach(function(item) {
			if(!orderObject[item]) {
				returnVal = false;
				return;
			}
		});
		if(orderObject["RecordType"] == 'BarterSale' && (!orderObject["EndContractDate"] || !orderObject["InitialContractDate"] || !orderObject["BarterType"])){
			returnVal = false;
			return;
		}
		return returnVal;
	}

	checkAllFieldsProduct(orderItemObject) {
		var returnVal = true;
		this.allReqFieldsScreenProduct.forEach(function(item) {
			if(!orderItemObject[item]) {
				returnVal = false;
				return;
			}
		});
		return returnVal;
	}

	cloneObj(obj) {
		return JSON.parse(JSON.stringify(obj));
	}

	nullOrderItemObject() {
		nullOrderItemObjectUtils(this.orderItemObject);
		this.disabledProductFields	 = true;
		this.disabledProductFieldsBonification	 = true;
		this.shippingDivision.Quantity	 = null;
		this.shippingDivision.DueDate	  = null;
		this.familyId	  = null;
	}

	nullShippingDivisionObject() {
		this.shippingDivision.Quantity = null;
		this.shippingDivision.DueDate  = null;
	}

	convertToDate(strDate) {
		return new Date(strDate);
	}

	checkCredit(){
		return this.orderObject.Rating == 'D' || this.orderObject.Bloqued;
	}

	uploadFinished(value) {
		this.documentId = this.returnDetailValue(value).documentId;
		this.FileName = this.returnDetailValue(value).name;
		this.hasAttachment = true;
	}

	changeStatusOrderToWriting(value) {
		this.orderObject.Status = this.returnDetailValue(value);
	}

	concludeOrder() {
		this.orderObject.Status   = 'Em aprovação';
		this.disabledAllFields	= true;
		this.disableLastPageProducts = true;
		this.disableConclude		 = true;
		this.disableLastPageEdit	= true;
		this.disablefreight	   = true;
		this.disabledAllObservation = true;
		this.disabledPaymentForm	= true;
		this.disabledNegotiationType = true;
		this.disabledCustomLookup = true;
		this.disabledContract = true;
		this.disabledSalesCondition = true;
		this.viewProduct		  = true;
		this.isNotBarter = this.orderObject.RecordType != 'BarterSale';
		this.showPedidoStep03	 = false;
		this.showPedidoStep03	 = true;
	}

	checkTotalValue(){
		var value = this.orderObject.BarterType == 'Financeiro' ? this.orderObject.StrikePrice: this.orderObject.CommUnitPrice;
		if(Math.ceil(Number(parseFloat(this.orderObject.TotalPriceOrder).toFixed(2))/parseFloat(value).toFixed(2)) <= this.orderObject.TotalDeliveryQuantity){
			return false;
		}
		return true;
	}

	returnTotalValue(){
		var totalPrice = this.orderObject.OrderItem.reduce((sum, item) => Number(sum) + Number(item.TotalValueItem), 0);
		this.orderObject.TotalPriceOrder = parseFloat(totalPrice).toFixed(2);
		if (this.isRefuseReason) {
			this.orderObject.TotalCredit = parseFloat(parseFloat(this.orderObject.RefusalReasonCredit.toFixed(2)) - parseFloat(this.orderObject.TotalPriceOrder)).toFixed(2);
		}
		var value = this.orderObject.BarterType == 'Financeiro' ? this.orderObject.StrikePrice: this.orderObject.CommUnitPrice;
		var total = Math.ceil(Number(parseFloat(this.orderObject.TotalPriceOrder).toFixed(2))/parseFloat(value).toFixed(2));
		this.orderObject.TotalDeliveryQuantity = total;
	}

	returnEachTotalValue(){
		var value = this.orderObject.BarterType == 'Financeiro' ? this.orderObject.StrikePrice: this.orderObject.CommUnitPrice;
		this.orderObject.OrderItem.forEach(function(item){
			item.EachTotalPrice = Math.ceil(Number(parseFloat(item.TotalValueItem).toFixed(2))/parseFloat(value).toFixed(2));
		});
	}

	uploudBarterSetValues() {
		this.documentId = undefined;
		this.hasAttachment = false;
	}

	changeStatusConcludeOrder() {
		this.orderObject.Status = (this.orderObject.RecordType == 'BarterSale' && this.orderObject.Status == 'Em digitação') ? 'Em aprovação grãos' : 'Em aprovação';
	}

	setTotalValueFromCampaign(value) {

		let orderObj = this.cloneObj(value.target.newOrderValues);

		this.orderObject.TotalPriceOrder = orderObj.finalPrice;
		this.orderObject.TotalCampaignDiscount = orderObj.finalDiscount;
		this.orderObject.TotalCampaignDisocuntPercentage = ((this.orderObject.TotalCampaignDiscount * 100) / (this.orderObject.TotalPriceOrder + this.orderObject.TotalCampaignDiscount));
		this.orderObject.TotalPriceOrderWithoutCampaign = this.orderObject.TotalPriceOrder + this.orderObject.TotalCampaignDiscount;

		var t = this;
		orderObj.orderItem.forEach(item => {
			let orderItem = t.orderObject.OrderItem.find(oi => oi.Product2.Id == item.Product2.Id);
			if (orderItem != null || orderItem != undefined) {
				orderItem.Campaign = item.Campaign;
				let discVal = orderItem.PriceList * (orderItem.DiscountPercent / 100);
				let audVal = orderItem.PriceList * (orderItem.AdditionPercent / 100);
				if (orderItem.Campaign.length > 0) {
					orderItem.listPriceValueWithInterestAndCampaign = item.listPriceValueWithInterestAndCampaign;
					orderItem.UnitPrice = item.UnitPrice;
					orderItem.UnitValue = orderItem.UnitPrice;
					orderItem.UnitValueWithSevenDecimalCases = parseFloat(parseFloat(orderItem.UnitPrice) + parseFloat(audVal) - parseFloat(discVal)).toFixed(7)
					orderItem.TotalValueItem = item.TotalValueItem;
					orderItem.TotalCampaignDiscount = parseFloat(item.TotalCampaignDiscount).toFixed(2);
					orderItem.TotalValueWithoutCampaign = parseFloat(parseFloat(orderItem.PriceList) + parseFloat(audVal) - parseFloat(discVal)) * parseFloat(orderItem.Quantity);
					orderItem.hasCampaign = true;
				} else {
					orderItem.TotalCampaignDiscount = 0;
					orderItem.TotalValueWithoutCampaign = 0;
					t.orderObject.TotalPriceOrder += orderItem.TotalValueItem;
					t.orderObject.TotalCampaignDisocuntPercentage = ((t.orderObject.TotalCampaignDiscount * 100) / (t.orderObject.TotalPriceOrder + t.orderObject.TotalCampaignDiscount));
					t.orderObject.TotalPriceOrderWithoutCampaign = t.orderObject.TotalPriceOrder + t.orderObject.TotalCampaignDiscount;
					orderItem.hasCampaign = false;
				}
			}
		});

		var hasCampaign = false;

		this.orderObject.OrderItem.forEach(orderItem => {
			if (orderItem.Campaign.length > 0) {
				hasCampaign = true;
			}
		});

		if (hasCampaign) {
			this.orderObject.hasCampaign = true;
			this.getAvailableCampaign();
			applyCampaignDiscounts(this);
		}

	}

	removeCampaign(value) {

		var idsObj = this.cloneObj(value.target.removeCampaignValues);

		var productId = idsObj.productId;
		var campaignId = idsObj.campaignId;
		var orderCampaign;

		let orderItem = this.orderObject.OrderItem.find(item => item.Product2.Id == productId);

		orderItem.Campaign = orderItem.Campaign.filter(campaign => campaign.campaignId != campaignId);

		let discVal = orderItem.PriceList * (orderItem.DiscountPercent / 100);
		let audVal = orderItem.PriceList * (orderItem.AdditionPercent / 100);

		let totalDiscount = 0;
		orderItem.Campaign.forEach(campaign => {

			if (campaign.hasFixedUnitPrice) {
				orderItem.DiscountPercent = 0;
				orderItem.DiscountValue   = 0;
				orderItem.AdditionPercent = 0;
				orderItem.AdditionValue   = 0;
			}

			var listPriceWithInterestAndDiscounts = parseFloat(orderItem.PriceList) + parseFloat(audVal) - parseFloat(discVal);

			if (parseFloat(campaign.discountValue) != 0) {
				totalDiscount += parseFloat(campaign.discountValue);
			}
			else {
				totalDiscount += campaign.discountPercentage * listPriceWithInterestAndDiscounts;
			}
		});

		if (!this.orderObject.OrderItem.find(ordItem => ordItem.hasCampaign)) {
			this.orderObject.hasCampaign = false;
		}

		var listPriceWithInterestAndDiscounts = parseFloat(orderItem.PriceList) + parseFloat(audVal) - parseFloat(discVal);

		orderItem.UnitValue = parseFloat(parseFloat(listPriceWithInterestAndDiscounts - parseFloat(totalDiscount)).toFixed(2));
		orderItem.UnitValueWithSevenDecimalCases = listPriceWithInterestAndDiscounts - parseFloat(totalDiscount);
		orderItem.listPriceValueWithInterestAndCampaign = parseFloat(orderItem.UnitValue);
		orderItem.UnitPrice = orderItem.listPriceValueWithInterestAndCampaign;
		orderItem.TotalValueItem = parseFloat((orderItem.UnitValueWithSevenDecimalCases * orderItem.Quantity).toFixed(2));
		if (orderItem.Campaign.length == 0) {
			orderItem.hasCampaign = false;
			orderItem.TotalCampaignDiscount = 0;
			orderItem.TotalValueWithoutCampaign = 0;
		} else {
			orderItem.hasCampaign = true;
			orderItem.TotalCampaignDiscount = orderItem.Quantity * totalDiscount;
			orderItem.TotalValueWithoutCampaign = listPriceWithInterestAndDiscounts * parseFloat(orderItem.Quantity);
		}

		let orderCampaignDiscount = 0;

		let hasCampaign = false;
		let orderTotalValue = 0;
		this.orderObject.OrderItem.forEach((item) => {
			if (item.Campaign.length > 0) {
				hasCampaign = true;
			}
			orderTotalValue += parseFloat(item.TotalValueItem);
			orderCampaignDiscount += parseFloat(item.TotalCampaignDiscount);
		});
		if (hasCampaign) {
			this.orderObject.hasCampaign = hasCampaign;
		} else {
			this.orderObject.hasCampaign = false;
		}
		this.orderObject.TotalPriceOrder = orderTotalValue;
		this.orderObject.TotalCampaignDiscount = orderCampaignDiscount;
		this.orderObject.TotalCampaignDisocuntPercentage = ((this.orderObject.TotalCampaignDiscount * 100) / (this.orderObject.TotalPriceOrder + this.orderObject.TotalCampaignDiscount));
		this.orderObject.TotalPriceOrderWithoutCampaign = this.orderObject.TotalPriceOrder + this.orderObject.TotalCampaignDiscount;
		validateAccumulativeAndIndustryCampaign(this);
		//updateOrderTotalValues(this);
	}

	async getAvailableCampaign(){
		this.showLoading(true);
		await getCampaign({team: this.orderObject.SalesTeam.Id, account: this.orderObject.Account.Id, accGroup: this.orderObject.CustomerGroup, activitySector: this.orderObject.ActivitySector, coinType: this.orderObject.Currency, orderType: this.orderObject.RecordType, crop: this.orderObject.Crop.Id}).then(data => {
			if (data) {
				var containCampaign = false;
				this.campaignList = validateCampaign(data, this);
				applyCampaignDiscounts(this);
				validateAccumulativeAndIndustryCampaign(this);
				//updateOrderTotalValues(this);
				var x = this;
				this.orderObject.OrderItem.forEach((ordItem) => {
					var hasInvalidCampaign = false;
					ordItem.Campaign.forEach(oiCampaign => {
						containCampaign = true;
						let campaignValidated = x.campaignList.find(cp => cp.CampaignId == oiCampaign.campaignId);
						if (!campaignValidated || campaignValidated.invalid) {
							oiCampaign.invalid = true;
							hasInvalidCampaign = true;
						} else {
							applyCampaignDiscountsAndValidation(this, campaignValidated.CampaignId);
						}
					});
					ordItem.hasInvalidCampaign = hasInvalidCampaign;
				});

				if(containCampaign) {
					validateAccumulativeAndIndustryCampaign(this);
					this.orderObject.hasCampaign = true;
				} else {
					this.orderObject.hasCampaign = false;
				}

			} else {
				this.campaignList = null;
			}
			this.showLoading(false);
		}).catch(error => { this.showLoading(false);});
	}

	removeCampaignFromOrderItens(value) {
		removeCampaignFromItem(this, this.cloneObj(value.target.targetCampaign));
		validateAccumulativeAndIndustryCampaign(this);
		//updateOrderTotalValues(this);
	}
}