public with sharing class ListPriceDAO {
    
    public static List<ListPrice__c> getListPriceByExternalId(List<String> externalIds, Set<String> listPriceUsedFields) {

        String query = new Q(ListPrice__c.SObjectType)
            .selectFields(listPriceUsedFields)
            .add(Q.condition('ExternalId__c').isIn(externalIds))
            .add(Q.condition('ExternalId__c').isNotNull())
            .build();
            
        return Database.query(query);
    }

    public static List<ListPrice__c> getListPriceData(
    Set<String> listPriceFields,String account, String crop, Date initialDate, Decimal calculatedUnitPrice,
    Boolean isActive, Date effectiveDate, String activitySector, String productFamily, String currencyType, Decimal unitPrice,
    Date endDate, List<String> productNameList, List<String> salesTeamList, List<String> salesOfficeList, String salesCondition, String activePrincible, List<String> orgList){

        String query = '';

        query = 'SELECT Id, Name, Account__c, Crop__r.Name, RecordType.DeveloperName, Crop__c, InterestPriority__c,'                +
                        ' Priority__c, SalesCondition__c, InitialDate__c, CalculatedUnitPrice__c, IsActive__c,'                     +
                        ' EffectiveDate__c, ActivitySector__c, ProductFamily__r.Name, Product2Id__r.Family__c,'                     +
                        ' Currency__c, UnitPrice__c, EndDate__c, Product2Id__r.Name, Product2Id__c, SalesConditionObject__r.Name,'  +
                        ' SalesTeam__r.DisplayName__c,SalesTeam__c, SalesOffice__c, Product2Id__r.ActivePrinciple__c,'              +
                        ' Product2Id__r.Family__r.Name, Product2Id__r.IsActive'                                                     +
                ' FROM ListPrice__c'                                                                                                +
                ' WHERE IsActive__c = true'                                                                                         +
                ' AND RecordType.DeveloperName = \'PR00\''                                                                          +
                ' AND EffectiveDate__c != null'                                                                                     +
                ' AND EndDate__c >= TODAY'                                                                                          +
                ' AND SalesCondition__c != \'18\''                                                                                  +
                ' AND InitialDate__c <= TODAY'                                                                                      +
                ' AND UnitPrice__c != 0'                                                                                            +
                ' AND (SalesTeam__c IN: salesTeamList OR SalesTeam__c = null)'                                                      +
                ' AND (SalesOffice__c IN: salesOfficeList OR SalesOffice__c = null)'                                                +
                ' AND (SalesOrg__c IN: orgList OR SalesOrg__c = null)'                                                              +
                ' AND Product2Id__r.IsActive = true'                                                                                +
                ' AND Currency__c =: currencyType';

        if(account != null){
            query = query + ' AND (Account__c =: account OR Account__c = null)';
        }
        else{
            query = query + ' AND Account__c = null';
        }

        if(crop != null){
            query = query + ' AND (Crop__c =: crop OR Crop__c = null)';
        }

        if(activitySector != null && activitySector != 'All'){
            query = query + ' AND (ActivitySector__c =: activitySector OR ActivitySector__c = null)';
        }

        if(productFamily != null){
            query = query + ' AND (Product2Id__r.Family__c =: productFamily OR Product2Id__r.Family__c = null)';
        }

        if(salesCondition != null && salesCondition != 'All'){
            query = query + ' AND (SalesCondition__c =: salesCondition OR SalesCondition__c = null)';
        }

        if(activePrincible != null){
            query = query + ' AND Product2Id__r.ActivePrinciple__c =: activePrincible';
        }

        if(!productNameList.isEmpty()){
            query = query + ' AND (Product2Id__c IN: productNameList OR Product2Id__c = null)';
        }

        query = query + ' Order By Product2Id__r.Name ASC, Priority__c DESC, EndDate__c ASC';

        System.debug(query);

        return Database.query(query);
    }

    public static List<ListPrice__c> getInterestListPriceData(
    Set<String> listPriceFields,String account, String crop, Date initialDate, Decimal calculatedUnitPrice,
    Boolean isActive, Date effectiveDate, String activitySector, String productFamily, String currencyType, Decimal unitPrice,
    Date endDate, List<String> productNameList, List<String> salesTeamList, List<String> salesOfficeList, String salesCondition, String activePrincible, List<String> orgList){

        List<Product2> productList = [
            SELECT Id, Name, Family__c
            FROM Product2
            WHERE Id IN: productNameList  
            ];

        List<Id> familyIdList = new List<Id>();

        for(Product2 product : productList){
            familyIdList.add(product.Family__c);
        }

        String query = '';

        query = 'SELECT Id, Name, Account__c, Crop__r.Name, RecordType.DeveloperName, Crop__c, InterestPriority__c,'            +
                        ' Priority__c, SalesCondition__c, InitialDate__c, CalculatedUnitPrice__c, IsActive__c,'                 +
                        ' EffectiveDate__c, ActivitySector__c, ProductFamily__r.Name, ProductFamily__c,'                        +
                        ' Currency__c, UnitPrice__c, EndDate__c, InterestValue__c, Product2Id__r.Name, Product2Id__c,'          +
                        ' SalesTeam__r.DisplayName__c,SalesTeam__c, SalesOffice__c, Product2Id__r.ActivePrinciple__c,'          +
                        ' CalculatedInterest__c, Product2Id__r.Family__c'                                                       +
                ' FROM ListPrice__c'                                                                                            +
                ' WHERE IsActive__c = true'                                                                                     +
                ' AND RecordType.DeveloperName != \'PR00\''                                                                     +
                ' AND EffectiveDate__c != null'                                                                                 +
                ' AND EndDate__c >= TODAY'                                                                                      +
                ' AND InitialDAte__c <= TODAY';

        if(!salesOfficeList.isEmpty()){
            query = query + ' AND (SalesOffice__c IN: salesOfficeList OR SalesOffice__c = null)';
        }

        if(crop != null){
            query = query + ' AND (Crop__c =: crop OR Crop__c = null)';
        }

        if(salesCondition != null && salesCondition != 'All'){
            query = query + ' AND (SalesCondition__c =: salesCondition OR SalesCondition__c = null)';
        }

        if(currencyType != null){
            query = query + ' AND (Currency__c =: currencyType OR Currency__c = null)';
        }

        if(productFamily != null){
            query = query + ' AND (ProductFamily__c =: productFamily OR ProductFamily__c = null)';
        }
        
        if(!orgList.isEmpty()){
            query = query + ' AND (SalesOrg__c IN: orgList OR SalesOrg__c = null)';
        }

        query = query + ' Order By InterestPriority__c ASC';

        System.debug(query);

        return Database.query(query);
    }

}
