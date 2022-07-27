public with sharing class FreightHelper {
    private static Boolean isEnabled;

    static{
        isEnabled = true;
    }

    public static Boolean isTriggerEnabled(){
        return isEnabled;
    }
    
    public static Boolean disableTrigger(){
        return isEnabled = false;
    }

    public static Boolean enableTrigger(){
        return isEnabled = true;
    }
    public static void mapRecords(List<Freight__c> context){
        for(Freight__c fre : context){
            fre.ExternalId__c = fre.ExternalIdIndex__c;
        }
    }
}
