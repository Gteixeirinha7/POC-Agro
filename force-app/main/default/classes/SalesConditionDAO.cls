public with sharing class SalesConditionDAO {
    
    public static List<SalesCondition__c> getActiveSalesConditions(Set<String> salesConditionUsedFields) {

        String query = new Q(SalesCondition__c.SObjectType)
            .selectFields(salesConditionUsedFields)
            .add(Q.condition('IsActive__c').equalsTo(true))
            .build();
            
        return Database.query(query);
    }
}
