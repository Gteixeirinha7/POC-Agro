trigger Account on Account  (before insert, before update, after insert, after update, before delete) {
    if(RelationsTerritoryClass.isTriggerEnabled()){
        switch on Trigger.operationType{
          

            when AFTER_UPDATE {
            }

            when AFTER_INSERT {
            }
        }
    }
}