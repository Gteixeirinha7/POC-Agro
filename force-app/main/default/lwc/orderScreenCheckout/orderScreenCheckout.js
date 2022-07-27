import { LightningElement, api, track } from 'lwc';
import Images from '@salesforce/resourceUrl/AllImagesScreenOrder';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createOrderScreen from '@salesforce/apex/CreateOrderController.createOrderScreen';
import getCampaign from '@salesforce/apex/CampaignController.getCampaign';
import getCampaignById from '@salesforce/apex/CampaignController.getCampaignById';
import StockError from '@salesforce/label/c.StockError';

export default class OrderScreenCheckout extends LightningElement {

	cIRemove = Images + '/AllImagesScreenOrder/ic-times-red.svg';
	cIArrowDown = Images + '/AllImagesScreenOrder/ic-arrow-down.svg';

	@api orderType;
	@api imagePaper;
	@api imageMoneyCheck;
	@api imageCheck;
	@api imageBack;
	@api imageContinueBlue;
	@api imagePlusCircle;
	@api imageDelete;
	@api imageEdit;
	@api imageView;
	@api showCampaignModal;
	@api orderObject;
	// @api clienteId;
	@api disabledReturnSap;
	@api disableLastPageProducts;
	@api disableRouteField;
	@api viewProduct;
	@api currencyScreenFormat;
	@api showTotalQuantity;
	haveAddition = false;
	@api authorityArray;
	@api finAuthority;
	@api mktAuthority;
	@api hideConclude;
	@api disableConclude;
	@api hideSave;
	@api documentId;
	@api strProductsName;
	@api showBarterContractField;
	@api isRefuseReason;
	@api refuseReasonMargin;
	@track campaignList;
	@track productId;
	@track familyId;
	@track manufacturer;
	@track comercialName;
	@track filtered = false;

	@track showRoute;
	@track route;

	@api targetCampaign;
	@api newOrderValues;
	@api removeCampaignValues;

	loading = false;
	orderRequest;

	connectedCallback() {
		this.showRoute = !(this.orderObject.RecordType == "BarterSale" || this.orderObject.RecordType == 'ZCNO' || this.orderObject.RecordType == 'ZCEF' || this.orderObject.RecordType == 'ZCCO') && 
						 this.orderObject.OrderItem.find(
							 item => (item.FreigthMode == 'CIF' || item.FreigthMode == 'FOB') && (item.Family.Name.includes('FERTILIZANTES-GRANULADOS') || item.Family.Name.includes('SEMENTES DE SOJA'))
						 );
		this.route = this.showRoute ? (this.orderObject.Route ? this.orderObject.Route : '') : '';
		console.log('connectedCallback: this.orderObject: ' +JSON.stringify(this.orderObject));
	}

	onClickShowPedidoStep1ByPriceCar(event) {
		var value = this.orderObject.OrderItem.length > 0;
		this.dispatchEvent(new CustomEvent('clickshowpedidostepbypricecar', {detail: value}));

		if(this.orderObject.RecordType == 'BarterSale') {
			this.dispatchEvent(new CustomEvent('getpaymentformpicklistvalues'));
		}
		else {
			this.dispatchEvent(new CustomEvent('getpaymentform', {detail: this.orderObject.PaymentCondition.Id}));
		}
		this.dispatchEvent(new CustomEvent('showscreen', {detail: "Step01"}));
	}

	onClickShowPedidoStep2aByCarScreenExclude(event) {
		var value = event.currentTarget.dataset.productId;
		swal("Deseja realmente excluir este produto?",
		{ icon: "warning", buttons: true }).then((action) => {
			if (action) {
				this.dispatchEvent(new CustomEvent('deleteproduct', {detail: value}));
			}
		});
	}

	onClickShowPedidoStep2aByCarScreenEdit(event) {
		var value = event.currentTarget.dataset.productId;
		this.dispatchEvent(new CustomEvent('clickshowpedidostep2abycarscreenedit', {detail: value}));
		this.dispatchEvent(new CustomEvent('showscreen', {detail: "Step2a"}));
	}

	onClickShowPedidoStep2aByCarScreenView(event) {
		var value = event.currentTarget.dataset.productId;
		this.dispatchEvent(new CustomEvent('clickshowpedidostep2abycarscreenview', {detail: value}));
		this.dispatchEvent(new CustomEvent('showscreen', {detail: "Step2a"}));
	}

	onClickShowPedidoStep2aByCarScreen(event) {
		this.dispatchEvent(new CustomEvent('clickshowpedidostep2abycarscreen'));
		this.dispatchEvent(new CustomEvent('showscreen', {detail: "Step2a"}));
	}

	checkTotalValue(){
		var value = this.orderObject.BarterType == 'Financeiro' ? this.orderObject.StrikePrice: this.orderObject.CommUnitPrice;
		if(Math.ceil(Number(parseFloat(this.orderObject.TotalPriceOrder).toFixed(2))/parseFloat(value).toFixed(2)) <= this.orderObject.TotalDeliveryQuantity){
			return false;
		}
		return true;
	}

	async handleConcludeOrder(event) {
		swal("Deseja concluir seu pedido?", { icon: "warning", buttons: true }).then((confirm) => {
			if (confirm){
				this.handleConcludeOrderSwal(event);
			}
			return;
		});
	}

	getType(){
		return (window.sessionStorage.getItem('OrderType') == null ? 'SFOR' : window.sessionStorage.getItem('OrderType'));
	}

