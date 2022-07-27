trigger DelimitedLand on DelimitedLand__c(before insert, before update, after insert, after update, after delete) {
    if(DelimitedLandTriggerHelper.isTriggerEnabled()){
        // switch on Trigger.operationType{
            // when BEFORE_INSERT {
            // }

            // when BEFORE_UPDATE {
            //     DelimitedLandTriggerHelper.checkCultureRecords(Trigger.newMap);
            // }

            // when AFTER_INSERT {
            //     DelimitedLandTriggerHelper.sumAccountLand(Trigger.new);
            //     DelimitedLandTriggerHelper.createListIdToIntegration(Trigger.new);
            // }
            // when AFTER_UPDATE {
            //     DelimitedLandTriggerHelper.sumAccountLand(Trigger.new);
            //     DelimitedLandTriggerHelper.createListIdToIntegration(Trigger.new);
            // }
            // when AFTER_DELETE {
            //     DelimitedLandTriggerHelper.sumAccountLand(Trigger.old);
            //     DelimitedLandTriggerHelper.createListIdToIntegration(Trigger.old);
            // }
        // }
    }
}