public with sharing class Product2DAO {
    
    public static List<Product2> getProduct2ByExternalId(List<String> externalIds, Set<String> product2UsedFields) {

        String query = new Q(Product2.SObjectType)
            .selectFields(product2UsedFields)
            .add(Q.condition('ExternalId__c').isIn(externalIds))
            .add(Q.condition('ExternalId__c').isNotNull())
            .build();
            
        return Database.query(query);
    }

    public static List<Product2> getProduct2ById(List<String> ids, Set<String> product2UsedFields) {

        String query = new Q(Product2.SObjectType)
            .selectFields(product2UsedFields)
            .add(Q.condition('Id').isIn(ids))
            .build();
            
        return Database.query(query);
    }

}