	createOrderRequest() {
		console.log('createOrderRequest: ' +JSON.stringify(this.orderObject));
		this.orderRequest = {
			"id": this.orderObject.Id,
			"types" : this.getType(),
			'marginApprover': 'MarginApprover' in this.orderObject ? this.orderObject.MarginApprover : null,
			"salesOrgId": this.orderObject.SalesTeam.SalesOrg__c != null ? this.orderObject.SalesTeam.SalesOrg__c : this.orderObject.SalesOrg,
			"customerGroup": this.orderObject.CustomerGroup,
			"currencys": this.orderObject.Currency, 
			"expirationDate": this.orderObject.ExpirationDate, 
			"paymentDate": this.orderObject.DueDate,
			"activitySector": this.orderObject.ActivitySector,
			"accountId": this.orderObject.Account.Id, 
			"billingLocationId": this.orderObject.BillingAccount.Id, 
			"shippingLocationId": this.orderObject.ShippingAccount.Id, 
			"rtvId": this.orderObject.Rtv.UserId != undefined ? this.orderObject.Rtv.UserId : this.orderObject.Rtv.Id, 
			"salesTeamId": this.orderObject.SalesTeam.Id, 
			"cropId": this.orderObject.Crop.Id,
			"recordTypeDeveloperName": this.orderObject.RecordType,
			"salesCondition": this.orderObject.SalesCondition,
			"observationNF": this.orderObject.Notes, 
			"paymentCondition": this.orderObject.PaymentCondition.Id, 
			"paymentMethod": this.orderObject.PaymentForm,
			"freightType": this.getFreigthTypeOrder(this.orderObject.OrderItem),
			"status": this.orderObject.Status,
			"itens": this.getOrderItemCreateOrderController(this.orderObject.OrderItem),
			"barterType": this.orderObject.BarterType,
			"commodity": this.orderObject.Commodity,
			"shippingCrop": this.orderObject.ShippingCrop != null ? this.orderObject.ShippingCrop.Id : null,
			"billingCrop": this.orderObject.BillingCrop != null ? this.orderObject.BillingCrop.Id : null,
			"grossUnitPrice": this.orderObject.GrossUnitPrice,
			"unitPrice": this.orderObject.CommUnitPrice,
			"commercialMeasureUnit": this.orderObject.CommercialMeasureUnit,
			"commodityShipping": this.orderObject.CommFreigthMode,
			"initialDeliveryDate": this.orderObject.InitialDeliveryDate,
			"endDeliveryDate": this.orderObject.EndDeliveryDate,
			"contractEndDate": this.orderObject.EndContractDate,
			"contractStartDate": this.orderObject.InitialContractDate,
			"totalDeliveryQuantity": this.orderObject.TotalDeliveryQuantity,
			"productionDeliveryLocation": this.orderObject.ProductionDeliveryLocation,
			"productionPickupLocation": this.orderObject.ProductionPickupLocation,
			"strikePrice": this.orderObject.StrikePrice,
			"dueDateFinancial": this.orderObject.FinancialDueDate,
			"trade": this.orderObject.Trade != null ? this.orderObject.Trade : null,
			"contractOrderId": this.orderObject.ContractProduct != null ? this.orderObject.ContractProduct.Id : null,
			"originalOrderId": this.isRefuseReason ? this.orderObject.OriginalOrderId : null,
			"oldOrderCredit": this.isRefuseReason ? this.orderObject.RefusalReasonCredit : null,
			"route": this.showRoute ? this.route : null};
		console.log('createOrderRequest ==> ' +JSON.stringify(this.orderRequest));
	}

	showLoading(show) {
		this.loading = show;
	}

	setIncoterms2(value) {
		return this.orderObject.ShippingAccount.InternShippingCity__r.Name;
	}

	getOrderItemCreateOrderController(orderItemList) {
		try {
			var orderItemArray = [];
			console.log('orderItemList: ' + JSON.stringify(orderItemList));
			for(var i = 0; i < orderItemList.length; i++) {
				var oiObj = {};
				
				// oiObj.cost				   = orderItemList[i].Cost != undefined ? orderItemList[i].Cost : null,
				oiObj.margin				 = orderItemList[i].margin;
				oiObj.projectedMargin		= orderItemList[i].projectedMargin;
				oiObj.familyMargin		   = orderItemList[i].familyMargin;
				oiObj.productId			  = orderItemList[i].Product2.Id;
				oiObj.QuantityUnitOfMeasure  = orderItemList[i].QuantityUnitOfMeasure;
				oiObj.listPriceId			= orderItemList[i].ListPrice.Id;
				oiObj.unitPrice			  = parseFloat(orderItemList[i].UnitValueWithSevenDecimalCases);
				oiObj.listPrice			  = parseFloat(orderItemList[i].PriceListWithoutInterest);
				oiObj.quantity			   = parseFloat(orderItemList[i].Quantity);
				oiObj.freightValue		   = parseFloat(orderItemList[i].Freigth);
				oiObj.freightType			= orderItemList[i].FreigthMode;
				oiObj.discountPercent		= parseFloat(orderItemList[i].DiscountPercentWithSixDecimalCases);
				oiObj.discountValue		  = parseFloat(orderItemList[i].DiscountValueWithSevenDecimalCases);
				oiObj.additionValue		  = parseFloat(orderItemList[i].AdditionValueWithSevenDecimalCases);
				oiObj.additionPercent		= parseFloat(orderItemList[i].AdditionPercentWithSixDecimalCases);
				oiObj.cultureId			  = orderItemList[i].Culture.Id;
				oiObj.LastChangedPriceList   = orderItemList[i].LastChangedPriceList;
				oiObj.Id					 = orderItemList[i].Id;
				oiObj.incoterms1			 = orderItemList[i].FreigthMode;
				oiObj.incoterms2			 = this.orderObject.ShippingAccount.hasOwnProperty("InternShippingCity__c") ? this.setIncoterms2(orderItemList[i].FreigthMode) : null;
				oiObj.status				 = this.orderObject.Status;
				oiObj.destinationCityId	  = this.orderObject.ShippingAccount.hasOwnProperty("InternShippingCity__c") ? this.orderObject.ShippingAccount.InternShippingCity__c : null;
				oiObj.sourceCityId		   = this.orderObject.SalesTeam.DistributionCenter__r.City__c;
				oiObj.interestListPriceId	= orderItemList[i].InterestList != null ? orderItemList[i].InterestList.Id : null;
				oiObj.antecipationDiscount   = orderItemList[i].InterestList != null ? this.setValueInterestAnticipation(orderItemList[i].InterestList) == true ? parseFloat(orderItemList[i].InterestListValue) : null : null;
				oiObj.interestValue		  = orderItemList[i].InterestList != null ? this.setValueInterest(orderItemList[i].InterestList) == true ? parseFloat(orderItemList[i].InterestListValue) : null : null;
				oiObj.interest			   = orderItemList[i].Freigth != parseFloat(0).toFixed(2) ? orderItemList[i].FreigthData.ValuePerTon__c : null;
				oiObj.itens				  = this.getOrderItemShippingDivisionCreateOrderController(orderItemList[i].ShippingDivision);
				oiObj.itensCampaign		  = this.getItemCampaignCreateOrderController(orderItemList[i].Campaign);
				orderItemArray.push(oiObj);
			}
			console.log('orderItemArray: ' + JSON.stringify(orderItemArray));
			return orderItemArray;
		} catch(e) {
			this.showLoading(false);
			swal("Erro: " + e,{ icon: "warning"}).then((action) => {});
		}
	}

	getItemCampaignCreateOrderController(campaign) {
		var campaignArray = [];
		console.log('campaign: ' + JSON.stringify(campaign));

		for(var i = 0; i < campaign.length; i++) {
			var cmpObj			   = {};
			cmpObj.productCampaignId = campaign[i].productId;
			cmpObj.discount		  = parseFloat(campaign[i].discountPercentage);
			cmpObj.Id				= campaign[i].Id;
			cmpObj.campaignId		= campaign[i].campaignId;
			cmpObj.fixedPrice		= campaign[i].fixedPrice;
			cmpObj.hasFixedUnitPrice = campaign[i].hasFixedUnitPrice;
			cmpObj.discountValue	 = campaign[i].discountValue;

			campaignArray.push(this.cloneObj(cmpObj));
		}
		return campaignArray;
	}

