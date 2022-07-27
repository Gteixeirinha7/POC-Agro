import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import getScenarioRecords from '@salesforce/apex/CreateProductCampaignController.getScenarioRecords';
import Images from '@salesforce/resourceUrl/AllImagesScreenOrder';
import upsertProduct from '@salesforce/apex/CreateProductCampaignController.upsertProduct';
import deleteProduct from '@salesforce/apex/CreateProductCampaignController.deleteProduct';
import AllJsFilesSweetAlert from '@salesforce/resourceUrl/AllJsFilesSweetAlert';
export default class TestPlanning extends LightningElement {

	cIRemove = Images + '/AllImagesScreenOrder/ic-times-red.svg';

    @api recordId;

    @track prodList;
    @track hasProduct = true;
    @track loading = true;

    showLoading(show) {
        this.loading = show;
    }

    connectedCallback() {
		Promise.all([loadScript(this, AllJsFilesSweetAlert + '/sweetalert-master/sweetalert.min.js')]).then(() => { }).catch(error => { });
		this.loadTasks();
    }
    
    handleNewRecordProduct(event) {
        this.handleNewRecordPrice(event, 'product2');
    }
    handleNewRecordFamily(event) {
        this.handleNewRecordPrice(event, 'family');
    }
    handleNewRecordPrice(event, param) {
        let objData = this.prodList.find(item => item.id == event.currentTarget.dataset.id);
        if(!objData[param] || objData[param] == undefined){
            var record = {};
            record = event?.detail || event?.detail?.value;
            objData[param] = {Id: record.record?.Id, Name: record.record?.Name};
            this.saveOnChangeByVal(event, objData[param]);
        }else{  
            objData[param] = null;
        }
    }

    loadTasks() {
        //calls the apex method
        getScenarioRecords({campaignId: this.recordId})
			.then(result => {
                this.prodList = result.productDataList == undefined ? [] : [...result.productDataList];
                //this.hasProduct = this.prodList.length != 0;
                this.showLoading(false);
			})
			.catch(error => {
                this.showMsg(error.body.message);
			});
    }

    saveOnChangeCheck(event) {
        this.saveOnChangeByVal(event, event.target.checked);
    }

    saveOnChange(event) {
        this.saveOnChangeByVal(event, event.target.value);
    }

    saveOnChangeByVal(event, val) {
        let type = event.currentTarget.dataset.type;
        
        let campaignProduct = this.prodList.find(item => item.id == event.currentTarget.dataset.id);

        if (campaignProduct[type] != val || campaignProduct.id == undefined) {
            campaignProduct[type] = type == 'max' ? parseFloat(val) : val;
            this.saveProduct(campaignProduct);
        }
    }
    
    saveProduct(product) {
        this.showLoading(true);
        upsertProduct({campaignId: this.recordId, prod: JSON.stringify(product)})
			.then(result => {
                if (!result.hasError)
                    this.loadTasks();
                else
                    this.showMsg(result.message);
			})
			.catch(error => {
                this.showMsg(error.body.message);
			});
    }

    showMsg(msg){        
        const evt = new ShowToastEvent({ title: 'Erro', message: msg, variant: 'error'});
        this.dispatchEvent(evt);
		this.showLoading(false);
    }

    addNewItem() {
        this.prodList.push(
            {
                id            : undefined,
                url           : undefined,
                name          : undefined,
                product2      : undefined,//{id : '', name : '', url : ''},
                family        : undefined,//{id : '', name : '', url : ''},
                manufacturer  : undefined,
                comercialName : undefined,
                campaign      : this.recordId,
                max           : 0,
                use           : 0,
                receive       : false,
                activates     : false
            }
        );
    }

    removeProduct(event) {
        if (event.currentTarget.dataset.productId != undefined) {
            let productId = event.currentTarget.dataset.productId;
            swal("Você tem certeza que deseja prosseguir com essa exclusão? ",{ icon: "warning", buttons: true}).then((action) => {
                if (action) {
                    let campaignProduct = this.prodList.find(item => item.id == productId);
                    deleteProduct({prod: JSON.stringify(campaignProduct)})
                        .then(result => {
                            if (!result.hasError)
                                this.loadTasks();
                            else
                                this.showMsg(result.message);
                        })
		            	.catch(error => {
                            this.showMsg(error.body.message);
		            	});
                } else {
                    return;
                }
            });
        } else {
            this.loadTasks();
        }
    }
}