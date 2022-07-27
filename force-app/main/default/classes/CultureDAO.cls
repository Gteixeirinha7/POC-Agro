public with sharing class CultureDAO {
    
    public static List<Culture__c> getCultureByExternalId(List<String> externalIds, Set<String> cultureUsedFields) {

        String query = new Q(Culture__c.SObjectType)
            .selectFields(cultureUsedFields)
            .add(Q.condition('ExternalId__c').isIn(externalIds))
            .build();
            
        return Database.query(query);
    }
    
}