	getOrderItemShippingDivisionCreateOrderController(shippingDivision) {
		var shippingDivisionArray = [];
		console.log('shippingDivision: ' + JSON.stringify(shippingDivision));

		for(var i = 0; i < shippingDivision.length; i++) {
			var shipObj		  = {};
			shipObj.deliveryDate = shippingDivision[i].SD.DueDate;
			shipObj.quantity	 = parseFloat(shippingDivision[i].SD.Quantity);
			shipObj.Id		   = shippingDivision[i].SD.Id;
			shippingDivisionArray.push(this.cloneObj(shipObj));
		}
		return shippingDivisionArray;
	}

	setValueInterestAnticipation(value) {
		return value.RecordType.DeveloperName == 'ZDJ1';
	}

	setValueInterest(value) {
		return value.RecordType.DeveloperName == 'ZJ01';
	}

	getFreigthTypeOrder(orderItemList) {
		var mode = 'FOB';
		orderItemList.forEach(function(item) {
			if(item.FreigthMode == 'CIF');
			mode = 'CIF';
			return;
		});
		return mode;
	}

	cloneObj(obj) {
		return JSON.parse(JSON.stringify(obj));
	}

	convertToDate(strDate) {
		return new Date(strDate);
	}

	checkDateSD() {
		var dateToday		= new Date().setUTCHours(0,0,0,0);
		this.strProductsName = [];
		
		for(var i = 0; i < this.orderObject.OrderItem.length; i++) {
			if(this.orderObject.OrderItem[i].ShippingDivision.find(item => this.convertToDate(item.SD.DueDate).getTime() < dateToday)) {
				this.strProductsName.push(this.cloneObj(this.orderObject.OrderItem[i].Product2.Name));
			}
		}
		return this.strProductsName.length > 0;
	}

	checkRefuseReasonMargin() {
		if (this.isRefuseReason) {
			let tolerance = this.orderObject.RefusalReasonCredit * (this.refuseReasonMargin / 100);
			if (this.orderObject.RefusalReasonCredit < (parseFloat(this.orderObject.TotalPriceOrder) - tolerance) ||
				this.orderObject.RefusalReasonCredit > (parseFloat(this.orderObject.TotalPriceOrder) + tolerance)) {
				swal("Saldo de crédito inválido para concluir o pedido", { icon: "warning" });
				this.showLoading(false);
				return false;
			} return true;
		} return true;
	}

	handleTextAreaRoute(event) {
		this.route = event.target.value;
	}

	async handleConcludeOrderSwal(event) {
		var barterError;
		if(this.orderObject.RecordType == 'BarterSale'){
			barterError = this.checkTotalValue();
		}
		var containInvalidCampaign = false;
		this.orderObject.OrderItem.forEach(ordItem => {
			if (ordItem.Campaign.length > 1) {
				if (ordItem.Campaign.find(campaign => campaign.invalid)) {
					containInvalidCampaign = true;
				}
			}
		});
		if (containInvalidCampaign) {
			swal("Uma ou mais campanhas estão inválidas, por favor, verifique os produtos com campanhas com problema para prosseguir.",
				{ icon: 'warning'}
			);
			return;
		}
		if(this.orderObject.OrderItem.find(item => item.hasInvalidCampaign)) {
			swal("Uma ou mais campanhas estão inválidas, por favor, verifique os produtos com campanhas com problema para prosseguir.",
				{ icon: 'warning'}
			);
			return;
		}
		if(this.orderObject.OrderItem.find(item => item.invalidListPrice || item.invalidProduct)) {
			swal("Um ou mais produtos do carrinho não tem lista de preço ou estão bloqueados, por favor, verifique os produtos com problema para prosseguir.",
				{ icon: 'warning'}
			);
			return;
		}
		if(this.orderObject.OrderItem.find(item => (item.hasInventoryError || item.hasInventoryErrorRTV) && item.Block)) {
			swal("Um ou mais produtos do carrinho não tem estoque disponível, por favor, verifique os produtos com problema para prosseguir.",
				{ icon: 'warning'}
			);
			return;
		}
		if(this.orderObject.OrderItem.length == 0 && !this.orderObject.deletedProductSAP) {
			swal("Nenhum produto foi adicionado ao pedido",
				{ icon: 'warning'}
			);
			return;
		}
		if (this.showRoute && !this.route) {
			swal("Para prosseguir, por favor, informe a rota de entrega do pedido.",
				{ icon: 'warning' }
			);
			return;
		}
		if((this.orderObject.Status == 'Em digitação' || this.orderObject.Status == 'Recusado' || this.orderObject.Status == 'Retorna RTV') && !barterError) {
			// this.orderObject.Status = (this.orderObject.RecordType == 'BarterSale' && this.orderObject.Status == 'Em digitação') ? 'Em aprovação grãos' : 'Em aprovação';
			if (this.checkRefuseReasonMargin()) {
				this.dispatchEvent(new CustomEvent('changestatusconcludeorder'));
				this.showLoading(true);
				this.createOrderRequest();
			
				if(!this.checkDateSD()) {
					await createOrderScreen({orderReq: JSON.stringify(this.orderRequest)}).then(data => {
						if(data) {
							console.log('Order created -->\n' +JSON.stringify(data));
							if(!data.hasError) {
								window.sessionStorage.setItem('OrderType', null);
								if(this.orderObject.RecordType == 'BarterSale' && this.documentId != undefined){
									const documentId = this.documentId;
									const recId = data.id;
									uploadBarterTerm({ documentId , recId}).then(result=>{
										this.dispatchEvent(new CustomEvent('uploudbartersetvalues'));
										// this.documentId = undefined,
										// this.hasAttachment = false
									}).catch(error => {
										console.log('ERROR: ' + JSON.stringify(error));
									});
								}
								this.showLoading(false);
								this.dispatchEvent(new CustomEvent('concludeorder'));
								swal("Pedido enviado para aprovação.",{ icon: "success"}).then((action) => {
									// this.navigateToView(data.id);
									this.dispatchEvent(new CustomEvent('navigatetoview', {detail: data.id}));
								});
							} else if(data.hasError) {
								this.showLoading(false);
								swal("Erro: " + data.errorMsg ,{ icon: "warning"}).then((action) => {});
								this.changeStatusOrderToWriting('Em digitação');
							}
						} else {
							console.log('data2: ' + JSON.stringify(data));
							this.changeStatusOrderToWriting('Em digitação');
						}
					}).catch(error => {
						console.log('ERROR: ' + JSON.stringify(error));
						this.showLoading(false);
						swal("Erro: " + JSON.stringify(error.body.message),{ icon: "success"}).then((action) => {});
						this.changeStatusOrderToWriting('Em digitação');
					});
				} else {
					this.showLoading(false);
					swal("Verifique a data das divisões de remessas do produto " + this.strProductsName[0] + " para prosseguir." ,{ icon: "error"}).then((action) => {});
					this.changeStatusOrderToWriting('Em digitação');
				}
			}
		} else if(barterError){ 
			this.showLoading(false);
			swal("O valor Total do Pedido ultrapassou o valor aprovado pela mesa.",{ icon: "warning"}).then((action) => {});
		}else {
			this.showLoading(false);
			swal("O Status deste pedido não pode ser enviado para aprovação.",{ icon: "warning"}).then((action) => {});
		}
	}

