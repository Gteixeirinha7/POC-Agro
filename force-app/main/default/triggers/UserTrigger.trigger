trigger UserTrigger on User (after insert, after update) {
    if (RelatedUserSalesTeamHelper.isTriggerEnabled()) {
        switch on Trigger.operationType {
            when AFTER_INSERT {        
                RelatedUserSalesTeamHelper.handleUsers(Trigger.new);          
            }
            when AFTER_UPDATE {
                RelatedUserSalesTeamHelper.handleUsers(Trigger.new);      
            }
        }
    }    

}