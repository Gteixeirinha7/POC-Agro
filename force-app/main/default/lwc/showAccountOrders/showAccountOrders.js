import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class ShowAccountOrders extends NavigationMixin(LightningElement) {
    @api recordId;
    @track componentStyle;

    @track prodList = [];

    connectedCallback() {
        this.componentStyle = "width: 100%; max-width: 60rem; min-width: 30rem;";

        this.prodList = [
            {
                key: '11',
                name: 'CONVENCE FS 5KG',
                family: 'INSETICIDAS',
                culture: 'SOJA',
                salesTeam: 'RONDONOPOLIS',
                order: '00011259 - KAIQUE CIRTO',
                date: '28/05/2022',
                margin: 20,
                quantity: 15,
                price: 90 
            },
            {
                key: '12',
                name: 'ABSOLUTO FIX 10L',
                family: 'FUNGICIDAS',
                culture: 'MILHO',
                salesTeam: 'SINOP',
                order: '00011260 - KAIQUE CIRTO',
                date: '11/06/2022',
                margin: 10,
                quantity: 15,
                price: 100 
            },
            {
                key: '11',
                name: 'BOLD 5L',
                family: 'INSETICIDAS',
                culture: 'SOJA',
                salesTeam: 'RONDONOPOLIS',
                order: '00011209 - KAIQUE CIRTO',
                date: '30/05/2022',
                margin: 90,
                quantity: 15,
                price: 20 
            },
            {
                key: '11',
                name: 'BOLD 5L',
                family: 'INSETICIDAS',
                culture: 'SOJA',
                salesTeam: 'RONDONOPOLIS',
                order: '00011389 - KAIQUE CIRTO',
                date: '25/05/2022',
                margin: 90,
                quantity: 15,
                price: 20 
            },
            {
                key: '11',
                name: 'BURNER 10L',
                family: 'HERBICIDAS',
                culture: 'SOJA 1',
                salesTeam: 'RONDONOPOLIS',
                order: '00012259 - KAIQUE CIRTO',
                date: '25/04/2022',
                margin: 20,
                quantity: 9,
                price: 20 
            }
        ]
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