	changeStatusOrderToWriting(value) {
		this.dispatchEvent(new CustomEvent('changestatus', {detail: value}));
	}

	async handleSaveOrder(event) {
		if(this.orderObject.OrderItem.find(item => item.invalidListPrice || item.invalidProduct)) {
			swal("Um ou mais produtos do carrinho não tem lista de preço ou estão bloqueados, por favor, verifique os produtos com problema para prosseguir.",
				{ icon: 'warning'}
			);
			return;
		}
		var containInvalidCampaign = false;
		this.orderObject.OrderItem.forEach(ordItem => {
			if (ordItem.Campaign.length > 1) {
				if (ordItem.Campaign.find(campaign => campaign.invalid)) {
					containInvalidCampaign = true;
				}
			}
		});
		if (containInvalidCampaign) {
			swal("Uma ou mais campanhas estão inválidas, por favor, verifique os produtos com campanhas com problema para prosseguir.",
				{ icon: 'warning'}
			);
			return;
		}
		if(this.orderObject.OrderItem.find(item => item.hasInvalidCampaign)) {
			swal("Uma ou mais campanhas estão inválidas, por favor, verifique os produtos com campanhas com problema para prosseguir.",
				{ icon: 'warning'}
			);
			return;
		}
		if(this.orderObject.OrderItem.find(item => (item.hasInventoryError || item.hasInventoryErrorRTV) && item.Block)) {
			swal("Um ou mais produtos do carrinho não tem estoque disponível, por favor, verifique os produtos com problema para prosseguir.",
				{ icon: 'warning'}
			);
			return;
		}
		if(this.orderObject.OrderItem.length == 0 && !this.orderObject.deletedProductSAP) {
			swal("Nenhum produto foi adicionado ao pedido",
				{ icon: 'warning'}
			);
			return;
		}
		if (this.showRoute && !this.route) {
			swal("Para prosseguir, por favor, informe a rota de entrega do pedido.",
				{ icon: 'warning' }
			);
			return;
		}
		this.showLoading(true);
		this.createOrderRequest();
		if (this.checkRefuseReasonMargin()) {
			if(!this.checkDateSD()) { 
				await createOrderScreen({orderReq: JSON.stringify(this.orderRequest)}).then(data => {
					if(data) {
						if(!data.hasError) {
							window.sessionStorage.setItem('OrderType', null);
							this.showLoading(false);
							this.dispatchEvent(new CustomEvent('concludeorder'));
							swal("Pedido "+(this.orderObject.Id != undefined ? 'editado' : 'criado')+" com sucesso.",{ icon: "success"}).then((action) => {
								// this.navigateToView(data.id);
								this.dispatchEvent(new CustomEvent('navigatetoview', {detail: data.id}));
							});
						} else if(data.hasError) {
							this.showLoading(false);
							swal("Erro: " + data.errorMsg ,{ icon: "error"}).then((action) => {});
						}
					} else {
						console.log('data2: ' + JSON.stringify(data));
					}
				}).catch(error => {
					console.log('error: ' + JSON.stringify(error));
					this.showLoading(false);
					swal("Error: " + JSON.stringify(error.body.message),{ icon: "error"}).then((action) => {});
				});
			} else {
				console.log('this.strProductsName: ' + JSON.stringify(this.strProductsName));
				this.showLoading(false);
				swal("Verifique a data das divisões de remessas do produto " + this.strProductsName[0] + " para prosseguir." ,{ icon: "error"}).then((action) => {});
			}
		}
	}

	async onClickShowCampaignModal(){
		await this.getAvailableCampaign();
		this.showCampaignModal = true;
	}

	async onClickShowCampaignModalSpecific(event){
		var value = event.currentTarget.dataset.productId;
		this.productId = value;
		this.setSpecificValues(value);
		this.filtered = true;
		await this.getAvailableCampaign();
		this.filtered = false;
		this.showCampaignModal = true;
	}

	setSpecificValues(productId){
		this.productId = productId;
		var x = null;
		x = this;
		this.orderObject.OrderItem.forEach(function(ordItem) {
			var selectedProduct
			if(ordItem.Product2.Id == x.productId){
				selectedProduct = true;
			}
			if(selectedProduct){
				x.familyId = ordItem.Product2.Family__r.Id;
				x.manufacturer = ordItem.Product2.Manufacturer__c;
				x.comercialName = ordItem.Product2.Brand__c;
			}
		});
	}

	closeModal(){
		this.showCampaignModal = false;
	}

