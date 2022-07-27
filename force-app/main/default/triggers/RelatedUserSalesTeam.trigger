trigger RelatedUserSalesTeam on RelatedUserSalesTeam__c (after insert, after update, after delete) {
    if (RelatedUserSalesTeamHelper.isTriggerEnabled()) {
        switch on Trigger.operationType {
            when AFTER_INSERT {        
                RelatedUserSalesTeamHelper.handleGroupMember(Trigger.new);                
                RelatedUserSalesTeamHelper.handleShareUser(Trigger.new);
            }
            when AFTER_UPDATE {
                RelatedUserSalesTeamHelper.handleGroupMember(Trigger.new);                
                RelatedUserSalesTeamHelper.handleShareUser(Trigger.new);
            }
            when AFTER_DELETE {
                RelatedUserSalesTeamHelper.handleGroupMember(Trigger.old);                
                RelatedUserSalesTeamHelper.handleShareUser(Trigger.old);
            }
        }
    }    
}