global without sharing class DeleteOrderWithoutSharing {

    @InvocableMethod(label='Delete Order Without Sharing' description='Delete Order Without Sharing' category = 'Apex To Flow')
    public static void deleteOrder(List<String> orderIds){
        Database.delete(new Order(Id = orderIds[0]));
    }
    
}