	applyCampaignDiscounts(value){
		this.showLoading(true);

		let orderUpdate = {
			finalPrice: 0,
			finalDiscount: 0,
			orderItem: [],
		};

		var campaignId = value.target.campaignId;
		
		let campaign = this.campaignList.find(campaign => campaign.CampaignId == campaignId);

		if(campaign.invalid){
			this.showLoading(false);
			return;
		}

		// let productsKeys = [];

		// campaign.ProductList.filter(
		//	 item => item.CanReceiveDiscount == true
		// ).forEach(cp => {
		//	 if (cp.Product2 || cp.Family || cp.Manufacturer) {
		//		 productsKeys.push(
		//			 cp.Product2 ? cp.Product2 :
		//			 (cp.Family ? cp.Family  : cp.Manufacturer)
		//		 );
		//	 }
		// });

		var x = null;
		x = this;

		let campaignToAllItens = [];

		this.targetCampaign = campaign.CampaignId;
		this.dispatchEvent(new CustomEvent('removecampaignfromitem'), {bubbles: true});
		//this.orderObject.OrderItem.forEach(item => {
		//	if (item.Campaign.length > 0) {
		//		item.Campaign = item.Campaign.filter(cp => cp.campaignId != campaign.CampaignId);
		//	}
		//});

		this.orderObject.OrderItem.forEach(orderItem => {

				campaign.ProductList = campaign.ProductList ? campaign.ProductList : [];

				var campaignProduct;

				campaign.ProductList.filter(
					item => item.CanReceiveDiscount == true
				).forEach(cp => {
					if (cp.Product2 == orderItem.Product2.Id || cp.Family == orderItem.Product2.Family__c || (cp.Manufacturer != null && cp.Manufacturer != undefined && cp.Manufacturer.toLowerCase() == orderItem.Product2.Manufacturer__c.toLowerCase()) || (cp.ComercialName != null && cp.ComercialName != undefined && cp.ComercialName.toLowerCase() == orderItem.Product2.Brand__c.toLowerCase())) {
						campaignProduct = cp.Id;
					}
				});

				orderItem = x.cloneObj(orderItem);
				//orderItem.Campaign = [];

				let orderItemCampaign = {
					campaignId: campaign.CampaignId,
					name: campaign.Name,
					orderItem: orderItem.code,
					productId: campaignProduct,
					campaignProductId: null,
					fixedPrice: 0,
					discountPercentage: 0,
					discountValue: 0,
					hasDiscountOrder: false,
					hasFixedUnitPrice: false,
					isAccumulative: campaign.Accumulative,
					invalid: false,
				};

				campaign.RulesList.forEach(rule => {
					if (!rule.invalid) {
						if (rule.OrderDiscount) {
							orderItemCampaign.hasDiscountOrder = true;
							if (rule.FixedUnitPrice) {
								orderItemCampaign.fixedPrice = rule.FixedUnitPrice;
								orderItemCampaign.hasFixedUnitPrice = true;
								orderItemCampaign.discountValue = parseFloat(orderItem.PriceList) - rule.FixedUnitPrice;
							} else {
								orderItemCampaign.discountPercentage = rule.Discount;
							}
						} else {

							if (!rule.CampaignProduct || rule.CampaignProduct == undefined) {

								if (rule.FixedUnitPrice) {
									orderItemCampaign.fixedPrice = rule.FixedUnitPrice;
									orderItemCampaign.hasFixedUnitPrice = true;
									orderItemCampaign.discountValue = parseFloat(orderItem.PriceList) - rule.FixedUnitPrice;
								} else {
									orderItemCampaign.discountPercentage = rule.Discount;
								}

								let campaignProduct = campaign.ProductList.find(
									item => (item.Product2 == orderItem.Product2.Id ||
										item.Family == orderItem.Product2.Family__c ||
										(item.Manufacturer != null && item.Manufacturer != undefined && item.Manufacturer.toLowerCase() == orderItem.Product2.Manufacturer__c.toLowerCase()) ||
										(item.ComercialName != null && item.ComercialName != undefined && item.ComercialName.toLowerCase() == orderItem.Product2.Brand__c.toLowerCase()))
								);

								if (campaignProduct) {
									orderItemCampaign.campaignProductId = campaignProduct.Id;
								}
							} else {
								let campaignProduct = campaign.ProductList.find(item => item.Id == rule.CampaignProduct);
								if (campaignProduct.Product2 == orderItem.Product2.Id ||
									campaignProduct.Family == orderItem.Product2.Family__c ||
									(campaignProduct.Manufacturer != null && campaignProduct.Manufacturer != undefined && campaignProduct.Manufacturer.toLowerCase() == orderItem.Product2.Manufacturer__c.toLowerCase()) ||
									(campaignProduct.ComercialName != null && campaignProduct.ComercialName != undefined && campaignProduct.ComercialName.toLowerCase() == orderItem.Product2.Brand__c.toLowerCase())) {
									
									if (rule.FixedUnitPrice) {
										orderItemCampaign.fixedPrice = rule.FixedUnitPrice;
										orderItemCampaign.hasFixedUnitPrice = true;
										orderItemCampaign.discountValue = parseFloat(orderItem.PriceList) - rule.FixedUnitPrice;
									} else {
										orderItemCampaign.discountPercentage = rule.Discount;
									}

									orderItemCampaign.campaignProductId = campaignProduct.Id;
								}
							}
						}
					}
				if((orderItemCampaign.hasFixedUnitPrice && orderItem.Campaign[0]) ||
				   (!orderItemCampaign.hasFixedUnitPrice && orderItem.Campaign.filter(item => item.hasFixedUnitPrice)[0])){
						orderItemCampaign.discountPercentage = 0;
						orderItemCampaign.fixedPrice = 0; 
					}
				});

				let specificCampaignProduct = campaign.ProductList.find(
					item => (item.Product2 == orderItem.Product2.Id ||
							item.Family == orderItem.Product2.Family__c ||
							(item.Manufacturer != null && item.Manufacturer != undefined && item.Manufacturer.toLowerCase() == orderItem.Product2.Manufacturer__c.toLowerCase()) ||
							(item.ComercialName != null && item.ComercialName != undefined && item.ComercialName.toLowerCase() == orderItem.Product2.Brand__c.toLowerCase()))
				); 

				if (campaign.ProductList.length == 0 || (specificCampaignProduct && specificCampaignProduct.CanReceiveDiscount)) {
					if (orderItemCampaign.discountPercentage > 0 || orderItemCampaign.fixedPrice > 0) {
						orderItemCampaign.campaignProduct = campaign.ProductList;
						orderItem.Campaign.push(orderItemCampaign);
					}
				}

				let totalDiscount = 0;
				orderItem.Campaign.forEach(campaign => {

					if (campaign.hasFixedUnitPrice) {
						orderItem.DiscountPercent = 0;
						orderItem.DiscountPercentWithSixDecimalCases = 0;
						orderItem.DiscountValue   = 0;
						orderItem.DiscountValueWithSevenDecimalCases = 0;
						orderItem.AdditionValue   = 0;
						orderItem.AdditionValueWithSevenDecimalCases = 0;
						orderItem.AdditionPercent = 0;
						orderItem.AdditionPercentWithSixDecimalCases = 0;
					}

					var listPriceWithInterestAndDiscounts = parseFloat(orderItem.PriceList) + parseFloat(orderItem.AdditionValueWithSevenDecimalCases) - parseFloat(orderItem.DiscountValueWithSevenDecimalCases);

					if (campaign.hasFixedUnitPrice) {
						totalDiscount += campaign.discountValue;
						campaign.discountPercentage = (campaign.discountValue * 100) / listPriceWithInterestAndDiscounts;
					
					} else {
						totalDiscount += ((campaign.discountPercentage * listPriceWithInterestAndDiscounts) / 100);
						campaign.discountValue = (campaign.discountPercentage * listPriceWithInterestAndDiscounts) / 100;
						campaign.fixedPrice = listPriceWithInterestAndDiscounts - ((campaign.discountPercentage * listPriceWithInterestAndDiscounts)/100);
					}
					if (campaign.hasDiscountOrder) {
						campaignToAllItens.push(orderItemCampaign);
					} else {

					}
				});

				var listPriceWithInterestAndDiscounts = parseFloat(orderItem.PriceList) + parseFloat(orderItem.AdditionValueWithSevenDecimalCases) - parseFloat(orderItem.DiscountValueWithSevenDecimalCases);

				orderItem.UnitValue = parseFloat(parseFloat(listPriceWithInterestAndDiscounts - parseFloat(totalDiscount)).toFixed(2));
				orderItem.UnitValueWithSevenDecimalCases = listPriceWithInterestAndDiscounts - parseFloat(totalDiscount);
				//item.UnitValueWithSevenDecimalCases = parseFloat(parseFloat(item.PriceList) + parseFloat(item.AdditionValue) - parseFloat(item.DiscountValue)).toFixed(7);
				orderItem.listPriceValueWithInterestAndCampaign = parseFloat(orderItem.UnitValue);
				orderItem.TotalValueItem = parseFloat((orderItem.UnitValueWithSevenDecimalCases * orderItem.Quantity).toFixed(2));
				orderItem.TotalCampaignDiscount = orderItem.Quantity * totalDiscount;
				//item.TotalValueWithoutCampaign = item.TotalValueItem + item.TotalDiscount;

				//orderItem.listPriceValueWithInterestAndCampaign = parseFloat(orderItem.UnitValue) - totalDiscount;
				//orderItem.UnitPrice = orderItem.listPriceValueWithInterestAndCampaign;
				//orderItem.TotalDiscount = orderItem.Quantity * totalDiscount;
				//orderItem.TotalValueItem = orderItem.UnitPrice * orderItem.Quantity;

				var newRegister = true;

				if(orderUpdate.orderItem.length == 0) {
					if(!orderItem.TotalCampaignDiscount){
						orderItem.TotalCampaignDiscount = 0;
					}
					orderUpdate.orderItem.push(orderItem);
					orderUpdate.finalPrice += orderItem.TotalValueItem;
					orderUpdate.finalDiscount += orderItem.TotalCampaignDiscount;
					newRegister = false;
				} else {
					orderUpdate.orderItem.forEach(function(ordItem) {
						if(ordItem.Product2.Id == orderItem.Product2.Id){
							newRegister = false;
						}
					});
				}

				if(newRegister) {
					if(!orderItem.TotalCampaignDiscount){
						orderItem.TotalCampaignDiscount = 0;
					}
					orderUpdate.orderItem.push(orderItem);
					orderUpdate.finalPrice += orderItem.TotalValueItem;
					orderUpdate.finalDiscount += orderItem.TotalCampaignDiscount;
				}
		});

		let orderTotalValue = 0;
		x.orderObject.OrderItem.forEach((item) => {
			if(!item.Campaign.find(cp => cp.id == campaign.CampaignId) && !((campaign.hasFixedUnitPrice && item.Campaign[0]) || (!campaign.hasFixedUnitPrice && item.Campaign.filter(its => its.hasFixedUnitPrice)[0]))) {
			item = x.cloneObj(item);

			if (campaignToAllItens.length > 0) {
				campaignToAllItens.forEach(campaign => {
					item.HasChange = true;

					let campaignProduct = campaign.campaignProduct ? campaign.campaignProduct.find(
						cp => (cp.Product2 == item.Product2.Id ||
							cp.Family == item.Product2.Family__c ||
							(cp.Manufacturer != null && cp.Manufacturer != undefined && cp.Manufacturer.toLowerCase() == item.Product2.Manufacturer__c.toLowerCase()) ||
							(cp.ComercialName != null && cp.ComercialName != undefined && cp.ComercialName.toLowerCase() == item.Product2.Brand__c.toLowerCase()))
					) : null; 

					if ((!campaignProduct || campaignProduct.length == 0) || (campaignProduct && campaignProduct.CanReceiveDiscount)) {

						if (!item.Campaign.find(cp => cp.id == campaign.CampaignId)) {
							item.Campaign.push(campaign);

							let totalDiscount = 0;
							item.Campaign.forEach(campaign => {

								if (campaign.hasFixedUnitPrice) {
									item.DiscountPercent = 0;
									item.DiscountPercentWithSixDecimalCases = 0;
									item.DiscountValue = 0;
									item.DiscountValueWithSevenDecimalCases = 0;
									item.AdditionValue = 0;
									item.AdditionValueWithSevenDecimalCases = 0;
									item.AdditionPercent = 0;
									item.AdditionPercentWithSixDecimalCases = 0;
								}

								var listPriceWithInterestAndDiscounts = parseFloat(item.PriceList) + parseFloat(item.AdditionValueWithSevenDecimalCases) - parseFloat(item.DiscountValueWithSevenDecimalCases);

								if (campaign.hasFixedUnitPrice) {
									totalDiscount += campaign.discountValue;
									campaign.discountPercentage = (campaign.discountValue * 100) / listPriceWithInterestAndDiscounts;
								} else {
									totalDiscount += ((campaign.discountPercentage * listPriceWithInterestAndDiscounts) / 100);
									campaign.discountValue = (campaign.discountPercentage * listPriceWithInterestAndDiscounts) / 100;
									campaign.fixedPrice = listPriceWithInterestAndDiscounts - (campaign.discountPercentage * listPriceWithInterestAndDiscounts);
								}
							});

							var listPriceWithInterestAndDiscounts = parseFloat(item.PriceList) + parseFloat(item.AdditionValueWithSevenDecimalCases) - parseFloat(item.DiscountValueWithSevenDecimalCases);

							item.UnitValue = parseFloat(parseFloat(listPriceWithInterestAndDiscounts - parseFloat(totalDiscount)).toFixed(2));
							item.UnitValueWithSevenDecimalCases = listPriceWithInterestAndDiscounts - parseFloat(totalDiscount);
							//item.UnitValueWithSevenDecimalCases = parseFloat(parseFloat(item.PriceList) + parseFloat(item.AdditionValue) - parseFloat(item.DiscountValue)).toFixed(7);
							item.listPriceValueWithInterestAndCampaign = parseFloat(item.UnitValue);
							item.TotalValueItem = parseFloat((item.UnitValueWithSevenDecimalCases * item.Quantity).toFixed(2));
							item.TotalDiscount = item.Quantity * totalDiscount;
							//item.TotalValueWithoutCampaign = item.TotalValueItem + item.TotalDiscount;


							//item.listPriceValueWithInterestAndCampaign = parseFloat(item.UnitValue) - totalDiscount;
							//item.UnitPrice = item.listPriceValueWithInterestAndCampaign;
							//item.TotalDiscount = item.Quantity * totalDiscount;
							//item.TotalValueItem = item.UnitPrice * item.Quantity;
						}
					}
				});
			}
		
			var newRegister = true;

			if(orderUpdate.orderItem.length == 0) {
				if(!item.TotalCampaignDiscount){
					item.TotalCampaignDiscount = 0;
				}
				orderUpdate.orderItem.push(item);
				orderUpdate.finalPrice += item.TotalValueItem;
				orderUpdate.finalDiscount += item.TotalCampaignDiscount;
			} else {
				orderUpdate.orderItem.forEach(function(orderItem) {
					if(orderItem.Product2.Id == item.Product2.Id){
						newRegister = false;
					}
				});
			}

			if(newRegister) {
				orderUpdate.orderItem.push(item);
				orderUpdate.finalPrice += item.TotalValueItem;
				orderUpdate.finalDiscount += item.TotalCampaignDiscount? item.TotalCampaignDiscount : 0;
			}
		}
		});
			this.newOrderValues = orderUpdate;
			this.dispatchEvent(new CustomEvent('setcampaignvalue'), {bubbles: true});
			this.showLoading(false);
	}

