public without sharing class ImportCampaignProduct {
    public ImportCampaignProduct(ApexPages.StandardController stdController) { }
    @RemoteAction
    public static String createRecords(String entryList){

        List<CampaignProductData> excelDataList = (List<CampaignProductData>)JSON.deserialize(entryList, List<CampaignProductData>.class);
        Map<String, sObject> lookups = new Map<String, sObject>();
        for(CampaignProductData oppData : excelDataList){
            lookups.put(oppData.campaignNumber, null);
            lookups.put(oppData.productCode, null);
            lookups.put(oppData.familyCode, null);
        }

        for(Campaign prod : [SELECT id, name FROM Campaign WHERE Name IN : lookups.keySet()]){
            lookups.put(prod.name, prod);
        }

        for(Product2 prod : [SELECT id, Name, ProductCode FROM Product2 WHERE Name IN : lookups.keySet()]){
            lookups.put(prod.ProductCode, prod);
        }
        
        for(Family__c prod : [SELECT id, Name, ExternalId__c FROM Family__c WHERE Name IN : lookups.keySet()]){
            lookups.put(prod.ExternalId__c, prod);
        }

        Map<String, CampaignProduct__c> oppLineItemMap = new Map<String, CampaignProduct__c>();
        for(CampaignProductData oppData : excelDataList){
            CampaignProduct__c prod  = oppData.getCampaignProductData(lookups);
            oppLineItemMap.put(prod.ExternalIdIndex__c, prod);
        }
        
        if(!oppLineItemMap.isEMpty()){
            Database.insert(oppLineItemMap.values());
        }

        return 'Sucesso';
    }
    public class CampaignProductData{
        public String campaignNumber {get;set;}
        public String productCode {get;set;}
        public String familyCode {get;set;}
        public String Manufacturer {get;set;}
        public String comercialName {get;set;}
        public String quantity {get;set;}
        public String rules {get;set;}
        public String discounts {get;set;}
        public CampaignProductData(Boolean isTest){
            if(isTest){
                this.campaignNumber = 'CAM-0190';
                this.productCode    = '100231';
                this.familyCode     = '1002';
                this.Manufacturer     = 'BAYER';
                this.comercialName  = 'FOX XPRO';
                this.quantity       = '100';
                this.rules          = 'true';
                this.discounts      = 'false';
            }
        }
        public CampaignProduct__c getCampaignProductData(Map<String, sObject> lookups){
        CampaignProduct__c campaignProduct = new CampaignProduct__c(
            Campaign__c = (Id)lookups.get(this.campaignNumber).get('Id'),
            CanActivateRules__c = this.rules == 'true',
            CanReceiveDiscount__c = this.discounts == 'true',
            CurrencyIsoCode = 'BRL',
            Manufacturer__c = this.Manufacturer,
            ComercialName__c = this.comercialName,
            Family__c = (Id)lookups.get(this.familyCode).get('Id'),
            Product2__c  = (Id)lookups.get(this.productCode).get('Id'),
            MaxQuantity__c = Decimal.valueOf(this.quantity)
        );
        campaignProduct.ExternalIdIndex__c = 
            (this.Manufacturer != null ? this.Manufacturer : 
            this.comercialName != null ? this.comercialName : 
            campaignProduct.Product2__c != null ? (String)lookups.get(this.productCode).get('Name') : 
            campaignProduct.Family__c != null ? (String)lookups.get(this.familyCode).get('Name') :  '') + ' - '+(String)lookups.get(this.campaignNumber).get('Name');
        return campaignProduct;
        }
    }
}