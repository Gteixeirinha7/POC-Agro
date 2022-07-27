trigger Freight on Freight__c (before insert, before update) {
    if (FreightHelper.isTriggerEnabled()) {
        switch on Trigger.operationType {
            when BEFORE_INSERT {
                PricingParamExternalKeyMapper.mapRecords(Trigger.new, Freight__c.SObjectType);
                FreightHelper.mapRecords(Trigger.new);
            }
            when BEFORE_UPDATE{
                PricingParamExternalKeyMapper.mapRecords(Trigger.new, Freight__c.SObjectType);
                FreightHelper.mapRecords(Trigger.new);
            }
        }
    }
}