	removeCampaign = (value) => {

		this.showLoading(true);

		var productId = value.currentTarget.dataset.productId;

		var campaignId = value.currentTarget.dataset.campaignId;

		let ids = {
			productId: productId,
			campaignId: campaignId,
		}

		this.removeCampaignValues = ids;

		this.dispatchEvent(new CustomEvent('removecampaign'), {bubbles: true});

		this.showLoading(false);

	}

	async getAvailableCampaign(){
		await getCampaign({team: this.orderObject.SalesTeam.Id, account: this.orderObject.Account.Id, accGroup: this.orderObject.CustomerGroup, activitySector: this.orderObject.ActivitySector, coinType: this.orderObject.Currency, orderType: this.orderObject.RecordType, crop: this.orderObject.Crop.Id}).then(data => {
			if (data) {
				this.campaignList = this.cloneObj(data);
				var x = null;
				x = this;
				if(this.filtered){
					this.campaignList.forEach(function(campaign) {
						campaign.ProductList = campaign.ProductList ? campaign.ProductList : [];
						campaign.ProductList.forEach(function(campaignProduct) {
							var hasProduct;
							if(campaignProduct.Campaign == campaign.CampaignId &&
							(campaignProduct.Product2 == x.productId || campaignProduct.Family == x.familyId || (campaignProduct.Manufacturer != null && campaignProduct.Manufacturer != undefined && campaignProduct.Manufacturer.toLowerCase() == x.manufacturer.toLowerCase()) || (campaignProduct.ComercialName != null && campaignProduct.ComercialName != undefined && campaignProduct.ComercialName.toLowerCase() == x.comercialName.toLowerCase()))){
								hasProduct = true;
							}

							//var hasProduct = campaignProduct.find(element => element.Campaign == campaign.CampaignId &&
							//									  (element.Product2		   == x.productId ||
							//									  element.Family			  == x.familyId  ||
							//									  (element.Manufacturer	   != null		&& element.Manufacturer == x.manufacturer)));
							if (hasProduct){
								campaign.show = true;
							}
						});
						if (campaign.ProductList.length == 0) {
							campaign.show = true;
						}
					});
				}

				this.campaignList.filter(item => item.show || this.filtered == false).forEach(function(campaign) {

					campaign.show			= true;
					campaign.styleCard	   = "card card-lista-pedido border-secondary card-margin-for-modal availableCampaign";
					campaign.labelBackground = "labelBackground";
					campaign.styleTitle	  = "content styleTitle";
					campaign.actionMethod	= "selectCampaign";

					campaign.ProductList = campaign.ProductList ? campaign.ProductList : [];

					let campaignProductActivators = campaign.ProductList.filter(item => item.CanActivateRules == true);

					if (campaign.Condition) {
						campaignProductActivators.forEach(campaignProduct => {
							let orderItems = x.getOrderItensByCampaignProduct(x.orderObject.OrderItem, campaignProduct);
							if (orderItems.length == 0) {
								campaign.invalid = true;
							}
						});
					} 
					// else {
					//	 let hasProductActivator = false;
					//	 campaignProductActivators.forEach(campaignProduct => {
					//		 let orderItems = x.getOrderItensByCampaignProduct(x.orderObject.OrderItem, campaignProduct);
					//		 if (orderItems.length >= 0) {
					//			 hasProductActivator = true;
					//		 }
					//	 });
					//	 if (!hasProductActivator) {
					//		 campaign.invalid = true;
					//	 }
					// }

					if (campaign.RulesList.length > 0) {
						campaign.RulesList.forEach(rule => {

							if (!rule.CampaignProduct) {
								campaign.ProductList.forEach(campaignProduct => {
									let orderItems = x.getOrderItensByCampaignProduct(x.orderObject.OrderItem, campaignProduct);

									if (campaignProduct.MaxQuantity > 0) {
										if (x.isInvalidMaxQtd(orderItems, campaignProduct)) {
											rule.invalid = true;
										}
									}
								});
							}

							if (rule.RecordType == 'ProductMix') { //campaign type -> ProductMix

								if (campaign.ProductList.length > 0) {
									if (campaignProductActivators && campaignProductActivators.length > 0) {
										x.verifyProductMixRule(x.orderObject, campaignProductActivators, rule);
									} else {
										rule.invalid = true;
									}
								} else {
									rule.invalid = true;
								}

							} else if (rule.RecordType == 'PaymentDate') { //campaign type -> PaymentDate

								if (rule.PaymentCondition && rule.PaymentDate) {
									if (x.orderObject.PaymentCondition.Id != rule.PaymentCondition || x.orderObject.DueDate > rule.PaymentDate) {
										rule.invalid = true;
									}
								} else {
									if (rule.PaymentCondition && x.orderObject.PaymentCondition.Id != rule.PaymentCondition) {
										rule.invalid = true;
									}

									if (rule.PaymentDate && x.orderObject.DueDate > rule.PaymentDate) {
										rule.invalid = true;
									}
								}

								if (!rule.CampaignProduct) {
									campaignProductActivators.forEach(campaignProduct => {
										x.verifyPaymentDateRule(x.orderObject, campaignProduct, rule);
									});
								} else {
										let specificProduct;

										campaign.ProductList.forEach(campaignProduct => {
											if(campaignProduct.Id == rule.CampaignProduct){
												specificProduct = campaignProduct;
											}
										});
									if (specificProduct) {
										x.verifyPaymentDateRule(x.orderObject, specificProduct, rule);
									} else {
										rule.invalid = true;
									}
								}
									
							} else if (rule.RecordType == 'QuantityCampaign') { //campaign type -> QuantityCampaign

								if (campaign.ProductList.length > 0) {
									if (!rule.CampaignProduct) {
										if (campaignProductActivators && campaignProductActivators.length > 0) {
											campaignProductActivators.forEach(campaignProduct => {
												x.verifyQuantityCampaignRule(x.orderObject, campaignProduct, rule);
											});
										} else {
											rule.invalid = true;
										}
									} else {
										let specificProduct;

										campaign.ProductList.forEach(campaignProduct => {
											if(campaignProduct.Id == rule.CampaignProduct){
												specificProduct = campaignProduct;
											}
										});
										if (specificProduct) {
											x.verifyQuantityCampaignRule(x.orderObject, specificProduct, rule);
										} else {
											rule.invalid = true;
										}
									}
								} else {
									rule.invalid = true;
								}

							} else if (rule.RecordType == 'VariableConstraints') { //campaign type -> VariableConstraints

								if ((rule.MinimumOrderValue && parseFloat(x.orderObject.TotalPriceOrder) < rule.MinimumOrderValue) || (parseFloat(x.orderObject.TotalPriceOrder) > rule.MaximumOrderValue && rule.MaximumOrderValue)) {
									rule.invalid = true;
								}

								// if (campaign.ProductList.length > 0) {

									if (!rule.CampaignProduct) {
										if (campaignProductActivators && campaignProductActivators.length > 0) {
											let orderItemList = [];
											campaignProductActivators.forEach(campaignProduct => {
												let orderItems = x.getOrderItensByCampaignProduct(x.orderObject.OrderItem, campaignProduct);
												if (campaignProduct.MaxQuantity > 0) {
													if (x.isInvalidMaxQtd(orderItems, campaignProduct)) {
														rule.invalid = true;
													}
												}

												orderItems.forEach(item => {
													if (!orderItemList.find(oi => oi.Product2.Id == item.Product2.Id)) {
														orderItemList.push(item);
													}
												});
											});
											x.verifyVariableConstraintsRule(x.orderObject, orderItemList, rule);
										} 
										// else {
										//	 rule.invalid = true;
										// }
									} else {
										let specificProduct;

										campaign.ProductList.forEach(campaignProduct => {
											if(campaignProduct.Id == rule.CampaignProduct){
												specificProduct = campaignProduct;
											}
										});
										if (specificProduct) {
											let orderItemList = [];
											let orderItems = x.getOrderItensByCampaignProduct(x.orderObject.OrderItem, specificProduct);

											if (specificProduct.MaxQuantity > 0) {
												if (x.isInvalidMaxQtd(orderItems, specificProduct)) {
													rule.invalid = true;
												}
											}

											if(orderItems.length != 0) {
												orderItems.forEach(item => {
													if (!orderItemList.find(oi => oi.Product2.Id == item.Product2.Id)) {
														orderItemList.push(item);
													}
												});
												x.verifyVariableConstraintsRule(x.orderObject, orderItemList, rule);
											} else {
												rule.invalid = true;
											}
										} else {
											rule.invalid = true;
										}
									}
								// } else {
								//	 rule.invalid = true;
								// }
							}

							if(rule.invalid != true){
								rule.invalid = false;
							}
						});
					} else {
						rule.invalid = true;
					}
				});

				this.campaignList.filter(item => item.show).forEach(campaign => {
					let validRules = campaign.RulesList.find(rule => !rule.invalid);
					if (!validRules) {
						campaign.styleTitle	  = "content styleErrorTitle";
						campaign.styleCard	   = "card card-lista-pedido border-secondary card-margin-for-modal campaignErrorBackground";
						campaign.labelBackground = "labelErrorBackground";
						campaign.actionMethod	= "";
					}
				});

			} else {
				this.campaignList = null;
			}
		}).catch(error => {});
	}
 
