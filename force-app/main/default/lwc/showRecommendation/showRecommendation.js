import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class ShowRecommendation extends NavigationMixin(LightningElement) {
    @api recordId;
    @track componentStyle;

    connectedCallback() {
        this.componentStyle = "width: 100%; max-width: 60rem; min-width: 30rem;";
    }

    showError() {        	
    	this.dispatchEvent(
    	    new ShowToastEvent({
    	        title: 'Removida',
    	        message: 'Recomendação marcada para exclusão',
    	        variant: 'warning'
    	    })
    	);
    }
    showSuccess() {        	
    	this.dispatchEvent(
    	    new ShowToastEvent({
    	        title: 'Adicionado ao carrinho',
    	        message: 'Produto adicionado ao Carrinho de Compras',
    	        variant: 'success'
    	    })
    	);
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
}