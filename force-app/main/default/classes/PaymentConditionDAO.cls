public with sharing class PaymentConditionDAO {
    
    public static List<PaymentCondition__c> getPaymentConditionByExternalId(List<String> externalIds, Set<String> paymentConditionUsedFields) {

        String query = new Q(PaymentCondition__c.SObjectType)
            .selectFields(paymentConditionUsedFields)
            .add(Q.condition('ExternalId__c').isIn(externalIds))
            .build();
            
        return Database.query(query);
    }

}
