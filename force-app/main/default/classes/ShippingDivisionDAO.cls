public with sharing class ShippingDivisionDAO {

    public static List<ShippingDivision__c> getShippingDivisionByExternalId(List<String> externalIds, Set<String> shippingDivisionUsedFields) {

        String query = new Q(ShippingDivision__c.SObjectType)
            .selectFields(shippingDivisionUsedFields)
            .add(Q.condition('ExternalId__c').isIn(externalIds))
            .build();
            
        return Database.query(query);
    }


}
