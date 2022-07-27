trigger ProductManagement on ProductManagement__c (before insert, before update) {
    if(ProductManagementHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when BEFORE_INSERT {
                ProductManagementHelper.setExternalId(Trigger.new);
                ProductManagementHelper.setSalesOrgname(Trigger.new);
            }
            when BEFORE_UPDATE {
                ProductManagementHelper.setExternalId(Trigger.new);
                ProductManagementHelper.setSalesOrgname(Trigger.new);
            }
        }
    }
}