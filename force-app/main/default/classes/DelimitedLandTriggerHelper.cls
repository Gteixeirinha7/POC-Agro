public without sharing class DelimitedLandTriggerHelper {
    private static Boolean runTrigger;

    static {
        runTrigger = true;
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

    public static void checkDelimitedLandId(List<DelimitedLandCultures__c> delimitedLandCultureList) {
        List<Id> delimitedLandIdList = new List<Id>();

        for (DelimitedLandCultures__c delimitedLandCulture : delimitedLandCultureList) {
            delimitedLandIdList.add(delimitedLandCulture.DelimitedLand__c);
        }

        sendDelimitedLandNotFuture(delimitedLandIdList);
    }

    public static void checkCultureRecords(Map<Id, DelimitedLandCultures__c> context){

        Map<Id, Set<Id>> contextMap = new Map<Id, Set<Id>>();
        List<DelimitedLand__c> contextDelimitedLand = new List<DelimitedLand__c>();
        for(DelimitedLandCultures__c cultures : context.values()){
            contextDelimitedLand.add(new DelimitedLand__c(Id = cultures.DelimitedLand__c));
            if(!contextMap.containsKey(cultures.DelimitedLand__c))
                contextMap.put(cultures.DelimitedLand__c, new Set<Id>());
            contextMap.get(cultures.DelimitedLand__c).add(cultures.Id);
        }
        
        Database.SaveResult[] results = Database.update(contextDelimitedLand, false);
        for(Database.SaveResult sv : results){
            if(sv.isSuccess()) continue;

            for(Id cultureId : contextMap.get(sv.getId()))
                context.get(cultureId).addError(getError(sv));
        }
    }
    public static void checkCultureRecords(Map<Id, DelimitedLand__c> context){
        Map<String, Decimal> delimitedMap = new Map<String, Decimal>();  
        for(DelimitedLandCultures__c culture : [SELECT id, TotalAreaMeters__c, DelimitedLand__r.AreaPasture__c, DelimitedLand__r.AreaCultivated__c, AreaCultivated__c, Crop__c, DelimitedLand__c, DelimitedLand__r.AreaCultivatedLandMeters__c, Culture__c, Culture__r.name, DelimitedLand__r.UnitMeasurement__c, DelimitedLand__r.AreaCultivatedLand__c
                                                FROM DelimitedLandCultures__c 
                                                WHERE DelimitedLand__c IN : context.keySet()]){
            String key = culture.Crop__c+'_'+culture.DelimitedLand__c+'_'+culture.Culture__r.name;

            delimitedMap.put(key, (delimitedMap.containsKey(key) ? delimitedMap.get(key) : 0) + culture.AreaCultivated__c);
            
            if(culture.DelimitedLand__r.AreaCultivatedLand__c < delimitedMap.get(key)){
                context.get(culture.DelimitedLand__c).addError('A área do Talhão ('+culture.DelimitedLand__r.AreaCultivatedLand__c.setScale(2)+' '+culture.DelimitedLand__r.UnitMeasurement__c+') é menor do que a area cultivada pela cultura: '+culture.Culture__r.name+' ('+delimitedMap.get(key).setScale(2)+' '+culture.DelimitedLand__r.UnitMeasurement__c+')');
            }
        }
    }
    public static void sumAccountLand(List<DelimitedLand__c> context){
        
        Map<Id, Account> accMap = new Map<Id, Account>();
        for(DelimitedLand__c lands : [SELECT id, Account__c, Account__r.ParentId, AreaCultivatedMeteers__c, AreaNotAllocatedMeters__c, AreaPastureMeteers__c, AreaPreservationMeters__c FROM DelimitedLand__c WHERE Account__c IN :Collection.of(context).pluckIds(DelimitedLand__c.Account__c) AND Account__r.ParentId != null]){
            Account acc = accMap.containsKey(lands.Account__r.ParentId) ? accMap.get(lands.Account__r.ParentId) : new Account(Id = lands.Account__r.ParentId, AreaCultivated__c = 0, AreaNotAllocated__c = 0, AreaPasture__c = 0, AreaPreservation__c = 0);
            acc.AreaCultivated__c   += lands.AreaCultivatedMeteers__c;
            acc.AreaNotAllocated__c += lands.AreaNotAllocatedMeters__c;
            acc.AreaPasture__c      += lands.AreaPastureMeteers__c;
            acc.AreaPreservation__c += lands.AreaPreservationMeters__c;
            accMap.put(lands.Account__r.ParentId, acc);
            accMap.put(lands.Account__c, new Account(Id = lands.Account__c));
        }

        // if(!accMap.isEmpty())
            // update accMap.values();
    }
    public static String getError(Database.SaveResult svList){
        String error = '';
        for(Database.Error err : svList.getErrors()) error += err.getMessage()+'\n';
        return error;
    }

    public static void createListIdToIntegration(List<DelimitedLand__c> delimitedLandList) {
        List<Id> delimitedLandIdSet = new List<Id>();
        for (DelimitedLand__c delimitedLand : delimitedLandList) {
            delimitedLandIdSet.add(delimitedLand.Id);
        }
        sendDelimitedLand(delimitedLandIdSet);
    }

    @future(callout = true)
    public static void sendDelimitedLand(List<Id> context){
        sendDelimitedLandNotFuture(context);
    }

    public static void sendDelimitedLandNotFuture(List<Id> context){
        DelimitedLandIntegration.invocableProcessIntegration(context);
    }

}
