public with sharing class OrderItemDAO {
    
    public static List<OrderItem> getOrderItemByExternalId(List<String> externalIds, Set<String> orderItemUsedFields) {

        String query = new Q(OrderItem.SObjectType)
            .selectFields(orderItemUsedFields)
            .add(Q.condition('ExternalId__c').isIn(externalIds))
            .build();
            
        return Database.query(query);
    }

    public static List<OrderItem> getOrderItemByOrderId(List<String> orderIds, Set<String> orderItemUsedFields) {

        String query = new Q(OrderItem.SObjectType)
            .selectFields(orderItemUsedFields)
            .add(Q.condition('OrderId').isIn(orderIds))
            .build();
            
        return Database.query(query);
    }

}
