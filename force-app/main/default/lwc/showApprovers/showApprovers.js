import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class ShowApprovers extends NavigationMixin(LightningElement) {
    @track componentList = [];
    @track componentStyle;

    connectedCallback() {
        this.componentStyle = "width: 100%; max-width: 60rem; min-width: 30rem;";
        this.componentList = [
            {
                key             : "approver1",
                color           : "slds-timeline__item_expandable slds-timeline__item_task",
                img             :  '',
                noImage         :  true,
                showIconImage   :  false,
                iconTitle       : "standard:approval",
                showImage       :  false,
                showError       :  false,
                textErrorSubTitle: "",
                iconSwitchTitle : "utility:chevronright",
                textTitle       : "Kaique Cirto Mafra",
                iconSideTitle   : "utility:alert",
                leftTextTitle   : "Supervisor da regional",
                textSubTitle    : "Aprovação devido desconto acima da politica: 3%",
                showDetails     : false,
                info            : [
                    {
                        name       : "Nome",
                        value      : "Kaique Cirto",
                        size       : 6,
                        smallSize  : 6,
                        mediumSize : 6,
                        largeSize  : 6
                    },                    
                    {
                        name       : "Loja",
                        value      : "SINOP",
                        size       : 6,
                        smallSize  : 6,
                        mediumSize : 6,
                        largeSize  : 6
                    },
                    {
                        name       : "Supervisor",
                        value      : "Gabriel Teixeira",
                        size       : 6,
                        smallSize  : 6,
                        mediumSize : 6,
                        largeSize  : 6
                    },
                    {
                        name       : "Faixa de Desconto",
                        value      : "3% á 6%",
                        size       : 6,
                        smallSize  : 6,
                        mediumSize : 6,
                        largeSize  : 6
                    }
                ],
            },
            {
                key             : "approver2",
                color           : "slds-timeline__item_expandable slds-timeline__item_event",
                img             :  '',
                noImage         :  true,
                showIconImage   :  false,
                iconTitle       : "standard:approval",
                showImage       :  false,
                showError       :  false,
                textErrorSubTitle: "",
                iconSwitchTitle : "utility:chevronright",
                textTitle       : "Gabriel Teixeira",
                iconSideTitle   : "utility:alert",
                leftTextTitle   : "Gerente da regional",
                textSubTitle    : "Aprovação devido desconto acima da politica: 6%",
                showDetails     : false,
                info            : [
                    {
                        name       : "Nome",
                        value      : "Gabriel Teixeira",
                        size       : 6,
                        smallSize  : 6,
                        mediumSize : 6,
                        largeSize  : 6
                    },                    
                    {
                        name       : "Loja",
                        value      : "SINOP & SORRISO",
                        size       : 6,
                        smallSize  : 6,
                        mediumSize : 6,
                        largeSize  : 6
                    },
                    {
                        name       : "Supervisor",
                        value      : "João Marcos",
                        size       : 6,
                        smallSize  : 6,
                        mediumSize : 6,
                        largeSize  : 6
                    },
                    {
                        name       : "Faixa de Desconto",
                        value      : "6% á 10%",
                        size       : 6,
                        smallSize  : 6,
                        mediumSize : 6,
                        largeSize  : 6
                    }
                ],
            },
            {
                key             : "approver3",
                color           : "slds-timeline__item_expandable slds-timeline__item_event",
                img             :  '',
                noImage         :  true,
                showIconImage   :  false,
                iconTitle       : "standard:approval",
                showImage       :  false,
                showError       :  true,
                textErrorSubTitle: "Aprovação mediante PDF gerado e enviado.",
                iconSwitchTitle : "utility:chevronright",
                textTitle       : "João Marcos",
                iconSideTitle   : "utility:alert",
                leftTextTitle   : "Diretor da Regional",
                textSubTitle    : "Aprovação devido desconto acima da politica: 10%",
                showDetails     : false,
                info            : [
                    {
                        name       : "Nome",
                        value      : "João Marcos Souza",
                        size       : 6,
                        smallSize  : 6,
                        mediumSize : 6,
                        largeSize  : 6
                    },                    
                    {
                        name       : "Loja",
                        value      : "CLUSTER SUL",
                        size       : 6,
                        smallSize  : 6,
                        mediumSize : 6,
                        largeSize  : 6
                    },
                    {
                        name       : "Observação",
                        value      : "Qualquer desconto acima de 10% deve ser alinhado com o supervisor da Regional antes",
                        size       : 12,
                        smallSize  : 12,
                        mediumSize : 12,
                        largeSize  : 12
                    }
                ],
            }
        ];
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
        this.dispatchEvent(
            new CustomEvent('closehistory', {
                detail: {
                    record: ''
                }
            })
        );
    }
    changeValue(event){
        var key = event.detail.key;
        var valueFilter = this.componentList.find(item => item.key == key);
        valueFilter.showDetails = !valueFilter.showDetails;
        valueFilter.iconSwitchTitle = valueFilter.showDetails ? 'utility:chevrondown' : 'utility:chevronright';
    }
}