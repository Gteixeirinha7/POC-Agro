public with sharing class CustomerPerOrgController {
 
    @AuraEnabled(cacheable=true)
    public static ResponseCallBackLwc getCustomerPerOrg(String accountId, String orgId, String activitySector) {
        System.debug('accountId: ' + accountId);
        System.debug('orgId: ' + orgId);
        System.debug('activitySector: ' + activitySector);
        List<CustomerPerOrg__c> cpoObj = new List<CustomerPerOrg__c>();
        if(activitySector == null) {
            cpoObj = [SELECT Id, IsDeleted,
            Name, CreatedDate, CreatedById,
            LastModifiedDate, LastModifiedById,
            SystemModstamp, LastActivityDate,
            LastViewedDate, LastReferencedDate, Blocked__c, ClientGroup__c, ActivitySector__c,
            Customer__c, DistributionChannel__c,
            SalesOrg__c, SalesOrg__r.Name, SalesSector__c FROM CustomerPerOrg__c WHERE Customer__c =: accountId AND SalesOrg__c =: orgId AND Blocked__c = false AND ActivitySector__c != null AND DistributionChannel__c = '10' AND ClientGroup__c != null];
    
            return cpoObj.isEmpty() == false ? new ResponseCallBackLwc(cpoObj) : null;
        } else {
            cpoObj = [SELECT Id, IsDeleted,
            Name, CreatedDate, CreatedById,
            LastModifiedDate, LastModifiedById,
            SystemModstamp, LastActivityDate,
            LastViewedDate, LastReferencedDate, Blocked__c, ClientGroup__c, ActivitySector__c,
            Customer__c, DistributionChannel__c,
            SalesOrg__c, SalesOrg__r.Name, SalesSector__c FROM CustomerPerOrg__c WHERE Customer__c =: accountId AND SalesOrg__c =: orgId AND Blocked__c = false AND ClientGroup__c != null AND DistributionChannel__c = '10' AND ActivitySector__c =: activitySector LIMIT 1];
    
            return cpoObj.isEmpty() == false ? new ResponseCallBackLwc(cpoObj) : null;
        }
    }
 
    public class ResponseCallBackLwc {
        @AuraEnabled public Boolean IsBlock                 {get; set;}
        @AuraEnabled public Boolean HaveCustomer            {get; set;}
        @AuraEnabled public Boolean HaveSector              {get; set;}
        @AuraEnabled public String  ActivitySectorList      {get; set;}
        @AuraEnabled public CustomerPerOrg__c CustPerOrgObj {get; set;}

        //Construtor
        public ResponseCallBackLwc(List<CustomerPerOrg__c> customerPerOrg) {
            this.CustPerOrgObj                       = new CustomerPerOrg__c();
            List<String> strListActivitySector       = new List<String>();
            List<String> strListActivitySectorToJoin = new List<String>();

            for(CustomerPerOrg__c cpo : customerPerOrg) {
                if(cpo.ActivitySector__c.contains(';')) {
                    strListActivitySector = cpo.ActivitySector__c.split(';');
                    if(!strListActivitySectorToJoin.contains(strListActivitySector[0])) {
                        strListActivitySectorToJoin.add(strListActivitySector[0]);
                    }
                } else {
                    if(!strListActivitySectorToJoin.contains(cpo.ActivitySector__c)) {
                        strListActivitySectorToJoin.add(cpo.ActivitySector__c);
                    }
                }
                this.ActivitySectorList = strListActivitySectorToJoin.size() > 1 ? String.join(strListActivitySectorToJoin,';') : strListActivitySectorToJoin[0];
                this.IsBlock       = false;
                this.HaveSector    = true;
                this.HaveCustomer  = true;
                this.CustPerOrgObj = cpo;
            }
        }
    }
}