	verifyProductMixRule = (order, campaignProductActivators, campaignRule) => {
		let productCount = 0;
		campaignProductActivators.forEach(campaignProduct => {
			let orderItems = this.getOrderItensByCampaignProduct(order.OrderItem, campaignProduct);

			productCount += orderItems.length;

			if (campaignProduct.MaxQuantity > 0) {
				if (this.isInvalidMaxQtd(orderItems, campaignProduct)) {
					campaignRule.invalid = true;
				}
			}
		});

		if (campaignRule.MaximumQuantity < productCount || campaignRule.MinimumQuantity > productCount) {
			campaignRule.invalid = true;
		}
	}

	verifyPaymentDateRule = (order, campaignProduct, campaignRule) => {
		if (campaignProduct.MaxQuantity > 0) {
			let orderItems = this.getOrderItensByCampaignProduct(order.OrderItem, campaignProduct);
			if (this.isInvalidMaxQtd(orderItems, campaignProduct)) {
				campaignRule.invalid = true;
			}
		}
	}

	verifyQuantityCampaignRule = (order, campaignProduct, campaignRule) => {
		let orderItems = this.getOrderItensByCampaignProduct(order.OrderItem, campaignProduct);

		// orderItems.forEach(item => {
		//	 sumProductQtdTon += (item.grossWeightAux * item.quantity);
		// });

		let sumProductQtdTon = orderItems.reduce((acc, obj) => {
			return acc + obj.Quantity
		}, 0);

		let maxQtdTon = campaignRule.MaximumQuantity;
		let minQtdTon = campaignRule.MinimumQuantity;

		if (maxQtdTon < sumProductQtdTon || minQtdTon > sumProductQtdTon) {
			campaignRule.invalid = true;
		}

		if (campaignProduct.MaxQuantity > 0) {
			if (this.isInvalidMaxQtd(orderItems, campaignProduct)) {
				campaignRule.invalid = true;
			}
		}
	}

