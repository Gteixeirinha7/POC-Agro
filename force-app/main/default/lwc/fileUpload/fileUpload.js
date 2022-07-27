import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
export default class FileUploadExample extends NavigationMixin(LightningElement) {
    
    @api recordId;

    @api acceptedFormats = ['.xlsx', '.xls', '.jpg', '.csv', '.png', '.doc', '.docx', '.pdf', '.txt'];

    handleUploadFinished(event) {
        let file = event.detail.files[0];
        let fileName = file.name;
        let documentId = file.documentId;

        this.navigateToView();
    }

    navigateToView(id) {
        this[NavigationMixin.Navigate]({ type: 'standard__recordPage', attributes: { recordId: this.recordId, objectApiName: 'Event', actionName: 'view' } });
    }
}