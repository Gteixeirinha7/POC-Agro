public with sharing class OrderItemHelper {
    private static Boolean runTrigger = true;

    public static Boolean isTriggerEnabled(){
        return runTrigger;
    }

    public static Boolean enableTrigger(){
        return runTrigger = true;
    }

    public static Boolean disableTrigger(){
        return runTrigger = false;
    }   
    
    public static void setMargin(List<OrderItem> newItems){
        for(OrderItem curOrderItem: newItems){
            curOrderItem.DirectMargin__c = calcMarginProduct(curOrderItem.UnitPrice, curOrderItem.Cost__c);
            curOrderItem.Margin__c = calcMarginProduct(curOrderItem.UnitPriceWithoutCampaign__c, curOrderItem.Cost__c);
        }
    }
    public static Decimal calcMarginProduct(Decimal unitVal, Decimal costs){
        if(unitVal != null && unitVal != 0 && costs != null)
            return ((unitVal - costs) / unitVal *100).setScale(4, RoundingMode.HALF_UP);
        else
            return null;
    }
    public static void calcMargem(List<OrderItem> newItems){
        Set<Id> ordIdSet =new Set<Id>();
        for(OrderItem ordItem: newItems){
            if(Approval.isLocked(ordItem.OrderId)) continue;
            ordIdSet.add(ordItem.OrderId);
        }

        if(ordIdSet.isEmpty()) return;
        
        Map<String, List<OrderItem>> ordItemMap = new Map<String, List<OrderItem>>();
        Map<Id, Order> orderMap = new Map<Id, Order>();
        for(OrderItem ordItem : [SELECT id, OrderId, Order.SalesOffice__r.ParentId__r.MarketingManager__c, Order.SalesOffice__r.SalesDirector__c, Order.SalesOffice__r.ParentId__r.Director__c, ProductFamily__c, DirectMargin__c, Margin__c,
                                Order.HasOrderItemWithoutMargin__c, Order.HasOrderItemWithoutCost__c, Order.HasOrderItemWithLowerMargin__c, Order.MarginApprovalNote__c,
                                Product2Id, Product2.Name, Product2.Family__c, ProductFamilyName__c,
                                InvalidCost__c, Cost__c,
                                Product2.Family__r.Name, ListPrice__c,DiscountAmount__c, 
                                ListPrice__r.UnitPrice__c, ListPrice__r.EffectiveDate__c,
                                LowerMargin__c,DirectFamilyMargin__c, FamilyMargin__c, ProjectedMargin__c,
                                DiscountPercent__c, TotalPrice__c, UnitMeasure__c, Quantity__c, CustomListPrice__c
                                FROM OrderItem WHERE OrderId IN :ordIdSet]){
            if(!ordItemMap.containsKey(ordItem.OrderId))
                ordItemMap.put(ordItem.OrderId, new List<OrderItem>());
            ordItemMap.get(ordItem.OrderId).add(ordItem);

            orderMap.put(ordItem.OrderId, ordItem.Order);
        }   

        List<Order> ordListUpdate = new List<Order>();
        List<OrderItem> ordItemListUpdate = new List<OrderItem>();
        for(Id ordId : ordItemMap.keySet()){
            Order ord = new Order(Id = ordId);
            
            Map<String, List<Decimal>> ordItemDirectFamMap = new Map<String, List<Decimal>>();
            Map<String, List<Decimal>> ordItemMarginFamMap = new Map<String, List<Decimal>>();

            Map<String, List<Decimal>> ordItemDirectMap = new Map<String, List<Decimal>>();
            Map<String, List<Decimal>> ordItemMarginMap = new Map<String, List<Decimal>>();

            for(OrderItem ordItem : ordItemMap.get(ordId)){
                ordItem.DirectFamilyMargin__c   = averageMargin(ordItem.ProductFamily__c, ordItem.DirectMargin__c,  ordItemDirectFamMap);
                ordItem.FamilyMargin__c         = averageMargin(ordItem.ProductFamily__c, ordItem.Margin__c,        ordItemMarginFamMap);
                ord.DirectMargin__c             = averageMargin(ordId,                    ordItem.DirectMargin__c,  ordItemDirectMap);
                ord.Margin__c                   = averageMargin(ordId,                    ordItem.Margin__c,        ordItemMarginMap);
            }
            ordItemListUpdate.addAll(ordItemMap.get(ordId));
            ordListUpdate.add(ord);

        }
        
        OrderHelper.setApprovalJustification(orderMap, ordItemMap);

        if (!ordItemListUpdate.isEmpty()){
            OrderItemHelper.disableTrigger();
            OrderHelper.disableTrigger();
            update ordItemListUpdate;
            update ordListUpdate;
            OrderItemHelper.enableTrigger();
            OrderHelper.enableTrigger();
        }
 
        //Inactive Margin
        /*
        List<Order> ordUpdate = new List<Order>();
        for(Order ord : [SELECT id,HasOrderItemWithoutMargin__c, HasOrderItemWithoutCost__c, HasOrderItemWithLowerMargin__c, SalesOffice__r.ParentId__r.MarketingManager__c,SalesOffice__r.SalesDirector__c,SalesOffice__r.ParentId__r.Director__c 
                        FROM Order 
                        WHERE Id IN :ordIdSet]){
            if(ord.HasOrderItemWithoutMargin__c || ord.HasOrderItemWithoutCost__c || ord.HasOrderItemWithLowerMargin__c){
                if(ord.HasOrderItemWithoutMargin__c || ord.HasOrderItemWithoutCost__c)
                    ord.MarginApprover__C = ord.SalesOffice__r.ParentId__r.MarketingManager__c;
                else
                    ord.MarginApprover__C = ord.SalesOffice__r.SalesDirector__c != null ? ord.SalesOffice__r.SalesDirector__c : ord.SalesOffice__r.ParentId__r.Director__c;
            }
            ordUpdate.add(ord);
        }
        if (!ordUpdate.isEmpty()){
            OrderItemHelper.disableTrigger();
            OrderHelper.disableTrigger();
            update ordUpdate;
            OrderItemHelper.enableTrigger();
            OrderHelper.enableTrigger();
        }
        */
    }

    public static void inputMap(String key, Decimal val, Map<String, List<Decimal>> ordMap){
        if(!ordMap.containsKey(key)) 
            ordMap.put(key, new List<Decimal>());
        ordMap.get(key).add(val);
    }

    public static Decimal averageMargin(String key, Decimal val, Map<String, List<Decimal>> ordMap){
        inputMap(key, val, ordMap);
        return ordMap.containsKey(key) ? new DecimalCollection(ordMap.get(key)).average(4, RoundingMode.HALF_UP) : null;
    }

    /*public static void calcMargem(List<OrderItem> newItems){
        Map<Id, Order> orders =new Map<Id, Order>();
        for(OrderItem curOrderItem: newItems){
            if(Approval.isLocked(curOrderItem.OrderId)) continue;
            orders.put(curOrderItem.OrderId, null);
        }

        orders =new Map<Id, Order>([SELECT
            Id, DirectMargin__c
            FROM Order
            WHERE Id in :orders.keySet()
        ]);
        newItems =[
            SELECT Id, Product2Id, OrderId, DirectMargin__c, DirectFamilyMargin__c, ProductFamily__c
            FROM OrderItem
            WHERE OrderId in :orders.keySet()
        ];        
        Map<Id, Map<Id, List<OrderItem>>> orderFamilyItem =new Map<Id, Map<Id, List<OrderItem>>>();
        for(OrderItem curOrderItem: newItems){
            if(Approval.isLocked(curOrderItem.OrderId)) continue;
            Map<Id, List<OrderItem>> familyItems =orderFamilyItem.get(curOrderItem.OrderId);
            if (familyItems==null){
                familyItems =new Map<Id, List<OrderItem>>();
                List<OrderItem> newList =new List<OrderItem>();
                newList.add(curOrderItem);
                familyItems.put(curOrderItem.ProductFamily__c, newList);
                orderFamilyItem.put(curOrderItem.OrderId, familyItems);
                continue;
            }
            List<OrderItem> items =familyItems.get(curOrderItem.ProductFamily__c);
            if (items==null){
                items =new List<OrderItem>();
                items.add(curOrderItem);
                familyItems.put(curOrderItem.ProductFamily__c, items);
                continue;
            }
            items.add(curOrderItem);
        }

        Map<Id, Map<Id, Decimal>> orderFamilyFmargin =new Map<Id, Map<Id, Decimal>>();
        List<Order> ordersToUpdate =new List<Order>();
        for(Id orderId: orderFamilyItem.keySet()){
            Integer orderQtd =0;
            Decimal orderSum =0;
            Map<Id, List<OrderItem>> curFamilyMap =orderFamilyItem.get(orderId);
            for(Id familyId: curFamilyMap.keySet()){                
                List<OrderItem> curOrderList =curFamilyMap.get(familyId);
                Integer qtd =0;
                Decimal sum =0;
                for(OrderItem curOrderItem: curOrderList){
                    if (curOrderItem.DirectMargin__c !=null){
                        qtd++;
                        orderQtd++;
                        orderSum = orderSum+curOrderItem.DirectMargin__c;
                        sum =sum +curOrderItem.DirectMargin__c;
                    }
                }
                Decimal toFamilyMargin =null;
                if (qtd>0){
                    toFamilyMargin =sum/qtd;
                    toFamilyMargin =toFamilyMargin.setScale(4, RoundingMode.HALF_UP);
                }
                Map<Id, Decimal> newFamilyMargMap =orderFamilyFmargin.get(orderId);
                if (newFamilyMargMap==null){
                    newFamilyMargMap =new Map<Id, Decimal>();
                    orderFamilyFmargin.put(orderId, newFamilyMargMap);
                }
                newFamilyMargMap.put(familyId, toFamilyMargin);
            }
            Order curOrder =orders.get(orderId);
            Decimal toOrderDirectMargin =null;
            if (orderQtd>0){
                toOrderDirectMargin =orderSum/orderQtd;
                toOrderDirectMargin =toOrderDirectMargin.setScale(4, RoundingMode.HALF_UP);
            }
            if (curOrder.DirectMargin__c!=toOrderDirectMargin){
                curOrder.DirectMargin__c =toOrderDirectMargin;
                ordersToUpdate.add(curOrder);
            }            
        }
        List<OrderItem> toUpdate =new List<OrderItem>();
        for(OrderItem curOrderItem: newItems){
            if(Approval.isLocked(curOrderItem.OrderId)) continue;
            Map<Id, Decimal> familyMargMap =orderFamilyFmargin.get(curOrderItem.OrderId);     
            if (familyMargMap ==null){
                System.debug('calcMargem Error: have not found familyMargMap');
                curOrderItem.DirectFamilyMargin__c =null;
                continue;
            }
            Decimal famMargin =familyMargMap.get(curOrderItem.ProductFamily__c);            
            if (curOrderItem.DirectFamilyMargin__c!=famMargin){
                curOrderItem.DirectFamilyMargin__c =famMargin;
                toUpdate.add(curOrderItem);
            }
        }
        if (!toUpdate.isEmpty()){
            OrderItemHelper.disableTrigger();
            update toUpdate;
            OrderItemHelper.enableTrigger();
        }
        if (!ordersToUpdate.isEmpty()){
            OrderHelper.disableTrigger();
            update ordersToUpdate;
            OrderHelper.enableTrigger();
        }
        
        // Realizar um select nos produtos dos pedidos de todos os pedidos,
        // agrupando pela seguinte chave:
        // OrderId + Id da Familia do produto.        
    }*/

}