public without sharing class CampaignOrderItemTriggerHelper {
    private static Boolean runTrigger;

    static {
        runTrigger = true;
    }

    public static Boolean isTriggerEnabled(){
        return runTrigger;
    }

    public static Boolean enableTrigger(){
        return runTrigger = true;
    }

    public static Boolean disableTrigger(){
        return runTrigger = false;
    }
    public static void checkDiscountOrderItem(CampaignOrderItem__c[] context){ 
        Map<Id, OrderItem> ordItemMap = new Map<Id, OrderItem>();
        for(CampaignOrderItem__c campaigns : context){
            ordItemMap.put(campaigns.OrderItem__c, new OrderItem(Id = campaigns.OrderItem__c, CampaignPercent__c = 0, CampaignIndustryPercent__c = 0, CampaigPercent__c = 0));
        }

        for(CampaignOrderItem__c campaings : [SELECT id, FixedUnitPriceCampaign__c, OrderItem__c, Discount__c, Campaign__r.RecordType.DeveloperName FROM CampaignOrderItem__c WHERE OrderItem__c IN :ordItemMap.keySet()]){
            OrderItem ordItem = ordItemMap.get(campaings.OrderItem__c);
            ordItem.FixedUnitPriceCampaign__c = campaings.FixedUnitPriceCampaign__c;
            if(campaings.Campaign__r.RecordType.DeveloperName != 'ForcaAgro')
                ordItem.CampaignIndustryPercent__c += campaings.Discount__c;
            else
                ordItem.CampaigPercent__c += campaings.Discount__c;
                
            ordItem.CampaignPercent__c += campaings.Discount__c;
            ordItemMap.put(campaings.OrderItem__c, ordItem);
        }

        if(!ordItemMap.isEmpty()){
            update ordItemMap.values();
        }
    }
}