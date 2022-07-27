public class CalloutOrderQueueable implements Queueable, Database.AllowsCallouts {
    public List<Id> approvedOrderIds {get;set;}
    public CalloutOrderQueueable(List<Id> approvedOrderIdsList){
        this.approvedOrderIds = approvedOrderIdsList;
    }
    public void execute(QueueableContext context){
        CalloutOrder.processIntegration(this.approvedOrderIds);
    }
}