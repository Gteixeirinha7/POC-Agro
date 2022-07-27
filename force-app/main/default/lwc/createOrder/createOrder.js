import { api, LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import Images from '@salesforce/resourceUrl/images';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CreateAvailabilitySupply extends NavigationMixin(LightningElement) {
	@track account;
	@track desktop;
	@track headerStyle = '';
	@track headerClass = '';
	@track showHeader = false;
	@track showCheckoutModal = false;

	@track allProducts = [];
	@track sumObject = {};
	@track filterObject = {};
	@track filterObjectCenter = {};

    imageFox = Images + '/fox-xpro.png'; 
    imageEvidence = Images + '/evidence.png'; 


	connectedCallback() {
		this.desktop = FORM_FACTOR == 'Large';
		this.headerStyle = this.desktop ? 'height: 100%' : '';
		this.headerClass = this.desktop ? 'main-content slds-scrollable_y' : 'main-content';
		this.account = {
			key : '13.607.309/0001-96',
			name : 'KAIQUE CIRTO - PROPRIEDADE LESTE',
			aditional : 'Grandes Fazendas',
			aditionalInfo : 'Grupo do Cliente',
			currency: "BRL"
		};
		this.allProducts = [
			{
				show: true,
				productCode: "0000010",
				name: "ABSOLUTO FIX 10L",
				img: Images + '/absoluto.png',
				stockUn: "UN",
				family: "FUNGICIDAS",
				center: [
					{
						show: true,
						name: "SINOP",
						stock: 200,
						listPrice: 115,
						showLastBuy: true,
						showCart: false,
						lastBuy: "10/05/2022",
						leadTime: 5,
						quantity: 0,
						discount: 0,
						totalPrice: 0
					},
					{
						show: true,
						name: "RONDONOPOLIS",
						stock: 300,
						listPrice: 117,
						showLastBuy: true,
						showCart: false,
						lastBuy: "11/05/2022",
						leadTime: 5,
						quantity: 0,
						discount: 0,
						totalPrice: 0
					}
				]
			},
			
			{
				show: true,
				productCode: "0000020",
				name: "BOLD 5L",
				img: Images + '/bold.png',
				stockUn: "UN",
				family: "INSETICIDAS",
				center: [
					{
						show: true,
						name: "CAMPO VERDE",
						stock: 1000,
						listPrice: 230,
						showLastBuy: false,
						showCart: false,
						lastBuy: "",
						leadTime: 7,
						quantity: 0,
						discount: 0,
						totalPrice: 0
					},
					{
						show: true,
						name: "RONDONOPOLIS",
						stock: 1300,
						listPrice: 220,
						showLastBuy: false,
						showCart: false,
						lastBuy: "",
						leadTime: 8,
						quantity: 0,
						discount: 0,
						totalPrice: 0
					}
				]
			},
			{
				show: true,
				productCode: "0000030",
				name: "BURNER 10L",
				img: Images + '/burner.png',
				stockUn: "UN",
				family: "HERBICIDAS",
				center: [
					{
						show: true,
						name: "SINOP",
						stock: 10,
						listPrice: 160,
						showLastBuy: true,
						showCart: false,
						lastBuy: "15/05/2022",
						leadTime: 15,
						quantity: 0,
						discount: 0,
						totalPrice: 0
					},
					{
						show: true,
						name: "RONDONOPOLIS",
						stock: 5,
						listPrice: 150,
						showLastBuy: false,
						showCart: false,
						lastBuy: "11/05/2022",
						leadTime: 13,
						quantity: 0,
						discount: 0,
						totalPrice: 0
					}
				]
			},
			{
				show: true,
				productCode: "0000040",
				name: "APPROVE 5L",
				img: Images + '/approve.png',
				stockUn: "UN",
				family: "FUNGICIDAS",
				center: [
					{
						show: true,
						name: "SORRISO",
						stock: 20,
						listPrice: 30,
						showLastBuy: true,
						showCart: false,
						lastBuy: "09/05/2022",
						leadTime: 5,
						quantity: 0,
						discount: 0,
						totalPrice: 0
					},
					{
						show: true,
						name: "CAMPO BELO",
						stock: 2,
						listPrice: 40,
						showLastBuy: true,
						showCart: false,
						lastBuy: "15/05/2022",
						leadTime: 5,
						quantity: 0,
						discount: 0,
						totalPrice: 0
					}
				]
			},
			{
				show: true,
				productCode: "0000050",
				name: "CONVENCE FS 5KG",
				img: Images + '/convence.png',
				stockUn: "UN",
				family: "INSETICIDAS",
				center: [
					{
						show: true,
						name: "SINOP",
						stock: 200,
						listPrice: 115,
						showLastBuy: true,
						showCart: false,
						lastBuy: "10/05/2022",
						leadTime: 5,
						quantity: 0,
						discount: 0,
						totalPrice: 0
					},
					{
						show: true,
						name: "RONDONOPOLIS",
						stock: 300,
						listPrice: 117,
						showLastBuy: true,
						showCart: false,
						lastBuy: "11/05/2022",
						leadTime: 5,
						quantity: 0,
						discount: 0,
						totalPrice: 0
					}
				]
			}
		];
		
		this.calcProducts();
		this.sumProducts();
    }

	calcProducts(){
		var t = this;
		this.allProducts.forEach(function(item){
			item.stock = item.center.reduce((sum, items) => Number(sum) + Number(items.stock), 0);
			item.price =    t.fmtDec((item.center.reduce((sum, items) => Number(sum) + Number(items.listPrice), 0) / item.center.length), 2);
			item.leadTime = t.fmtDec((item.center.reduce((sum, items) => Number(sum) + Number(items.leadTime),  0) / item.center.length), 0);
			item.leadTimeLabel = t.getCurrentDateTime(t.setDate(new Date(), item.leadTime));
			item.center.forEach(function(items){
				items.key = item.name+' - '+items.name;
				items.productName = item.name;
				items.img = item.img;
				items.leadTimeLabel = t.getCurrentDateTime(t.setDate(new Date(), items.leadTime));
			}, {item, t});
		}, {t});
	}

	fmtDec(val, fixedd){
		return Number((val).toFixed(fixedd));
	}

	setDate(dt, val){
		return new Date(dt.setDate(dt.getDate() + val));
	}
    getCurrentDateTime(dt){
        return this.formatNumber(dt.getDate())+'/'+this.formatNumber(dt.getMonth())+'/'+dt.getFullYear();
    }
    formatNumber(val){
        return (val <= 9 ? '0' : '') +val;
    }


	closeHeader(){
		this.showHeader = false;
		this.handleProductScreen();
	}
	closeCheckoutModal(){
		this.showCheckoutModal = false;
		this.handleProductScreen();
	}
	showHeaderButton(){
		this.showHeader = !this.showHeader;
		this.scrollToTop();
		this.handleProductScreen();
	}

	showCheckout(){
		this.showCheckoutModal = !this.showCheckoutModal;
		this.scrollToTop();
		this.handleProductScreen();
	}
	handleProductScreen(){
		let divAllProducts = this.template.querySelectorAll(`[data-name="left_div"]`);
		var t = this;

		divAllProducts.forEach(function(div){
			var lenghts = 12;
			lenghts -= (t.showCheckoutModal ? 3 : 0);
			lenghts -= (t.showHeader ? 2 : 0);
			div.classList.remove('slds-size_7-of-12');
			div.classList.remove('slds-size_8-of-12');
			div.classList.remove('slds-size_5-of-12');
			div.classList.remove('slds-size_9-of-12');
			div.classList.remove('slds-size_10-of-12');
			div.classList.remove('slds-size_12-of-12');
			div.classList.add(`slds-size_${lenghts.toString()}-of-12`);
		}, {t});

	}

	@track isMixClientOpen = false;
	@track isBarterOpen = false;
	@track isRecommendation = false;
	@track isApprovers = false;
	@track showResumo = true;
	@track iconResumo = 'utility:chevronright'

	@track iconCordeiro = 'utility:chevronright'
	@track showCordeiro = true;

	@track iconAves = 'utility:chevronright'
	@track showAves = true;

	@track orderObjectCrop = null;
	@track orderObjectRecordType = null;
	@track orderItemObjectCulture = null;
	@track orderItemObjectCulture2 = null;
	@track orderObjectBarterType = null;
	
	@track disabledCustomLookupCrop = false;

	@track isBarter = false;

	@track checkedCurrencyDol	 = false;
	@track checkedCurrencyReal	= true;

	@track productSelected = '';
	@track familySelected = '';

	@track showFox = true;
	@track showGranary = true;

	@track allQuantity = 0;

	get optionsBarter(){
        return [
			{ label : 'Trigo em Grãos', value: 'Trigo em Grãos'},
			{ label : 'Sorgo em Grãos', value: 'Sorgo em Grãos'},
			{ label : 'Milho em Grãos', value: 'Milho em Grãos'},
			{ label : 'Soja em Grãos', value: 'Soja em Grãos'},
			{ label : 'Algodão em Pluma', value: 'Algodão em Pluma'}
        ];
	}

	get optionsFamily(){
        return [
			{ label : '', value: ''},
			{ label : 'FUNGICIDAS', value: 'FUNGICIDAS'},
			{ label : 'INSETICIDAS', value: 'INSETICIDAS'},
			{ label : 'HERBICIDAS', value: 'HERBICIDAS'}
        ];
	}

	get optionsCenter(){
        return [
			{ label : '', value: ''},
			{ label : 'SINOP', value: 'SINOP'},
			{ label : 'RONDONOPOLIS', value: 'RONDONOPOLIS'},
			{ label : 'CAMPO VERDE', value: 'CAMPO VERDE'},
			{ label : 'CAMPO BELO', value: 'CAMPO BELO'}
        ];
	}


    get options() {
        return [
            { label: 'Pedido de Venda', value: 'SalesOrder' },
            { label: 'Pedido Barter', value: 'BarterSales' },
            { label: 'Contrato de Venda', value: 'Contrato' },
        ];
    }
	get optionsCondition(){
        return [
            { label: 'Verão', value: 'Verao' },
            { label: 'Safrinha', value: 'Safrinha' },
            { label: 'Inverno', value: 'Inverno' },
            { label: 'Café', value: 'Cafe' },
        ];
	}

	get optionsPayment(){
        return [
            { label: 'Depósito', value: 'Deposito' },
            { label: 'Cartão de Crédito', value: 'Credito' },
            { label: 'Cartão de Débito', value: 'Debito' },
            { label: 'Boleto', value: 'Boleto' },
        ];
	}

	get getBarterType(){
        return [
            { label: 'Por Dentro', value: 'PorDentro' },
            { label: 'Por Fora', value: 'PorFora' },
            { label: 'Triangulação', value: 'Triangulacao' },
        ];
	}


	calcQuatidade(event){
		this.allQuantity = (Number(parseFloat(event.target.value).toFixed(3)) * 10)
	}

	handleCurrency(event) {
		this.account.currency = event.target.value;
		this.checkedCurrencyReal = this.account.currency == 'BRL';
		this.checkedCurrencyDol  = this.account.currency != 'BRL';
	}

	showMessage(){		
    	this.showMsg('Consulta de Crédito','Muito Positivo , Crédito: R$ 10.000,00','success');
	}
	showMsg(title, msg, vari){	
    	this.dispatchEvent(
    	    new ShowToastEvent({
    	        title: title,
    	        message: msg,
    	        variant: vari
    	    })
    	);

	}

	sumProducts(){
		var t = this;
		var allCenter = [];
		this.allProducts.forEach(function(item){
			item.center.forEach(function(center){
				if(center.showCart)
					allCenter.push(center);
			}, {allCenter, t});
		}, {allCenter, t});

		this.sumProductsFilter(allCenter);
	}
	sumProductsFilter(center){
		this.sumObject.length = center.length;
		this.sumObject.amount = center.reduce((sum, item) => Number(sum) + Number(item.totalPrice), 0);
		this.sumObject.freight = 3 * center.length;
		this.sumObject.totalAmount = this.sumObject.amount + this.sumObject.freight;

		this.sumObject.minimumOrderTotal = 1000;

		this.sumObject.minimumOrder = this.sumObject.minimumOrderTotal - this.sumObject.totalAmount ;
		this.sumObject.minimumOrder = this.sumObject.minimumOrder <= 0  ? 0 : this.sumObject.minimumOrder;

		this.sumObject.minimumOrderPercent = this.sumObject.totalAmount / this.sumObject.minimumOrderTotal;
		this.sumObject.minimumOrderPercent = this.sumObject.minimumOrderPercent > 1 ? 1 : (this.sumObject.minimumOrderPercent < 0 ? 0 : this.sumObject.minimumOrderPercent);
		this.sumObject.width = 'width: '+this.sumObject.minimumOrderPercent * 100+'% !important';
	}

	addProduct(event){
		this.showCart(event.currentTarget.dataset.key, true);
		this.sumProducts();
	}

	removeProduct(event){
		this.showCart(event.currentTarget.dataset.key, false);
		this.sumProducts();
	}

	showCart(key, show){
		var t = this;
		this.allProducts.forEach(function(item){
			item.center.forEach(function(center){
				if(center.key == key && center.quantity && center.unitPrice){
					if(center.quantity && center.unitPrice){
						center.showCart = show;
					}else if(show){
						t.showMsg('Cuidado!!','Preencha a quantidade e informe um preço para o Produto','warning');
					}
				} 
			}, {key, show, t});
		}, {key, show, t});
	}

	changeQuantity(event){
		var val = parseFloat(event.currentTarget.dataset.quantity) + parseFloat(event.currentTarget.dataset.operation);
		this.updateFieldRelated(event.currentTarget.dataset.key, val, 'quantity');
	}

	changeValueBarter(event){
		this.updateFieldRelated(event.detail.key, event.detail.value, event.detail.field);
	}

	changeField(event){
		this.updateFieldRelated(event.currentTarget.dataset.key, parseFloat(event?.target?.value), event.currentTarget.dataset.field);
	}
	updateFieldRelated(key, val, field){
		var t = this;
		val = val < 0 ? 0 : val;
		if(val == 0 && field == 'quantity'){
			this.showCart(key, false);
		}
		this.allProducts.forEach(function(item){
			item.center.forEach(function(center){
				if(center.key == key){
					center[field] = val;
					center.unitPrice  = t.calcPrice(center);
					center.totalPrice  = t.calcTotalPrice(center);
					center.discount  = t.fmtDec(center.discount, 2);
				}
			}, {key, val, field, t});
		}, {key, val, field, t});
		this.sumProducts();
	}

	calcPrice(center){
		return this.fmtDec(((1 - (center.discount / 100) ) * center.listPrice), 2);
	}

	calcTotalPrice(center){
		return center.quantity * center.unitPrice;
	}

    handleFilter(event) {
		this.filterObject[event.currentTarget.dataset.filter] = event?.detail?.value?.toUpperCase();
		this.filterContext();
	}
    handleFilterRelated(event) {
		this.filterObjectCenter[event.currentTarget.dataset.filter] = event?.detail?.value?.toUpperCase();
		this.filterContext();
		this.filterContextCenter();
	}
	filterContext(){
		this.allProducts.forEach(item => item.show = true);
		var t = this;
		Object.keys(this.filterObject).forEach(function(key){
			if(key){
				var val = t.filterObject[key];
				if(val){
					t.allProducts.forEach(function(item){
						item.show = item[key].toString().includes(val) && item.show;
					}, {key, val});
				}
			}
		}, {t});
	}
	filterContextCenter(){
		var t = this;
		this.allProducts.forEach(function(item){
			item.center.forEach(function(center){center.show = true});
		});
		Object.keys(this.filterObjectCenter).forEach(function(key){
			if(key){
				var val = t.filterObjectCenter[key];
				if(val){
					t.allProducts.forEach(function(item){
						var hasTrue = {'show' : false};
						item.center.forEach(function(center){
							center.show = center[key].toString().includes(val) && center.show;
							if(center.show)
								hasTrue['show'] = true;
						}, {key, val, hasTrue});
						item.show = hasTrue['show'] && item.show;
					}, {key, val});
				}
			}
		}, {t});
	}

    handleChangeType(event) {
        this.orderObjectRecordType = event.detail.value;
		this.isBarter = event.detail.value == 'BarterSales';
		if(this.isBarter){
			this.showResumo = false;
			this.iconResumo = this.showResumo ? 'utility:chevronright' :'utility:chevrondown'; 
		}else{
			this.showResumo = true;
			this.iconResumo = this.showResumo ? 'utility:chevronright' :'utility:chevrondown'; 
		}
	}
	handlePicklistBarterType(event){
		var record				  = {};
		record					  = event?.detail || event?.detail?.value;
		this.orderObjectBarterType = record.record;
	}

	showResumoButton(){
		this.showResumo = !this.showResumo;
		this.iconResumo = this.showResumo ? 'utility:chevronright' :'utility:chevrondown'; 
	}

	conclude(){
		this.dispatchEvent(new ShowToastEvent({ title: 'Sucesso!', message: "Pedido Criado com Sucesso.", variant: 'success' }));	
		 this[NavigationMixin.Navigate]({ type: 'standard__recordPage', attributes: { recordId: '8018a000000jiO7AAI', objectApiName: 'Order', actionName: 'view' } });
		// upsertOrder({products: JSON.stringify(this.getItems())})
		// .then(result => {
		//     if (!result.hasError)
		//         this.loadTasks();
		//     else
		//         this.showMsg(result.message);
		// })
		// .catch(error => {
		//    	this.dispatchEvent(new ShowToastEvent({ title: 'Sucesso!', message: "Pedido Criado com Sucesso.", variant: 'success' }));	
		// });
	}

	getItems(){
		// var checkoutOrderItem = [];
		// return checkoutOrderItem;
	}
	checkNote(){
		this.dispatchEvent(new ShowToastEvent({ title: 'Sucesso!', message: "Produto adicionado ao carrinho.", variant: 'success' }));
	}
    scrollToTop() {
        if (!this.desktop) {
            const scrollOptions = {
				left: 0,
				top: 0
			}
			parent.scrollTo(scrollOptions);
        }
    }
	openMixClient() {
		this.isMixClientOpen = true;
		this.scrollToTop();
	}
    
	onclosehistory(event) {
		this.isMixClientOpen = false;
	}

	openBarter() {
		this.isBarterOpen = true;
		this.scrollToTop();
	}
    
	onclosebarter(event) {
		this.isBarterOpen = false;
	}

	openApprovers() {
		this.isApprovers = true;
		this.scrollToTop();
	}
    
	openRecommendation() {
		this.isRecommendation = true;
		this.scrollToTop();
	}
    
	oncloseApprovers(event) {
		this.isApprovers = false;
	}

	oncloseRecommendation(event) {
		this.isRecommendation = false;
	}

	removeOrderedProduct(event){
    }

	handleNewRecordCrop(event) {
		var record = {};
		record	 = event?.detail || event?.detail?.value;
		this.orderObjectCrop = record.record == null ? undefined : record.record;
	}
	handleNewRecordCulture(event) {
		var record = event?.detail || event?.detail?.value;
		this.orderItemObjectCulture = record.record != null ? record.record : null;
	}
	handleNewRecordCulture2(event) {
		var record = event?.detail || event?.detail?.value;
		this.orderItemObjectCulture = record.record != null ? record.record : null;
	}

}