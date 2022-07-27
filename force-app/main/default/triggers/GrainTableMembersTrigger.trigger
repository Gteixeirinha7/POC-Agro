trigger GrainTableMembersTrigger on GrainTableMembers__c (after insert, after update, after delete) {
    if (GrainTableMembersHelper.isTriggerEnabled()) {
        switch on Trigger.operationType{
            when AFTER_INSERT {
                GrainTableMembersHelper.insertGroupMember(Trigger.new);
            }
            
            when AFTER_UPDATE {
                GrainTableMembersHelper.updateGroupMember(Trigger.new, Trigger.old);
            }
            
            when AFTER_DELETE {
                GrainTableMembersHelper.deleteGroupMember(Trigger.old);
            }
        }
    }
}