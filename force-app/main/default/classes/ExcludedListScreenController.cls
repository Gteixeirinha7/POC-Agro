public with sharing class ExcludedListScreenController {
    public class PriceListData{
        @AuraEnabled public Boolean isActive      {get;set;}
        @AuraEnabled public String recordId    {get;set;}
        @AuraEnabled public String productName    {get;set;}
        @AuraEnabled public String productCode    {get;set;}
        @AuraEnabled public String cropName         {get;set;}
        @AuraEnabled public String salesTeamName {get;set;}
        @AuraEnabled public String externalId {get;set;}
        public PriceListData(ProductManagement__c prod){
            this.isActive      = prod.IsActive__c;
            this.recordId      = prod.Id;
            this.productName   = prod.Product2__r.name;
            this.productCode   = prod.Product2__r.ProductCode;
            this.cropName      = prod.Crop__r.name;
            this.salesTeamName = prod.SalesTeam__r.DisplayName__c == null ? prod.SalesTeam__r.Name: prod.SalesTeam__r.DisplayName__c;
            this.externalId    = prod.ExternalId__c;
        }
    }
    
    public static Set<String> getProduct2IdSet(List<String> productIdList, String principleActive, String productFamily){
        Set<String> prodIdSet = new Set<String>();
        prodIdSet.addAll(productIdList);

        if(productFamily == null && principleActive == null){
            return prodIdSet;
        }

        String query = ' SELECT Id FROM Product2 WHERE isActive = true ';

        if(productFamily != null){
            query += ' AND (Family__c =: productFamily OR Family__c = null) ';
        }

        if(principleActive != null){
            query += ' AND ActivePrinciple__c =: principleActive ';
        }

        query += ' Order By Name ASC';

        System.debug('query => ' + query);

        List<Product2> prodList =  (List<Product2>)Database.query(query);
        for(Product2 prod : prodList){
            prodIdSet.add(prod.id);
        }
        System.debug('prodIdSet => ' + prodIdSet);

        return prodIdSet;
    }

    public static List<PriceListData> getProductManagement(Set<String> productIdList, String crop, Boolean isActive, String salesTeamId){
        List<PriceListData> pricListDataList = new List<PriceListData>();

        String query = ' SELECT Id, Crop__c, Crop__r.Name, ExternalId__c, IsActive__c, Product2__c, Product2__r.Name, Product2__r.ProductCode, SalesTeam__c, SalesTeam__r.DisplayName__c, SalesTeam__r.Name FROM ProductManagement__c WHERE RecordType.DeveloperName = \'ExclusionList\' AND Crop__c != null ';

        if(crop != null){
            query += ' AND Crop__c =:crop ';
        }
        if(isActive != null){
            query += ' AND IsActive__c =:isActive ';
        }

        if(salesTeamId != null){
            query += ' AND SalesTeam__c =:salesTeamId ';
        }
        if(productIdList != null && !productIdList.isEmpty()){
            query += ' AND Product2__c IN :productIdList ';
        }


        query += ' Order By Product2__r.Name ASC ';
        query += ' LIMIT 100';

        System.debug('query => ' + query);

        List<ProductManagement__c> prodList =  (List<ProductManagement__c>)Database.query(query);
        for(ProductManagement__c prod : prodList){
            pricListDataList.add(new PriceListData(prod));
        }
        System.debug('pricListDataList => ' + pricListDataList);

        return pricListDataList;
    }
    
    @AuraEnabled
    public static List<PriceListData> getListPrice(List<String> productIdList, String crop, Boolean isActive, String salesTeamId, String principleActive, String productFamily){
         List<PriceListData> priceData =  getProductManagement(getProduct2IdSet(productIdList, principleActive, productFamily), crop, isActive, salesTeamId);
         System.debug('priceData => ' + priceData);
        return priceData;
    }
    //Método desenvolvido para a implmentação dos botôes (ativar/desativar) na tela de lista de exclusão
    @AuraEnabled
    public static List<PriceListData> activeList(List<String> productIdList, String crop, Boolean isActive, String salesTeamId, String principleActive, String ProductFamily, Boolean active) {
        List<PriceListData> priceDataList = getListPrice(productIdList, crop, isActive, salesTeamId, principleActive, productFamily);
        List<ProductManagement__c> productManagementList = new List<ProductManagement__c> ();
        for (PriceListData priceData : priceDataList) {
            priceData.isActive = active;
            productManagementList.add(new ProductManagement__c(
                Id = priceData.recordId,
                IsActive__c = active
            ));
        }

        update productManagementList;

        System.debug('priceDataList => ' + priceDataList);
        return priceDataList;
    }

    @AuraEnabled
    public static void saveList(String priceId, Boolean actualValue){
        update new ProductManagement__c(Id = priceId, isActive__c = actualValue);
    }
    @AuraEnabled
    public static void createList(String crop, String product, String salesTeam, Boolean isActive){
        List<ProductManagement__c> prodList = new List<ProductManagement__c>{new ProductManagement__c(Crop__C = crop, Product2__c = product, SalesTeam__c = salesTeam, isActive__c = isActive == null ? true : isACtive, RecordTypeId = Schema.SObjectType.ProductManagement__c.getRecordTypeInfosByDeveloperName().get('ExclusionList').getRecordTypeId())};
        ProductManagementHelper.setSalesOrgname(prodList);
        ProductManagementHelper.setExternalId(prodList);
        Database.upsert(prodList, ProductManagement__c.ExternalId__c, false);
    }
}
