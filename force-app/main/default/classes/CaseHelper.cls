public without sharing class CaseHelper {
    private static Boolean runTrigger;
    private static Id ocorrenceRecordTypeid;
    static {
        runTrigger = true;
        ocorrenceRecordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OcorrenceField').getRecordTypeId();
    }

    public static Boolean isTriggerEnabled(){
        return runTrigger;
    }

    public static Boolean enableTrigger(){
        return runTrigger = true;
    }

    public static Boolean disableTrigger(){
        return runTrigger = false;
    }
    public static void eventContext(Map<Id, Case> contextMap){
        List<Event> eventList = new List<Event>();
        for(Case cs : contextMap.values()){
            if(cs.RecordTypeId == ocorrenceRecordTypeid && cs.Comments != null && cs.Comments.contains('00U')){
                eventList.add(new Event(Id = cs.Comments, Case__c = cs.id));
            }
        }
        try{
        if(!eventList.isEmpty())
            update eventList;
        }catch(Exception ex){}
    }
    public static void ownerContext(Map<Id, Case> contextMap){
        Map<id, Id> csIdToOwnerMap = new Map<id, Id>();
        for(Case cs : contextMap.values()){
            if(cs.RecordTypeId == ocorrenceRecordTypeid){
                csIdToOwnerMap.put(cs.id, cs.CreatedByid);
            }
        }
        if(!csIdToOwnerMap.isEmpty())
            setOwner(csIdToOwnerMap);
    }

    @future
    public static void setOwner(Map<id, Id> csIdToOwnerMap){
        List<Case> csContext = new List<Case>();
        for(Id csId : csIdToOwnerMap.keySet()){
            csContext.add(new Case(Id = csId , OwnerId = csIdToOwnerMap.get(csId)));
        }
        if(!csContext.isEmpty()){
            update csContext;
        }
    }
}
