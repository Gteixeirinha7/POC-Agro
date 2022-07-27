trigger RangeDiscount on RangeDiscount__c (before insert,after insert, before update, after update) {
    if(RangeDiscountHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when BEFORE_INSERT {
                RangeDiscountHelper.initRangeDiscountValidation(Trigger.new);
            }
            when AFTER_INSERT {
                RangeDiscountHelper.rangeDiscountValidation(Trigger.newMap);
            }
            when BEFORE_UPDATE {
                RangeDiscountHelper.initRangeDiscountValidation(Trigger.new);
            }
            when AFTER_UPDATE {
                RangeDiscountHelper.rangeDiscountValidation(Trigger.newMap);
            }
        }
    }
}