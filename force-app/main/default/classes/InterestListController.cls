public with sharing class InterestListController {
    public class InterestListData{
        public String productFamilyId {get;set;}
        public String productId       {get;set;}
        public String salesTeamId     {get;set;}
        public String salesOfficeId   {get;set;}
        public String currencyType    {get;set;}
        public String cropId          {get;set;}
        public String salesCondition  {get;set;}
        public String listPriceType   {get;set;}
    }
   
    @AuraEnabled(cacheable=true)
    public static ListPrice__c getInterestListData(String priceData) {

        System.debug('priceData: ' + priceData);

        InterestListData interestListData    = new interestListData();

        interestListData = (InterestListData)JSON.deserialize(priceData, InterestListData.class);

        ListPrice__c priceReturnMap = new ListPrice__c();

        try {
            SalesTeam__c salesTeam = SalesTeamDAO.getSalesTeamById(new List<String>{interestListData.salesTeamId}, new Set<String>{'Id', 'ParentId__c', 'SalesOrg__c'})[0];

            priceReturnMap = getAllPriceData(interestListData, salesTeam);

        } catch(Exception ex) {
            priceReturnMap = null;
        }
		System.debug('priceReturnMap: ' + priceReturnMap);

        return priceReturnMap;
    }

    public static ListPrice__c getAllPriceData(InterestListData priceData, SalesTeam__c salest) {
        List<ListPrice__c> lp = new List<ListPrice__c>();
        
        lp = [
            SELECT Id, OwnerId, IsDeleted,
            Name, RecordTypeId, CreatedDate, CreatedById, LastModifiedDate,
            LastModifiedById, SystemModstamp, LastActivityDate, LastViewedDate,
            LastReferencedDate, Account__c, CalculatedInterest__c,
            CalculatedUnitPrice__c, Crop__c, Currency__c,
            CustomerGroup__c, Description__c, EffectiveDate__c,
            EndDate__c, ExternalId__c, InitialDate__c, InterestValue__c,
            IsActive__c, PriceMultiplier__c, Priority__c, Product2Id__c,
            ProductFamily__c, SalesCondition__c, SalesOffice__c, SalesOrg__c,
            ActivitySector__c, SalesTeam__c, UnitMeasurement__c, UnitPrice__c, RecordType.DeveloperName
            FROM ListPrice__c 
            WHERE (InitialDate__c <= TODAY AND EndDate__c >= TODAY  
                    AND IsActive__c               = true
                    AND RecordType.DeveloperName  = :priceData.listPriceType
                    AND (SalesOffice__c           = :priceData.salesOfficeId   OR SalesOffice__c     = null)
                    AND (Currency__c              = :priceData.currencyType    OR Currency__c        = null)
                	AND (ProductFamily__c         = :priceData.productFamilyId OR ProductFamily__c   = null)
                    AND (Product2Id__c            = :priceData.productId       OR Product2Id__c      = null)
                	AND (SalesCondition__c        = :priceData.salesCondition  OR SalesCondition__c  = null)
                	AND (Crop__c                  = :priceData.cropId          OR Crop__c            = null)
                	AND (SalesOrg__c              = :salest.SalesOrg__c)) ORDER BY InterestPriority__c DESC NULLS LAST LIMIT 1];

        return lp == null || lp.isEmpty() ? null : lp[0];
    }
}