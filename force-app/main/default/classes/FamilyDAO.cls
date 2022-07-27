public with sharing class FamilyDAO {
    
    public static List<Family__c> getFamilyByExternalId(List<String> externalIds, Set<String> familyUsedFields) {

        String query = new Q(Family__c.SObjectType)
            .selectFields(familyUsedFields)
            .add(Q.condition('ExternalId__c').isIn(externalIds))
            .build();
            
        return Database.query(query);
    }


}
