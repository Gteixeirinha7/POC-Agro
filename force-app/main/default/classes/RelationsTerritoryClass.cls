public class RelationsTerritoryClass {
    public static String ModelDefault;
   
    private static Boolean runTrigger = true;

    static{ 
        ModelDefault = 'Cluster';
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


    public static void deleteTerritory(sObject[] sobjectList) {
        String objectName = getObjectName(sobjectList);
        Set<String> externalIdSet = getRequestFieldSet(sobjectList, 'ExternalId__c');


        Set<String> externalSearchIdSet = new Set<String>();
        for(String extId :  externalIdSet){
            externalSearchIdSet.add(objectName+extId);
        }
        

        List<Territory2> terList = new List<Territory2>();
        for(Territory2 ter : Territory2DAO.getTerritory2ByExternalIdAndTerritoryTypeDeveloperName(new List<String>(externalSearchIdSet), objectName, new Set<String>{'Id'})){
            terList.add(ter);
        }
        if(!terList.isEmpty()){
            //DISABLE TERRITORY TRIGGER
            System.debug('terlist: '+ terlist);
            deleteDML(JSON.serialize(terList));
        }
    }
    public static void createTerritory(sObject[] sobjectList) {
        String objectName = getObjectName(sobjectList);
        Set<String> parentIdSet = objectName != 'Cluster' ? getRequestFieldSet(sobjectList, 'ParentId__c') : new Set<String>();

        Id terTypeId = getTerritoryType(objectName);

        if(terTypeId == null) return;

        Id terModelId = getTerritoryModel();

        Map<Id, Id> objtoTerMap  = getParentObjectMap(parentIdSet, objectName);

        List<Territory2> terList = new List<Territory2>();
        for(sObject sobj : sobjectList){

            Territory2 ter = new Territory2(); 
            ter.ExternalId__c = objectName+(String)sobj.get('ExternalId__c');
            ter.Description = (String)sobj.get('Description__c');
            ter.Name = (String)sobj.get('Name');
            ter.DeveloperName = objectName+(String)sobj.get('ExternalId__c');
            ter.Territory2TypeId = terTypeId;
            ter.Territory2ModelId = terModelId;

            if(objectName != 'Cluster' && objtoTerMap.containsKey((String)sobj.get('ParentId__c'))){
                ter.ParentTerritory2Id = objtoTerMap.get((String)sobj.get('ParentId__c'));
            }
            terList.add(ter);
        }
        if(!terList.isEmpty()){
            //DISABLE TERRITORY TRIGGER
            upsertDML(JSON.serialize(terList));
        }
    }
    public static String getObjectName(sObject[] sobjectList){
        for(sObject sobj : sobjectList){
            return  sobj.getSObjectType().getDescribe().getName().replace('__c', '');
        }
        return '';
    }
    public static Set<String> getRequestFieldSet(sObject[] sobjectList, string field){
        Set<String> parentIdSet = new Set<String>();
        for(sObject sobj : sobjectList){
            parentIdSet.add((String)sobj.get(field));
        }
        return parentIdSet;
    }
    public static Id getTerritoryType(String objectName){
        Id terTypeId = null;
        for(Territory2Type ter : Territory2TypeDAO.getTerritory2TypeByDeveloperName(objectName, new Set<String>{'Id'})){
            terTypeId = ter.id;
        }
        return terTypeId;
    }
    public static Id getTerritoryModel(){
        Id terModelId = null;
        for(Territory2Model ter : Territory2ModelDAO.getTerritory2ModelByDeveloperName(ModelDefault, new Set<String>{'Id'})){
            terModelId = ter.id;
        }
        return terModelId;
    }
    public static Map<Id, Id> getParentObjectMap(Set<String> parentIdSet, String objectName){

        String relatedObjectName = '';
        if(objectName == 'Cluster') return new Map<Id, Id>();
        else if(objectName == 'SalesOffice') relatedObjectName = 'Cluster';
        else if(objectName == 'SalesTeam')   relatedObjectName = 'SalesOffice';
        
        
        List<sObject> sobjRelatedList = new List<sObject>();
        sobjRelatedList.addAll(Database.query('SELECT id, ExternalId__c FROM '+relatedObjectName+'__c WHERE ID IN: parentIdSet'));

        Map<String, Id> externalIdMap = new Map<String, Id>();
        for(sObject sobj : sobjRelatedList){
            externalIdMap.put(relatedObjectName+(String)sobj.get('ExternalId__c'), (Id)sObj.get('Id'));
        }

        Map<Id, Id> objtoTerMap  = new Map<Id, Id>();
        for(Territory2 ter : Territory2DAO.getTerritory2ByExternalIdAndTerritoryTypeDeveloperName(new List<String>(externalIdMap.keySet()), relatedObjectName, new Set<String>{'Id', 'ExternalId__c'})){
            if(externalIdMap.containsKey(ter.ExternalId__c))
                objtoTerMap.put(externalIdMap.get(ter.ExternalId__c), ter.id);
        }

        return objtoTerMap;
    }
    @future
    public static void upsertDML(string territoryu2JSON){
        Database.Upsert((List<Territory2>)JSON.deserialize(territoryu2JSON, List<Territory2>.class), Territory2.ExternalId__c);
    }

    @future
    public static void deleteDML(string territoryu2JSON){
        Database.Delete((List<Territory2>)JSON.deserialize(territoryu2JSON, List<Territory2>.class));
    }
}