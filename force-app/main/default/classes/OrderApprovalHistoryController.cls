global class OrderApprovalHistoryController implements Schedulable{
    
    global void execute(SchedulableContext SC){
        try{
            Map<String, Object> params = new Map<String, Object>();
            Flow.Interview.Order_ApprovalHistory myFlow = new Flow.Interview.Order_ApprovalHistory(params);
            myFlow.start();
        } catch(Exception e){
            system.debug('Error: ' + e);
        }
    }

}