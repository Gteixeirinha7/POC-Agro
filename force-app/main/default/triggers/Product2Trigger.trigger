trigger Product2Trigger on Product2 (after insert,before insert, before update, before delete) {
    if (Product2Helper.isTriggerEnabled()) {
        switch on Trigger.operationType {
            when AFTER_INSERT {        
                Product2Helper.createStandardEntries(Trigger.new);
            }
            when BEFORE_INSERT {
                Product2Helper.removeLeadingZeros(Trigger.new);
                EcommerceUtils.checkProduct2(Trigger.new, true);
            }
            when BEFORE_UPDATE {
                Product2Helper.removeLeadingZeros(Trigger.new);
                EcommerceUtils.checkProduct2(Trigger.new, true);
            }
            when BEFORE_DELETE {
                EcommerceUtils.checkProduct2(Trigger.new, false);
            }
        }
    } 
}