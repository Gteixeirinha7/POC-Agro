import { LightningElement, api, track, wire } from 'lwc';
import Images from '@salesforce/resourceUrl/AllImagesScreenOrder';
import getListPriceData from '@salesforce/apex/PriceListController.getListPriceData';
import getInterestListData from '@salesforce/apex/InterestListController.getInterestListData';
import getFreigth from '@salesforce/apex/GetFreigthController.getFreigth';
import {refreshApex} from '@salesforce/apex';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import AllJsFilesSweetAlert from '@salesforce/resourceUrl/AllJsFilesSweetAlert';
import getContractInfo from '@salesforce/apex/CustomLookupController.getContractInfo';
import handleInventory from '@salesforce/apex/OrderScreenController.handleInventory';
import getDelimitedLand from '@salesforce/apex/OrderScreenController.getDelimitedLand';
// import getProductCost from '@salesforce/apex/OrderScreenController.getProductCost';


export default class OrderItemScreen extends LightningElement {
	cISum			   = Images + '/AllImagesScreenOrder/ic-plus-green.svg';
	cISub			   = Images + '/AllImagesScreenOrder/ic-minus.svg';
	interestPlaces = 7;

	@api clienteId;
	@api productId;
	@api idsProducts;
	@api priceData;
	@api interestListData;
	@api priceListData
	@api priceListDataJsonStrg;
	@api currencyScreen;
	@api currencyScreenFormat;
	@api context;
	@api checkFreightFCA;
	@api checkFreightFOB;
	@api checkFreightCIF;
	@api productContract;
	@api productContractId;
	@api productContractQuantity; 
	@api productWithContract;
	@api containInventoryError;
	@api disabledAllFields	  = false;
	@api disabledQuantity	   = false;
	@api disabledProduct2	   = false;
	@api loading				= false;
	@api productSelected		= false;
	@api interestTable		  = new Object();
	@api orderObject			= new Object();
	@api orderItemObjectApi	 = new Object();

	@track showContract					  = false;
	@track familyId;
	@track principleName;
	@track listDay;
	@track listMonth;
	@track listYear;
	@track campaignDiscountPercentage;
	@track campaignDiscountValue;
	@track disabledProductFields			 = false;
	@track disabledProductFieldsBonification = true;
	@track orderItemObject				   = new Object();

	@track hasDelimitedLand = false;
	@track totalcultureMeters = 0;
	@track hasDelimitedLandCulture = false;
	@track cultureName = '-';
	@track cultureMeters = 0;
	@track delimitedLandMeters = 0;

	@wire(getInterestListData, {priceData: '$interestListData'})
	getInterestListDataRefreshed;

	@wire(getListPriceData, {priceDatas: '$priceListDataJsonStrg'})
	getListPriceRefreshed;

	@wire(getFreigth, {destinationCityId: '$orderObject.ShippingAccount.InternShippingCity__c', sourceCityId: '$orderObject.SalesTeam.DistributionCenter__r.City__c' , product2Id: '$orderItemObject.Product2.Id' })
	getFreigthRefreshed;
		
	async refreshApexGetListPriceRefreshed() {
		try {
			console.log('this.priceListData: ' + JSON.stringify(this.priceListDataJsonStrg));
			await refreshApex(this.getListPriceRefreshed);
		} catch(e) {
			console.log('Error: ' + JSON.stringify(e));
		}
	}

	async refreshApexGetInterestListDataRefreshed() {
		try {
			await refreshApex(this.getInterestListDataRefreshed);
		} catch(e) {
			console.log('Error: ' + JSON.stringify(e));
		}
	}
		
	async refreshApexGetFreigthRefreshed() {
		try {
			await refreshApex(this.getFreigthRefreshed);
		} catch(e) {
			console.log('Error: ' + JSON.stringify(e));
		}
	}

	connectedCallback() {
		Promise.all([loadScript(this, AllJsFilesSweetAlert + '/sweetalert-master/sweetalert.min.js')]).then(() => {console.log('Files loaded.');}).catch(error => {console.log('error: ' + JSON.stringify(error));});

		var orderItem = this.cloneObj(this.orderItemObjectApi);
		this.orderItemObject = orderItem;
		if(this.orderItemObject.ListPrice != undefined){
			this.listDay		   = this.orderItemObject.ListPrice.EffectiveDate ? new Date(this.orderItemObject.ListPrice.EffectiveDate).getDate()+1 : null;
			this.listMonth		 = this.orderItemObject.ListPrice.EffectiveDate ? new Date(this.orderItemObject.ListPrice.EffectiveDate).getMonth()+1 : null;
			this.listYear		  = this.orderItemObject.ListPrice.EffectiveDate ? new Date(this.orderItemObject.ListPrice.EffectiveDate).getFullYear() : null;
			this.showListPriceDate = this.orderItemObject.ListPrice.EffectiveDate ? true : false;
			if(this.listDay != null) this.padLeadingZeros();
		}

		console.log('this.orderObject.RecordType: ' + JSON.stringify(this.orderObject.RecordType));
		this.checkBonificationState();
		this.getListPrice();
		if(this.context == '_isNew_'){
			this.nullOrderItemObject();
		}else if(this.context == '_isEdit_'){
			if (this.orderItemObject) {
				if (this.orderItemObject.Campaign) {
					if (this.orderItemObject.Campaign.length > 0) {
						this.orderItemObject.hasCampaign = true;
						var campaignDiscountSum = 0;
						this.orderItemObject.Campaign.forEach(campaign => {
							campaignDiscountSum += campaign.discountPercentage / 100;
						});
						var unitValueWithoutCampaign = parseFloat(this.orderItemObject.UnitValueWithSevenDecimalCases) / (1 - campaignDiscountSum);
						//var discountPercentage = ((parseFloat(this.orderItemObject.PriceList) - unitValueWithoutCampaign ) * 100) / parseFloat(this.orderItemObject.PriceList);
						var discountValue	  = parseFloat(this.orderItemObject.PriceList) - unitValueWithoutCampaign;
						let totalDiscount = 0;
						this.orderItemObject.Campaign.forEach(campaign => {
							campaign.discountValue = (campaign.discountPercentage / 100) * (parseFloat(this.orderItemObject.PriceList) - discountValue);
							totalDiscount += campaign.discountValue;
						});
						this.campaignDiscountValue = totalDiscount;
						this.campaignDiscountPercentage = totalDiscount ? ((totalDiscount * 100) / (parseFloat(this.orderItemObject.UnitValue) + totalDiscount)) : 0;
					} else {
						this.orderItemObject.hasCampaign = false;
						this.campaignDiscountPercentage = 0;
						this.campaignDiscountValue = 0;
					}
				}
			}
			this.checkInventoryUnit();
			if(this.orderItemObject.Id != null && this.orderItemObject.Id != undefined) {
				this.disabledProduct2 = true;
			} else {
				this.disabledProduct2 = false;
			}
			this.disabledProductFields = false;
		}else if(this.context == '_isView_'){
			this.disabledProductFields = true;
			this.disabledProduct2	  = true;
		}

		this.getDelimitedLandData();

		this.disabledProductFieldsBonification = orderItem.Campaign && orderItem.Campaign.filter(item => item.hasFixedUnitPrice)[0] ?  true : false;

		console.log('CONNECTED CALLBACK ORDERITEMSCREEN');
		console.log('this.orderItemObject: ' + JSON.stringify(this.orderItemObject));
	}

