public with sharing class DistributionCenterDAO {
    
    public static List<DistributionCenter__c> getDistributionCenterByExternalId(List<String> externalIds, Set<String> distributionCenterUsedFields) {

        String query = new Q(DistributionCenter__c.SObjectType)
            .selectFields(distributionCenterUsedFields)
            .add(Q.condition('ExternalId__c').isIn(externalIds))
            .build();
            
        return Database.query(query);
    }

    public static List<DistributionCenter__c> getDistributionCenterBylId(List<String> ids, Set<String> distributionCenterUsedFields) {

        String query = new Q(DistributionCenter__c.SObjectType)
            .selectFields(distributionCenterUsedFields)
            .add(Q.condition('Id').isIn(ids))
            .build();
            
        return Database.query(query);
    }

}
