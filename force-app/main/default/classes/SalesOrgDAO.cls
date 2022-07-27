public with sharing class SalesOrgDAO {
    
    public static List<SalesOrg__c> getSalesOrgById(List<String> ids, Set<String> salesOrgUsedFields) {

        String query = new Q(SalesOrg__c.SObjectType)
            .selectFields(salesOrgUsedFields)
            .add(Q.condition('Id').isIn(ids))
            .build();
            
        return Database.query(query);
    }
    
    public static List<SalesOrg__c> getSalesOrgByExternalId(List<String> externalIds, Set<String> salesOrgUsedFields) {

        String query = new Q(SalesOrg__c.SObjectType)
            .selectFields(salesOrgUsedFields)
            .add(Q.condition('ExternalId__c').isIn(externalIds))
            .build();
            
        return Database.query(query);
    }

}
