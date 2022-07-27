@RestResource(urlMapping='/ForcaAgroApp/1_0/createOrder/*')
global without sharing class OrderController {
    @HttpPost
    global static OrderResponse createOrderApp(string orderReq){
        return createOrder(orderReq);
    }

    @AuraEnabled
    global static OrderResponse createOrderScreen(string orderReq){
        return createOrder(orderReq);
    }
    global static OrderResponse createOrder(string orderReq){
        OrderResponse ordResponse = null;
        Savepoint sp = null;
        OrderRequest ordRequest = (OrderRequest)JSON.deserialize(orderReq, OrderRequest.class);
        try{
            sp = Database.setSavepoint();

        }catch(Exception ex){
            Database.rollback(sp);
            ordResponse = new OrderResponse(ex, ordRequest);
        }
        return ordResponse;
    }
    
	global abstract class OrderBaseRequest{
        @AuraEnabled public String  id                      {get;set;}
        @AuraEnabled public OrderItemResponse[] itens {get;set;}
    }
	global abstract class OrderItemBaseRequest{
        @AuraEnabled public String  id                      {get;set;}
    }
    global class OrderResponse extends OrderBaseRequest{
        @AuraEnabled public Boolean hasError {get;set;}
        @AuraEnabled public String errorMsg {get;set;}
        public OrderResponse(Exception ex, OrderRequest ordReq){
            this.hasError = true;
            this.errorMsg = ex.getMessage();//+'\n Erro :'+ex.getStackTraceString();
        } 
        public OrderResponse(String error, OrderRequest ordReq){
            this.hasError = true;
            this.errorMsg = error;
        }
        public OrderResponse(OrderRequest ordReq, Order ord){
            this.hasError                = false;
            this.errorMsg                = 'Sucesso!';

            this.itens = new List<OrderItemResponse>();
        }  
    }
    global class OrderItemResponse extends OrderItemBaseRequest{
        @AuraEnabled public Boolean hasError {get;set;}
        @AuraEnabled public String errorMsg {get;set;}
        public OrderItemResponse(Exception ex, OrderRequest ordReq){
            this.hasError = true;
            this.errorMsg = ex.getMessage();//+'\n Erro :'+ex.getStackTraceString();
        } 
        public OrderItemResponse(String error, OrderRequest ordReq){
            this.hasError = true;
            this.errorMsg = error;
        }
        public OrderItemResponse(OrderRequest ordReq, Order ord){
            this.hasError                = false;
            this.errorMsg                = 'Sucesso!';
        }  
    }
    global class OrderRequest extends OrderBaseRequest {   
        public Order getOrder(){
            return new Order();
        }
    }
    global class OrderItemRequest extends OrderItemBaseRequest {   
        public OrderItem getOrderItem(){
            return new OrderItem();
        }
    }

}
