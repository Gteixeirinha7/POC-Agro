trigger DelimitedLandCultures on DelimitedLandCultures__c(after insert, after update) {
    if(DelimitedLandTriggerHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when AFTER_UPDATE {
                DelimitedLandTriggerHelper.checkCultureRecords(Trigger.newMap);
                DelimitedLandTriggerHelper.checkDelimitedLandId(Trigger.new);
            }
            when AFTER_INSERT {
                DelimitedLandTriggerHelper.checkCultureRecords(Trigger.newMap);
                DelimitedLandTriggerHelper.checkDelimitedLandId(Trigger.new);
            }
        }
    }
}