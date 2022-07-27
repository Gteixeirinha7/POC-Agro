import { LightningElement, api } from 'lwc';
import Images from '@salesforce/resourceUrl/AllImagesScreenOrder';
import getCampaign from '@salesforce/apex/CampaignController.getCampaign';
export default class CampaignModal extends LightningElement {

    cIArrowLeft = Images + '/AllImagesScreenOrder/ic-arrow-left.svg';
    cIArrowDown = Images + '/AllImagesScreenOrder/ic-arrow-down.svg';

    //Boolean tracked variable to indicate if modal is open or not default value is false as modal is closed when page is loaded 
    @api isModalOpen = false;
    @api orderObject;
    @api campaignRule;
    @api campaignProduct;
    @api campaign;
    @api campaignId;

    renderedCallback(){
        //this.getAvailableCampaign();
    }

    async openModal() {
        // to open modal set isModalOpen tarck value as true
        this.isModalOpen = true;

    }
    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.dispatchEvent(new CustomEvent('closemodal'));
        this.isModalOpen = false;
    }
    submitDetails() {
        // to close modal set isModalOpen tarck value as false
        //Add your code to call apex method or do some processing
        this.dispatchEvent(new CustomEvent('closemodal'));
        this.isModalOpen = false;
    }

    handleSectionToggle(event) {
        const openSections = event.detail.openSections;

        if (openSections.length === 0) {
            this.activeSectionsMessage = 'All sections are closed';
        } else {
            this.activeSectionsMessage =
                'Open sections: ' + openSections.join(', ');
        }
    }

    selectCampaign(event) {
        this.campaignId = event.currentTarget.dataset.campaignId;
        var x = null;
        x = this;
        this.campaign.forEach(function(campaign) {
            if(campaign.CampaignId == x.campaignId) {
                if (campaign.invalid) {
                    return;
                } else {
                    x.dispatchEvent(new CustomEvent('applycampaigndiscounts'), {bubbles: true});
                    x.dispatchEvent(new CustomEvent('closemodal'));
                    x.isModalOpen = false;
                    return;
                }
            }
        });
    }
}