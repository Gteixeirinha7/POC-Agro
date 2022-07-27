import { api, LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CreateAvailabilitySupply extends NavigationMixin(LightningElement) {
	@track desktop;
	@track headerStyle = '';
	@track headerClass = '';
	@track isMixClientOpen = false;
	@track showCheckoutModal = false;
	@track showBovinos = true;
	@track iconBovinos = 'utility:chevronright'

	@track iconCordeiro = 'utility:chevronright'
	@track showCordeiro = true;

	@track iconAves = 'utility:chevronright'
	@track showAves = true;

	connectedCallback() {
		this.desktop = FORM_FACTOR == 'Large';
		this.headerStyle = this.desktop ? 'height: 100%' : '';
		this.headerClass = this.desktop ? 'main-content slds-scrollable_y' : 'main-content';
    }
	displayCordeiro(){
		this.showCordeiro = this.showCordeiro ? false : true;
		this.iconCordeiro = this.showCordeiro ? 'utility:chevronright' : 'utility:chevrondown';
	}
	displayAves(){
		this.showAves = this.showAves ? false : true;
		this.iconAves = this.showAves ? 'utility:chevronright' : 'utility:chevrondown';
	}
	displayBovinos(){
		this.showBovinos = this.showBovinos ? false : true;
		this.iconBovinos = this.showBovinos ? 'utility:chevronright' : 'utility:chevrondown';
	}
	conclude(){
		this.dispatchEvent(new ShowToastEvent({ title: 'Sucesso!', message: "Pedido Criado com Sucesso.", variant: 'success' }));	
		
         this[NavigationMixin.Navigate]({
             type: 'standard__recordPage',
             attributes: {
                 recordId: '8018a000000nufLAAQ',
                 objectApiName: 'Order',
                 actionName: 'view'
             }
         });
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

	closeCheckoutModal(){
		this.showCheckoutModal = false;
		let divAllProducts = this.template.querySelectorAll(`[data-name="left_div"]`);
		
		divAllProducts.forEach(div =>{
			div.classList.remove('slds-size_2-of-3');
			div.classList.add('slds-size_3-of-3');
		});
	}

	showCheckout(){
		this.showCheckoutModal = !this.showCheckoutModal;

		this.scrollToTop();

		if (this.showCheckoutModal) {
			let divAllProducts = this.template.querySelectorAll(`[data-name="left_div"]`);
			divAllProducts.forEach(div => {
				div.classList.remove('slds-size_3-of-3');
				div.classList.add('slds-size_2-of-3');
			});
		} else {
			let divAllProducts = this.template.querySelectorAll(`[data-name="left_div"]`);

			divAllProducts.forEach(div => {
				div.classList.remove('slds-size_2-of-3');
				div.classList.add('slds-size_3-of-3');
			});
		}
	}
	removeOrderedProduct(event){
    }
}