	renderedCallback() {
		console.log('RENDERED CALLBACK ORDERITEMSCREEN');
	}

		
	handleNewRecordFamily(event) {
		var record = {};
		record	 = event?.detail || event?.detail?.value;
		console.log('record da familia',record);
		console.log('event',event);
		if(record.record != null) {
			this.nullOrderItemObject();
			this.orderItemObject.Family = record.record;
			this.familyId			   = record.record.Id;
			this.familyName			 = record.record.Name;
			// this.template.querySelector('c-custom-lookup-product2').setFamilyId(record.record.Id);
			this.template.querySelector('c-custom-lookup-active-principle').setFamilyPrinciple(record.record);
			this.template.querySelector('c-custom-lookup-product2').setFamilyName(record.record.Name);
		} else {
			this.orderItemObject.Family = null;
			this.familyId			   = null;
			this.nullOrderItemObject();
			// this.template.querySelector('c-custom-lookup-product2').setFamilyId(null);
			this.template.querySelector('c-custom-lookup-active-principle').setFamilyPrinciple(null);
			this.template.querySelector('c-custom-lookup-product2').setFamilyName(null);
		}
	}
	async handleNewRecordPrinciple(event) {
		var record = {};
		record	 = event?.detail || event?.detail?.value;
		console.log('record do Principle',record);
		console.log('Principle',event);
		if(record.record != null) {
			if(this.productSelected == true){
				await this.nullOrderItemObject();
				this.template.querySelector('c-custom-lookup-active-principle').setValor(record.record);
				console.log('Entrou sim');
			}
			this.principleName			   = record.record.ActivePrinciple__c;
			console.log('this.principleName ',this.principleName);
		} else {
			this.principleName		  = null;
			//this.template.querySelector('c-custom-lookup-product2').setFamilyId(null);
		}
	}
	dateTodayFormat() {
		var data = new Date(),
			dia  = data.getDate().toString(),
			diaF = (dia.length == 1) ? '0'+dia : dia,
			mes  = (data.getMonth()+1).toString(),
			mesF = (mes.length == 1) ? '0'+mes : mes,
			anoF = data.getFullYear();
		return diaF+"/"+mesF+"/"+anoF;
	}
	dateTodayWithoutFormat() {
		var data = new Date(),
			dia  = data.getDate().toString(),
			diaF = (dia.length == 1) ? '0'+dia : dia,
			mes  = (data.getMonth()+1).toString(),
			mesF = (mes.length == 1) ? '0'+mes : mes,
			anoF = data.getFullYear();
		return anoF+"-"+mesF+"-"+diaF;
	}
	getInterestValue(price){
		return parseFloat(Number(price) + Number(((this.setValueInterestList() == 'ZDJ1' ? -1 : 1) * Number(this.orderItemObject.InterestListValue)).toFixed(this.interestPlaces)));
	}
	async handleNewRecordProduct2(event) {
		var record = {};
		record	 = event?.detail || event?.detail?.value;
		if(record.record == null) {	
			this.nullOrderItemObject();
			await this.template.querySelector('c-custom-lookup-active-principle').setFamilyPrinciple(this.orderItemObject.Product2);  
		} else {
			this.showLoading(true);			
			this.orderItemObject.Product2							 = record.record;
			if(this.productWithContract == true) {
				this.setInformationContract();
				this.disabledProductFieldsBonification = true;
				this.disabledAllFields = true;
				this.orderItemObject.Family							   = this.orderItemObject.Product2.Family__c != undefined && this.orderItemObject.Product2.Family__c != null ? {"Id": this.orderItemObject.Product2.Family__r.Id, "Name": this.orderItemObject.Product2.Family__r.Name} : null;
				this.familyId											 = this.orderItemObject.Product2.Family__c != undefined && this.orderItemObject.Product2.Family__c != null ? this.orderItemObject.Product2.Family__r.Id : null;
			}else{
				var newTable = this.priceData[this.orderItemObject.Product2.Id];
				if(this.orderItemObject != null && newTable.Id != this.orderItemObject.ListPrice?.Id)
					this.orderItemObject.LastChangedPriceList				 = this.dateTodayWithoutFormat();
					this.orderItemObject.ListPrice							= newTable;
				this.listDay											  = this.orderItemObject.ListPrice.EffectiveDate ? new Date(this.orderItemObject.ListPrice.EffectiveDate).getDay() : null;
				this.listMonth											= this.orderItemObject.ListPrice.EffectiveDate ? new Date(this.orderItemObject.ListPrice.EffectiveDate).getMonth() : null;
				this.listYear											 = this.orderItemObject.ListPrice.EffectiveDate ? new Date(this.orderItemObject.ListPrice.EffectiveDate).getFullYear() : null;
				if(this.listDay != null) this.padLeadingZeros();
				this.showListPriceDate									= this.orderItemObject.ListPrice.EffectiveDate ? true : false;
				this.orderItemObject.QuantityUnitOfMeasure				= this.orderItemObject.Product2.QuantityUnitOfMeasure;
				this.interestListData									 = {"productFamilyId": this.orderItemObject.Product2.Family__c,
																			 "productId": this.orderItemObject.Product2.Id,
																			 "salesOfficeId": this.orderObject.SalesTeam.ParentId__c,
																			 "currencyType": this.orderObject.Currency,
																			 "salesTeamId": this.orderObject.SalesTeam.Id,
																			 "cropId": this.orderObject.Crop.Id, 
																			 "salesCondition":this.orderObject.SalesCondition, 
																			 "listPriceType": this.setValueInterestList()};
				this.interestListData									 = JSON.stringify(this.cloneObj(this.interestListData));
				await this.getInterestTable();
				var newInterestTable = this.interestTable == null ? null : this.cloneObj(this.interestTable);

				if(newInterestTable != null && newInterestTable.Id != this.orderItemObject.InterestList?.Id)
					this.orderItemObject.LastChangedPriceList				 = this.dateTodayWithoutFormat();
				
				this.orderItemObject.InterestList						 = newInterestTable;
				var valueDatesBetween									 = Number(this.getDifferentValueBetweenDates());
				var totalMonths										   = parseFloat(valueDatesBetween/30).toFixed(2);
				if(parseFloat(totalMonths) > 12 && this.setValueInterestList() == 'ZDJ1') {totalMonths = 12;}
				this.orderItemObject.InterestListValue					= this.orderItemObject.InterestList == null ? null : (totalMonths * this.orderItemObject.InterestList.InterestValue__c) / 100;
				this.orderItemObject.InterestListValue					= this.orderItemObject.InterestListValue == null ? null : parseFloat(this.orderItemObject.ListPrice.UnitPrice * this.orderItemObject.InterestListValue).toFixed(this.interestPlaces);
				this.orderItemObject.PriceList							= this.orderItemObject.InterestListValue == null ? parseFloat(this.orderItemObject.ListPrice.UnitPrice).toFixed(this.interestPlaces) : this.getInterestValue(this.orderItemObject.ListPrice.UnitPrice);
				this.orderItemObject.PriceListWithoutInterest			 = parseFloat(this.orderItemObject.ListPrice.UnitPrice).toFixed(2);
				this.orderItemObject.UnitValueWithSevenDecimalCases	   = parseFloat(this.orderItemObject.PriceList).toFixed(7);
				this.orderItemObject.UnitValue							= parseFloat(this.orderItemObject.PriceList).toFixed(2);
				this.maxValueUnitPrice									= parseFloat(this.orderItemObject.PriceList).toFixed(7);
				this.orderItemObject.Multiplicity						 = parseFloat((this.orderItemObject.Product2.Multiplicity__c).toFixed(3)) == parseFloat(0) ? parseFloat(1) : parseFloat((this.orderItemObject.Product2.Multiplicity__c).toFixed(3));
				this.orderItemObject.Quantity							 = this.orderItemObject.Multiplicity;
				this.orderItemObject.TotalValueItem					   = parseFloat(Number(this.orderItemObject.UnitValueWithSevenDecimalCases) * Number(this.orderItemObject.Quantity)).toFixed(2);
				this.orderItemObject.DiscountPercent					  = parseFloat(((this.orderItemObject.PriceList - this.orderItemObject.UnitValueWithSevenDecimalCases) / 100) * 100).toFixed(3);
				this.orderItemObject.DiscountValue						= parseFloat((this.orderItemObject.PriceList - this.orderItemObject.UnitValueWithSevenDecimalCases)).toFixed(2);
				this.orderItemObject.DiscountValueWithSevenDecimalCases   = parseFloat((this.orderItemObject.PriceList - this.orderItemObject.UnitValueWithSevenDecimalCases)).toFixed(7);
				this.orderItemObject.DiscountPercentWithSixDecimalCases   = parseFloat(((this.orderItemObject.PriceList - this.orderItemObject.UnitValueWithSevenDecimalCases) / 100) * 100).toFixed(6);
				this.orderItemObject.AdditionValue						= (0).toFixed(2);
				this.orderItemObject.AdditionPercent					  = (0).toFixed(3);
				this.orderItemObject.AdditionValueWithSevenDecimalCases   = (0).toFixed(7);
				this.orderItemObject.AdditionPercentWithSixDecimalCases   = (0).toFixed(6);
				this.orderItemObject.TotalAdditionAmount				  = parseFloat(this.orderItemObject.ListPrice.UnitPrice).toFixed(2);
				this.orderItemObject.BorderColor						= 'card card-lista-pedido border-primary';
				this.disabledProductFields								= false;
				this.orderItemObject.Family							   = this.orderItemObject.Product2.Family__c != undefined && this.orderItemObject.Product2.Family__c != null ? {"Id": this.orderItemObject.Product2.Family__r.Id, "Name": this.orderItemObject.Product2.Family__r.Name} : null;
				this.familyId											 = this.orderItemObject.Product2.Family__c != undefined && this.orderItemObject.Product2.Family__c != null ? this.orderItemObject.Product2.Family__r.Id : null;
				await this.template.querySelector('c-custom-lookup-active-principle').setFamilyPrincipleProduct(this.orderItemObject.Product2);
				await this.getFreigthValue();
				this.discountNotNegative();
				this.productSelected = true;
				this.disabledProductFieldsBonification = false;
				this.disabledAllFields = false;
				this.orderItemObject.ShowDetails = true;
				if(this.orderItemObject.DiscountPercent != 0 && this.orderItemObject.AdditionPercent == 0){
					this.orderItemObject.IsDiscount = true;
				}
				else{
					this.orderItemObject.IsDiscount = false;
				}
			}
			this.checkInventoryUnit();
			this.setMargin();
			this.showLoading(false); 
		}
		
	}


