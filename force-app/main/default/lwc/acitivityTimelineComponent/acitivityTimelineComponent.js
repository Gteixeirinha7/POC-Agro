import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class AcitivityTimelineComponent extends NavigationMixin(LightningElement) {
    @api componentList = [];
    changeValue(event) {
        this.dispatchEvent(
            new CustomEvent('changeview', {
                detail: {
                    key: event.currentTarget.dataset.key
                }
            })
        );
    }
}