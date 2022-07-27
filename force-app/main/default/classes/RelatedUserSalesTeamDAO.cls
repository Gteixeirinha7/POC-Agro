public with sharing class RelatedUserSalesTeamDAO {
    
    public static List<RelatedUserSalesTeam__c> getRelatedUserSalesTeamByRTV(List<String> rtvs, Set<String> relatedUserSalesTeamUsedFields) {

        String query = new Q(RelatedUserSalesTeam__c.SObjectType)
            .selectFields(relatedUserSalesTeamUsedFields)
            .add(Q.condition('RTV__c').isIn(rtvs))
            .build();
            
        return Database.query(query);
    }

}
