public without sharing class ShippingDivisionHelper {
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

    public static void tablueuField(List<ShippingDivision__c> context) {
        for(ShippingDivision__c ship : context){
            ship.TableauShippingValue__c = ship.ShippingValue__c;
            ship.CurrencyIsoCode = ship.OrderCurrency__c;
        }
    }
    public static void checkRefuseReason(List<ShippingDivision__c> newShippingDivisionList, Map<Id, ShippingDivision__c> oldShippingDivisionMap) {
        Map<Id, OrderItem> orderItemMap = new Map<Id, OrderItem>();
        for (ShippingDivision__c shippingDivision : newShippingDivisionList) {
            if ((oldShippingDivisionMap == null || String.isBlank(oldShippingDivisionMap.get(shippingDivision.Id).RefuseReason__c)) && 
                shippingDivision.RefuseReason__c == '25' && String.isNotBlank(shippingDivision.OrderItem__c)) {
                orderItemMap.put(
                    shippingDivision.OrderItem__c, 
                    new OrderItem(
                        Id = shippingDivision.OrderItem__c,
                        HasRefuseReason__c = true
                    )
                );
            }
        }

        if (orderItemMap.size() > 0) {
            update orderItemMap.values();
        }
    }

    public static void createShippingDivision(List<ShippingDivision__c> spList){
        List<Id> orderIdList = new List<Id>();
        List<Id> shippingList = new List<Id>();
        for (ShippingDivision__c sd : spList){
            shippingList.add(sd.Id);
        }
        List<ShippingDivision__c> sdSearch = [
            SELECT Id, OrderItem__r.Order.OwnerId
            FROM ShippingDivision__c
            WHERE Id IN: shippingList
        ];
        for(ShippingDivision__c sd : sdSearch){
            sd.OwnerId = sd.OrderItem__r.Order.OwnerId;
        }
        ShippingDivisionHelper.disableTrigger();
        update sdSearch;
        ShippingDivisionHelper.enableTrigger();
    }

    public static void updateShare(List<ShippingDivision__c> spList){
        List<ShippingDivision__c> shipList = new List<ShippingDivision__c>();
        for(ShippingDivision__c ship : spList){
            if(ship.RecalcShare__c) 
                shipList.add(ship);
            ship.RecalcShare__c = false;
        }
        if(!shipList.isEmpty()){
            createShareShippingDivision(shipList);
        }
    }
    public static void createShareShippingDivision(List<ShippingDivision__c> spList){
        Set<String> nameSet = new Set<String>();
        Set<Id> orderIdSet = new Set<Id>();
        Set<Id> spIdSet = new Set<Id>();

        for (ShippingDivision__c sp : spList){
            spIdSet.add(sp.Id);
        }
        
        List<ShippingDivision__c> spNewList = [
            SELECT Id, OrderItem__r.OrderId
            FROM ShippingDivision__C
            WHERE Id IN: spIdSet
        ];

        for (ShippingDivision__c sp : spNewList) {
            orderIdSet.add(sp.OrderItem__r.OrderId);
        }
        Map<Id,Order> orderMap = new Map<Id,Order>([
            SELECT Name, Id, SalesTeam__c, RTV__c, CreatedById, SalesOrg__r.Director__c, SalesTeam__r.Manager__c, SalesOffice__r.GGN__c, SalesTeam__r.Name, SalesOffice__r.ParentId__r.Director__c, SalesOffice__r.ParentId__r.MarketingManager__c,SalesOffice__r.ParentId__r.FinancialAdministrativeManager__c, OwnerId
            FROM Order
            WHERE  Id IN: orderIdSet
        ]);

        Map<Id, Set<Id>> userIdMap = new Map<Id,  Set<Id>>();

        for (Order order : orderMap.values()) {
            // nameSet.add('AT_'+order.SalesTeam__r.Name);
            nameSet.add('Gerente_Comercial_'+order.SalesTeam__r.Name);
            // nameSet.add('RTV_'+order.SalesTeam__r.Name);
            nameSet.add('Vendedor_Interno_'+order.SalesTeam__r.Name);

            if(!userIdMap.containsKey(order.id)){
                userIdMap.put(order.id, new Set<Id>());
            }

            
            if(order.SalesTeam__r.Manager__c != null && order.OwnerId != order.SalesTeam__r.Manager__c)
                userIdMap.get(order.id).add(order.SalesTeam__r.Manager__c);

            if(order.SalesOffice__r.GGN__c != null)
                userIdMap.get(order.id).add(order.SalesOffice__r.GGN__c);

            if(order.SalesOffice__r.ParentId__r.Director__c != null)
                userIdMap.get(order.id).add(order.SalesOffice__r.ParentId__r.Director__c);

            if(order.SalesOffice__r.ParentId__r.MarketingManager__c != null)
                userIdMap.get(order.id).add(order.SalesOffice__r.ParentId__r.MarketingManager__c);

            if(order.SalesOffice__r.ParentId__r.FinancialAdministrativeManager__c != null)
                userIdMap.get(order.id).add(order.SalesOffice__r.ParentId__r.FinancialAdministrativeManager__c);

            if(order.SalesOrg__r.Director__c != null)
                userIdMap.get(order.id).add(order.SalesOrg__r.Director__c);
            
            if(!userIdMap.get(order.id).contains(order.RTV__c)){
                userIdMap.get(order.id).add(order.RTV__c);
            }

            if(!userIdMap.get(order.id).contains(order.OwnerId)){
                userIdMap.get(order.id).add(order.OwnerId);
            }

            if(!userIdMap.get(order.id).contains(order.CreatedById)){
                userIdMap.get(order.id).add(order.CreatedById);
            }

        }
        List<Group> GroupList = new List<Group>([
            SELECT DeveloperName, Id
            FROM Group
            WHERE DeveloperName IN: nameSet AND DeveloperName != null
        ]);

        System.debug('userIdMap: ' + userIdMap);
        System.debug('GroupList: ' + GroupList);
        
        //Set<ShippingDivision__c> sharesCreate = new Set<ShippingDivision__c>();
        Set<ShippingDivision__Share> SDShareCreate = new Set<ShippingDivision__Share>();

        
        if (!userIdMap.IsEmpty()) {
            for (ShippingDivision__c shippingDivision : spNewList) {
                if(userIdMap.containsKey(shippingDivision.OrderItem__r.OrderId)){
                    for(Id usId : userIdMap.get(shippingDivision.OrderItem__r.OrderId)){
                        ShippingDivision__Share shippingDivisionShare  = new ShippingDivision__Share();
                        shippingDivisionShare.ParentId = shippingDivision.Id;
                        shippingDivisionShare.UserOrGroupId = usId;
                        shippingDivisionShare.AccessLevel = 'Edit';    
                        SDShareCreate.add(shippingDivisionShare); 
                    }
                }
            }
        }

        if (!GroupList.IsEmpty()) {
            for (ShippingDivision__c shippingDivision : spNewList) {
                for (Group userGroup : GroupList) {
                    if (orderMap.containsKey(shippingDivision.OrderItem__r.OrderId) && orderMap.get(shippingDivision.OrderItem__r.OrderId).SalesTeam__r.Name != null &&  userGroup.DeveloperName.contains(orderMap.get(shippingDivision.OrderItem__r.OrderId).SalesTeam__r.Name)) {
                        ShippingDivision__Share shippingDivisionShare  = new ShippingDivision__Share();
                        shippingDivisionShare.ParentId = shippingDivision.Id;
                        shippingDivisionShare.UserOrGroupId = userGroup.Id;
                        shippingDivisionShare.AccessLevel = 'Edit';    
                        SDShareCreate.add(shippingDivisionShare); 
                    }
                }
            }
        }

        System.debug('ShareCreate: ' + SDShareCreate);
        if (!SDShareCreate.isEmpty()) {
            insertDML(JSON.serialize(SDShareCreate));
        }
    }

    public static void insertDML(string SDShareCreate){
        Database.Insert((List<ShippingDivision__Share>)JSON.deserialize(SDShareCreate, List<ShippingDivision__Share>.class), false);
    }

}