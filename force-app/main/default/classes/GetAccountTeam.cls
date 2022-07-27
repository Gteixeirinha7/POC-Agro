public with sharing class GetAccountTeam {
    
    public static Map<Id, List<SalesTeamResponse>> getAccountTeam(Id accIds, Boolean isListPrice) {
        Map<Id, List<SalesTeamResponse>> responseMap = new Map<Id, List<SalesTeamResponse>>();

        User us = null;
        Map<Id, User> usIdMap = new Map<Id, User>();
        for(User users : [SELECT id, Profile.Name, ExternalId__c, Name, TerritoryRole__c FROM User WHERE id =: Userinfo.getUserId() LIMIT 1]){
            us = users;
            if(us.Profile.Name == 'RTV' || (us.Profile.Name == 'Auxiliar Técnico (AT)' && isListPrice) ||us.Profile.Name.contains('Vendedor Interno') || us.Profile.Name.contains('Gerente Comercial'))
            	usIdMap.put(users.id, users);
        }

        if(!isListPrice && us.Profile.Name != 'RTV'){
            usIdMap.putAll(getManagerRelatedUser(us, accIds));
        }

        if(isListPrice && us.Profile.Name != 'RTV'){
            if(!us.Profile.Name.contains('Admin')){
                usIdMap.putAll(getRelatedUser());
            }else{
                responseMap.put( Userinfo.getUserId() , new List<SalesTeamResponse>());                
                for(SalesTeam__c salesTeam : [SELECT id, Name, ExternalId__c, SalesOrg__c, SalesOrg__r.Name, ParentId__c, DistributionCenter__r.City__c,
                                                    Manager__r.Name, ParentId__r.GGN__r.Name, ParentId__r.ParentId__r.Director__r.Name, SalesOrg__r.Director__r.Name,
                                                    ParentId__r.SalesDirector__r.Name, ParentId__r.ParentId__r.FinancialAdministrativeManager__r.Name, 
                                                    ParentId__r.ParentId__r.MarketingManager__r.Name, DisplayName__c, Address__c, PostalCode__c, City__r.Name, 
                                                    CNPJ__c, IE__c, Phone__c 
                                                FROM SalesTeam__c]){
                    responseMap.get(Userinfo.getUserId()).add(new SalesTeamResponse(salesTeam, null, new User(Id=Userinfo.getUserId())));
                }
            }
        }

        System.debug(usIdMap);

        Map<id, Set<String>> userSalesTeamMap = new Map<id, Set<String>>();
        Set<String> salesTeamSet = new Set<String>();
        for(RelatedUserSalesTeam__c relUser : [SELECT id, RTV__c, SalesTeam__r.ExternalId__c FROM RelatedUserSalesTeam__c WHERE RTV__C IN :usIdMap.keySet()]){
            if(!userSalesTeamMap.containsKey(relUser.RTV__c)){
                userSalesTeamMap.put(relUser.RTV__c, new Set<String>());
            }
            userSalesTeamMap.get(relUser.RTV__c).add(relUser.SalesTeam__r.ExternalId__c);

            salesTeamSet.add(relUser.SalesTeam__r.ExternalId__c);
        }
        System.debug(userSalesTeamMap);


        Map<Id, Set<Id>> usToAccIdMap = new Map<Id, Set<Id>>();
        for(AccountTeamMember accTeam : [SELECT id, AccountId, UserId FROM AccountTeamMember WHERE UserId IN :usIdMap.keySet()]){
            if(!usToAccIdMap.containsKey(accTeam.UserId)){
                usToAccIdMap.put(accTeam.UserId, new Set<Id>());
            }
            usToAccIdMap.get(accTeam.UserId).add(accTeam.AccountId);
        }
        System.debug(usToAccIdMap);

        Map<String, SalesTeam__c> salesTeamMap = new Map<String, SalesTeam__c>();
        for(SalesTeam__c salesTeam : [SELECT id, Name, ExternalId__c, SalesOrg__c, SalesOrg__r.Name, ParentId__c, DistributionCenter__r.City__c,
                                             Manager__r.Name, ParentId__r.GGN__r.Name, ParentId__r.ParentId__r.Director__r.Name, SalesOrg__r.Director__r.Name,
                                             ParentId__r.SalesDirector__r.Name, ParentId__r.ParentId__r.FinancialAdministrativeManager__r.Name, 
                                             ParentId__r.ParentId__r.MarketingManager__r.Name, DisplayName__c, Address__c, PostalCode__c, City__r.Name, 
                                             CNPJ__c, IE__c, Phone__c, ParentId__r.ParentId__c, DistributionCenter__c 
                                      FROM SalesTeam__c]){
            salesTeamMap.put(salesTeam.ExternalId__c, salesTeam);
            salesTeamMap.put(salesTeam.Name, salesTeam);
        }
        System.debug(salesTeamMap);

        for(Id usId : usToAccIdMap.keySet()){
            
            responseMap.put(usId, new List<SalesTeamResponse>());

            Set<String> userSalesTeamSet = userSalesTeamMap.containsKey(usId) ? userSalesTeamMap.get(usId) : new Set<String>();

            for(Id accId : usToAccIdMap.get(usId)){
                for(String salesTeam : userSalesTeamSet){
                    responseMap.get(usId).add(new SalesTeamResponse(salesTeamMap.get(salesTeam), accId, usIdMap.get(usId)));
                }
            }
        }
        if(usToAccIdMap.isEmpty()){
            for(User userr : usIdMap.values()){
                if(!salesTeamMap.containsKey(userr.TerritoryRole__c)) continue;

                if(!responseMap.containsKey(userr.Id))
                    responseMap.put(userr.Id, new List<SalesTeamResponse>());
                responseMap.get(userr.Id).add(new SalesTeamResponse(salesTeamMap.get(userr.TerritoryRole__c), null, usIdMap.get(userr.id)));
            }
        }
        System.debug(responseMap);

        return responseMap;
    }

    @AuraEnabled(cacheable=true)
    public static String getRTVSalesTeam(Id accId) {
        return getRTVSalesTeam(accId, false);
    }
    @AuraEnabled(cacheable=true)
    public static String getRTVSalesTeamListPrice(Id accId) {
        return getRTVSalesTeam(accId, true);
    }
    public static String getRTVSalesTeam(Id accId, Boolean isListPrice) {
        System.debug('accId: '+ accId);
        Map<Id, Set<String>> returnUserMap = new Map<Id, Set<String>>();
        Map<Id, List<SalesTeamResponse>> salesTeamMap = getAccountTeam(accId, isListPrice);
        
        for(Id rtvId : salesTeamMap.keySet()){
            for(SalesTeamResponse sales : salesTeamMap.get(rtvId)) {
                if(accId  == sales.AccountId || isListPrice){
                    if(!returnUserMap.containsKey(sales.RTVId)){
                        returnUserMap.put(sales.RTVId, new Set<String>());
                    }
                    returnUserMap.get(sales.RTVId).add(sales.salesTeamId);
                }
            }
        }
        return JSON.serialize(returnUserMap);
    }

    public static Map<Id, User> getRelatedUser(){
        Set<Id> terIDSet = new Set<Id>();
        Set<Id> usIdSet = new Set<Id>();
        Set<String> terNameSet = new Set<String>();
        
        for(UserTerritory2Association objs : [SELECT id, Territory2Id, Territory2.Name
                                              FROM UserTerritory2Association 
                                              WHERE UserId = :Userinfo.getUserId()]){
            terNameSet.add(objs.Territory2.Name);
        }
        
        for(SalesTeam__c sl : [SELECT id, Name 
                                FROM SalesTeam__c 
                                WHERE SalesOrg__r.name IN :terNameSet 
                                OR ParentId__r.name IN :terNameSet 
                                OR ParentId__r.ParentId__r.name IN :terNameSet ]){
            terNameSet.add(sl.Name);
        }

        for(AggregateResult objs : [SELECT userId usId 
                                              FROM UserTerritory2Association 
                                              WHERE Territory2.Name IN :terNameSet
                                              OR Territory2.ParentTerritory2.Name IN :terNameSet
                                              OR Territory2.ParentTerritory2.ParentTerritory2.Name IN :terNameSet
                                              OR Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Name IN :terNameSet GROUP BY userId]){
            usIdSet.add((Id)objs.get('usId'));
        }
        for(AggregateResult objs : [SELECT UserId usId 
                                    FROM AccountTeamMember
                                    WHERE accountid IN (SELECT ObjectId FROM ObjectTerritory2Association WHERE Territory2.Name IN :terNameSet) 
                                    GROUP BY UserId]){
            usIdSet.add((Id)objs.get('usId'));
        }
        System.debug(usIdSet);
        
        Map<Id, User> usIdMap = new Map<Id, User>();
        for(User us : [SELECT id, Profile.Name, ExternalId__c, Name FROM User WHERE id IN : usIdSet AND Profile.Name = 'RTV' AND TerritoryRole__c IN :terNameSet]){
            usIdMap.put(us.id, us);
        }
        System.debug(usIdMap);
        return usIdMap;
    }

    public static Map<Id, User> getManagerRelatedUser(User us, Id accId){
        Set<Id> terIDSet = new Set<Id>();
        Set<Id> accIDSet = new Set<Id>();
        if(accId == null){
            for(UserTerritory2Association objs : [SELECT id, Territory2Id 
                                                  FROM UserTerritory2Association 
                                                  WHERE UserId = :us.id]){
                terIDSet.add(objs.Territory2Id);
            }
            System.debug(terIDSet);

            for(ObjectTerritory2Association objs : [SELECT id, ObjectId 
                                                    FROM ObjectTerritory2Association 
                                                    WHERE Territory2Id IN :terIDSet]){
                accIDSet.add(objs.ObjectId);
            }
            System.debug(accIDSet);
        }else{
            accIDSet.add(accId);
        }
        
        Set<Id> usIdSet = new Set<Id>();
        for(AccountTeamMember accTeam : [SELECT id, AccountId, UserId, User.Profile.Name, User.ExternalId__c, User.Name FROM AccountTeamMember WHERE AccountId IN :accIdSet]){
            usIdSet.add(accTeam.UserId);
        }

        return new Map<Id, User>([SELECT id, Profile.Name, ExternalId__c, Name FROM User WHERE id IN : usIdSet]);
    }

    public class SalesTeamResponse{
        public String salesTeamId            {get;set;}
        public String salesTeamName          {get;set;}
        public String salesTeamExternalId    {get;set;}
        public String salesTeamDistCenterId  {get;set;}
        public String salesTeamSalesOrgId    {get;set;}
        public String salesTeamSalesOrgName  {get;set;}
        public String salesTeamSalesOfficeId {get;set;}
        public String salesTeamCluesterId    {get;set;}
        public String salesTeamCity          {get;set;}
        public String accountId              {get;set;}
        public String RTVId                  {get;set;}
        public String RTVName                {get;set;}
        public String RTVExternalId          {get;set;}
        public String salesTeamManager       {get;set;}
        public String salesOfficeGGN         {get;set;}
        public String clusterDirector        {get;set;}
        public String salesOrgDirector       {get;set;}
        public String clusterFinancial       {get;set;}
        public String marketingManager       {get;set;}

        public String salesTeamDisplayName   {get;set;}
        public String salesTeamAddress       {get;set;}
        public String salesTeamPostalCode    {get;set;}
        public String salesTeamAddressCity   {get;set;}
        public String salesTeamCNPJ          {get;set;}
        public String salesTeamIE            {get;set;}
        public String salesTeamPhone         {get;set;}

        public SalesTeamResponse(SalesTeam__c p_salesTeam, Id p_accountId, User p_RTV){
            this.salesTeamId            = p_salesTeam.id;
            this.salesTeamName          = p_salesTeam.Name;
            this.salesTeamExternalId    = p_salesTeam.ExternalId__c;
            this.salesTeamDistCenterId  = p_salesTeam.DistributionCenter__c;
            this.salesTeamSalesOrgId    = p_salesTeam.SalesOrg__c;
            this.salesTeamSalesOrgName  = p_salesTeam.SalesOrg__r.Name;
            this.salesTeamSalesOfficeId = p_salesTeam.ParentId__c;
            this.salesTeamCluesterId    = p_salesTeam?.ParentId__r?.ParentId__c;
            this.salesTeamCity          = p_salesTeam.DistributionCenter__r.City__c;
            this.accountId      	    = p_accountId;
            this.RTVId          	    = p_RTV.id;
            this.RTVName        	    = p_RTV.Name;
            this.RTVExternalId  	    = p_RTV.ExternalId__c;

            this.salesTeamManager       = p_salesTeam.Manager__r?.Name;
            this.salesOfficeGGN         = p_salesTeam.ParentId__r?.GGN__r?.Name;

            if (String.isNotBlank(p_salesTeam.ParentId__r?.SalesDirector__c)) {
                this.clusterDirector = p_salesTeam.ParentId__r?.SalesDirector__r.Name;
            } else {
                this.clusterDirector = p_salesTeam.ParentId__r?.ParentId__r?.Director__r?.Name;
            }

            this.salesOrgDirector       = p_salesTeam.SalesOrg__r?.Director__r?.Name;
            this.clusterFinancial       = p_salesTeam.ParentId__r?.ParentId__r.FinancialAdministrativeManager__r?.Name;
            this.marketingManager       = p_salesTeam.ParentId__r?.ParentId__r.MarketingManager__r?.Name;

            this.salesTeamDisplayName   = p_salesTeam.DisplayName__c;
            this.salesTeamAddress       = p_salesTeam.Address__c;
            this.salesTeamPostalCode    = p_salesTeam.PostalCode__c;
            this.salesTeamAddressCity   = p_salesTeam.City__r?.Name;
            this.salesTeamCNPJ          = p_salesTeam.CNPJ__c;
            this.salesTeamIE            = p_salesTeam.IE__c;
            this.salesTeamPhone         = p_salesTeam.Phone__c;

        }
    }
}