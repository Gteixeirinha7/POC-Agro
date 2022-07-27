public with sharing class SalesOfficeDAO {
    
    public static List<SalesOffice__c> getSalesOfficeByExternalId(List<String> externalIds, Set<String> salesOfficeUsedFields) {

        String query = new Q(SalesOffice__c.SObjectType)
            .selectFields(salesOfficeUsedFields)
            .add(Q.condition('ExternalId__c').isIn(externalIds))
            .build();
            
        return Database.query(query);
    }

    public static List<SalesOffice__c> getSalesOfficeByGGN(List<String> gnns, Set<String> salesOfficeUsedFields) {

        String query = new Q(SalesOffice__c.SObjectType)
            .selectFields(salesOfficeUsedFields)
            .add(Q.condition('GGN__c').isIn(gnns))
            .build();
            
        return Database.query(query);
    }

}
