import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ShowBarterScreen extends NavigationMixin(LightningElement) {
    @api recordId;
    @api products;
    @api sumprod;
    @api account;
    @track componentStyle;
    @track allQuantity;
    @track viability = '';
    @track marginContrato = 0;
    @track lucroContrato = 0;
    @track commodityPrice = 0;

    connectedCallback() {
        this.componentStyle = "width: 100%; max-width: 60rem; min-width: 30rem;";
    }

	get optionsBarter(){
        return [
			{ label : 'Trigo em Grãos', value: 'Trigo em Grãos'},
			{ label : 'Sorgo em Grãos', value: 'Sorgo em Grãos'},
			{ label : 'Milho em Grãos', value: 'Milho em Grãos'},
			{ label : 'Soja em Grãos', value: 'Soja em Grãos'},
			{ label : 'Algodão em Pluma', value: 'Algodão em Pluma'}
        ];
	}

	calcQuatidade(event){
		this.allQuantity = (Number(parseFloat(event.target.value).toFixed(3)) * 10);
        this.commodityPrice = this.allQuantity * 80;
        this.viability = this.commodityPrice > this.sumprod.totalAmount ? 'Economicamente Viavel' : 'Economicamente Inviavel';
        this.marginContrato = ((this.commodityPrice / this.sumprod.totalAmount) - 1) * 100;

        this.marginContrato = this.marginContrato < 0 ? 0 : parseFloat(this.marginContrato.toFixed(2)); 
        this.lucroContrato = this.commodityPrice > this.sumprod.totalAmount ? parseFloat((this.commodityPrice - this.sumprod.totalAmount).toFixed(2)) : 0; 

        
        this.viability =  this.sumprod.totalAmount == 0 ? 'Informe os Produtos de Insumos' : this.viability;
        this.marginContrato =  this.sumprod.totalAmount == 0 ? 0 : this.marginContrato;
        this.lucroContrato =  this.sumprod.totalAmount == 0 ? 0 : this.lucroContrato;
	}

    closeModal() {
        // to close modal set isModalOpen tarck value as false

        this.dispatchEvent(
            new CustomEvent('closehistory', {
                detail: {
                    record: ''
                }
            })
        );
    }

    
    changeValue(event) {
        this.dispatchEvent(
            new CustomEvent('changevalue', {
                detail: {
                    key: event.currentTarget.dataset.key,
                    field: event.currentTarget.dataset.field,
                    value: parseFloat(event?.target?.value),
                }
            })
        );
    }
	showMessage(){		
    	this.dispatchEvent(
    	    new ShowToastEvent({
    	        title: 'Consulta de Crédito',
    	        message: 'Muito Positivo , Crédito: R$ 10.000,00',
    	        variant: 'success'
    	    })
    	);
	}
}