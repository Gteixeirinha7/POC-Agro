trigger CampaignOrderItemTrigger on CampaignOrderItem__c  (after insert, after update, after delete) {
    if(CampaignOrderItemTriggerHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when AFTER_DELETE {
                CampaignOrderItemTriggerHelper.checkDiscountOrderItem(Trigger.old);
            }

            when AFTER_UPDATE {
                CampaignOrderItemTriggerHelper.checkDiscountOrderItem(Trigger.new);
            }

            when AFTER_INSERT {
                CampaignOrderItemTriggerHelper.checkDiscountOrderItem(Trigger.new);
            }
        }
    }
}