public class GrainTableMembersHelper {
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


    public static void insertGroupMember(List<GrainTableMembers__c> newGrainTableMembersList){
        Map<Id,Id> clusterIdToUserIdMap = new Map<Id,Id>();
        
        Set<Id> clusterIdsSet = new Set<Id>();
        
        
        Set<Id> newGrainTableMembersIdSet = new Set<Id>();
        for(GrainTableMembers__c gtm : newGrainTableMembersList){
            newGrainTableMembersIdSet.add(gtm.Id);
            clusterIdsSet.add(gtm.Cluster__c);
            clusterIdToUserIdMap.put(gtm.Cluster__c, gtm.BoardMember__c);
        }

        insertGroupMemberFuture(newGrainTableMembersIdSet, clusterIdsSet, clusterIdToUserIdMap);
        
    }

    @future
    public static void insertGroupMemberFuture(Set<Id> newGrainTableMembersIdSet, Set<Id> clusterIdsSet, Map<Id,Id> clusterIdToUserIdMap){
        Map<String,Id> clusterNameToQueueIdMap = new Map<String,Id>();
        String clusterNameLESTE = null;
        String clusterNameNORTE = null;
        String clusterNameSUL = null;
        List<QueueSobject> queueListLESTE = new List<QueueSobject>();
        List<QueueSobject> queueListNORTE = new List<QueueSobject>();
        List<QueueSobject> queueListSUL = new List<QueueSobject>();
        List<GrainTableMembers__c> newGrainTableMembersListSelect = [SELECT Id, Cluster__r.Name, Cluster__c FROM GrainTableMembers__c WHERE Id IN: newGrainTableMembersIdSet];
        //Busca o cluster relacionado
        List<Cluster__c> clusterList = [SELECT Id, Name FROM Cluster__c WHERE Id IN: clusterIdsSet];
        for(Cluster__c cluster : clusterList){
            if(cluster.Name == 'CLUSTER LESTE'){
                clusterNameLESTE = 'EastClusterGrainsTable';
            }
            else if(cluster.Name == 'CLUSTER NORTE'){
                clusterNameNORTE = 'NorthClusterGrainTable';
            }
            else if(cluster.Name == 'CLUSTER SUL'){
                clusterNameSUL = 'SouthClusterGrainTable';
            }
        }


        if(clusterNameLESTE != null){
            queueListLESTE = [SELECT Id, Queue.DeveloperName FROM QueueSobject WHERE Queue.DeveloperName =: clusterNameLESTE];
        }
        if(clusterNameNORTE != null){
            queueListNORTE = [SELECT Id, Queue.DeveloperName FROM QueueSobject WHERE Queue.DeveloperName =: clusterNameNORTE];
        }
        if(clusterNameSUL != null){
            queueListSUL = [SELECT Id, Queue.DeveloperName FROM QueueSobject WHERE Queue.DeveloperName =: clusterNameSUL];
        }

        for(QueueSobject queue : queueListLESTE){
            clusterNameToQueueIdMap.put(queue.Queue.DeveloperName, queue.QueueId);
        }
        for(QueueSobject queue : queueListNORTE){
            clusterNameToQueueIdMap.put(queue.Queue.DeveloperName, queue.QueueId);
        }
        for(QueueSobject queue : queueListSUL){
            clusterNameToQueueIdMap.put(queue.Queue.DeveloperName, queue.QueueId);
        }

        List<GroupMember> gmList = new List<GroupMember>();
        for(GrainTableMembers__c gtm : newGrainTableMembersListSelect){
            GroupMember gm = new GroupMember();
            gm.UserOrGroupId = clusterIdToUserIdMap.get(gtm.Cluster__c);
            if(gtm.Cluster__r.Name == 'CLUSTER LESTE'){
                gm.GroupId = clusterNameToQueueIdMap.get(clusterNameLESTE);
            }
            else if(gtm.Cluster__r.Name == 'CLUSTER NORTE'){
                gm.GroupId = clusterNameToQueueIdMap.get(clusterNameNORTE);
            }
            else if(gtm.Cluster__r.Name == 'CLUSTER SUL'){
                gm.GroupId = clusterNameToQueueIdMap.get(clusterNameSUL);
            }   
            gmList.add(gm);
        }
        System.debug('INSERT - gmList:' + gmList);
        insert gmList;
    }