	setMargin(){
		var curTable = this.priceData[this.orderItemObject.Product2.Id];
		// if ('Cost' in this.orderItemObject==false){
		//	 this.orderItemObject['Cost'] =null;
		// }		
		this.orderItemObject['Cost'] =null;
		if (curTable && 'Cost' in curTable){
			this.orderItemObject.Cost =parseFloat(curTable.Cost);
			console.log('foud cost: ' +this.orderItemObject.Cost);
		}
		console.log('curTable: ' +JSON.stringify(curTable));
		this.orderItemObject['margin'] =null;
		this.recalculateMargin();

	}
		
	recalculateMargin(){
		if (this.orderItemObject.Cost !=null
			&& this.orderItemObject.UnitValueWithSevenDecimalCases!=null
			&& this.orderItemObject.Cost > 0){
		this.orderItemObject.margin =
			((parseFloat(this.orderItemObject.UnitValueWithSevenDecimalCases) - this.orderItemObject.Cost ) / this.orderItemObject.UnitValueWithSevenDecimalCases) *100;
		console.log('margin = ' +this.orderItemObject.margin);
		}
		else{
			this.orderItemObject.margin =null;
		}
	}

	async setInformationContract() {
		console.log('productContractId: ', this.productContractId);
		console.log('this.orderItemObject.Culture: ', this.orderItemObject.Culture);
		console.log('this.orderItemObject.Product2: ', this.orderItemObject.Product2);
		console.log('orderItemObject.Family: ', this.orderItemObject.Family);
		await getContractInfo({orderId: this.productContractId, productId: this.orderItemObject.Product2.Id }).then(data => {
			if(data) {
				console.log('data1: ', data);
				this.orderItemObject.Culture					 = {Id:data.Culture__c, Name: data.Culture__r.Name}; 
				this.orderItemObject.ListPrice				   = {Id:data.ListPrice__c, Name: data.ListPrice__r.Name, UnitPrice: data.ListPrice__r.UnitPrice__c,EffectiveDate: data.PriceListEffectiveDate__c }; 
				this.orderItemObject.UnitValue				   = data.UnitPrice;
				this.orderItemObject.TotalValueItem			  = data.TotalPrice;
				this.orderItemObject.DiscountPercent			 = data.DiscountPercent__c;
				this.orderItemObject.DiscountValue			   = data.DiscountAmount__c;
				this.orderItemObject.QuantityUnitOfMeasure	   = data.UnitMeasure__c;
				if(data.AdditionPercent__c != undefined){
					this.orderItemObject.AdditionPercent = data.AdditionPercent__c;
				}else{
					this.orderItemObject.AdditionPercent = 0;
				}
				this.orderItemObject.AdditionValue			   = data.AdditionAmount__c;
				this.orderItemObject.LastChangedPriceList		= data.LastChangedPriceList__c;
				this.orderItemObject.PriceList					   = this.orderItemObject.ListPrice.UnitPrice;
				this.orderItemObject.PriceListWithoutInterest		= parseFloat(this.orderItemObject.ListPrice.UnitPrice).toFixed(2);
				this.orderItemObject.Multiplicity					= parseFloat((this.orderItemObject.Product2.Multiplicity__c).toFixed(3)) == parseFloat(0) ? parseFloat(1) : parseFloat((this.orderItemObject.Product2.Multiplicity__c).toFixed(3));
				this.orderItemObject.Quantity						= this.orderItemObject.Multiplicity;
				this.orderItemObject.UnitValueWithSevenDecimalCases  = parseFloat(data.UnitPrice).toFixed(7);
				this.orderItemObject.DiscountValueWithSevenDecimalCases   = parseFloat((this.orderItemObject.PriceList - this.orderItemObject.UnitValueWithSevenDecimalCases)).toFixed(7);
				this.orderItemObject.DiscountPercentWithSixDecimalCases   = parseFloat(((this.orderItemObject.PriceList - this.orderItemObject.UnitValueWithSevenDecimalCases) / 100) * 100).toFixed(6);
				
				this.orderItemObject.DiscountValueWithSevenDecimalCases   = parseFloat((this.orderItemObject.PriceList - this.orderItemObject.UnitValueWithSevenDecimalCases)).toFixed(7);
				this.orderItemObject.DiscountPercentWithSixDecimalCases   = parseFloat(((this.orderItemObject.PriceList - this.orderItemObject.UnitValueWithSevenDecimalCases) / 100) * 100).toFixed(6);
				if(data.AdditionPercent__c != undefined){
					this.orderItemObject.AdditionPercentWithSixDecimalCases = data.AdditionPercent__c.toFixed(7);
				}else{
					this.orderItemObject.AdditionPercentWithSixDecimalCases = (0).toFixed(7);
				}
				this.orderItemObject.AdditionValueWithSevenDecimalCases = data.AdditionAmount__c.toFixed(6);
				this.orderItemObject.ContractProductCredit			  = data.ContractProductCredit__c;
				this.orderItemObject.BorderColor						= 'card card-lista-pedido border-primary';
				this.interestListData									 = {"productFamilyId": this.orderItemObject.Product2.Family__c,
				"productId": this.orderItemObject.Product2.Id,
				"salesOfficeId": this.orderObject.SalesTeam.ParentId__c,
				"currencyType": this.orderObject.Currency,
				"salesTeamId": this.orderObject.SalesTeam.Id,
				"cropId": this.orderObject.Crop.Id, 
				"salesCondition":this.orderObject.SalesCondition, 
				"listPriceType": this.setValueInterestList()};
				console.log('this.interestListData ' + JSON.stringify(this.interestListData));
				this.interestListData									 = JSON.stringify(this.cloneObj(this.interestListData));
				if(this.orderItemObject.ListPrice.EffectiveDate){
					this.listDay		   = this.orderItemObject.ListPrice.EffectiveDate ? new Date(this.orderItemObject.ListPrice.EffectiveDate).getDate()+1 : null;
					this.listMonth		 = this.orderItemObject.ListPrice.EffectiveDate ? new Date(this.orderItemObject.ListPrice.EffectiveDate).getMonth()+1 : null;
					this.listYear		  = this.orderItemObject.ListPrice.EffectiveDate ? new Date(this.orderItemObject.ListPrice.EffectiveDate).getFullYear() : null;
					this.padLeadingZeros();
					

					this.showListPriceDate					   = true;
				}else{
					this.showListPriceDate					   = false;
				}
				this.disabledProductFields					   = false;
			} 
		  }).catch(error => {
			console.log('error: ' + JSON.stringify(error));
		  });
		await this.getInterestTable();
		var newInterestTable = this.interestTable == null ? null : this.cloneObj(this.interestTable);
		this.orderItemObject.InterestList						 = newInterestTable;
		var valueDatesBetween							= Number(this.getDifferentValueBetweenDates());
		var totalMonths								  = parseFloat(valueDatesBetween/30).toFixed(2);
		if(parseFloat(totalMonths) > 12 && this.setValueInterestList() == 'ZDJ1') {totalMonths = 12;}
		this.orderItemObject.InterestListValue			   = this.orderItemObject.InterestList == null ? null : (totalMonths * this.orderItemObject.InterestList.InterestValue__c) / 100;
		this.orderItemObject.InterestListValue			   = this.orderItemObject.InterestListValue == null ? null : parseFloat(this.orderItemObject.ListPrice.UnitPrice * this.orderItemObject.InterestListValue).toFixed(7);
		console.log('newInterestTable ' + JSON.stringify(newInterestTable));
		this.orderItemObject.InterestList					 = newInterestTable;
		console.log('this.orderItemObject.InterestList ' + JSON.stringify(this.orderItemObject.InterestList));
		await this.getFreigthValue();
		this.discountNotNegative();
		this.showContract = true;
	}

