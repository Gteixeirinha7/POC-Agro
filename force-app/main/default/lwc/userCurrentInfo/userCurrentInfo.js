import { LightningElement, wire, track } from 'lwc';
import uId from '@salesforce/user/Id';
import { loadScript } from 'lightning/platformResourceLoader';
import AllJsFilesSweetAlert from '@salesforce/resourceUrl/AllJsFilesSweetAlert';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import NAME_FIELD from '@salesforce/schema/User.Name';
import EMAIL_FIELD from '@salesforce/schema/User.Email';
import USERROLE_NAME_FIELD from '@salesforce/schema/User.UserRole.Name';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import EXTERNALID_FIELD from '@salesforce/schema/User.ExternalId__c';
import PHONE_FIELD from '@salesforce/schema/User.Phone';
import CHECKPHONE_FIELD from '@salesforce/schema/User.CheckPhone__c';
import SYNC_FIELD from '@salesforce/schema/User.LastSyncedDate__c';
import ID_FIELD from '@salesforce/schema/User.Id';


const fields = [ID_FIELD, NAME_FIELD, EMAIL_FIELD, USERROLE_NAME_FIELD, PROFILE_NAME_FIELD, EXTERNALID_FIELD, PHONE_FIELD, SYNC_FIELD, CHECKPHONE_FIELD];

export default class CurrentUser extends LightningElement {
     @wire(getRecord, {
       recordId: uId,
       fields
     })
     user;

     renderedCallback() {
       console.log(this.user.data);
     }
     connectedCallback(){
        Promise.all([loadScript(this, AllJsFilesSweetAlert + '/sweetalert-master/sweetalert.min.js')]).then(() => {


        }).catch(error => { console.log(error); });
     }
    
     get idField() {
       return getFieldValue(this.user.data, ID_FIELD);
     }

     get name() {
       return getFieldValue(this.user.data, NAME_FIELD);
     }

     get email() {
       return getFieldValue(this.user.data, EMAIL_FIELD);
     }

     get userRole() {
       return getFieldValue(this.user.data, USERROLE_NAME_FIELD);
     }

     get profile() {
       return getFieldValue(this.user.data, PROFILE_NAME_FIELD);
     }

     get phone() {
        if(this.checkPhone){
          return getFieldValue(this.user.data, PHONE_FIELD);
         }else{ 
          var pphones = getFieldValue(this.user.data, PHONE_FIELD);        
          swal({
              title: (pphones ? `Confirme o cadastro do seu Telefone: ${pphones}, Caso esteja errado, informar um abaixo.` : `Seu Telefone ainda não foi validado, favor informar o Telefone no campo abaixo.`),
              content: {
                element: 'input',
                attributes: {
                  placeholder: 'Digite seu Telefone',
                  defaultValue: (pphones ? pphones : ''),
                }
              },
              icon: 'warning',
              confirmButtonText: 'Confirmar!',
            }).then((result) => {
              if (result || pphones) {
                const fields = {};
                fields[ID_FIELD.fieldApiName] = getFieldValue(this.user.data, ID_FIELD);
                fields[PHONE_FIELD.fieldApiName] = result ? result: pphones;
                fields[CHECKPHONE_FIELD.fieldApiName] = true;
                updateRecord({ fields }).then(() => {
                  this.dispatchEvent(new ShowToastEvent({title: 'Sucesso', message: 'Telefone Atualizado', variant: 'success'}));
                  return refreshApex(this.user);
                }).catch(error => {
                  this.dispatchEvent( new ShowToastEvent({ title: 'Error creating record', message: error.body.message, variant: 'error'}));
                });
              }
            });
            return pphones;
         }
     }

     get checkPhone() {
       return getFieldValue(this.user.data, CHECKPHONE_FIELD);
     }

     get externalId() {
       return getFieldValue(this.user.data, EXTERNALID_FIELD);
     }

     get syncDate() {
        var dts = getFieldValue(this.user.data, SYNC_FIELD);
        if(dts) 
          return this.convertDate(dts);
        else 
          return '';
     }
    convertDate(dts) {
        var dtTimes = dts.split("T");
        var dtList = [];
        dtList.push(dtTimes[0].split('-')[2]);
        dtList.push(dtTimes[0].split('-')[1]);
        dtList.push(dtTimes[0].split('-')[0]);

        var date = dtList.join('/');
        return date+' '+dtTimes[1].split('.')[0];
    }
}