    public static void updateGroupMember(List<GrainTableMembers__c> newGrainTableMembersList, List<GrainTableMembers__c> oldGrainTableMembersList){
        Boolean flag = false;
        
        for(GrainTableMembers__c oldGTM : oldGrainTableMembersList){
            for(GrainTableMembers__c newGTM : newGrainTableMembersList){
                if(oldGTM.BoardMember__c != newGTM.BoardMember__c || oldGTM.Cluster__c != newGTM.Cluster__c){
                    flag = true;
                }
            }
        }

        if(flag){
            Set<Id> clusterIdsOldSet = new Set<Id>();
            //Set<String> clusterOldNamesSet = new Set<String>();
            Set<Id> userIdsOldSet = new Set<Id>();
            
            Set<Id> queueIdsOldSet = new Set<Id>();
            for(GrainTableMembers__c oldGTM : oldGrainTableMembersList){
                clusterIdsOldSet.add(oldGTM.Cluster__c);
                userIdsOldSet.add(oldGTM.BoardMember__c);
            }

            deleteGroupMemberFuture(clusterIdsOldSet, userIdsOldSet);


            Map<Id,Id> clusterIdToUserIdMap = new Map<Id,Id>();
            Set<Id> clusterIdsSet = new Set<Id>();
            Set<Id> newGrainTableMembersIdSet = new Set<Id>();

            for(GrainTableMembers__c gtm : newGrainTableMembersList){
                newGrainTableMembersIdSet.add(gtm.Id);
                clusterIdsSet.add(gtm.Cluster__c);
                clusterIdToUserIdMap.put(gtm.Cluster__c, gtm.BoardMember__c);
            }
    
            insertGroupMemberFuture(newGrainTableMembersIdSet, clusterIdsSet, clusterIdToUserIdMap);

        }
    }

    public static void deleteGroupMember(List<GrainTableMembers__c> newGrainTableMembersList){
        Set<Id> clusterIdsSet = new Set<Id>();
        Set<Id> userIdsSet = new Set<Id>();
        for(GrainTableMembers__c gtm : newGrainTableMembersList){
            clusterIdsSet.add(gtm.Cluster__c);
            userIdsSet.add(gtm.BoardMember__c);
        }

        deleteGroupMemberFuture(clusterIdsSet, userIdsSet);
    }

    @future
    public static void deleteGroupMemberFuture(Set<Id> clusterIdsSet, Set<Id> userIdsSet){
        System.debug('clusterIdsSet: ' + clusterIdsSet);
        System.debug('userIdsSet: ' + userIdsSet);
        
        Set<String> clusterNames = new Set<String>();
        String clusterNameLESTE = null;
        String clusterNameNORTE = null;
        String clusterNameSUL = null;
        List<QueueSobject> queueListLESTE = new List<QueueSobject>();
        List<QueueSobject> queueListNORTE = new List<QueueSobject>();
        List<QueueSobject> queueListSUL = new List<QueueSobject>();
        Set<Id> queueIdsSet = new Set<Id>();

        //Busca o cluster relacionado
        List<Cluster__c> clusterList = [SELECT Id, Name FROM Cluster__c WHERE Id IN: clusterIdsSet];
        for(Cluster__c cluster : clusterList){
            if(cluster.Name == 'CLUSTER LESTE'){
                clusterNameLESTE = 'EastClusterGrainsTable';
            }
            else if(cluster.Name == 'CLUSTER NORTE'){
                clusterNameNORTE = 'NorthClusterGrainTable';
            }
            else if(cluster.Name == 'CLUSTER SUL'){
                clusterNameSUL = 'SouthClusterGrainTable';
            }
        }

        System.debug('CLUSTER NORTE TA AI?: ' + clusterNameNORTE);

        if(clusterNameLESTE != null){
            queueListLESTE = [SELECT Id, Queue.DeveloperName FROM QueueSobject WHERE Queue.DeveloperName =: clusterNameLESTE];
        }
        if(clusterNameNORTE != null){
            queueListNORTE = [SELECT Id, Queue.DeveloperName FROM QueueSobject WHERE Queue.DeveloperName =: clusterNameNORTE];
        }
        if(clusterNameSUL != null){
            queueListSUL = [SELECT Id, Queue.DeveloperName FROM QueueSobject WHERE Queue.DeveloperName =: clusterNameSUL];
        }

        for(QueueSobject queue : queueListLESTE){
            queueIdsSet.add(queue.QueueId);
        }
        for(QueueSobject queue : queueListNORTE){
            queueIdsSet.add(queue.QueueId);
        }
        for(QueueSobject queue : queueListSUL){
            queueIdsSet.add(queue.QueueId);
        }

        System.debug('queueIdsSet: ' + queueIdsSet);
        //System.debug('DELETE - queueIdsSet: ' + queueIdsSet);
        List<GroupMember> groupMemberList = [SELECT Id FROM GroupMember WHERE UserOrGroupId IN: userIdsSet AND GroupId IN: queueIdsSet];
        System.debug('DELETE - groupMemberList: ' + groupMemberList);
        delete groupMemberList;
    }
}
