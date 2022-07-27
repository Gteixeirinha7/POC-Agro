public class GaugeGoalController {
    public Decimal currentStatus {get;set;}
    public GaugeGoalController(ApexPages.StandardController controller){    
        Goal__c goalRecord = (Goal__c)controller.getRecord();   
        currentStatus = [SELECT id, PercentGoal__c FROM Goal__c WHERE Id =: goalRecord.Id LIMIT 1].PercentGoal__c;
        currentStatus = currentStatus.setScale(0);
    }
}