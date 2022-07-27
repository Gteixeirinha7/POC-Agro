trigger SalesOrg on SalesOrg__c  (before insert, before update, after insert, after update, before delete) {
    //System.debug(Trigger.new);
    if(RelationsTerritoryClass.isTriggerEnabled()){
        switch on Trigger.operationType{
             
            when BEFORE_UPDATE {
                //RelationsTerritoryClass.createTerritory(Trigger.new);
            } 

            when BEFORE_INSERT {
                //RelationsTerritoryClass.createTerritory(Trigger.new);
            }
            
            when BEFORE_DELETE {
                //RelationsTerritoryClass.deleteTerritory(Trigger.old);
            }

            when AFTER_UPDATE {
            }

            when AFTER_INSERT {
            }
        }
    }
}