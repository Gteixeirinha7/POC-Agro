public class ObjectTerritory2AssociationClass {

    public static void createTerritoryAssociation(List<AccountTeamMember> accountTeamMemberListInIntegration) {
        //Map<String, String> AccountExIdTerritoryExId
        
        List<AccountTeamMember> accountTeamMemberList = getAccountTeamMembersWithId(accountTeamMemberListInIntegration);

        Set<String> userIds = getUserById(accountTeamMemberList);

        //UserId => terExIds
        Map<String, List<String>> userIdTerritoryExIdMap = getTerritoryExIds(userIds);
        system.debug('userIdTerritoryExIdMap: ' + userIdTerritoryExIdMap);

        //terExId => terId
        Map<String, String> territoryMap = getTerritoryIds(userIdTerritoryExIdMap.values());

        //List to Upsert ObjectTerritory2Association Objects
        Map<String, ObjectTerritory2Association> objTer2AssociationMap = new Map<String, ObjectTerritory2Association>();
        //System.debug('territoryMap : ' + territoryMap);
        List<String> objTer2Association = getObjectTerritory2AssociationsInAccount(accountTeamMemberList, territoryMap.values());
        //System.debug('objTer2Association : ' + objTer2Association);

        for(AccountTeamMember accountTeamMember : accountTeamMemberList){
            for(String terExId : userIdTerritoryExIdMap.get(accountTeamMember.UserId)){
                if(!objTer2Association.contains(accountTeamMember.AccountId + '|' + territoryMap.get(terExId))){
                    objTer2AssociationMap.put(accountTeamMember.AccountId + '|' + territoryMap.get(terExId), new ObjectTerritory2Association(
                        Territory2Id = territoryMap.get(terExId),
                        ObjectId = accountTeamMember.AccountId,
                        AssociationCause = 'Territory2Manual'
                    ));
                }
            }
        }
        //System.debug('objTer2AssociationMap : ' + objTer2AssociationMap.values());
        if(!objTer2AssociationMap.values().isEmpty()){
            upsertDML(JSON.serialize(objTer2AssociationMap.values()));
        }
    }

    public static void deleteTerritoryAssociation(List<AccountTeamMember> accountTeamMemberListInIntegration) {
        //Map<String, String> AccountExIdTerritoryExId
        
        List<AccountTeamMember> accountTeamMemberList = getAccountTeamMembersWithId(accountTeamMemberListInIntegration);

        Set<String> userIds = getUserById(accountTeamMemberList);

        //UserId => terExIds
        Map<String, List<String>> userIdTerritoryExIdMap = getTerritoryExIds(userIds);
        //System.debug('userIdTerritoryExIdMap: ' + userIdTerritoryExIdMap);

        //terExId => terId
        Map<String, String> territoryMap = getTerritoryIds(userIdTerritoryExIdMap.values());

        //List to Upsert ObjectTerritory2Association Objects
        List<ObjectTerritory2Association> objTer2AssociationRemoveList = new List<ObjectTerritory2Association>();
        //System.debug('territoryMap : ' + territoryMap);
        //Map to Remove ObjectTerritory2Association Objects
        Map<String, String> territoryIdAccountIdMap = new Map<String, String>();

        for(AccountTeamMember accountTeamMember : accountTeamMemberList){
            for(String terExId : userIdTerritoryExIdMap.get(accountTeamMember.UserId)){
                territoryIdAccountIdMap.put(
                    accountTeamMember.AccountId + '|' + territoryMap.get(terExId), 
                    accountTeamMember.AccountId
                );
            }
        }
        objTer2AssociationRemoveList = getObjectTerritory2Associations(territoryIdAccountIdMap);
        System.debug('objTer2AssociationRemoveList : ' + objTer2AssociationRemoveList);
        if(!objTer2AssociationRemoveList.isEmpty()){
            deleteDML(JSON.serialize(objTer2AssociationRemoveList));
        }
    }

    public static List<AccountTeamMember> getAccountTeamMembersWithId(List<AccountTeamMember> accountTeamMemberListToUpsert){
        List<AccountTeamMember> accountTeamMemberList = new List<AccountTeamMember>();
        //Searching accounts with Id
        for (AccountTeamMember accountTeamMember : accountTeamMemberListToUpsert) {
            if(accountTeamMember.Id != null){
                accountTeamMemberList.add(accountTeamMember);
            }
        }
        return accountTeamMemberList;
    }

    public static Set<String> getUserById(List<AccountTeamMember> accountTeamMemberList){
        Set<String> userIds = new Set<String>();
        //Searching accounts with Id
        for (AccountTeamMember accountTeamMember : accountTeamMemberList) {
            userIds.add(accountTeamMember.UserId);
        }
        return userIds;
    }

    public static Map<String,List<String>> getTerritoryExIds(Set<String> userIds){
        Map<String,List<String>> userIdTerritoryExIdMap = new Map<String,List<String>>();
        for(String user : userIds){
            userIdTerritoryExIdMap.put(user, new List<String>());
        }
        //TerritoryExId search based on SalesOffice | SalesTeam ExternalId field sent
        for (RelatedUserSalesTeam__c relatedUserSalesTeam : RelatedUserSalesTeamDAO.getRelatedUserSalesTeamByRTV(new List<String>(userIds), new Set<String>{'Id', 'RTV__c', 'SalesTeam__c', 'SalesTeam__r.ExternalId__c'})) {
            if(userIdTerritoryExIdMap.containsKey(relatedUserSalesTeam.RTV__c)){
                userIdTerritoryExIdMap.get(relatedUserSalesTeam.RTV__c).add('SalesTeam' + relatedUserSalesTeam.SalesTeam__r.ExternalId__c);
            }
        }

        return userIdTerritoryExIdMap;
    }

    public static Map<String,String> getTerritoryIds(List<List<String>> territoryExIdsList){
        Map<String,String> territoryMap = new Map<String,String>();
        List<String> territoryExIds = new List<String>();
        for(List<String> terExIds : territoryExIdsList){
            territoryExIds.addAll(terExIds);
        }
        //Territory search based on SalesOffice | SalesTeam ExternalId field sent
        for (Territory2 territory : Territory2DAO.getTerritory2ByExternalId(territoryExIds, new Set<String>{'Id', 'ExternalId__c'})) {
            territoryMap.put(territory.ExternalId__c, territory.Id);
        }
        return territoryMap;
    }

    public static List<String> getObjectTerritory2AssociationsInAccount(List<AccountTeamMember> accountTeamMemberList, List<String> territoryIds){
        List<String> accIdSet = new List<String>();
        for(AccountTeamMember acc : accountTeamMemberList){
            accIdSet.add(acc.AccountId);
        }
        
        List<String> objectTerritory2AssociationList = new List<String>();
        //ObjectTerritory2Association search based on AccountId field sent
        for (ObjectTerritory2Association objectTerritory2Association : ObjectTerritory2AssociationDAO.getObjectTerritory2AssociationByTerritory2Id(accIdSet, new List<String>(territoryIds), new Set<String>{'Id', 'Territory2Id', 'ObjectId'})) {
            objectTerritory2AssociationList.add(objectTerritory2Association.ObjectId + '|' + objectTerritory2Association.Territory2Id);
        }
        return objectTerritory2AssociationList;
    }

    public static List<ObjectTerritory2Association> getObjectTerritory2Associations(Map<String, String> territoryIdAccountIdMap){
        List<ObjectTerritory2Association> objectTerritory2AssociationList = new List<ObjectTerritory2Association>();
        //ObjectTerritory2Association search based on AccountId + | + Territory2Id => AccountId field sent
        for (ObjectTerritory2Association objectTerritory2Association : ObjectTerritory2AssociationDAO.getObjectTerritory2AssociationByObjectId(new List<String>(territoryIdAccountIdMap.values()), new Set<String>{'Id', 'Territory2Id', 'ObjectId'})) {
            if(territoryIdAccountIdMap.get(objectTerritory2Association.ObjectId + '|' + objectTerritory2Association.Territory2Id) == objectTerritory2Association.ObjectId){
                objectTerritory2AssociationList.add(objectTerritory2Association);
            }
        }
        return objectTerritory2AssociationList;
    }

    @future
    public static void upsertDML(string objTer2AssociationJSON){
        Database.Upsert((List<ObjectTerritory2Association>)JSON.deserialize(objTer2AssociationJSON, List<ObjectTerritory2Association>.class));
    }

    @future
    public static void deleteDML(string objTer2AssociationJSON){
        Database.DeleteResult[] result = Database.Delete((List<ObjectTerritory2Association>)JSON.deserialize(objTer2AssociationJSON, List<ObjectTerritory2Association>.class));
    }
}