	productQuantity(event) {
		var record = {};
		record	 = event?.detail || event?.detail?.value;
		this.productContractQuantity = record.record;
		}

	handleChangeQuantityFocusOut(event) {
		var value = parseFloat(event.target.value);
		var isDecimal = this.isDecimal(parseFloat((value/this.orderItemObject.Multiplicity).toFixed(3)));

		if(!isDecimal) {
			if((parseFloat((value).toFixed(3)) > parseFloat((0).toFixed(3)))) {
				
				if(this.productContract != null  && parseFloat((value).toFixed(3)) > this.productContract[this.orderItemObject.Product2.Id]){
					swal("A quantidade máxima disponível para este produto para o contrato selecionado é de: "+(this.productContract[this.orderItemObject.Product2.Id]),{ icon: "warning"});
					this.orderItemObject.Quantity = this.productContract[this.orderItemObject.Product2.Id];
				}else{
					this.orderItemObject.Quantity		= parseFloat((value).toFixed(3));
					this.orderItemObject.TotalValueItem  = parseFloat(this.orderItemObject.UnitValueWithSevenDecimalCases * this.orderItemObject.Quantity).toFixed(2);
					//this.orderItemObject.DiscountPercent = parseFloat(100 - ((this.orderItemObject.UnitValueWithSevenDecimalCases * 100) / this.orderItemObject.PriceList)).toFixed(3);
					//this.orderItemObject.DiscountPercentWithSixDecimalCases   = parseFloat(100 - ((this.orderItemObject.UnitValueWithSevenDecimalCases * 100) / this.orderItemObject.PriceList)).toFixed(6);
					//this.orderItemObject.DiscountValue   = parseFloat(this.orderItemObject.PriceList - this.orderItemObject.UnitValueWithSevenDecimalCases).toFixed(2);
					//this.orderItemObject.DiscountValueWithSevenDecimalCases = parseFloat(this.orderItemObject.PriceList - this.orderItemObject.UnitValueWithSevenDecimalCases).toFixed(7);
					this.setFreigthValueByQuantity();
					this.discountNotNegative();
				}
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

	handleOnClickSomar(event) {
		var isDecimal = this.isDecimal(parseFloat((this.orderItemObject.Quantity/this.orderItemObject.Multiplicity).toFixed(3)));

		console.log('isDecimal: ' + JSON.stringify(isDecimal));

		if(!isDecimal == true) {
			var qtds = parseFloat((parseFloat(this.orderItemObject.Quantity) + parseFloat(this.orderItemObject.Multiplicity)).toFixed(3));
			if(this.productContract != null && qtds > this.productContract[this.orderItemObject.Product2.Id]){
				swal("A quantidade máxima disponível para este produto para o contrato selecionado é de: "+(this.productContract[this.orderItemObject.Product2.Id]),{ icon: "warning"});
			}else{
				this.orderItemObject.Quantity = qtds;
			}
		} else {
			swal("Insira um valor múltiplo de " + this.orderItemObject.Multiplicity,{ icon: "warning"});
		}
		this.orderItemObject.TotalValueItem = parseFloat(Number(this.orderItemObject.Quantity) * parseFloat(this.orderItemObject.UnitValueWithSevenDecimalCases)).toFixed(2);
		this.setFreigthValueByQuantity();
	}

	handleOnClickSubtrair(event) {
		var differenceValue = parseFloat((this.orderItemObject.Quantity - this.orderItemObject.Multiplicity).toFixed(3));

		if(differenceValue > 0) {
		   if(this.productContract != null && differenceValue > this.productContract[this.orderItemObject.Product2.Id]){
				swal("A quantidade máxima disponível para este produto para o contrato selecionado é de: "+(this.productContract[this.orderItemObject.Product2.Id]),{ icon: "warning"});
			}else{
				this.orderItemObject.Quantity = differenceValue;
			}
		}
		this.orderItemObject.TotalValueItem = parseFloat(Number(this.orderItemObject.Quantity) * parseFloat(this.orderItemObject.UnitValueWithSevenDecimalCases)).toFixed(2);
		this.setFreigthValueByQuantity();
	}

	handleCommitUnitPriceFocusOut(event) {
		var value = event.target.value;
		console.log('value: ' + JSON.stringify(value));
		if(Number(parseFloat(value).toFixed(2)) >= Number(parseFloat(0).toFixed(2))) {
			this.orderItemObject.UnitValue = parseFloat(value).toFixed(2);
			this.orderItemObject.UnitValueWithSevenDecimalCases = parseFloat(value).toFixed(7);
			this.orderItemObject.TotalValueItem  = parseFloat((Number(this.orderItemObject.UnitValueWithSevenDecimalCases) * Number(this.orderItemObject.Quantity)) + Number(this.orderItemObject.Freigth)).toFixed(2);
			var campaignDiscountSum = 0;
			this.orderItemObject.Campaign.forEach(campaign => {
				campaignDiscountSum += campaign.discountPercentage / 100;
			});
			var unitValueWithoutCampaign = parseFloat(this.orderItemObject.UnitValueWithSevenDecimalCases) / (1 - campaignDiscountSum);
			if((Number(unitValueWithoutCampaign) >= Number(this.orderItemObject.PriceList)) == true) {
				var additionPercentage = ((unitValueWithoutCampaign - parseFloat(this.orderItemObject.PriceList)) * 100) / parseFloat(this.orderItemObject.PriceList);
				var additionValue	  = unitValueWithoutCampaign - parseFloat(this.orderItemObject.PriceList);
				this.orderItemObject.DiscountPercent = 0;
				this.orderItemObject.DiscountPercentWithSixDecimalCases   = 0;
				this.orderItemObject.DiscountValue = 0;
				this.orderItemObject.DiscountValueWithSevenDecimalCases = 0;
				this.orderItemObject.AdditionPercent = parseFloat(additionPercentage).toFixed(3);
				this.orderItemObject.AdditionPercentWithSixDecimalCases = parseFloat(additionPercentage).toFixed(6);
				this.orderItemObject.AdditionValue = parseFloat(additionValue).toFixed(2);
				this.orderItemObject.AdditionValueWithSevenDecimalCases = parseFloat(additionValue).toFixed(7);
			} else{
				var discountPercentage = ((parseFloat(this.orderItemObject.PriceList) - unitValueWithoutCampaign ) * 100) / parseFloat(this.orderItemObject.PriceList);
				var discountValue	  = parseFloat(this.orderItemObject.PriceList) - unitValueWithoutCampaign;
				this.orderItemObject.DiscountPercent = parseFloat(discountPercentage).toFixed(3);
				this.orderItemObject.DiscountPercentWithSixDecimalCases   = parseFloat(discountPercentage).toFixed(6);
				this.orderItemObject.DiscountValue   = parseFloat(discountValue).toFixed(2);
				this.orderItemObject.DiscountValueWithSevenDecimalCases = parseFloat(discountValue).toFixed(7);
				this.orderItemObject.AdditionPercent = 0;
				this.orderItemObject.AdditionPercentWithSixDecimalCases = 0;
				this.orderItemObject.AdditionValue = 0;
				this.orderItemObject.AdditionValueWithSevenDecimalCases = 0;
				this.discountNotNegative();
			}

			var listPriceWithInterestAndDiscounts = parseFloat(this.orderItemObject.PriceList) + parseFloat(this.orderItemObject.AdditionValue) - parseFloat(this.orderItemObject.DiscountValue);

			if (this.orderItemObject.Campaign.length > 0) {
				let totalDiscount = 0;
				this.orderItemObject.Campaign.forEach(campaign => {
					campaign.discountValue = (campaign.discountPercentage / 100) * listPriceWithInterestAndDiscounts;
					campaign.fixedPrice = listPriceWithInterestAndDiscounts - (campaign.discountPercentage * listPriceWithInterestAndDiscounts);
					totalDiscount += campaign.discountValue;
				});
				this.campaignDiscountValue = totalDiscount;
				this.campaignDiscountPercentage = totalDiscount ? ((totalDiscount * 100) / (parseFloat(this.orderItemObject.UnitValue) + totalDiscount)) : 0;
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
		this.recalculateMargin();
	}
	contractProducts(product) {
		console.log('productOrderItem: ' + JSON.stringify(product));
	   this.productWithContract = product;
	}

	handleCommitAdditionValue(event) {
		var value = parseFloat(event.target.value);
		if(parseFloat(this.orderItemObject.DiscountPercent) > 0) {
			var event = {"target": {"value": "0"}};
			this.handleCommitDiscountPercentFocusOut(event);
		}

		if(value >= 0) {
			this.orderItemObject.AdditionValue						= value;
			this.orderItemObject.AdditionValueWithSevenDecimalCases   = parseFloat(parseFloat(value).toFixed(7));
			var totalDiscount = 0;
			this.orderItemObject.Campaign.forEach(campaign => {
				totalDiscount += (campaign.discountPercentage / 100) * (parseFloat(this.orderItemObject.PriceList) + parseFloat(this.orderItemObject.AdditionValue));
			});
			var listPriceWithInterestAndDiscounts = parseFloat(this.orderItemObject.PriceList) + parseFloat(this.orderItemObject.AdditionValue);
			this.orderItemObject.UnitValue = parseFloat((parseFloat(listPriceWithInterestAndDiscounts) - totalDiscount).toFixed(2));
			this.orderItemObject.UnitValueWithSevenDecimalCases = parseFloat((parseFloat(listPriceWithInterestAndDiscounts) - totalDiscount).toFixed(7));
			let baseValue											 = this.orderItemObject.InterestListValue == null ? parseFloat(this.orderItemObject.PriceListWithoutInterest).toFixed(this.interestPlaces) : this.getInterestValue(this.orderItemObject.PriceListWithoutInterest);
			this.orderItemObject.AdditionPercent					  = parseFloat(((this.orderItemObject.AdditionValue * 100) / parseFloat(baseValue)).toFixed(3));
			this.orderItemObject.AdditionPercentWithSixDecimalCases   = parseFloat(((this.orderItemObject.AdditionValue * 100) / parseFloat(baseValue)).toFixed(6));
			let newUnitPrice										  = parseFloat(baseValue) + value;
			// this.orderItemObject.PriceList							= parseFloat(baseValue) + value;
			//this.orderItemObject.UnitValueWithSevenDecimalCases	   = parseFloat(newUnitPrice).toFixed(7);
			//this.orderItemObject.UnitValue							= parseFloat(newUnitPrice).toFixed(2);
			this.orderItemObject.TotalValueItem					   = parseFloat(parseFloat(this.orderItemObject.UnitValueWithSevenDecimalCases) * parseFloat(this.orderItemObject.Quantity).toFixed(2));
			this.campaignDiscountValue = totalDiscount;
			this.campaignDiscountPercentage = totalDiscount ? ((totalDiscount * 100) / (parseFloat(this.orderItemObject.UnitValue) + totalDiscount)) : 0;
		} else {
			let oldValue = parseFloat(this.cloneObj(this.orderItemObject.AdditionPercent));
			this.orderItemObject.AdditionValue = value ? value : 0;
			this.orderItemObject.AdditionPercent = value ? value : 0;
			swal("Insira um valor válido entre 0 e 100",{ icon: "warning"}).then((action) => {
				this.orderItemObject.AdditionPercent = oldValue;
			});
		}
		this.recalculateMargin();
	}

	handleCommitAdditionPercent(event) {
		var value = parseFloat(event.target.value);
		if(parseFloat(this.orderItemObject.DiscountPercent) > 0) {
			var event = {"target": {"value": "0"}};
			this.handleCommitDiscountPercentFocusOut(event);
		}
		if(value >= 0) {
			this.orderItemObject.AdditionPercent = parseFloat(parseFloat(value).toFixed(3));;
			this.orderItemObject.AdditionPercentWithSixDecimalCases = parseFloat(parseFloat(value).toFixed(6));

			var unitPrice = parseFloat(this.orderItemObject.PriceList) + (parseFloat(this.orderItemObject.PriceList) * (this.orderItemObject.AdditionPercent / 100));
			var addition = parseFloat(unitPrice) - parseFloat(this.orderItemObject.PriceList);
			var totalDiscount = 0;
			this.orderItemObject.Campaign.forEach(campaign => {
				totalDiscount += (campaign.discountPercentage / 100) * (parseFloat(this.orderItemObject.PriceList) + addition);
			});
			var listPriceWithInterestAndDiscounts = parseFloat(this.orderItemObject.PriceList) + addition;
			this.orderItemObject.UnitValue		= parseFloat((parseFloat(listPriceWithInterestAndDiscounts) - totalDiscount).toFixed(2));
			this.orderItemObject.UnitValueWithSevenDecimalCases = parseFloat((parseFloat(listPriceWithInterestAndDiscounts) - totalDiscount).toFixed(7));

			let baseValue											 = this.orderItemObject.InterestListValue == null ? parseFloat(this.orderItemObject.PriceListWithoutInterest).toFixed(this.interestPlaces) : this.getInterestValue(this.orderItemObject.PriceListWithoutInterest);
			let newUnitPrice										  = parseFloat((parseFloat(baseValue) * (1 + (value/100))).toFixed(7));
			// this.orderItemObject.PriceList						 = parseFloat((parseFloat(baseValue) * (1 + (value/100))).toFixed(7));
			//this.orderItemObject.UnitValue							= parseFloat(newUnitPrice).toFixed(2);
			this.orderItemObject.AdditionValue						= parseFloat((parseFloat(newUnitPrice) - baseValue).toFixed(2));
			this.orderItemObject.AdditionValueWithSevenDecimalCases   = parseFloat((parseFloat(newUnitPrice) - baseValue).toFixed(7));
			//orderItemObject.UnitValueWithSevenDecimalCases	   = parseFloat(newUnitPrice).toFixed(7);
			this.orderItemObject.TotalValueItem					   = parseFloat(parseFloat(this.orderItemObject.UnitValueWithSevenDecimalCases) * parseFloat(this.orderItemObject.Quantity).toFixed(2));
			this.campaignDiscountValue = totalDiscount;
			this.campaignDiscountPercentage = totalDiscount ? ((totalDiscount * 100) / (parseFloat(this.orderItemObject.UnitValue) + totalDiscount)) : 0;
		} else { 
			let oldValue				  = parseFloat(this.cloneObj(this.orderItemObject.AdditionPercent));		   
			this.orderItemObject.AdditionPercent = null;
			swal("Insira um valor válido entre 0 e 100",{ icon: "warning"}).then((action) => {
				this.orderItemObject.AdditionPercent = oldValue;
			});
		}
		this.recalculateMargin();
	}

	handleCommitDiscountPercentFocusOut(event) {
		var value = event.target.value;

		if(parseFloat(this.orderItemObject.AdditionPercent) > 0) {
			var event = {"target": {"value": "0"}};
			this.handleCommitAdditionPercent(event);
		}

		if(Number(parseFloat(event.target.value).toFixed(3)) >= Number(parseFloat(0).toFixed(3)) && Number(parseFloat(value).toFixed(3)) <= Number(parseFloat(100).toFixed(3))) {
			this.orderItemObject.DiscountPercent = parseFloat(parseFloat(value).toFixed(3));
			this.orderItemObject.DiscountPercentWithSixDecimalCases = parseFloat(parseFloat(value).toFixed(6));
			var unitPrice = parseFloat(this.orderItemObject.PriceList) - (parseFloat(this.orderItemObject.PriceList) * (this.orderItemObject.DiscountPercent / 100));
			var discountValue = this.orderItemObject.PriceList - unitPrice;
			var totalDiscount = 0;
			this.orderItemObject.Campaign.forEach(campaign => {
				totalDiscount += (campaign.discountPercentage / 100) * (parseFloat(this.orderItemObject.PriceList) - discountValue);
			});
			var listPriceWithInterestAndDiscounts = parseFloat(this.orderItemObject.PriceList) - discountValue;
			this.orderItemObject.UnitValue	   = parseFloat(parseFloat(listPriceWithInterestAndDiscounts - totalDiscount).toFixed(2));
			this.orderItemObject.UnitValueWithSevenDecimalCases = parseFloat(parseFloat(listPriceWithInterestAndDiscounts - totalDiscount).toFixed(7));
			this.orderItemObject.TotalValueItem  = parseFloat((Number(this.orderItemObject.UnitValueWithSevenDecimalCases) * Number(this.orderItemObject.Quantity)) + Number(this.orderItemObject.Freigth).toFixed(2));
			this.orderItemObject.DiscountValue   = parseFloat((parseFloat(this.orderItemObject.PriceList) - listPriceWithInterestAndDiscounts).toFixed(2));
			this.orderItemObject.DiscountValueWithSevenDecimalCases = parseFloat((parseFloat(this.orderItemObject.PriceList) - listPriceWithInterestAndDiscounts).toFixed(7));
			this.campaignDiscountValue = totalDiscount;
			this.campaignDiscountPercentage = totalDiscount ? ((totalDiscount * 100) / (parseFloat(this.orderItemObject.UnitValue) + totalDiscount)) : 0;
		} else {
			var oldvalue = parseFloat(JSON.parse(JSON.stringify(this.orderItemObject.DiscountPercent))).toFixed(3);
			this.orderItemObject.DiscountPercent = null;
			swal("Percentual de Desconto não pode ser maior do que 100% nem menor que 0%.",{ icon: "warning"}).then((action) => {this.orderItemObject.DiscountPercent = oldvalue;});
		}
		this.recalculateMargin();
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
			this.orderItemObject.DiscountValue   = value ? value : 0;
			this.orderItemObject.DiscountValueWithSevenDecimalCases = value ? value : 0;
			//var discountPercentage = this.orderItemObject.PriceList > 0 ? (this.orderItemObject.DiscountValue * 100) / this.orderItemObject.DiscountValue : 0;
			var totalDiscount = 0;
			this.orderItemObject.Campaign.forEach(campaign => {
				totalDiscount += (campaign.discountPercentage / 100) * (this.orderItemObject.PriceList - parseFloat(this.orderItemObject.DiscountValue));
			});
			var listPriceWithInterestAndDiscounts = this.orderItemObject.PriceList - parseFloat(this.orderItemObject.DiscountValue);
			this.orderItemObject.UnitValue	   = parseFloat(parseFloat(listPriceWithInterestAndDiscounts - totalDiscount).toFixed(2));
			this.orderItemObject.UnitValueWithSevenDecimalCases = parseFloat(parseFloat(listPriceWithInterestAndDiscounts - totalDiscount).toFixed(7));
			this.orderItemObject.DiscountPercent = parseFloat(((100 * parseFloat(this.orderItemObject.DiscountValue)) / this.orderItemObject.PriceList)).toFixed(3);
			this.orderItemObject.DiscountPercentWithSixDecimalCases   = parseFloat(((100 * parseFloat(this.orderItemObject.DiscountValue)) / this.orderItemObject.PriceList)).toFixed(6);
			this.orderItemObject.TotalValueItem  = parseFloat((Number(this.orderItemObject.UnitValueWithSevenDecimalCases) * Number(this.orderItemObject.Quantity)) + Number(this.orderItemObject.Freigth)).toFixed(2);
			this.campaignDiscountValue = totalDiscount;
			this.campaignDiscountPercentage = totalDiscount ? ((totalDiscount * 100) / (parseFloat(this.orderItemObject.UnitValue) + totalDiscount)) : 0;
		}
		this.discountNotNegative();
		this.recalculateMargin();
	}

	handleNewRecordCulture(event) {
		var record = {};
		record	 = event?.detail || event?.detail?.value;
		if(record.record != null) {
			this.orderItemObject.Culture = record.record;
		} else {
			this.orderItemObject.Culture = null;
		}
		this.getDelimitedLandData();
	}

	async getDelimitedLandData() {
		await getDelimitedLand({accId : this.orderObject.ShippingAccount.Id, CropId : this.orderObject.Crop.Id, cultureId : this.orderItemObject?.Culture?.Id}).then(data => {
			if(data) {
				this.hasDelimitedLand		= data.hasDelimitedLand;
				this.totalcultureMeters	  = data.totalcultureMeters;
				this.hasDelimitedLandCulture = data.hasDelimitedLandCulture;
				this.cultureName			 = data.cultureName;
				this.cultureMeters		   = data.cultureMeters;
				this.delimitedLandMeters	 = data.delimitedLandMeters;
			} else {
				this.hasDelimitedLand		= false;
				this.totalcultureMeters	  = 0;
				this.hasDelimitedLandCulture = false;
				this.cultureName			 = '-';
				this.cultureMeters		   = 0;
				this.delimitedLandMeters	 = 0;
			}
		}).catch(error => {
		  console.log('error: ' + JSON.stringify(error));
		});
	}
	async getInterestTable() {
		await this.refreshApexGetInterestListDataRefreshed();
		await getInterestListData({priceData: this.interestListData}).then(data => {
			if(data) {
				console.log('data1 Interest OrderItemJS: ' + JSON.stringify(data));
				this.interestTable = this.cloneObj(data);
				this.setLabelInterest(this.interestTable);
			} else {
				console.log('data2 Interest OrderItemJS: ' + JSON.stringify(data));
				this.interestTable = null;
			}
		  }).catch(error => {
			console.log('error: ' + JSON.stringify(error));
			this.interestTable = null;
		  });
	}

	setLabelInterest(value) {
		if(value.RecordType.DeveloperName == 'ZDJ1') {
			this.orderItemObject.InterestListValueName = 'Desconto de Antecipação (Unitário)';
		} else {
			this.orderItemObject.InterestListValueName = 'Juros Unitário';
		}
	}

	setValueInterestList() {
		var paymentDate		= new Date(this.orderObject.DueDate);
		var effectiveDate	  = new Date(this.orderItemObject.ListPrice.EffectiveDate);

		if(paymentDate.getTime() < effectiveDate.getTime()) {
			return 'ZDJ1';
		}
		else if(paymentDate.getTime() > effectiveDate.getTime()) {
			return 'ZJ01';
		} else {
			return 'ZJ01';
		}
	}

	setFreigthValue(value) {
		this.orderItemObject.FreigthData = value;
		if(this.orderObject.Currency == 'BRL') {
			if(this.orderItemObject.Product2.GrossWeightUnity__c == 'KG') {
				this.orderItemObject.Freigth = parseFloat((Number(this.orderItemObject.Product2.GrossWeight__c) * Number(this.orderItemObject.Quantity) * Number(this.orderItemObject.FreigthData.ValuePerTon__c)) / 1000).toFixed(2);
			} else if (this.orderItemObject.Product2.GrossWeightUnity__c == 'TO') {
				this.orderItemObject.Freigth = parseFloat(Number(this.orderItemObject.Product2.GrossWeight__c) * Number(this.orderItemObject.Quantity) * Number(this.orderItemObject.FreigthData.ValuePerTon__c)).toFixed(2);
			}
		} else if(this.orderObject.Currency == 'USD') {
			if(this.orderItemObject.Product2.GrossWeightUnity__c == 'KG') {
				this.orderItemObject.Freigth = parseFloat((Number(this.orderItemObject.Product2.GrossWeight__c) * Number(this.orderItemObject.Quantity) * Number(this.orderItemObject.FreigthData.ValuePerTonDolar__c)) / 1000).toFixed(2);
			} else if (this.orderItemObject.Product2.GrossWeightUnity__c == 'TO') {
				this.orderItemObject.Freigth = parseFloat(Number(this.orderItemObject.Product2.GrossWeight__c) * Number(this.orderItemObject.Quantity) * Number(this.orderItemObject.FreigthData.ValuePerTonDolar__c)).toFixed(2);
			}
		}
		this.orderItemObject.Freigth = this.orderItemObject.Freigth * parseFloat(this.orderItemObject.Multiplicity.toFixed(3));
		this.orderItemObject.TotalValueItem  = parseFloat(parseFloat(this.orderItemObject.TotalValueItem) + parseFloat(this.orderItemObject.Freigth)).toFixed(2);
	}

	setFreigthValueByQuantity() {
		if(this.orderItemObject.Freigth != null && this.orderItemObject.Freigth != parseFloat(0).toFixed(2)) {
			if(this.orderObject.Currency == 'BRL') {
				if(this.orderItemObject.Product2.GrossWeightUnity__c == 'KG') {
					this.orderItemObject.Freigth = parseFloat((Number(this.orderItemObject.Product2.GrossWeight__c) * Number(this.orderItemObject.Quantity) * Number(this.orderItemObject.FreigthData.ValuePerTon__c)) / 1000).toFixed(2);
				} else if (this.orderItemObject.Product2.GrossWeightUnity__c == 'TO') {
					this.orderItemObject.Freigth = parseFloat(Number(this.orderItemObject.Product2.GrossWeight__c) * Number(this.orderItemObject.Quantity) * Number(this.orderItemObject.FreigthData.ValuePerTon__c)).toFixed(2);
				}
			} else if(this.orderObject.Currency == 'USD') {
				if(this.orderItemObject.Product2.GrossWeightUnity__c == 'KG') {
					this.orderItemObject.Freigth = parseFloat((Number(this.orderItemObject.Product2.GrossWeight__c) * Number(this.orderItemObject.Quantity) * Number(this.orderItemObject.FreigthData.ValuePerTonDolar__c)) / 1000).toFixed(2);
				} else if (this.orderItemObject.Product2.GrossWeightUnity__c == 'TO') {
					this.orderItemObject.Freigth = parseFloat(Number(this.orderItemObject.Product2.GrossWeight__c) * Number(this.orderItemObject.Quantity) * Number(this.orderItemObject.FreigthData.ValuePerTonDolar__c)).toFixed(2);
				}
			}
			this.orderItemObject.Freigth = this.orderItemObject.Freigth * parseFloat(this.orderItemObject.Multiplicity.toFixed(3));
			this.orderItemObject.TotalValueItem  = parseFloat((parseFloat(this.orderItemObject.TotalValueItem) + parseFloat(this.orderItemObject.Freigth))).toFixed(2);
		}
	}

	async getFreigthValue() {
		this.showLoading(true);
		if(this.orderObject.RecordType != "IndustryBonification" && this.orderObject.RecordType != "Bonification") {
			await this.refreshApexGetFreigthRefreshed();
			if(this.orderObject.ShippingAccount.hasOwnProperty("InternShippingCity__c")) {
				await getFreigth({destinationCityId: this.orderObject.ShippingAccount.InternShippingCity__c, sourceCityId: this.orderObject.SalesTeam.DistributionCenter__r.City__c, product2Id: this.orderItemObject.Product2.Id}).then(data => {
					console.log('Data freigth: ' + JSON.stringify(data));
					if(data != null) {
						this.setFreigthValue(data);
					} else {
						this.orderItemObject.Freigth = parseFloat(0).toFixed(2);
						this.orderItemObject.FreigthMode = 'FOB';
						this.checkFreightFOB = true;
						this.checkFreightCIF = false;
						this.checkFreightFCA = false;
					}
				}).catch(error => {
					console.log('Erro: ' + JSON.stringify(error));
					swal("Erro: " + JSON.stringify(error.body.message),{ icon: "warning"}).then((action) => {});
				});
			} else {
				this.orderItemObject.Freigth = parseFloat(0).toFixed(2);
			}
			if(this.orderItemObject.FreigthMode != 'FOB'){
				this.orderItemObject.FreigthMode = 'CIF';
			}
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

	getDifferentValueBetweenDates() {
		var Difference_In_Time = 0;
		var Difference_In_Days = 0;
		var paymentDate		= new Date(this.orderObject.DueDate);
		var effectiveDate	  = new Date(this.orderItemObject.ListPrice.EffectiveDate);

		if(this.orderItemObject.ListPrice != undefined){

			this.listDay		   = this.orderItemObject.ListPrice.EffectiveDate ? new Date(this.orderItemObject.ListPrice.EffectiveDate).getDate()+1 : null;

			this.listMonth		 = this.orderItemObject.ListPrice.EffectiveDate ? new Date(this.orderItemObject.ListPrice.EffectiveDate).getMonth()+1 : null;

			this.listYear		  = this.orderItemObject.ListPrice.EffectiveDate ? new Date(this.orderItemObject.ListPrice.EffectiveDate).getFullYear() : null;

			this.showListPriceDate = this.orderItemObject.ListPrice.EffectiveDate ? true : false;

			if(this.listDay != null) this.padLeadingZeros();

		}
		console.log('effectiveDate: ' + JSON.stringify(effectiveDate));

		console.log('paymentDate: ' + JSON.stringify(paymentDate));

		if(paymentDate.getTime() < effectiveDate.getTime()) {
			Difference_In_Time = Number(effectiveDate.getTime() - paymentDate.getTime());
			Difference_In_Days = Number(Difference_In_Time / (1000 * 3600 * 24));
		}
		else if(paymentDate.getTime() > effectiveDate.getTime()) {
			Difference_In_Time = Number(paymentDate.getTime() - effectiveDate.getTime());
			Difference_In_Days = Number(Difference_In_Time / (1000 * 3600 * 24));
		} else if(paymentDate.getTime() == effectiveDate.getTime()) {
			Difference_In_Days = 0;
		}
		console.log('Difference_In_Days: ' + JSON.stringify(Difference_In_Days));
		return Difference_In_Days;
	}

	async getListPrice() {
		this.showLoading(true);
		this.priceListData = {
		"customerGroup": this.orderObject.CustomerGroup,
		"activitySector": this.orderObject.ActivitySector,
		"accountId": this.orderObject.Account.Id,
		"salesTeamId": this.orderObject.SalesTeam.Id,
		"cropId": this.orderObject.Crop.Id,
		"salesCondition": this.orderObject.SalesCondition,
		"currencys": this.orderObject.Currency};
		this.priceListDataJsonStrg = JSON.stringify(this.priceListData);
		console.log('this.priceListData: ' + JSON.stringify(this.priceListData));
		console.log('getListPrice: this.orderItemObject:' +JSON.stringify(this.orderItemObject));
		await this.refreshApexGetListPriceRefreshed();

		await getListPriceData({priceDatas: JSON.stringify(this.priceListData)}).then(data => {
			if(data) {
				console.log('data1: ' + JSON.stringify(data));
				this.priceData   = this.cloneObj(data.priceData);
				this.idsProducts = Object.keys(this.priceData);
				console.log('this.idsProducts: ' + JSON.stringify(this.idsProducts));
			} else {
				console.log('data2: ' + JSON.stringify(data));
			}
		}).catch(error => {
			console.log('error: ' + JSON.stringify(error));
			this.showLoading(false);
			if(error != null){
				swal("Erro: " + JSON.stringify(error.body.message),{ icon: "warning"}).then((action) => {});
			}
		});
		if(this.productWithContract == true && this.orderItemObject.Product2 != null) this.contractInfoEdit();
		this.showLoading(false);
	}

	async contractInfoEdit(){
		await getContractInfo({orderId: this.orderObject.ContractProduct.Id, productId: this.orderItemObject.Product2.Id }).then(data => {
			if(data) {
				console.log('data: ' + JSON.stringify(data));
				this.orderItemObject.ContractProductCredit			  = data.ContractProductCredit__c;
			}
		});
		this.showContract = true;
	}

	discountNotNegative(){
		if(this.orderItemObject.DiscountPercent < 0)					this.orderItemObject.DiscountPercent = 0;
		if(this.orderItemObject.DiscountPercentWithSixDecimalCases < 0) this.orderItemObject.DiscountPercentWithSixDecimalCases = 0;
		if(this.orderItemObject.DiscountValue < 0)					  this.orderItemObject.DiscountValue = 0;
		if(this.orderItemObject.DiscountValueWithSevenDecimalCases < 0) this.orderItemObject.DiscountValueWithSevenDecimalCases = 0;
	}

	checkBonificationState() {
		if((this.orderObject.RecordType == "IndustryBonification" || this.orderObject.RecordType == "Bonification")) {
			this.disabledProductFieldsBonification  = true;
		} else {
			if(this.context == '_isView_') {
				this.disabledProductFieldsBonification  = true;
			} else {
				this.disabledProductFieldsBonification  = false;
			}
		}
	}

	padLeadingZeros() {
		if(this.listDay < 10){
			this.listDay = "0" + this.listDay;
		}
		if(this.listMonth < 10){
			this.listMonth = "0" + this.listMonth;
		}
	}

	@api
	setDisableProduct2(value){
		this.disabledProduct2 = value;
	}
	@api
	getContractQuantity(){
		return this.productContractQuantity;
	}
	@api
	getOrderItemObject(){
		return this.cloneObj(this.orderItemObject);
	}

	async checkInventoryUnit(){
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
					this.orderItemObject.hasInventory = true;
					this.orderItemObject = this.handleInventoryCheck(this.orderItemObject, inventory, this.orderObject.Status);
					if(this.orderItemObject.Block){
						this.containInventoryError = true;
					}
					else {
						this.containInventoryError = false;
					}
				}
				else {
					this.orderItemObject = this.handleNullStock(this.orderItemObject);
					this.orderItemObject.hasInventory = false;
				}
			}
		}).catch(error => {
			this.showLoading(false);
			if (error != null) {
				swal("Erro: " + JSON.stringify(error.body.message),{ icon: "warning"}).then((action) => {});
			}
		});
	}

	handleInventoryCheck = (ordItem, inventory, status) => {
		ordItem.hasInventory = true;
		if(inventory.Block){
			ordItem.BorderColor = 'card card-lista-pedido border-danger';
			ordItem.Block = inventory.Block;
			ordItem.ShowErrorDetails = true;
		}
		else{
			ordItem.ShowErrorDetails = false;
			ordItem.Block = false;
			ordItem.BorderColor = 'card card-lista-pedido border-primary';
		}
		ordItem.stockQuantity = inventory.Quantity;
		if (inventory.Quantity < ordItem.Quantity && inventory.Block) {
			ordItem.Block = true;
			ordItem.ShowErrorDetails = true;
			if(status == 'Retorna RTV'){
				ordItem.hasInventoryError = false;
				ordItem.hasInventoryErrorRTV = true;
			}
			else {
				ordItem.hasInventoryError = true;
				ordItem.hasInventoryErrorRTV = false;
			}
		} else {
			ordItem.Block = false;
			ordItem.ShowErrorDetails = false;
			ordItem.BorderColor = 'card card-lista-pedido border-primary';
			ordItem.hasInventoryError = false;
		}

		if (ordItem.Block) {
			ordItem.showBlockMessage = true;
			ordItem.showInventoryErrorMessage = false;
		}
		else if (!ordItem.Block && (ordItem.hasInventoryError || ordItem.hasInventoryErrorRTV)) {
			ordItem.showBlockMessage = false;
			ordItem.showInventoryErrorMessage = true;
		}
		return ordItem;
	}

	handleNullStock = (ordItem) => {
		ordItem.hasInventory = false;
		ordItem.stockQuantity = null;
		ordItem.ShowErrorDetails = false;
		ordItem.Block = false;
		ordItem.showBlockMessage = false;
		ordItem.showInventoryErrorMessage = false;
		ordItem.stockMeasure = null;
		ordItem.hasInventoryErrorRTV = false;
		ordItem.hasInventoryError = false;
		return ordItem;
	}

	nullOrderItemObject() {
		this.disabledProductFields								= true;
		this.orderItemObject.Product2							 = null;
		this.orderItemObject.UnitValue							= null;
		this.orderItemObject.UnitValueWithSevenDecimalCases	   = null;
		this.orderItemObject.TotalValueItem					   = null;
		this.orderItemObject.DiscountPercent					  = null;
		this.orderItemObject.DiscountPercentWithSixDecimalCases   = null;
		this.orderItemObject.DiscountValue						= null;
		this.orderItemObject.Quantity							 = null;
		this.orderItemObject.PriceList							= null;
		this.orderItemObject.ListPrice							= null;
		this.orderItemObject.Freigth							  = null;
		this.orderItemObject.Family							   = null;
		this.orderItemObject.Culture							  = null;
		this.orderItemObject.ShippingDivision					 = [];
		this.orderItemObject.Campaign							 = [];
		this.orderItemObject.InternShippingCity				   = null;
		this.orderItemObject.FreigthMode						  = null;
		this.familyId											 = null;
		this.orderItemObject.InterestListValue					= null;
		this.orderItemObject.PriceListWithoutInterest			 = null;
		this.orderItemObject.InterestList						 = null;
		this.orderItemObject.QuantityUnitOfMeasure				= null;
		this.orderItemObject.Id								   = null;
		this.orderItemObject.DiscountValueWithSevenDecimalCases	= null;
		this.orderItemObject.AdditionValue						= null;
		this.orderItemObject.stockQuantity						= null;
		this.orderItemObject.AdditionValueWithSevenDecimalCases   = null;
		this.orderItemObject.AdditionPercent					  = null;
		this.orderItemObject.AdditionPercentWithSixDecimalCases = null;
		this.orderItemObject.Campaign = [];
		
		this.orderItemObject.hasCampaign = false;
		this.orderItemObject.hasInventory = false;
		this.orderItemObject.stockQuantity = null;
		this.orderItemObject.ShowErrorDetails = false;
		this.orderItemObject.Block = false;
		this.orderItemObject.showBlockMessage = false;
		this.orderItemObject.showInventoryErrorMessage = false;
		this.orderItemObject.stockMeasure = null;
		this.orderItemObject.hasInventoryErrorRTV = false;
		this.orderItemObject.hasInventoryError = false;

		this.productSelected = false;
		this.showContract = false;
		this.hasInventory = false;
		this.stockQuantity = null;
		this.QuantityUnitOfMeasure = null;
	}

	cloneObj(obj) {
		return JSON.parse(JSON.stringify(obj));
	}

	isDecimal(num) {
		return (num % 1) !== 0;
	}

	showLoading(show) {
		this.loading = show;
	}
}