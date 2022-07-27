public with sharing class SalesTeamDAO {
    
    public static List<SalesTeam__c> getSalesTeamByExternalId(List<String> externalIds, Set<String> salesTeamUsedFields) {

        String query = new Q(SalesTeam__c.SObjectType)
            .selectFields(salesTeamUsedFields)
            .add(Q.condition('ExternalId__c').isIn(externalIds))
            .build();
            
        return Database.query(query);
    }
    public static List<SalesTeam__c> getSalesTeamById(List<String> Ids, Set<String> salesTeamUsedFields) {

        String query = new Q(SalesTeam__c.SObjectType)
            .selectFields(salesTeamUsedFields)
            .add(Q.condition('Id').isIn(Ids))
            .build();
            
        return Database.query(query);
    }

    public static List<SalesTeam__c> getSalesTeamByManager(List<String> managers, Set<String> salesTeamUsedFields) {

        String query = new Q(SalesTeam__c.SObjectType)
            .selectFields(salesTeamUsedFields)
            .add(Q.condition('Manager__c').isIn(managers))
            .build();
            
        return Database.query(query);
    }

}
