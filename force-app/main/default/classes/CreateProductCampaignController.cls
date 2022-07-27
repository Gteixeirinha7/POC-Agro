public with sharing class CreateProductCampaignController {

    @AuraEnabled
    public static CampaignData getScenarioRecords(String campaignId) {
        CampaignData campaignDatas = new CampaignData();
        for (CampaignProduct__c campProd : [SELECT Id, Campaign__c, Campaign__r.Name, ComercialName__c, Product2__r.Name, Product2__c, Family__c, Family__r.Name, MaxQuantity__c, CanReceiveDiscount__c, CanActivateRules__c, Manufacturer__c FROM CampaignProduct__c WHERE Campaign__c = :campaignId ORDER BY CreatedDate ASC]) {
            campaignDatas.addProduct(campProd);
        }
        return campaignDatas;
    }

    @AuraEnabled
    public static Response upsertProduct(String campaignId, String prod) {
        ProductData ProductData = (ProductData)JSON.deserialize(prod, ProductData.class);
        System.debug('converteu');
        CampaignProduct__c projStep = new CampaignProduct__c(
            Id                    = ProductData.id,
            Name                  = ProductData.name,
            ExternalIdIndex__c    = ProductData.name,

            Campaign__c           = ProductData.campaign,
            Product2__c           = ProductData.product2?.id,
            Family__c             = ProductData.family?.id,
            Manufacturer__c       = ProductData.manufacturer,
            ComercialName__c      = ProductData.comercialName,
            MaxQuantity__c        = ProductData.max,

            CanReceiveDiscount__c = ProductData.receive,
            CanActivateRules__c   = ProductData.activates
        );

        try {
            //upsert projStep CampaignProduct__c.ExternalIdIndex__c; 
            upsert projStep;
            return new Response(false, 'Success');
        } catch (Exception e) {
            return new Response(true, e.getMessage());
        }
    }

    @AuraEnabled
    public static Response deleteProduct(String prod) {
        ProductData ProductData = (ProductData)JSON.deserialize(prod, ProductData.class);
        System.debug('converteu');
        CampaignProduct__c projStep = new CampaignProduct__c(
            Id                    = ProductData.id,
            Name                  = ProductData.name,
            ExternalIdIndex__c    = ProductData.name,

            Campaign__c           = ProductData.campaign,
            Product2__c           = ProductData.product2?.id,
            Family__c             = ProductData.family?.id,
            Manufacturer__c       = ProductData.manufacturer,
            ComercialName__c      = ProductData.comercialName,
            MaxQuantity__c        = ProductData.max,

            CanReceiveDiscount__c = ProductData.receive,
            CanActivateRules__c   = ProductData.activates
        );

        try {
            //upsert projStep CampaignProduct__c.ExternalIdIndex__c; 
            delete projStep;
            return new Response(false, 'Success');
        } catch (Exception e) {
            return new Response(true, e.getMessage());
        }
    }

    public class Response {
        @AuraEnabled
        public Boolean hasError {get;set;}
        @AuraEnabled
        public String  message  {get;set;}

        public Response(Boolean hasError, String message) {
            this.hasError = hasError;
            this.message  = message;
        }
    }

    public class CampaignData {
        @AuraEnabled public String campaignId    {get;set;}
        @AuraEnabled public String campaignName    {get;set;}
        @AuraEnabled public List<ProductData> productDataList    {get;set;}
        public CampaignData () {}

        public void addProduct(CampaignProduct__c campaignProd){
            this.campaignId = campaignProd.Campaign__c;
            this.campaignName = campaignProd.Campaign__r.Name;

            if(this.productDataList == null)
                this.productDataList = new List<ProductData>();
            
            this.productDataList.add(new ProductData(campaignProd));
        }
    }
    public class ProductData {
        @AuraEnabled public String id                    {get;set;}
        @AuraEnabled public String url                    {get;set;}
        @AuraEnabled public String name                    {get;set;}
        @AuraEnabled public ObjectLinkData product2                    {get;set;}
        @AuraEnabled public ObjectLinkData family                    {get;set;}
        @AuraEnabled public String manufacturer                    {get;set;}
        @AuraEnabled public String comercialName {get;set;}
        @AuraEnabled public Decimal max                    {get;set;}
        @AuraEnabled public Boolean receive                    {get;set;}
        @AuraEnabled public Boolean activates                    {get;set;}
        @AuraEnabled public String campaign {get;set;}

        public ProductData() {}

        public ProductData(CampaignProduct__c prods) {
            this.id                 = prods.Id;
            this.url                = '/' + prods.Id;
            this.name               = prods.product2__r.Name + ' - '+prods.Campaign__r.Name;
            this.product2           = prods.Product2__c == null ? null : new ObjectLinkData(prods.Product2__c, prods.Product2__r.Name);
            this.family             = prods.Family__c   == null ? null : new ObjectLinkData(prods.Family__c, prods.Family__r.Name);
            this.comercialName      = prods.ComercialName__c;
            this.manufacturer       = prods.Manufacturer__c;
            this.campaign           = prods.Campaign__c;

            this.max = prods.MaxQuantity__c;

            this.receive  = prods.CanReceiveDiscount__c;
            this.activates = prods.CanActivateRules__c;
        }
    }
    public class ObjectLinkData {
        @AuraEnabled public String Id                   {get;set;}
        @AuraEnabled public String Name                 {get;set;}

        public ObjectLinkData(String p_id, String p_name) { 
            this.id = p_id;
            this.name = p_Name;
            // this.url = '/'+p_id;
        }
    }


}