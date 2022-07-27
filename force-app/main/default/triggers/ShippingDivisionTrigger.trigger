trigger ShippingDivisionTrigger on ShippingDivision__c (before insert, after insert, before update) {
    if (ShippingDivisionHelper.isTriggerEnabled()) {

    switch on Trigger.operationType{
        when BEFORE_INSERT{
            ShippingDivisionHelper.tablueuField(Trigger.new);
        }
        when BEFORE_UPDATE{
            ShippingDivisionHelper.checkRefuseReason(Trigger.new, Trigger.oldMap);
            ShippingDivisionHelper.updateShare(Trigger.new);
            ShippingDivisionHelper.tablueuField(Trigger.new);

        }
        when AFTER_INSERT{
            ShippingDivisionHelper.checkRefuseReason(Trigger.new, null);
            ShippingDivisionHelper.createShippingDivision(Trigger.new);
            ShippingDivisionHelper.createShareShippingDivision(Trigger.new);
        }
    }
    }

}