public with sharing class Territory2DAO {

    public static List<Territory2> getTerritory2ByExternalId(List<String> externalIds, Set<String> territory2UsedFields) {

        String query = new Q(Territory2.SObjectType)
            .selectFields(territory2UsedFields)
            .add(Q.condition('ExternalId__c').isIn(externalIds))
            .build();
            
        return Database.query(query);
    }

    public static List<Territory2> getTerritory2ByExternalIdAndTerritoryTypeDeveloperName(List<String> externalIds, String territoryTypeDeveloperName, Set<String> territory2UsedFields){

        String query = new Q(Territory2.SObjectType)
            .selectFields(territory2UsedFields)
            .add(Q.condition('ExternalId__c').isIn(externalIds))
            .add(Q.condition('Territory2Type.DeveloperName').equalsTo(territoryTypeDeveloperName))
            .build();
            
        return Database.query(query);
    }

}
