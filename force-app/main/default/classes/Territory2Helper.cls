public with sharing class Territory2Helper {
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

    @future
    public static void deleteTerritoryRelations(Map<String,String> objectNameExternalIdMap){
        Boolean flagCluster = false;
        Boolean flagSalesOrg = false;
        Boolean flagSalesOffice = false;
        Boolean flagSalesTeam = false;

        List<Cluster__c> clusterListToDelete = new List<Cluster__c>();
        List<SalesOrg__c> salesOrgListToDelete = new List<SalesOrg__c>();
        List<SalesOffice__c> salesOfficeListToDelete = new List<SalesOffice__c>();
        List<SalesTeam__c> salesTeamListToDelete = new List<SalesTeam__c>();

        List<SObject> objectList = new List<SObject>();
        for(String objectName : objectNameExternalIdMap.keySet()){
            if(objectName == 'Cluster__c'){
                flagCluster = true;
            }
            else if(objectName == 'SalesOrg__c'){
                flagSalesOrg = true;
            }
            else if(objectName == 'SalesOffice__c'){
                flagSalesOffice = true;
            }
            else if(objectName == 'SalesTeam__c'){
                flagSalesTeam = true;
            }
        }

        if(flagCluster){
            for(Cluster__c cluster : [SELECT Id FROM Cluster__c WHERE ExternalId__c IN: objectNameExternalIdMap.values()]){
                clusterListToDelete.add(cluster);
            }
        }
        if(flagSalesOrg){
            for(SalesOrg__c salesOrg : [SELECT Id FROM SalesOrg__c WHERE ExternalId__c IN: objectNameExternalIdMap.values()]){
                salesOrgListToDelete.add(salesOrg);
            }
        }
        if(flagSalesOffice){
            for(SalesOffice__c salesOffice : [SELECT Id FROM SalesOffice__c WHERE ExternalId__c IN: objectNameExternalIdMap.values()]){
                salesOfficeListToDelete.add(salesOffice);
            }
        }
        if(flagSalesTeam){
            for(SalesTeam__c salesTeam : [SELECT Id FROM SalesTeam__c WHERE ExternalId__c IN: objectNameExternalIdMap.values()]){
                salesTeamListToDelete.add(salesTeam);
            }
        }

        RelationsTerritoryClass.disableTrigger();
        if(!clusterListToDelete.isEmpty()){
            delete clusterListToDelete;
        }
        if(!salesOrgListToDelete.isEmpty()){
            delete salesOrgListToDelete;
        }
        if(!salesOfficeListToDelete.isEmpty()){
            delete salesOfficeListToDelete;
        }
        if(!salesTeamListToDelete.isEmpty()){
            delete salesTeamListToDelete;
        }
        RelationsTerritoryClass.enableTrigger();
    }

    public static void getTerritoryRelations(List<Territory2> oldRecordList){
        String externalIdRep;
        String formattedExternalId;
        Map<String,String> objectNameExternalIdMap = new Map<String,String>();
        Map<Id,String> territory2TypeIdToDeveloperName = new Map<Id,String>();
        
        for(Territory2Type ter2Type : [SELECT Id, DeveloperName FROM Territory2Type]){
            territory2TypeIdToDeveloperName.put(ter2Type.Id, ter2Type.DeveloperName);    
        }
        
        for(Territory2 ter : oldRecordList){
            externalIdRep = ter.ExternalId__c;
            formattedExternalId = externalIdRep.replace(territory2TypeIdToDeveloperName.get(ter.Territory2TypeId), '');
            objectNameExternalIdMap.put(territory2TypeIdToDeveloperName.get(ter.Territory2TypeId)+'__c', formattedExternalId);
        }
        if(!objectNameExternalIdMap.isEmpty()){
            deleteTerritoryRelations(objectNameExternalIdMap);
        }
    }
}