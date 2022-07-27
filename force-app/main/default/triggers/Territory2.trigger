trigger Territory2 on Territory2 (before delete) {
    if(Territory2Helper.isTriggerEnabled()){
        switch on Trigger.operationType{
            when BEFORE_DELETE {
                Territory2Helper.getTerritoryRelations(Trigger.old);
            }
        }
    }
}