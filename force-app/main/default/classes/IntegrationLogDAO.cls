public with sharing class IntegrationLogDAO {
    
    public static List<IntegrationLog__c> getIntegrationLog(Set<String> integrationLogUsedFields, Integer limite) {

        String query = new Q(IntegrationLog__c.SObjectType)
            .selectFields(integrationLogUsedFields)
            .addLimit(limite)
            .build();
            
        return Database.query(query);
    }

}
