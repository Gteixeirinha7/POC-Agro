trigger OrderItemTrigger on OrderItem (before insert, before update, after insert, after update, after delete) {
    if (OrderItemHelper.isTriggerEnabled()) {
        switch on Trigger.operationType {
            when BEFORE_INSERT {
                OrderItemHelper.setMargin(Trigger.new);
            }                
            when BEFORE_UPDATE {
                OrderItemHelper.setMargin(Trigger.new); 
            }        
            when AFTER_INSERT {
                OrderItemHelper.calcMargem(Trigger.new);
            }
            when AFTER_UPDATE {
                OrderItemHelper.calcMargem(Trigger.new);            
            }  
            when AFTER_DELETE {
                OrderItemHelper.calcMargem(Trigger.old);            
            }           
        }
    }
}