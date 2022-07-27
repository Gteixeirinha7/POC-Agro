trigger OrderTrigger on Order (before insert, before update, after insert, after update, before delete) {
    if (OrderHelper.isTriggerEnabled()) {
        switch on Trigger.operationType{
            
            when BEFORE_UPDATE {
                OrderHelper.updatePath(Trigger.new);
                OrderHelper.sendToGrainTable(Trigger.new, Trigger.oldMap);
                OrderHelper.newApprovalProcessFields(Trigger.newMap, Trigger.oldMap);
                OrderHelper.clearRejectFields(Trigger.new, Trigger.oldMap);
                OrderHelper.checkIntegrationError(Trigger.new, Trigger.oldMap);
            }

            when BEFORE_INSERT {
                OrderHelper.updatePath(Trigger.new);
                OrderHelper.commodityProduct(Trigger.new);
            }
            
            when BEFORE_DELETE {
                OrderHelper.deleteShipping(Trigger.oldMap.keySet());
            }

            when AFTER_UPDATE {
                // OrderHelper.checkProcess(Trigger.newMap, Trigger.oldMap);
                OrderHelper.shareRead(Trigger.new, Trigger.oldMap);
                OrderHelper.attAccountLastBuyInfo(Trigger.newMap);
                OrderHelper.insertUpdateFinancialDueDate(Trigger.new);
                OrderHelper.initIntegrationGrainPurchaseContractOrderActive(Trigger.new);
                OrderHelper.verifyToCallApprovalProcess(Trigger.new, Trigger.oldMap);
                OrderHelper.checkContractCredit(Trigger.new, Trigger.oldMap);
                OrderHelper.initIntegrationOrderBarterActive(Trigger.new, Trigger.oldMap);
                OrderHelper.initIntegrationOrderActive(Trigger.new, Trigger.oldMap);
                OrderHelper.sendNotificationRTV(Trigger.new, Trigger.oldMap);
            }

            when AFTER_INSERT {
                // OrderHelper.initIntegrationOrderActive(Trigger.new);
                OrderHelper.shareRead(Trigger.new);
                OrderHelper.insertUpdateFinancialDueDate(Trigger.new);
                OrderHelper.verifyToCallApprovalProcess(Trigger.new);
                OrderHelper.initIntegrationGrainPurchaseContractOrderActive(Trigger.new);
            }
        }
    }
}