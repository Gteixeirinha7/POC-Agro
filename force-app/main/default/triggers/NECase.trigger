trigger NECase on Case (before insert, before update, after insert) {
    if(CaseHelper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when AFTER_INSERT {
                CaseHelper.ownerContext(Trigger.newMap);
                CaseHelper.eventContext(Trigger.newMap);
            }
        }
    }
}