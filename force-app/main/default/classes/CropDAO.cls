public with sharing class CropDAO {
    
    public static List<Crop__c> getCropByExternalId(List<String> externalIds, Set<String> cropUsedFields) {

        String query = new Q(Crop__c.SObjectType)
            .selectFields(cropUsedFields)
            .add(Q.condition('ExternalId__c').isIn(externalIds))
            .build();
            
        return Database.query(query);
    }

    public static List<Crop__c> getCropById(List<String> ids, Set<String> cropUsedFields) {

        String query = new Q(Crop__c.SObjectType)
            .selectFields(cropUsedFields)
            .add(Q.condition('Id').isIn(ids))
            .build();
            
        return Database.query(query);
    }

}
