public with sharing class RelatedUserSalesTeamHelper {
    private static Boolean runTrigger;
    static {
        runTrigger = true;
    }

    public static Boolean isTriggerEnabled(){
        return runTrigger;
    }

    public static void handleUsers(List<User> context){
        try{
            update [SELECT id FROM RelatedUserSalesTeam__c WHERE SalesTeamName__c IN :Collection.of(context).pluckStrings(User.TerritoryRole__c)];
        }catch(Exception ex){ }
    }
    public static void handleShareUser(List<RelatedUserSalesTeam__c> relatedUsers){
        Set<String> salesTeamNameSet = new Set<String>();
        for(RelatedUserSalesTeam__c relatedList : relatedUsers){
            salesTeamNameSet.add(relatedList.SalesTeamName__c);
        }
        
        Map<String, UserShare> usShareMap = new Map<String, UserShare>();

        handleInsertShareUser(salesTeamNameSet, usShareMap);
        handleDeleteShareUser(salesTeamNameSet, usShareMap);

    }

    public static void handleInsertShareUser(Set<String> salesTeamNameSet, Map<String, UserShare> usShareMap){        
        Map<String, Set<Id>> usMap = new Map<String, Set<Id>>();
        for(User usRelated : [SELECT id, TerritoryRole__c FROM User WHERE TerritoryRole__c  IN :salesTeamNameSet ]){
            if(!usMap.containsKey(usRelated.TerritoryRole__c))
                usMap.put(usRelated.TerritoryRole__c, new Set<Id>());
            usMap.get(usRelated.TerritoryRole__c).add(usRelated.Id);
        }

        for(RelatedUserSalesTeam__c relatedSalesTeam : [SELECT id, SalesTeamName__c, RTV__c FROM RelatedUserSalesTeam__c WHERE SalesTeamName__c IN : usMap.keySet()]){     
            for(Id usId : usMap.get(relatedSalesTeam.SalesTeamName__c)){
                if(usId == relatedSalesTeam.RTV__c) continue;
                usShareMap.put(relatedSalesTeam.RTV__c+'_'+usId, shareUser(relatedSalesTeam.RTV__c, usId));
            }
        }
        
        if(!usShareMap.isEmpty()){
            Database.Insert(usShareMap.values(), false);
        }
    }

    public static void handleDeleteShareUser(Set<String> salesTeamNameSet, Map<String, UserShare> usShareMap){             
        List<UserShare> deleteList = new List<UserShare>();
        for(UserShare usShare : [SELECT Id, UserId, UserOrGroupId FROM UserShare WHERE User.TerritoryRole__c IN :salesTeamNameSet]){
            if(!usShareMap.containsKey(usShare.UserId+'_'+usShare.UserOrGroupId)){
                deleteList.add(usShare);
            }
        }

        if(!deleteList.isEmpty()){
            Database.Delete(deleteList, false);
        }   
    }
    
    public static UserShare shareUser(Id us, Id usId){
        return new UserShare(UserId = us, UserOrGroupId = usId, UserAccessLevel = 'Edit');
    }

    public static void handleGroupMember(List<RelatedUserSalesTeam__c> relatedUsers){
        Set<String> externalIdList = new Set<String>();
        for(RelatedUserSalesTeam__c relatedList : relatedUsers){
            externalIdList.add(relatedList.SalesOrgExternalId__c);
        }

        Map<String, GroupMember> gmList = new Map<String, GroupMember>();
        handleInsertGroupMember(externalIdList, gmList);
        handleDeleteGroupMember(externalIdList, gmList);

    }
    public static void handleInsertGroupMember(Set<String> externalIdList, Map<String, GroupMember> gmList){ 

        Map<String, Id> gpMap = new Map<String, Id>();
        for(Group gp : [SELECT id, Name FROM Group WHERE Name IN: externalIdList]){
            gpMap.put(gp.Name, gp.Id);
        }

        for(RelatedUserSalesTeam__c user : [SELECT id, SalesTeam__r.SalesOrg__r.ExternalId__c, RTV__c FROM RelatedUserSalesTeam__c WHERE SalesTeam__r.SalesOrg__r.ExternalId__c IN :externalIdList]){
            if(!gpMap.containsKey(user.SalesTeam__r.SalesOrg__r.ExternalId__c)) continue;
            
            Id gpId = gpMap.get(user.SalesTeam__r.SalesOrg__r.ExternalId__c);
            gmList.put(user.RTV__c+'_'+gpId, new GroupMember(UserOrGroupId = user.RTV__c, GroupId = gpId));
        }

        if(!gmList.isEmpty()){
            Database.Insert(gmList.values(), false);
        }
    }
    public static void handleDeleteGroupMember(Set<String> externalIdList, Map<String, GroupMember> gmList){ 
        List<GroupMember> deleteList = new List<GroupMember>();
        for(GroupMember gpMember : [SELECT id, Group.name, UserOrGroupId, GroupId FROM GroupMember WHERE Group.name IN :externalIdList]){
            if(!gmList.containsKey(gpMember.UserOrGroupId+'_'+gpMember.GroupId) && String.valueOf(gpMember.UserOrGroupId).startsWith('005')){
                deleteList.add(gpMember);
            }
        }

        if(!deleteList.isEmpty()){
            Database.Delete(deleteList, false);
        }
    }

    /*public static void createGroupMember(List<RelatedUserSalesTeam__c> relatedUsers) {
        List<String> externalIdList = new List<String>();
        List<String> relatedUserIdList = new List<String>();
        List<String> rtvList = new List<String>();
        Map<String,Groupmember> GroupmemberNameMap = new Map<String,Groupmember>();
        Map<String,Groupmember> GroupmemberRTVMap = new Map<String,Groupmember>();

        for(RelatedUserSalesTeam__c users : relatedUsers){
            relatedUserIdList.add(users.Id);
            rtvList.add(users.RTV__c);
        }
        System.debug(rtvList);
        List<RelatedUserSalesTeam__c> relatedTeamList = [SELECT id, RTV__c, SalesTeam__r.Name, SalesTeam__r.SalesOrg__r.ExternalId__c, SalesTeam__r.SalesOrg__c  FROM RelatedUserSalesTeam__c WHERE Id IN: relatedUserIdList];
        System.debug('relatedTeamList: ' + relatedTeamList);

        for(RelatedUserSalesTeam__c relatedList : relatedTeamList){
            externalIdList.add(relatedList.SalesTeam__r.SalesOrg__r.ExternalId__c);
        }
        System.debug('externalIdList: ' + externalIdList);
        List<Groupmember> groupMemberList = [SELECT Id, UserOrGroupId, GroupId, Group.Name FROM Groupmember WHERE Group.Name IN: externalIdList];
        List<Groupmember> groupMemberRTVList = [SELECT Id, UserOrGroupId, GroupId, Group.Name FROM Groupmember WHERE Group.Name IN: externalIdList AND UserOrGroupId IN: rtvList];
        Map<Id, User> userRoleMap = new Map<Id, User>([SELECT UserRole.DeveloperName FROM User WHERE Id IN: rtvList]);
        System.debug('groupMemberList: ' + groupMemberList);

        for(Groupmember groupMemb : groupMemberList){
            GroupmemberNameMap.put(groupMemb.Group.Name, groupMemb);
        }
        for(Groupmember groupMemb : groupMemberRTVList){
            GroupmemberRTVMap.put(groupMemb.UserOrGroupId, groupMemb);
        }

        List<GroupMember> gmList = new List<GroupMember>();
        for(RelatedUserSalesTeam__c relatedList : relatedTeamList){
            Groupmember groupMember = GroupmemberNameMap.get(relatedList.SalesTeam__r.SalesOrg__r.ExternalId__c);
            Groupmember groupMemberRTV = GroupmemberRTVMap.get(relatedList.RTV__c);
            User userRole = userRoleMap.get(relatedList.RTV__c);

            System.debug(userRole.UserRole.DeveloperName + '++++' + relatedList.SalesTeam__r.Name);
            if(groupMember?.GroupId != null && userRole?.UserRole?.DeveloperName != null && relatedList?.SalesTeam__r?.Name != null && !userRole.UserRole.DeveloperName.contains(relatedList.SalesTeam__r.Name)){
                if(groupMemberRTV == null ){
                    GroupMember gm = new GroupMember();
                    gm.UserOrGroupId = relatedList.RTV__c;
                    gm.GroupId = groupMember.GroupId;
                    gmList.add(gm);
                }
                if(groupMemberRTV != null && groupMemberRTV.UserOrGroupId != groupMember.UserOrGroupId){
                    GroupMember gm = new GroupMember();
                    gm.UserOrGroupId = relatedList.RTV__c;
                    gm.GroupId = groupMember.GroupId;
                    gmList.add(gm);
                }
                
            }
        }
        System.debug('gmList: ' + gmList);
        if(gmList != null){
            insertDML(JSON.serialize(gmList));
        }
    }

    public static void deleteGroupMember(List<RelatedUserSalesTeam__c> relatedUsers) {
        List<String> externalIdList = new List<String>();
        List<String> relatedUserIdList = new List<String>();
        List<String> rtvList = new List<String>();

        for(RelatedUserSalesTeam__c users : relatedUsers){
            relatedUserIdList.add(users.Id);
        }
        List<RelatedUserSalesTeam__c> relatedTeamList = [SELECT id, RTV__c, SalesTeam__r.SalesOrg__r.ExternalId__c, SalesTeam__r.SalesOrg__c  FROM RelatedUserSalesTeam__c WHERE Id IN: relatedUserIdList];
        System.debug('relatedTeamList: ' + relatedTeamList);

        for(RelatedUserSalesTeam__c relatedList : relatedTeamList){
            externalIdList.add(relatedList.SalesTeam__r.SalesOrg__r.ExternalId__c);
            rtvList.add(relatedList.RTV__c);
        }

        List<GroupMember> groupMemberList = [SELECT Id FROM GroupMember WHERE UserOrGroupId IN: rtvList AND Group.Name IN:  externalIdList];
        System.debug('DELETE - groupMemberList: ' + groupMemberList);
        delete groupMemberList;
    }

    public static void updateGroupMember(Map<Id, RelatedUserSalesTeam__c> newRelatedUserSalesMap, Map<Id, RelatedUserSalesTeam__c> oldRelatedUserSalesMap) {
        List<RelatedUserSalesTeam__c> modifiedRelatedUserSalesList = new List<RelatedUserSalesTeam__c>();
        List<String> externalIdList = new List<String>();
        List<String> relatedUserIdList = new List<String>();
        List<String> rtvList = new List<String>();
        Map<String,Groupmember> GroupmemberNameMap = new Map<String,Groupmember>();
        Map<String,Groupmember> GroupmemberRTVMap = new Map<String,Groupmember>();

        for (RelatedUserSalesTeam__c newRelatedUserSales : newRelatedUserSalesMap.values()) {
            RelatedUserSalesTeam__c oldRelatedUserSales = oldRelatedUserSalesMap.get(newRelatedUserSales.Id);

            if ((newRelatedUserSales.RTV__c !=  oldRelatedUserSales.RTV__c) && (newRelatedUserSales.SalesTeam__c !=  oldRelatedUserSales.SalesTeam__c)) {
                modifiedRelatedUserSalesList.add(newRelatedUserSales);
            }
        }
        if(modifiedRelatedUserSalesList != null){

            for(RelatedUserSalesTeam__c users : modifiedRelatedUserSalesList){
                relatedUserIdList.add(users.Id);
                rtvList.add(users.RTV__c);
            }
            List<RelatedUserSalesTeam__c> relatedTeamList = [SELECT id, RTV__c, SalesTeam__r.Name, SalesTeam__r.SalesOrg__r.ExternalId__c, SalesTeam__r.SalesOrg__c  FROM RelatedUserSalesTeam__c WHERE Id IN: relatedUserIdList];
            System.debug('relatedTeamList: ' + relatedTeamList);

            for(RelatedUserSalesTeam__c relatedList : relatedTeamList){
                externalIdList.add(relatedList.SalesTeam__r.SalesOrg__r.ExternalId__c);
            }
            System.debug('externalIdList: ' + externalIdList);
            List<Groupmember> groupMemberList = [SELECT Id, UserOrGroupId, GroupId, Group.Name FROM Groupmember WHERE Group.Name IN: externalIdList];
            List<Groupmember> groupMemberRTVList = [SELECT Id, UserOrGroupId, GroupId, Group.Name FROM Groupmember WHERE Group.Name IN: externalIdList AND UserOrGroupId IN: rtvList];
            Map<Id, User> userRoleMap = new Map<Id, User>([SELECT UserRole.DeveloperName FROM User WHERE Id IN: rtvList]);
            System.debug('groupMemberList: ' + groupMemberList);
            System.debug('groupMemberRTVList: ' + groupMemberRTVList);

            for(Groupmember groupMemb : groupMemberList){
                GroupmemberNameMap.put(groupMemb.Group.Name, groupMemb);
            }
            for(Groupmember groupMemb : groupMemberRTVList){
                GroupmemberRTVMap.put(groupMemb.UserOrGroupId, groupMemb);
            }

            List<GroupMember> gmList = new List<GroupMember>();
            for(RelatedUserSalesTeam__c relatedList : relatedTeamList){
                Groupmember groupMember = GroupmemberNameMap.get(relatedList.SalesTeam__r.SalesOrg__r.ExternalId__c);
                Groupmember groupMemberRTV = GroupmemberRTVMap.get(relatedList.RTV__c);
                User userRole = userRoleMap.get(relatedList.RTV__c);

                if(!userRole.UserRole.DeveloperName.contains(relatedList.SalesTeam__r.Name)){
                    if(groupMemberRTV == null ){
        
                        GroupMember gm = new GroupMember();
                        gm.UserOrGroupId = relatedList.RTV__c;
                        gm.GroupId = groupMember.GroupId;
                        gmList.add(gm);
                    }
                    if(groupMemberRTV != null && groupMemberRTV.UserOrGroupId != groupMember.UserOrGroupId){
        
                        GroupMember gm = new GroupMember();
                        gm.UserOrGroupId = relatedList.RTV__c;
                        gm.GroupId = groupMember.GroupId;
                        gmList.add(gm);
                    }
                }
            }
            System.debug('gmList: ' + gmList);
            if(gmList != null){
                upsert gmList;
            }
        }
    }
    public static void insertDML(string groupMember){
        Database.Insert((List<GroupMember>)JSON.deserialize(groupMember, List<GroupMember>.class), false);
    }*/
}
