public with sharing class OrderDAO {
    
    public static List<Order> getOrderById(List<String> ids, Set<String> orderUsedFields) {

        String query = new Q(Order.SObjectType)
            .selectFields(orderUsedFields)
            .add(Q.condition('Id').isIn(ids))
            .build();
            
        return Database.query(query);
    }

    public static List<Order> getOrderByOrderNumber(List<String> orderNumbers, Set<String> orderUsedFields) {

        String query = new Q(Order.SObjectType)
            .selectFields(orderUsedFields)
            .add(Q.condition('OrderNumber').isIn(orderNumbers))
            .add(Q.condition('OrderNumber').isNotNull())
            .build();
            
        return Database.query(query);
    }

    public static List<Order> getOrderByExternalId(List<String> externalIds, Set<String> orderUsedFields) {

        String query = new Q(Order.SObjectType)
            .selectFields(orderUsedFields)
            .add(Q.condition('ExternalId__c').isIn(externalIds))
            .add(Q.condition('ExternalId__c').isNotNull())
            .build();
            
        return Database.query(query);
    }

}
