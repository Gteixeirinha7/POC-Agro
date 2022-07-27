public with sharing class StockListScreenController {
    public class StockData{
        @AuraEnabled public String recordId      {get;set;}
        @AuraEnabled public String productName   {get;set;}
        @AuraEnabled public String productCode   {get;set;}
        @AuraEnabled public Decimal tolerance   {get;set;}
        @AuraEnabled public Boolean showTolerance   {get;set;}
        @AuraEnabled public String salesTeamId   {get;set;}
        @AuraEnabled public String salesTeamName {get;set;}
        @AuraEnabled public Boolean hasCrop   {get;set;}
        @AuraEnabled public String cropId   {get;set;}
        @AuraEnabled public String cropName {get;set;}
        @AuraEnabled public String externalId    {get;set;}
        @AuraEnabled public Decimal stock         {get;set;}
        @AuraEnabled public Decimal stockBaseCalc {get;set;}
        @AuraEnabled public Boolean isBlocked     {get;set;}
        @AuraEnabled public Boolean hasExcluded   {get;set;}
        @AuraEnabled public Boolean hasStock   {get;set;}
        @AuraEnabled public Boolean showActive   {get;set;}
        @AuraEnabled public String distId        {get;set;}
        @AuraEnabled public String distName      {get;set;}
        @AuraEnabled public String unitmeasure     {get;set;}
        @AuraEnabled public String styleColor     {get;set;}
        @AuraEnabled public String styleTextColor     {get;set;}
        @AuraEnabled public String styleText     {get;set;}
        public StockData(Product2 prod, SalesTeam__c salesteam, ProductManagement__c prodExcluded){
            this.recordId      = prod.Id+'_'+salesTeam.Id;
            this.productName   = prod.name;
            this.productCode   = prod.ProductCode;
            this.salesTeamId   = salesteam.id;
            this.salesTeamName = salesteam.DisplayName__c == null ? salesteam.Name: salesteam.DisplayName__c;
            this.externalId    = prod.Id+'_'+salesTeam.Id;
            this.stock         = null;
            this.stockBaseCalc = null;
            this.tolerance     = null;
            this.showTolerance = false;
            this.isBlocked     = false;
            this.hasCrop       = false;
            this.distId        = salesteam.DistributionCenter__c;
            this.distName      = salesteam.DistributionCenter__r.Name;
            this.unitmeasure   = prod.QuantityUnitOfMeasure;
            this.hasExcluded   = prodExcluded != null;
            this.hasStock = false;
            this.checkTitle();
        }
        public StockData(ProductManagement__c prod, SalesTeam__c salesteam, ProductManagement__c prodExcluded){
            this.recordId      = prod.Id;
            this.productName   = prod.Product2__r.name;
            this.productCode   = prod.Product2__r.ProductCode;
            this.hasCrop       = prod.Crop__c != null;
            this.cropId   = prod.Crop__c;
            this.cropName = prod.Crop__r?.Name;            
            this.showTolerance = true;
            this.salesTeamId   = salesteam.id;
            this.salesTeamName = salesteam.DisplayName__c == null ? salesteam.Name: salesteam.DisplayName__c;
            this.externalId    = prod.ExternalId__c;
            this.stock         = prod.AvailableInventory__c;
            this.stockBaseCalc = (prod.AvailableInventory__c != null ? prod.AvailableInventory__c : 0) - (prod.Tolerance__c != null ? prod.Tolerance__c : 0);
            this.tolerance     = this.stockBaseCalc != 0 ? (((prod.Tolerance__c != null ? prod.Tolerance__c : 0) * 100) / this.stockBaseCalc) : 0;
            this.isBlocked     = prod.Block__c;
            this.distId        = prod.DistributionCenter__c;
            this.distName      = prod.DistributionCenter__r.Name;
            this.unitmeasure   = prod.UnitMeasurement__c;
            this.hasExcluded   = prodExcluded != null;
            this.hasStock = true;
            this.checkTitle();
        }
        public void checkPermission(Boolean isAdmin){
            this.showActive = isAdmin && (this.hasStock);
            this.showTolerance = isAdmin && (this.hasStock);
        }
        public void checkTitle(){
            this.styleColor    = 'border: 2px solid {recordData} !important;';
            if((this.stock > 0 && !this.isBlocked) || this.stock == null){
                this.styleText = 'Produto disponível para venda';
                this.styleColor = this.styleColor.replace('{recordData}', 'green');
                this.styleTextColor = 'color: green;';
            }else{
                if(this.stock < 0 && this.isBlocked ){
                    this.styleText = 'Este produto não possui estoque para venda. Em caso de dúvida, contatar Customer Service';
                    this.styleColor = this.styleColor.replace('{recordData}', 'red');
                    this.styleTextColor = 'color: red;';
                }
                /*else if(this.stock < 0 && !this.isBlocked ){
                    this.styleText = 'Atenção, este produto pode não ter estoque disponível. Em caso de dúvida, contatar Customer Service';
                    this.styleColor = this.styleColor.replace('{recordData}', 'red');
                    this.styleTextColor = 'color: red;';
                }*/
            }

            if(this.hasExcluded){
                this.styleText = 'Produto marcado para exclusão';
                this.styleColor = this.styleColor.replace('{recordData}', 'red');
                this.styleTextColor = 'color: red;';
            }
        }
    }
    
    public static Set<String> getProduct2IdSet(String[] prodIdParam, String principles){
        Set<String> prodIdSet = new Set<String>();
        if(principles != null){
            prodIdParam.add(principles);
        }
        for(Product2 prod : [SELECT id 
                            FROM Product2 
                            WHERE isActive = true
                            AND (Family__c IN :prodIdParam
                                OR ActivePrinciple__c IN :prodIdParam
                                OR Id IN :prodIdParam) ORDER BY  Name ASC ]){
            prodIdSet.add(prod.id);
        }
        return prodIdSet;
    }

    public static Map<String, ProductManagement__c> getExclusionList(String[] cropId, Set<String> productIdList, Map<String, SalesTeam__c>  centerIdMap){
        Map<String, ProductManagement__c> prodMap = new Map<String, ProductManagement__c>();
        for(ProductManagement__c prod : [SELECT id, SalesTeam__c, Product2__c FROM ProductManagement__c WHERE  RecordType.DeveloperName = 'ExclusionList' AND (Crop__c IN :cropId OR Crop__c = null) AND SalesTeam__c IN :Collection.of(centerIdMap.values()).pluckIds() AND IsActive__c = true  AND Product2__c IN :productIdList  ]){
            prodMap.put(prod.Product2__c+'_'+prod.SalesTeam__c, prod);
        }
        return prodMap;
    }
    public static Map<String, SalesTeam__c> getCenterId(String[] salesTeamId){
        Map<String, SalesTeam__c> prodIdMap = new Map<String, SalesTeam__c>();

        if(salesTeamId.isEmpty()){
            for(SalesTeam__c sales : [SELECT id, DistributionCenter__c, DisplayName__c, Name, DistributionCenter__r.Name FROM SalesTeam__c])
                prodIdMap.put(sales.DistributionCenter__c, sales);

        }else{
            for(SalesTeam__c sales : [SELECT id, DistributionCenter__c, DisplayName__c, Name, DistributionCenter__r.Name FROM SalesTeam__c WHERE id IN :salesTeamId OR DistributionCenter__c IN :salesTeamId])
                prodIdMap.put(sales.DistributionCenter__c, sales);
        }

        System.debug('prodIdMap => ' + prodIdMap);

        return prodIdMap;
    }

    public static Map<String, StockData> getStockData(String[] cropId, String clusterId, Boolean isActive, Set<String> productIdList, Map<String, SalesTeam__c>  centerIdMap, Map<String, ProductManagement__c> prodMap){
        Map<String, StockData> pricListDataMap = new Map<String, StockData>();
        Set<String> centerIdSet = null;

        Map<String, SalesTeam__c> prodIdMap = new Map<String, SalesTeam__c>();
        for(SalesTeam__c sales : [SELECT id, DistributionCenter__c, DisplayName__c, Name, DistributionCenter__r.Name, ParentId__r.ParentId__c FROM SalesTeam__c]){
            prodIdMap.put(sales.DistributionCenter__c, sales);
            if(clusterId != null && sales.ParentId__r.ParentId__c == clusterId && centerIdMap.isEmpty()){
                centerIdMap.put(sales.DistributionCenter__c, sales);
            }
        }
            

        String query = ' SELECT Id, Product2__r.name, Tolerance__c, Crop__c, Crop__r.name, Product2__r.ProductCode, AvailableInventory__c, Block__c, DistributionCenter__r.Name, DistributionCenter__c, ExternalId__c, Product2__c, UnitMeasurement__c FROM ProductManagement__c WHERE RecordType.DeveloperName LIKE \'%Stock%\' ';

        if(!centerIdMap.isEmpty()){
            centerIdSet = centerIdMap.keySet(); 

            query += ' AND DistributionCenter__c IN :centerIdSet ';
        }

        if(productIdList != null && !productIdList.isEmpty()){
            query += ' AND Product2__c IN :productIdList ';
        }

        if(!cropId.isEmpty()){
            query += ' AND (Crop__c IN :cropId OR Crop__c = null) ';
        }

        if(isActive != null){
            query += ' AND (Block__c = :isActive) ';
        }

        query += ' Order By Product2__r.Name ASC ';
        query += ' LIMIT 1000';

        System.debug('query => ' + query);
        System.debug('query => ' + isActive);
        System.debug('query => ' + productIdList);
        System.debug('query => ' + centerIdMap);

        List<ProductManagement__c> prodList =  (List<ProductManagement__c>)Database.query(query);
        for(ProductManagement__c prod : prodList){
            if(!prodIdMap.containsKey(prod.DistributionCenter__c)) continue;
            SalesTeam__c sales = prodIdMap.get(prod.DistributionCenter__c);

            String key = prod.Product2__c+'_'+sales.Id;

            ProductManagement__c prodExcluded = prodMap.containsKey(key) ? prodMap.get(key) : null;
            
            pricListDataMap.put(key+'_'+prod.Crop__c, new StockData(prod, sales, prodExcluded));
        }
        System.debug('pricListDataMap => ' + pricListDataMap);

        return pricListDataMap;
    }
    
    public static void getInventoryNewRecords(Map<String, StockData> priceData, Set<String> productIdList, Map<String, SalesTeam__c>  centerIdMap, Map<String, ProductManagement__c> prodMap){
        for(Product2 prod : [SELECT id, name, ProductCode, QuantityUnitOfMeasure FROM Product2 WHERE Id = :productIdList]){
           for(SalesTeam__c sales : centerIdMap.values()){
               String key = prod.id+'_'+sales.id;
                ProductManagement__c prodExcluded = prodMap.containsKey(key) ? prodMap.get(key) : null;
            
               if(!priceData.containsKey(key)){
                   priceData.put(key, new StockData(prod, sales, prodExcluded));
               }
           }
        }
    }
    public static Boolean getProfileName(){        
        User us = [SELECT id, Profile.Name FROM User WHERE Id =: Userinfo.getUserId()];
        
        return us.Profile.Name.contains('Admin') || us.Profile.Name.contains('Service') ;
    }
    public static void handleProfileName(Map<String, StockData> priceData){        
        Boolean isAdmin = getProfileName();
        for(StockData stck : priceData.values()){
            stck.checkPermission(isAdmin);
        }
    }
    @AuraEnabled
    public static Boolean getProfileCheck(){
        return getProfileName();
    }
    @AuraEnabled
    // public static List<StockData> getStock(String cropId, Boolean isActive, String productId, String clusterId, String salesTeamId, String principleActive, String productFamily){
    public static List<StockData> getStock(Boolean isActive, String clusterId, String[] idsSet, String[] centerSet, String[] cropIdSet, String principleActive){
        // idsSet.add(principleActive); 
        Set<String> prodIdList = getProduct2IdSet(idsSet, principleActive);
         Map<String, SalesTeam__c> salesIdMap = getCenterId(centerSet);
         Map<String, ProductManagement__c> exclusionListMap = getExclusionList(cropIdSet, prodIdList, salesIdMap);

         Map<String, StockData> priceData =  getStockData(cropIdSet, clusterId, isActive, prodIdList, salesIdMap, exclusionListMap);

        //  getInventoryNewRecords(priceData, prodIdList, salesIdMap, exclusionListMap);

         System.debug('priceData => ' + priceData);

         handleProfileName(priceData);

        return priceData.values();
    }
    
    @AuraEnabled
    public static void activeList(List<String> priceIdList, Boolean actualValue) {
        List<ProductManagement__c> productManagementList = new List<ProductManagement__c>();
        for (String priceData : priceIdList) {
            if(!priceData.contains('_')){
                productManagementList.add(new ProductManagement__c(
                    Id = priceData,
                    Block__c = actualValue
                ));
            }
        }

        update productManagementList;
    }

}
