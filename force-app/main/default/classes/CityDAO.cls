public with sharing class CityDAO {
    
    public static List<City__c> getCityByExternalId(List<String> externalIds, Set<String> cityUsedFields) {

        String query = new Q(City__c.SObjectType)
            .selectFields(cityUsedFields)
            .add(Q.condition('ExternalId__c').isIn(externalIds))
            .build();
            
        return Database.query(query);
    }

}
