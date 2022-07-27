public with sharing class CustomerPerOrgDAO {

    public static List<CustomerPerOrg__c> getCustomerPerOrgByExternalId(List<String> externalIds, Set<String> customerPerOrgUsedFields) {

        String query = new Q(CustomerPerOrg__c.SObjectType)
            .selectFields(customerPerOrgUsedFields)
            .add(Q.condition('ExternalId__c').isIn(externalIds))
            .add(Q.condition('Blocked__c').equalsTo(false))
            .build();
            
        return Database.query(query);
    }

    public static List<CustomerPerOrg__c> getCustomerPerOrgByAccountIdDiffIds(List<String> ids, List<String> accountIds, Set<String> customerPerOrgUsedFields){
        
        String query = new Q(CustomerPerOrg__c.SObjectType)
            .selectFields(customerPerOrgUsedFields)
            .add(Q.condition('Id').isNotIn(ids))
            .add(Q.condition('Customer__c').isIn(accountIds))
            .add(Q.condition('Blocked__c').equalsTo(false))
            .build();
            
        return Database.query(query);
    }

}
