public with sharing class PriceListController {

    public class PriceListData{
        public String accountId      {get;set;}
        public String salesTeamId    {get;set;}
        public String cropId         {get;set;}
        public String salesCondition {get;set;}
        public String currencys      {get;set;}
        public String customerGroup  {get;set;}
        public String activitySector {get;set;}
    }

    public class ProductData {
        @AuraEnabled public String  id               {get;set;}
        @AuraEnabled public String  name             {get;set;}
        @AuraEnabled public String  productCode      {get;set;}
        @AuraEnabled public Decimal multiplicy       {get;set;}
        @AuraEnabled public String  productType      {get;set;}
        @AuraEnabled public Boolean isActive         {get;set;}
        @AuraEnabled public String  activitySector   {get;set;}
        @AuraEnabled public Decimal grossWeight      {get;set;}
        @AuraEnabled public String  grossWeightUnity {get;set;}
        @AuraEnabled public String  unitMeasurement  {get;set;}
        @AuraEnabled public String  family           {get;set;}
        

        public ProductData(Product2 prod){
            this.id               = prod.id;
            this.name             = prod.name;
            this.productCode      = prod.productCode;
            this.multiplicy       = prod.multiplicity__c;
            this.productType      = prod.productType__c;
            this.isActive         = prod.isActive;
            this.activitySector   = prod.activitySector__c;
            this.grossWeight      = prod.grossWeight__c;
            this.grossWeightUnity = prod.grossWeightUnity__c;
            this.unitMeasurement  = prod.QuantityUnitOfMeasure;
            this.family           = prod.Family__c;

        }
    }

    public class PriceResponseData{
        @AuraEnabled public String errorMsg                   {get;set;}
        @AuraEnabled public Boolean hasError                  {get;set;}
        @AuraEnabled public Map<String , PriceData> priceData {get;set;}
        @AuraEnabled public List<ProductData> productData     {get;set;}
        public PriceResponseData(Exception ex){
            this.hasError = true;
            this.errorMsg = ex.getMessage();
        } 
        public PriceResponseData(Map<String , PriceData> priceList, List<ProductData> prodData){
            this.priceData   = priceList;
            this.productData = prodData;
            this.hasError = false;
            this.errorMsg = 'Success';
        } 
    }
    public class PriceData{
        @AuraEnabled public String Id               {get;set;}
        @AuraEnabled public String Name             {get;set;}
        @AuraEnabled public String RecordType       {get;set;}
        @AuraEnabled public String RecordTypeName   {get;set;}
        @AuraEnabled public String ExternalId       {get;set;}
        @AuraEnabled public String CustomerGroup    {get;set;}
        @AuraEnabled public String AccountId        {get;set;}
        
        @AuraEnabled public Decimal UnitPrice       {get;set;}
        @AuraEnabled public Decimal Priority        {get;set;}
        @AuraEnabled public Decimal PriceMultiplier {get;set;}

        @AuraEnabled public Date EffectiveDate      {get;set;}
        @AuraEnabled public Date EndDate            {get;set;}
        @AuraEnabled public Date InitialDate        {get;set;}

        @AuraEnabled public Boolean IsActive        {get;set;}

        @AuraEnabled public String Crop             {get;set;}
        @AuraEnabled public String Currencys        {get;set;}
        @AuraEnabled public String Description      {get;set;}
        @AuraEnabled public String SalesOrg         {get;set;}
        @AuraEnabled public String Product2Id       {get;set;}
        @AuraEnabled public String SalesOffice      {get;set;}
        @AuraEnabled public String ActivitySector   {get;set;}
        @AuraEnabled public String SalesTeam        {get;set;}
        @AuraEnabled public String SalesCondition   {get;set;}
        @AuraEnabled public String UnitMeasurement  {get;set;}

        @AuraEnabled public Decimal Cost {get;set;}

        public PriceData(ListPrice__c priceData){
            this.Id             = priceData.Id;
            this.Name           = priceData.Name;
            this.RecordType     = priceData.RecordTypeId;
            this.RecordTypeName = priceData.RecordType.DeveloperName;
            this.ExternalId     = priceData.ExternalId__c;
            this.CustomerGroup  = priceData.CustomerGroup__c;
            this.AccountId      = priceData.Account__c;
           
            this.UnitPrice = priceData.CalculatedUnitPrice__c;
            this.Priority = priceData.Priority__c;

            this.EffectiveDate  = priceData.EffectiveDate__c;
            this.EndDate = priceData.EndDate__c;
            this.InitialDate = priceData.InitialDate__c;
            
            this.IsActive = priceData.IsActive__c;
            
            this.Crop = priceData.Crop__c;
            this.Currencys = priceData.Currency__c;
            this.Description = priceData.Description__c;        
            this.SalesOrg = priceData.SalesOrg__c;                    
            this.Product2Id = priceData.Product2Id__c;
            this.SalesOffice = priceData.SalesOffice__c;                    
            this.ActivitySector = priceData.ActivitySector__c;
            this.SalesTeam = priceData.SalesTeam__c;
            this.SalesCondition = priceData.SalesCondition__c;
            this.UnitMeasurement = priceData.UnitMeasurement__c; 
            this.PriceMultiplier = priceData.PriceMultiplier__c;

            this.Cost =priceData.Cost__c;
        }
    }

    @AuraEnabled(cacheable=true)
    public static PriceResponseData getListPriceData(String priceDatas){
        PriceResponseData priceResponse = null;
        System.debug('priceData: ' + JSON.deserializeUntyped(priceDatas));
        PriceListData priceData = new PriceListData();
        priceData = (PriceListData)JSON.deserialize(priceDatas, PriceListData.class);
        try {
            SalesTeam__c salesTeam = SalesTeamDAO.getSalesTeamById(new List<String>{priceData.salesTeamId}, new Set<String>{'Id', 'ParentId__c', 'SalesOrg__c'})[0];
            System.debug('salesTeam: ' + salesTeam);
            Account acc = AccountDAO.getAccountById(new List<String>{priceData.AccountId}, new Set<String>{'Id', 'CustomerGroup__C', 'SalesSector__c', 'ActivitySector__c'})[0];
            System.debug('acc: ' + acc);
            Map<Id, ListPrice__c> priceReturnMap = getAllPriceData(priceData, salesTeam, acc);
            System.debug('priceReturnMap: ' + priceReturnMap);
            List<ProductData> prodDataList  = new List<ProductData>();
            for(Product2 prod : [SELECT id, name, productCode, multiplicity__c, productType__c, isActive, activitySector__c, grossWeight__c, grossWeightUnity__c, QuantityUnitOfMeasure , Family__c
                                FROM Product2 
                                WHERE Id IN : priceReturnMap.keySet()]){
                prodDataList.add(new ProductData(prod));
            }
            System.debug('prodDataList: ' + prodDataList);
            Map<String, PriceData> priceMap = new Map<String, PriceData>();
            for(Id prodId : priceReturnMap.keySet()){
                priceMap.put(prodId, new PriceData(priceReturnMap.get(prodId)));
            }
			System.debug('priceMap: ' + priceMap);
            priceResponse = new PriceResponseData(priceMap, prodDataList);


        }catch(Exception ex){
            priceResponse = new PriceResponseData(ex);
        }

        System.debug('priceResponse: ' + priceResponse);
        return priceResponse;
    }

    public static Map<Id, ListPrice__c> getAllPriceData(PriceListData priceData, SalesTeam__c salest, Account acc) {
        Map<Id, ListPrice__c> priceMap = new Map<Id, ListPrice__c>();
		
        List<String> activitySectorSet = new List<String>();
        
        if(!String.isEmpty(acc.ActivitySector__c) && acc.ActivitySector__c.contains(';')) {
            activitySectorSet = acc.ActivitySector__c.split(';');
        } else {
            activitySectorSet.add(acc.ActivitySector__c);
		}
        System.debug('activitySectorSet: ' + activitySectorSet);
        
        Set<String> relIdSet = new Set<String>();
        for(RelatedSalesOrg__c rel : [SELECT Product2Id__c FROM RelatedSalesOrg__c WHERE SalesOrg__c =:salest.SalesOrg__c]){
            relIdSet.add(rel.Product2Id__c);
        }

        for(ProductManagement__c productManagement : [SELECT id, Product2__c
                                FROM ProductManagement__c 
                                WHERE SalesTeam__c =: salest.Id 
                                AND (Crop__c =: priceData.cropId OR Crop__c = null)
                                AND RecordType.DeveloperName  = 'ExclusionList'
                                AND IsActive__c               = true]){
            if(relIdSet.contains(productManagement.Product2__c)){
                relIdSet.remove(productManagement.Product2__c);
            }
        }

		System.debug('relIdSet: ' + relIdSet);
        for(ListPrice__c prices : [
            SELECT Id, Name, RecordTypeId, RecordType.DeveloperName, ExternalId__c, CustomerGroup__c, Account__c, 
                    CalculatedInterest__c, CalculatedUnitPrice__c, Crop__c, Cost__c, Currency__c, Description__c, 
                    EffectiveDate__c, EndDate__c, InitialDate__c, InterestValue__c, IsActive__c, SalesOrg__c, 
                    PriceMultiplier__c, Priority__c, Product2Id__c, ProductFamily__c, SalesOffice__c, 
                    ActivitySector__c, SalesTeam__c, UnitMeasurement__c, UnitPrice__c, SalesCondition__c, Account__r.ActivitySector__c
            FROM ListPrice__c 
            WHERE (
                InitialDate__c <= TODAY AND EndDate__c >= TODAY 
                AND IsActive__c               = true 
                AND Product2Id__r.isActive    = true 
                AND Product2Id__c             IN  : relIdSet
                AND RecordType.DeveloperName  = 'PR00'
                AND SalesCondition__c         != '18'
                AND Crop__c                   = :priceData.cropId
                AND SalesOrg__c               = :salest.SalesOrg__c
                AND Currency__c               = :priceData.currencys

                AND (  
                    (Account__c             = null OR Account__c              = :acc.id)                   AND
                    (SalesCondition__c      = null OR SalesCondition__c       = :priceData.salesCondition) AND
                    (CustomerGroup__c       = null OR CustomerGroup__c        = :priceData.customerGroup)  AND
                    (SalesOffice__c         = null OR SalesOffice__c          = :salest.ParentId__c)       AND
                    (SalesTeam__c           = null OR SalesTeam__c            = :salest.Id)                AND
                    (ActivitySector__c      = null OR ActivitySector__c       = :priceData.activitySector)
                )
            )
            ORDER BY Priority__c ASC, EndDate__c DESC
        ]){
            priceMap.put(prices.Product2Id__c, prices);
        }
		System.debug('priceMap:' + priceMap);
        return priceMap;
    }
}