	verifyVariableConstraintsRule = (order, orderItemList, campaignRule) => {
		let itemTotalValue = orderItemList.reduce((acc, obj) => {
			return acc + obj.TotalValueItem
		}, 0);

		let totalPercent = (itemTotalValue * 100) / order.TotalPriceOrder;

		if (campaignRule.ProductPercent && totalPercent < campaignRule.ProductPercent) {
			campaignRule.invalid = true;
		}
	}

	getOrderItensByCampaignProduct = (orderItems, campaignProduct) => {
		return orderItems.filter(item =>
			item.Product2.Id == campaignProduct.Product2 ||
			item.Product2.Family__c == campaignProduct.Family ||
			(item.Product2.Manufacturer__c != null && item.Product2.Manufacturer__c != undefined && item.Product2.Manufacturer__c.toLowerCase() == campaignProduct.Manufacturer.toLowerCase()) ||
			(item.Product2.Brand__c != null && item.Product2.Brand__c != undefined && item.Product2.Brand__c.toLowerCase() == campaignProduct.ComercialName.toLowerCase())
		);
	}

	isInvalidMaxQtd = (orderItems, campaignProduct) => {
		let sumProductQtdTon = orderItems.reduce((acc, obj) => {
			return acc + obj.Quantity
		}, 0);
		let availableQtdTon = campaignProduct.AvailableQuantity;
		if (availableQtdTon < sumProductQtdTon) {
			return true;
		} else return false;
	}

	getCampaignById = (campaignId) => {
		return this.campaigns.find(campaign => campaign.Id == campaignId);
	}

	cloneObj(obj) {
		return JSON.parse(JSON.stringify(obj));
	}

	returnDetailValue(value) {
		if(value && this.cloneObj(value).hasOwnProperty("detail")) {
			return value.detail;
		} else {
			return value;
		}
	}

	onClickShowBarterStepA(event) {
		if(this.orderObject.OrderItem.find(item => item.invalidListPrice || item.invalidProduct)) {
			swal("Um ou mais produtos do carrinho não tem lista de preço ou estão bloqueados, por favor, verifique os produtos com problema para prosseguir.",
				{ icon: 'warning'}
			);
			return;
		}
		if(this.orderObject.OrderItem.length == 0 && !this.orderObject.deletedProductSAP) {
			swal("Nenhum produto foi adicionado ao pedido",
				{ icon: 'warning'}
			);
			return;
		}
		this.dispatchEvent(new CustomEvent('showscreen', {detail: "StepA"}));
		this.dispatchEvent(new CustomEvent('clickshowbarterstepa'));
	}

	onClickShowPedidoBarter(event) {
		this.dispatchEvent(new CustomEvent('showscreen', {detail: "StepCheckoutBarter"}));
	}

	viewCampaignDescription = (value) => {
		this.showLoading(true);
		var campaignId = value.currentTarget.dataset.campaignId;

		getCampaignById({ campaignId: campaignId }).then(data => {
			if (data) {
				let campaign = data;
				let message = `
					<div style="font-weight: 600;font-size: 18px;padding-bottom: 7px;">${campaign.Name}</div>
					<div style="white-space: pre-line;text-align:left;">${campaign.Description.replaceAll('\\r\\n', '\n')}</div>
					${campaign.Type ? `<div style="text-align: left;padding-top: 5px;font-size: 14px;">Tipo: ${campaign.Type}</div>` : ``}
					<div style="text-align: left;color: #dc3545;padding-top: 5px;font-size: 14px;">${campaign.Acummulative}</div>
				`;
				var content = document.createElement("div");
				content.innerHTML = message;
				swal(content);
			}
			this.showLoading(false);
		});
	}
}