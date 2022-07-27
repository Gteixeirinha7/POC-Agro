public without sharing class OrderHelper {
    private static Boolean runTrigger;
    private static id barterId;

    static {
        runTrigger = true;
        barterId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('BarterSale').getRecordTypeId();
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
    public static void updatePath(Order[] context){ 
        for(Order ord : context){
            ord.StatusPath__c = ord.StatusSF__c;
            
            if(ord.RecordTypeId == barterId && ord.StatusSF__c == 'Em aprovação grãos') 
                ord.StatusPath__c = 'Em aprovação grãos';
            
            if(ord.RecordTypeId == barterId && ord.StatusSF__c == 'Aprovado')
                ord.StatusPath__c = (ord.ContractGrainCode__c == null ? 'Aguardando Contrato de grãos SAP' : (ord.ExternalId__c == null ? 'Aguardando Contrato de Insumos SAP' : 'Integrado'));
            
            if(ord.RecordTypeId != barterId && ord.StatusSF__c == 'Aprovado')
                ord.StatusPath__c = 'Aguardando retorno da integração';

            if(ord.StatusPath__c == 'Integrado' || ord.StatusSF__c == 'Integrado')
                ord.StatusPath__c = ord.ContainIntegrationError__c ? 'Integrado' : ord.StatusSAP__c;

            if(ord.StatusSF__c == 'Cancelado' || ord.StatusSF__c == 'Recusado')
                ord.StatusPath__c = 'X';
        }
    }
    public static void deleteShipping(Set<Id> ordIdSet) {
        List<ShippingDivision__c> shippingList = new List<ShippingDivision__c>();
        for(ShippingDivision__c ship : [SELECT id FROM ShippingDivision__c WHERE OrderItem__r.OrderId IN :ordIdSet]){
            shippingList.add(ship);
        }
        if(!shippingList.isEmpty()){
            delete shippingList;
        }
    }
    @future(callout = true)
    public static void checkProcess(Set<Id> ordIdSet) {
        checkProcessNotFuture(ordIdSet);
    }

    public static void checkProcessNotFuture(Set<Id> ordIdSet) {
        recallProcess(ordIdSet);
        recalculateCostFields(ordIdSet);
        CreateOrderController.callApprovalProcess(ordIdSet);
    }

    public static void checkIntegrationError(Order[] context, Map<Id, Order> oldContext) {
        Set<Id> ordIdSet = new Set<Id>();
        for(Order ord : context){
            Order oldOrd = oldContext.get(ord.id);
            if(ord.StatusSAP__c != oldOrd.StatusSAP__c && oldOrd.StatusSAP__c == null && ord.ExternalId__c != null){
                ord.ContainIntegrationError__c = false;
                ord.IntegrationErrorMessage__c = '';
            }
        }
    }
    public static void checkContractCredit(Order[] context, Map<Id, Order> oldContext) {
        Set<Id> ordIdSet = new Set<Id>();
        for(Order ord : context){
            Order oldOrd = oldContext.get(ord.id);
            if(ord.StatusSF__c == 'Retorna RTV' && oldOrd.StatusSF__c != ord.StatusSf__C){
                ordIdSet.add(ord.id);
            }
        }
        if(!ordIdSet.isEmpty()){
            IntegrationOrderIN.handleContractCredit(ordIdSet);
        }
    }
    public static void checkContractCreditApproved(Map<Id, Order> context, Map<Id, Order> oldContext) {
        Set<Id> ordIdSet = new Set<Id>();
        for(Order ord : context.values()){
            Order oldOrd = oldContext.get(ord.id);
            if(ord.StatusSF__c == 'Aprovado' && oldOrd.StatusSF__c != ord.StatusSf__C && ord.ContractOrder__c != null){
                ordIdSet.add(ord.id);
            }
        }
        if(ordIdSet.isEmpty()) return;

        IntegrationOrderIN.handleContractCredit(ordIdSet);

        Map<Id, OrderItem[]> ordItemZeroErrorMap = new Map<Id, OrderItem[]>();
        Map<Id, OrderItem[]> ordItemErrorMap = new Map<Id, OrderItem[]>();
        Map<Id, OrderItem[]> ordItemMap = new Map<Id, OrderItem[]>();
        for(OrderItem ordItem : [SELECT Id, OrderId, Product2Id, ContractOrderItem__r.ContractProductCredit__c FROM OrderItem WHERE OrderId IN :ordIdSet]){
            if(ordItem.ContractOrderItem__r.ContractProductCredit__c == 0)
                inputMapCredit(ordItem, ordItemZeroErrorMap);

            if(ordItem.ContractOrderItem__r.ContractProductCredit__c < 0)
                inputMapCredit(ordItem, ordItemErrorMap);
                
            inputMapCredit(ordItem, ordItemMap);
        }

        Set<Id> ordCancelIdSet = new Set<Id>();
        Set<Id> ordReturnIdSet = new Set<Id>();
        for(Id ordId : ordIdSet){
            List<OrderItem> ordItemZeroErrorList  = ordItemZeroErrorMap.containsKey(ordId) ? ordItemZeroErrorMap.get(ordId) : new List<OrderItem>();
            List<OrderItem> ordItemErrorList  = ordItemErrorMap.containsKey(ordId) ? ordItemErrorMap.get(ordId) : new List<OrderItem>();
            List<OrderItem> ordItemList       = ordItemMap.containsKey(ordId) ? ordItemMap.get(ordId) : new List<OrderItem>();
            if(ordItemZeroErrorList.size() == ordItemList.size()){
                ordCancelIdSet.add(ordId);
            }else if(ordItemErrorList.size() > 0 || ordItemZeroErrorList.size() > 0){
                ordReturnIdSet.add(ordId);
            }
        }

        if(!ordCancelIdSet.isEmpty()){
            updateOrderObservation(ordCancelIdSet, 'Cancelado', Label.CancelOrderContract);
        }
        if(!ordReturnIdSet.isEmpty()){
            updateOrderObservation(ordReturnIdSet, 'Retorna RTV', Label.ReturnOrderContract);
        }

        IntegrationOrderIN.handleContractCredit(ordIdSet);
    }
    public static void inputMapCredit(OrderItem ordItem, Map<Id, OrderItem[]> maps){
        if(!maps.containsKey(ordItem.OrderId))
            maps.put(ordItem.OrderId, new List<OrderItem>());
        maps.get(ordItem.OrderId).add(ordItem);
    }
    public static void updateOrderObservation(Set<Id> ordIdSet, String status, String texts){
        List<Order> ordList = new List<Order>();
        for(Id ordId : ordIdSet){
            ordList.add(new Order(Id = ordId, StatusSF__c = status, ObservationRTV__c = texts));
        }
        OrderHelper.disableTrigger();
        update ordList;
        sendNotificationRTV(ordIdSet);
        OrderHelper.enableTrigger();
    }
    public static void sendNotificationRTV(Order[] context, Map<Id, Order> oldContext) {
        Set<Id> ordIdSet = new Set<Id>();
        for(Order ord : context){
            Order oldOrd = oldContext.get(ord.id);
            if(ord.ObservationRTV__c != null && oldOrd.ObservationRTV__c != ord.ObservationRTV__c){
                ordIdSet.add(ord.id);
            }
        }
        if(!ordIdSet.isEmpty()){
            sendNotificationRTV(ordIdSet);
        }
    }
    // OrderHelper.sendNotificationRTV(new Set<Id>{'801050000009vvaAAA'});
    public static void sendNotificationRTV(Set<Id> ordIdSet) {
        Id typeId = [SELECT Id FROM CUstomNotificationType WHERE DeveloperName = 'RetornaRTV'].Id;
        Id usID = [SELECT Id FROM User WHERE Name LIKE '%Nescara Sales Force Integração%' LIMIT 1].Id;
        for(Order ord : [SELECT id, ObservationRTV__c, RTV__c, OrderNumber FROM Order WHERE Id IN :ordIdSet]){
            if(ord.ObservationRTV__c == null) continue;
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setBody(ord.ObservationRTV__c);
            notification.setTitle('Pedido '+ord.OrderNumber+', retornou do processo de aprovação');
            notification.setSenderId(usID);
            notification.setNotificationTypeId(typeId );
            notification.setTargetId(ord.ID); // target object id
            notification.send(new Set<String> { ord.RTV__c }); // target user id.
        }
    }
    public static void clearRejectFields(Order[] context, Map<Id, Order> oldContext) {
        Set<Id> ordIdSet = new Set<Id>();
        for(Order ord : context){
            Order oldOrd = oldContext.get(ord.id);
            if(ord.StatusSF__c == 'Retorna RTV' && oldOrd.StatusSF__c != ord.StatusSf__C){
                clearFields(ord);
                ordIdSet.add(ord.id);
            }else if(checkRecalculateApprovals(ord, oldOrd)){
                clearFields(ord);
            }

            //para casos de datas inferiores a data de criação
            if(ord.CreatedDate >= ord.EndDate){
                ord.EndDate = ord.EndDate.addDays(1);
            }
        }
        if(!ordIdSet.isEmpty()){
            Map<Id, String> commentsMap = handleOrderComments(ordIdSet);
            for(Order ord : context){
                if(ord.StatusSF__c == 'Retorna RTV' && oldContext.get(ord.id).StatusSF__c != ord.StatusSf__C){
                    ord.ObservationRTV__c = commentsMap.containsKey(ord.id) ? commentsMap.get(ord.id) : null;
                }
            }
        }
    }
    public static Map<Id, String> handleOrderComments(Set<Id> ordIdSet){
        Map<Id, String> processMap = new Map<Id, String>();
        for(ProcessInstanceStep process : [SELECT ProcessInstance.TargetObjectId, Actor.name, Comments FROM ProcessInstanceStep WHERE StepStatus = 'Rejected' ORDER BY  CreatedDate DESC]){
            if(!processMap.containsKey(process.ProcessInstance.TargetObjectId)){
                processMap.put(process.ProcessInstance.TargetObjectId, process.Comments);
            }
        }
        return processMap;
    } 
    public static void clearFields(Order ord){
        ord.MarginApprover__c =null;
        ord.Approved1__c = false;
        ord.Approved2__c = false;
        ord.Approved3__c = false;
        ord.Approved4__c = false;
        
        ord.DiscountApprover__c = null;
        ord.DiscountApprover2__c = null;
        ord.DiscountApprover3__c = null;
        ord.DiscountApprover4__c = null;
        ord.ObservationRTV__c = null;
        
        ord.FinancialAdministrativeManager__c = null;
        ord.CommercialApproval__c = false;
        
        ord.ApproverDiscountAmount__c = 0;
        ord.ApprovalJustification__c = '';
        ord.BonificationApprovalNote__c = '';
        ord.RegistrationApprovalNote__c = '';
        ord.DiscountApprovalNote__c = '';
        ord.FinancialApprovalNote__c = '';
    }
    public static void recalculateCostFields(Set<Id> recordId) {
        Map<String, OrderItem[]> externalMap = new Map<String, OrderItem[]>();
        Map<Id, OrderItem> ordItemUpdateMap = new Map<Id, OrderItem>();
        for(OrderItem ordItem : [SELECT id, ListPrice__r.Cost__c, Cost__c, ProductFamilyName__c, ProductFamily__c, Order.Crop__c, Order.SalesOrg__c FROM Orderitem WHERE OrderId IN :recordId]){
            String key = ordItem.Order.Crop__c+'_'+ordItem.Order.SalesOrg__c+'_'+ordItem.ProductFamily__c;
            ordItem.Cost__c = ordItem.ListPrice__r.Cost__c;
            if(!externalMap.containsKey(key))
                externalMap.put(key, new List<OrderItem>());
            externalMap.get(key).add(ordItem);
            ordItemUpdateMap.put(ordItem.id, ordItem);
        }
        for(ProjectedMargin__c projeted : [SELECT id, Margin__c, ExternalIdIndex__c FROM ProjectedMargin__c WHERE ExternalIdIndex__c IN :externalMap.keySet()]){
            if(!externalMap.containsKey(projeted.ExternalIdIndex__c)) continue;
            for(OrderItem ordItem : externalMap.get(projeted.ExternalIdIndex__c)){
                ordItem.Cost__c = ordItem.ListPrice__r.Cost__c;
                ordItem.ProjectedMargin__C = projeted.Margin__c;
                ordItemUpdateMap.put(ordItem.id, ordItem);
            }
        }
        OrderHelper.disableTrigger();
        update ordItemUpdateMap.values();
        OrderHelper.enableTrigger();
    
    }
    public static void recallProcess(Set<Id> recordId) {
        List<ProcessInstanceWorkitem> Pval = [SELECT Id FROM ProcessInstanceWorkItem 
        WHERE ProcessInstance.TargetObjectId = :recordId AND ProcessInstance.Status = 'Pending']; 
        System.debug('Pval=>'+Pval);
        List<Approval.ProcessWorkItemRequest> preqs = new List<Approval.ProcessWorkItemRequest>();
        for(ProcessInstanceWorkitem pival : Pval){
            Approval.ProcessWorkItemRequest preq= new Approval.ProcessWorkItemRequest();
            Preq.setAction('Removed');
            Preq.setWorkItemId(pival.Id);
            preqs.add(Preq);
        }
        List<Approval.ProcessResult> result = new List<Approval.ProcessResult>();
        if(!preqs.isEmpty()){
            result = Approval.process(preqs);
        }
    }

    
    public static void commodityProduct(Order[] context) {
        Set<String> prodNameSet = new Set<String>();
        for(Order ord : context){
            prodNameSet.add(IntegrationUtils.validSpecialCaracter(ord.Commodity__c == null ? '' : ord.Commodity__c).toUpperCase().replaceAll('(\\s+)',''));
        }
        Map<String, Product2[]> prodMap = (Map<String, Product2[]>) Collection.of([SELECT id, ProductNameKey__c FROM Product2 WHERE ProductNameKey__c IN :prodNameSet]).groupByStrings(Product2.ProductNameKey__c);
        for(Order ord : context){
            String prodName = IntegrationUtils.validSpecialCaracter(ord.Commodity__c == null ? '' : ord.Commodity__c).toUpperCase().replaceAll('(\\s+)','');
            ord.CommodityProduct2Id__c = prodMap.containsKey(prodName) && ord.Commodity__c != null ? prodMap.get(prodName)[0].id : null; 
        }
    }
    //Put approvals info when needed
    public static void newApprovalProcessFields(Map<Id, Order> orderMap, Map<Id, Order> oldOrderMap) {
        System.debug('orderNewMap' + orderMap);

        //Get Order Extra Informations From Relations
        Map<String, Order> orderNewMap = getOrderByOrderId(orderMap.keySet());
        System.debug('orderNewMap' + orderNewMap);

        //Get OrderItems on orders
        Map<String, List<OrderItem>> orderIdToOrderItemsMap = getOrderItemsByOrderId(orderNewMap.keySet());
        System.debug('orderIdToOrderItemsMap' + orderIdToOrderItemsMap);

        if(!orderIdToOrderItemsMap.isEmpty()){
            //CustomerPerOrg For Validations
            Map<String, CustomerPerOrg__c> customerPerOrgMap = getCustomerOrgBySalesOrg(orderNewMap.values());
            System.debug('customerPerOrgMap' + customerPerOrgMap);
            
            //Get Range Discounts Based On Product2 Family
            Map<String, List<RangeDiscount__c>> familyToRangeDiscountsMap = getRangeDiscountByFamily(orderNewMap.values(), orderIdToOrderItemsMap, customerPerOrgMap);
            System.debug('familyToRangeDiscountsMap' + familyToRangeDiscountsMap);

            //Get Range Discounts Based On OrderItem
            Map<String, RangeDiscount__c> orderItemToRangeDiscountMap = getRangeDiscountByOrderItemId(orderNewMap.values(), orderIdToOrderItemsMap, familyToRangeDiscountsMap, customerPerOrgMap);
            System.debug('orderItemToRangeDiscountMap' + orderItemToRangeDiscountMap);

            for(Order order : orderMap.values()){
                Order oldOrder = oldOrderMap.get(order.id);
                System.debug('order=>'+order);
                System.debug('oldOrder=>'+oldOrder);
                System.debug('orderIdToOrderItemsMap.containsKey(order.Id) =>' + orderIdToOrderItemsMap.containsKey(order.Id));
                System.debug('oldOrder.StatusSF__c =>' + oldOrder.StatusSF__c);
                System.debug('order.StatusSF__c =>' + order.StatusSF__c);
                System.debug('!Approval.isLocked(order.id) =>' + !Approval.isLocked(order.id));
                System.debug('order.RecalculateApprovals__c =>' + order.RecalculateApprovals__c);
                if((orderIdToOrderItemsMap.containsKey(order.Id) && (oldOrder.StatusSF__c == 'Em digitação' || (order.StatusSF__c == 'Em Aprovação' && !Approval.isLocked(order.id)))) || checkRecalculateApprovals(order)){
                    clearRejectFields(orderMap.values(), oldOrderMap);
                    if(order.CommercialApproval__c == false && comercialApprovalCheck(orderIdToOrderItemsMap.get(order.Id), orderItemToRangeDiscountMap)){
                        order.CommercialApproval__c = true;
                        order.RegistrationApprovalNote__c = buildRegistrationApprovalNote(orderIdToOrderItemsMap.get(order.Id), orderItemToRangeDiscountMap);
                    }

                    if(order.FinancialAdministrativeManager__c == null && financialApprovalCheck(orderNewMap.get(order.Id), orderIdToOrderItemsMap.get(order.Id))){
                        order.FinancialAdministrativeManager__c = orderNewMap.get(order.Id).SalesOffice__r.ParentId__r.FinancialAdministrativeManager__c;
                    }
                    //Inactive Margin
                    if(false && (order.HasOrderItemWithoutMargin__c || order.HasOrderItemWithoutCost__c || order.HasOrderItemWithLowerMargin__c)){
                        if(order.HasOrderItemWithoutMargin__c || order.HasOrderItemWithoutCost__c)
                            order.MarginApprover__C = orderNewMap.get(order.Id).SalesOffice__r.ParentId__r.MarketingManager__c;
                        else
                            order.MarginApprover__C = orderNewMap.get(order.Id).SalesOffice__r.SalesDirector__c != null ? orderNewMap.get(order.Id).SalesOffice__r.SalesDirector__c : orderNewMap.get(order.Id).SalesOffice__r.ParentId__r.Director__c;
                        setApprovalJustification(orderMap, orderIdToOrderItemsMap);
                            
                    }else if(orderNewMap.get(order.Id).RecordType.DeveloperName == 'IndustryBonification'){
                        order.MarginApprover__C = null;
                        order.DiscountApprover__c = orderNewMap.get(order.Id).SalesOffice__r.ParentId__r.MarketingManager__c;
                        order.BonificationApprovalNote__c = buildBonificationApprovalNote(orderIdToOrderItemsMap.get(order.Id));
                        system.debug('Industria');
                    }else if(orderNewMap.get(order.Id).RecordType.DeveloperName == 'Bonification'){
                        order.MarginApprover__C = null;
                        order.DiscountApprover__c = orderNewMap.get(order.Id).SalesOffice__r.SalesDirector__c != null ? orderNewMap.get(order.Id).SalesOffice__r.SalesDirector__c : orderNewMap.get(order.Id).SalesOffice__r.ParentId__r.Director__c;
                        order.BonificationApprovalNote__c = buildBonificationApprovalNote(orderIdToOrderItemsMap.get(order.Id));
                    }
                    else if(!comercialApprovalCheck(orderIdToOrderItemsMap.get(order.Id), orderItemToRangeDiscountMap)){
                        String discountApprover = discountApproverCheck(orderNewMap.get(order.Id), orderIdToOrderItemsMap.get(order.Id), familyToRangeDiscountsMap, customerPerOrgMap);
                        Boolean check = order.DiscountApprover__c == null || order.DiscountApprover__c != orderNewMap.get(order.Id).SalesOffice__r.ParentId__r.Director__c;
                        if(discountApprover == 'ClusterDirector' && check){
                            if(orderNewMap.get(order.Id).SalesOrg__c != null && orderNewMap.get(order.Id).SalesOffice__r.SalesDirector__c != null){
                                order.DiscountApprover4__c = orderNewMap.get(order.Id).SalesOffice__r.SalesDirector__c;
                            }else{
                                order.DiscountApprover4__c = orderNewMap.get(order.Id).SalesOrg__c != null ? orderNewMap.get(order.Id).SalesOffice__r.ParentId__r.Director__c : null;
                            }
                            order.DiscountApprover3__c = orderNewMap.get(order.Id).SalesOrg__c != null ? orderNewMap.get(order.Id).SalesOrg__r.Director__c : orderNewMap.get(order.Id).SalesOffice__r.ParentId__r.Director__c;
                            order.DiscountApprover2__c = orderNewMap.get(order.Id).SalesOffice__r.GGN__c; 
                            order.DiscountApprover__c = orderNewMap.get(order.Id).SalesTeam__r.Manager__c;
                            order.MarginApprover__C = null;
                        }
                        else if(discountApprover == 'InvesteeDirector' && check){
                            order.DiscountApprover3__c = orderNewMap.get(order.Id).SalesOrg__r.Director__c;
                            order.DiscountApprover2__c = orderNewMap.get(order.Id).SalesOffice__r.GGN__c; 
                            order.DiscountApprover__c = orderNewMap.get(order.Id).SalesTeam__r.Manager__c;
                            order.DiscountApprover4__c = null;
                            order.MarginApprover__C = null;
                        }
                        else if(discountApprover == 'GGN' && check){
                            order.DiscountApprover2__c = orderNewMap.get(order.Id).SalesOffice__r.GGN__c; 
                            order.DiscountApprover__c = orderNewMap.get(order.Id).SalesTeam__r.Manager__c;
                            order.DiscountApprover3__c = null;
                            order.DiscountApprover4__c = null;
                            order.MarginApprover__C = null;
                        }
                        else if(discountApprover == 'Manager' && check){
                            order.DiscountApprover__c = orderNewMap.get(order.Id).SalesTeam__r.Manager__c;
                            order.DiscountApprover2__c = null;
                            order.DiscountApprover3__c = null;
                            order.DiscountApprover4__c = null;
                            order.MarginApprover__C = null;
                        }
                        else if(discountApprover == null){
                            order.DiscountApprover__c = null;
                            order.DiscountApprover2__c = null;
                            order.DiscountApprover3__c = null;
                            order.DiscountApprover4__c = null;
                            order.DiscountApprovalNote__c = null;
                        }
                        if(discountApprover != null){
                            order.MarginApprovalNote__c = null;
                            order.DiscountApprovalNote__c = buildDiscountApprovalNote(orderIdToOrderItemsMap.get(order.Id));
                        }
                    }
                }
            }
            checkApproversVacation(orderMap.Values());
            checkApproversVacationShared(orderMap.Values());
        }
    }


    public static void checkApproversVacation(List<Order> orderList) {
        Set<String> userApprovers = new Set<String>();
        for (Order order : orderList) {
            userApprovers.add(order.DiscountApprover__c);
            userApprovers.add(order.DiscountApprover2__c);
            userApprovers.add(order.DiscountApprover3__c);
            userApprovers.add(order.DiscountApprover4__c);
            userApprovers.add(order.FinancialAdministrativeManager__c);
        }

        List<Vacation__c> vacationList = [
            SELECT Id, VacationUser__c, DelegateApproverUser__c
            FROM Vacation__c
            WHERE VacationStartDate__c <= TODAY AND VacationEndDate__c >= TODAY AND VacationUser__c IN: userApprovers   
        ];
        System.debug('vacationList =>' + vacationList); 
        
        Map<String, String> vacationUserToDelegateApproverUser = new Map<String, String>();
            for (Vacation__c vacation : vacationList) {
                vacationUserToDelegateApproverUser.put(vacation.VacationUser__c, vacation.DelegateApproverUser__c);
            }
        System.debug('vacationUserToDelegateApproverUser =>' + vacationUserToDelegateApproverUser);

        for (Order order : orderList) {
            order.DiscountApprover__c = vacationUserToDelegateApproverUser.containsKey(order.DiscountApprover__c) ? vacationUserToDelegateApproverUser.get(order.DiscountApprover__c) : order.DiscountApprover__c;
            order.DiscountApprover2__c = vacationUserToDelegateApproverUser.containsKey(order.DiscountApprover2__c) ? vacationUserToDelegateApproverUser.get(order.DiscountApprover2__c) : order.DiscountApprover2__c;
            order.DiscountApprover3__c = vacationUserToDelegateApproverUser.containsKey(order.DiscountApprover3__c) ? vacationUserToDelegateApproverUser.get(order.DiscountApprover3__c) : order.DiscountApprover3__c;
            order.DiscountApprover4__c = vacationUserToDelegateApproverUser.containsKey(order.DiscountApprover4__c) ? vacationUserToDelegateApproverUser.get(order.DiscountApprover4__c) : order.DiscountApprover4__c;
            order.FinancialAdministrativeManager__c = vacationUserToDelegateApproverUser.containsKey(order.FinancialAdministrativeManager__c) ? vacationUserToDelegateApproverUser.get(order.FinancialAdministrativeManager__c) : order.FinancialAdministrativeManager__c;
        }
    }
    
    public static void checkApproversVacationShared(List<Order> orderList) {
        Set<String> fieldSet= new Set<String>{'DiscountApprover__c', 'DiscountApprover2__c', 'DiscountApprover3__c', 'DiscountApprover4__c', 'FinancialAdministrativeManager__c'};
        
        List<OrderShare> sharesCreate = new List<OrderShare>();
        for(Order ord : orderList){
            for(String field : fieldSet){
                sharesCreate.add(shareOrder(ord, (String)ord.get(field)));
            }
        }

        if(!sharesCreate.isEmpty()){
            insertDML(JSON.serialize(sharesCreate));
        }
    }
    public static OrderShare shareOrder(Order ord, String usId){
        return new OrderShare(OrderId = ord.Id, UserOrGroupId = usId, OrderAccessLevel = 'Edit');
    }
    //Check Comercial Approval Process Needed
    public static Boolean comercialApprovalCheck(List<OrderItem> orderItems, Map<String, RangeDiscount__c> orderItemToRangeDiscountMap){
        for(OrderItem orderItem : orderItems){
            if(!orderItemToRangeDiscountMap.containsKey(orderItem.Id) && orderItem.DiscountPercent__c != null && orderItem.DiscountPercent__c != 0){
                return true;
            }

        }
        return false;
    }

    //Check Financial Approval Process Needed
    public static Boolean financialApprovalCheck(Order order, List<OrderItem> orderItems){
        for(OrderItem orderItem : orderItems){
            if(order.PaymentDate__c != null && OrderItem.ListPrice__c != null){
                Date paymentDate = order.PaymentDate__c;
                Date effectiveDate = OrderItem.ListPrice__r.EffectiveDate__c;
                System.debug(paymentDate);
                System.debug(OrderItem.ListPrice__r.EffectiveDate__c);
                System.debug(effectiveDate);
                System.debug(effectiveDate?.addDays(30));
                if(paymentDate > effectiveDate?.addDays(30)){
                    return true;
                }
            }
            else{
                return true;
            }
        }
        return false;
    }

    //Check Financial Approver of the Approval Process If Needed
    public static String discountApproverCheck(Order order, List<OrderItem> orderItems, Map<String, List<RangeDiscount__c>> familyToRangeDiscountsMap, Map<String, CustomerPerOrg__c> customerPerOrgMap){
        Map<String, List<Decimal>> familyToPercentsMap = new Map<String, List<Decimal>>();
        Map<String, Decimal> familyToAverageMap = new Map<String, Decimal>();

        String approvingAuthority = null;
        Decimal grossTotal = 0;
        //get all values by family
        
        for(OrderItem orderItem : orderItems){
            if (familyToPercentsMap.containsKey(orderItem.Product2.Family__c)) {
                familyToPercentsMap.get(orderItem.Product2.Family__c).add(orderItem.DiscountPercent__c);
            }
            else {
                familyToPercentsMap.put(orderItem.Product2.Family__c, new List<Decimal>{orderItem.DiscountPercent__c});
            }
            if (orderItem.CustomListPrice__c != null) {
                grossTotal += orderItem.CustomListPrice__c * orderItem.Quantity__c; 
            }
        }
        //get average of each list by family
        for(String family : familyToPercentsMap.keySet()){
            integer count = 0;
            Decimal sum = 0;
            for(Decimal percent : familyToPercentsMap.get(family)){
                if (percent != null){ sum += percent;}
                count++;
            }
            familyToAverageMap.put(family, (sum/count));
        }
        //look for approvers on each RangeDiscount
        for(String family : familyToRangeDiscountsMap.keySet()){
            for(RangeDiscount__c rangeDiscount : familyToRangeDiscountsMap.get(family)){
                if(familyToAverageMap.containsKey(family) 
                && (customerPerOrgMap.containsKey(order.Account.ExternalId__c + '|' + order.SalesOrg__r.ExternalId__c + '|' + order.DistributionChannel__c + '|' + order.ActivitySector__c) 
                && rangeDiscount.CustomerCategory__c == customerPerOrgMap.get(order.Account.ExternalId__c + '|' + order.SalesOrg__r.ExternalId__c + '|' + order.DistributionChannel__c + '|' + order.ActivitySector__c).ClientGroup__c) 
                && rangeDiscount.SalesOffice__c == order.SalesOffice__c && rangeDiscount.PaymentType__c == order.PaymentCondition__r.PaymentType__c 
                && rangeDiscount.InitialDate__c <= Date.Today() && Date.Today() <= rangeDiscount.FinalDate__c 
                && rangeDiscount.MinimumPercentage__c <= familyToAverageMap.get(family) && familyToAverageMap.get(family) <= rangeDiscount.MaximaPercentage__c){
                    Decimal totalDiscount = ((grossTotal - order.TotalAmount)/ grossTotal) * 100;
                    System.debug('Valor Bruto: ' + grossTotal);
                    System.debug('Valor Liquido: ' + order.TotalAmount);
                    System.debug('totalDiscount: ' + totalDiscount);
                    System.debug('Discount => totalDiscount: ' + totalDiscount + ' => ' + order.SalesOrg__r.ManagerPercentApprovalLimit__c);
                    System.debug('Moeda: ' + order.Currency__c);
                    System.debug('Valor => Valor Limite Em Real: ' + order.TotalAmount + ' => ' + order.SalesOrg__r.ManagerValueApprovalLimit__c);
                    System.debug('Valor => Valor Limite Em Dolar: ' + order.TotalAmount + ' => ' + order.SalesOrg__r.ManagerDolarApprovalLimit__c);
                    if (approvingAuthority == null) {
                        approvingAuthority = rangeDiscount.ApprovingAuthority__c;
                    }
                    else if(rangeDiscount.ApprovingAuthority__c == 'ClusterDirector') {
                        approvingAuthority = rangeDiscount.ApprovingAuthority__c;
                    }
                    else if(rangeDiscount.ApprovingAuthority__c == 'InvesteeDirector' && approvingAuthority != 'ClusterDirector'){
                        approvingAuthority = rangeDiscount.ApprovingAuthority__c;
                    }
                    else if(rangeDiscount.ApprovingAuthority__c == 'GGN' && approvingAuthority == 'Manager') {
                        approvingAuthority = rangeDiscount.ApprovingAuthority__c;
                    }
                    if (approvingAuthority != null && 
                    (((order.Currency__c == 'BRL' && order.TotalAmount <= order.SalesOrg__r.ManagerValueApprovalLimit__c) || 
                    (order.Currency__c == 'USD' && order.TotalAmount <= order.SalesOrg__r.ManagerDolarApprovalLimit__c)) && 
                    (totalDiscount <= order.SalesOrg__r.ManagerPercentApprovalLimit__c))) {
	                    approvingAuthority = 'Manager';
                    }               
                }
            }
        }
        return approvingAuthority;
    }

    public static String buildRegistrationApprovalNote(List<OrderItem> OrderItems, Map<String, RangeDiscount__c> orderItemToRangeDiscountMap){
        System.debug('orderItemToRangeDiscountMap' + orderItemToRangeDiscountMap);
        List<OrderItem> orderItemsWithouthRangeDiscount = getOrderItemByWithouthRangeDiscount(OrderItems, orderItemToRangeDiscountMap);
        System.debug('orderItemsWithouthRangeDiscount' + orderItemsWithouthRangeDiscount);
        Map<String, List<OrderItem>> familyToOrderItemMap = getOrderItemByFamily(orderItemsWithouthRangeDiscount);
        System.debug('familyToOrderItemMap' + familyToOrderItemMap);
        String finalString = '';
        for(String family : familyToOrderItemMap.keySet()){
            //FamilyName
            if(familyToOrderItemMap.get(family)[0] != null){
                finalString += familyToOrderItemMap.get(family)[0].Product2.Family__r.Name + ' - ';
            }
            Decimal totalValue = 0;
            Decimal totalPercent = 0;
            Integer count = 0;
            for(OrderItem orderItem: familyToOrderItemMap.get(family)){
                totalValue += orderItem.TotalPrice__c;
                if(orderItem.DiscountPercent__c != null){totalPercent += orderItem.DiscountPercent__c;}
                count++;
            }
            //TotalValue
            finalString += familyToOrderItemMap.get(family)[0].order.Currency__c =='USD' ? ('$ ' + totalValue + ' - ') : ('R$ ' + totalValue + ' - ');

            //TotalPercentage
            finalString += (totalPercent/count).setScale(2) + '% Desc : \n';

            for(OrderItem orderItem: familyToOrderItemMap.get(family)){
                finalString += '    ' + orderItem.Product2.Name + ' - ' + orderItem.Quantity__c + ' ' + orderItem.UnitMeasure__c + '\n';
            }
            finalString += '\n';
        }
        return finalString;
    }

    public static String buildBonificationApprovalNote(List<OrderItem> OrderItems){
        String finalString = '';
        for(OrderItem orderItem: OrderItems){
            finalString += orderItem.Product2.Name + ' - ' + orderItem.Quantity__c + ' ' + orderItem.UnitMeasure__c + '\n' + '\n';
        }
        return finalString;
    }

    public static String buildDiscountApprovalNote(List<OrderItem> OrderItems){
        Map<String, List<OrderItem>> familyToOrderItemMap = getOrderItemByFamily(OrderItems);
        String finalString = '';
        for(String family : familyToOrderItemMap.keySet()){
            //FamilyName
            if(familyToOrderItemMap.get(family)[0] != null){
                finalString += familyToOrderItemMap.get(family)[0].Product2.Family__r.Name + ' - ';
            }
            Decimal totalValue = 0;
            Decimal totalPercent = 0;
            Integer count = 0;
            for(OrderItem orderItem: familyToOrderItemMap.get(family)){
                totalValue += orderItem.TotalPrice__c;
                if(orderItem.DiscountPercent__c != null){
                    totalPercent += orderItem.DiscountPercent__c;
                }
                count++;
            }
            //TotalValue
            finalString += familyToOrderItemMap.get(family)[0].order.Currency__c =='USD' ? ('$ ' + totalValue + ' - ') : ('R$ ' + totalValue + ' - ');
            //TotalPercentage
            finalString += (totalPercent/count).setScale(2) + '% Desc : \n';

            for(OrderItem orderItem: familyToOrderItemMap.get(family)){
                finalString += '    ' + orderItem.Product2.Name + ' - ' + orderItem.Quantity__c + ' ' + orderItem.UnitMeasure__c + '\n';
            }
            finalString += '\n';
        }
        return finalString;
    }
    public static void shareRead(List<Order> orderList){
     
        Set<String> nameSet = new Set<String>();
        Set<Id> orderIdSet = new Set<Id>();

        for (Order order : orderList) {
            orderIdSet.add(order.Id);
        }
        Map<Id,Order> orderMap = new Map<Id,Order>([
            SELECT Name, Id, SalesTeam__c, SalesOrg__r.Director__c, SalesOffice__r.ExternalId__c, SalesOffice__r.SeedsCoordinator__c, SalesOffice__r.SpecialtiesCoordinator__c, SalesTeam__r.Manager__c, SalesOffice__r.GGN__c, SalesTeam__r.Name, SalesOffice__r.ParentId__r.Director__c, SalesOffice__r.ParentId__r.MarketingManager__c,SalesOffice__r.ParentId__r.FinancialAdministrativeManager__c, DiscountApprover__c, DiscountApprover2__c, DiscountApprover3__c, DiscountApprover4__c, FinancialAdministrativeManager__c, OwnerId
            FROM Order
            WHERE  Id IN: orderIdSet
        ]);

        checkApproversVacationShared(orderMap.Values());

        Map<Id, Set<Id>> userIdMap = new Map<Id,  Set<Id>>();

        for (Order order : orderMap.values()) {
            // nameSet.add('AT_'+order.SalesTeam__r.Name);
            nameSet.add('Gerente_Comercial_'+order.SalesTeam__r.Name);
            // nameSet.add('RTV_'+order.SalesTeam__r.Name);
            nameSet.add('Vendedor_Interno_'+order.SalesTeam__r.Name);
            nameSet.add('Coordenador_Produtos_'+order.SalesOffice__r.ExternalId__c);

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

            if(order.SalesOffice__r.SeedsCoordinator__c != null)
                userIdMap.get(order.id).add(order.SalesOffice__r.SeedsCoordinator__c);

            if(order.SalesOffice__r.SpecialtiesCoordinator__c != null)
                userIdMap.get(order.id).add(order.SalesOffice__r.SpecialtiesCoordinator__c);

        }
        List<Group> GroupList = new List<Group>([
            SELECT DeveloperName, Id
            FROM Group
            WHERE DeveloperName IN: nameSet
        ]);

        System.debug('userIdMap: ' + userIdMap);
        System.debug('GroupList: ' + GroupList);
        
        Set<OrderShare> sharesCreate = new Set<OrderShare>();

        if (!userIdMap.IsEmpty()) {
            for (Order order : orderMap.values()) {
                if(userIdMap.containsKey(order.id)){
                    for(Id usId : userIdMap.get(order.id)){
                        OrderShare OrderShr  = new OrderShare();
                        OrderShr.OrderId = order.Id;
                        OrderShr.UserOrGroupId = usId;
                        OrderShr.OrderAccessLevel = 'Edit';    
                        sharesCreate.add(OrderShr); 
                    }
                }
            }
        }

        if (!GroupList.IsEmpty()) {
            for (Order order : orderMap.values()) {
                for (Group userGroup : GroupList) {
                    if (userGroup.DeveloperName.contains(order.SalesTeam__r.Name) || userGroup.DeveloperName.contains('Coordenador_Produtos_'+order.SalesOffice__r.ExternalId__c)) {
                        OrderShare OrderShr  = new OrderShare();
                        OrderShr.OrderId = order.Id;
                        OrderShr.UserOrGroupId = userGroup.Id;
                        OrderShr.OrderAccessLevel = 'Edit';    
                        sharesCreate.add(OrderShr); 
                    }
                }
            }
        }

        System.debug('ShareCreate: ' + sharesCreate);
        if (!sharesCreate.isEmpty()) {
            insertDML(JSON.serialize(sharesCreate));
        }
    }

    public static void shareRead(List<Order> newOrderList, Map<Id, Order> oldOrderMap){

        Map<Id, Order> orderMap = new Map<Id, Order>();

        checkApproversVacationShared(orderMap.Values());

        for(Order newOrder : newOrderList){
            if(oldOrderMap.containsKey(newOrder.Id)){
                if(newOrder.SalesTeam__c != oldOrderMap.get(newOrder.Id).SalesTeam__c){
                    orderMap.put(newOrder.Id, newOrder);
                }
            }
        }

        if(orderMap.size() > 0){
            shareRead(orderMap.values());

            List<OrderItem> ordItemList = [
                SELECT Id
                FROM OrderItem
                WHERE OrderId IN : orderMap.keySet()
            ];

            List<String> ordItemIdList = new List<String>();

            for (OrderItem orderItem : ordItemList){
                ordItemIdList.add(orderItem.Id);
            }

            List<ShippingDivision__c> shippingDivisionList = [
                SELECT Id, RecalcShare__c
                FROM ShippingDivision__c
                WHERE OrderItem__c IN : ordItemIdList
            ];

            for(ShippingDivision__c shippingDivision : shippingDivisionList){
                shippingDivision.RecalcShare__c = true;
            }

            if(!shippingDivisionList.isEmpty()){
                update shippingDivisionList;
            }
        }
    }


    //look for approved accounts and populates lastBuyInfos
    public static void attAccountLastBuyInfo(Map<Id, Order> orderMap) {
        Map<String, String> approvedOrderToAccountIdMap = getOrderToAccountIdByApproval(orderMap.values());

        if(approvedOrderToAccountIdMap.isEmpty()) return;

        Map<Id, Account> accountMap = new Map<Id, Account>(AccountDAO.getAccountById(approvedOrderToAccountIdMap.values(), new Set<String>{'Id','LastPurchaseDate__c','LastPurchaseValue__c'}));
        //Map because that Trigger new can contain 2 orders of same account been approved
        Map<Id, Account> accountsToUpdateMap = new Map<Id, Account>();

        for(String orderId : approvedOrderToAccountIdMap.keySet()){
            Order ord = orderMap.get(orderId);
            String accId = approvedOrderToAccountIdMap.get(orderId);

            if(!accountMap.containsKey(accId)) continue;
            Account acc = accountMap.get(accId);

            if(acc == null) continue;

            if(acc.LastPurchaseDate__c == null || ord.CreatedDate >= acc.LastPurchaseDate__c){
                acc.LastPurchaseDate__c = ord.CreatedDate?.Date();
                acc.LastPurchaseValue__c = ord.TotalAmountWithFreight__c;
                accountsToUpdateMap.put(acc.Id, acc);
            }
        }
        //update accounts with last order infos
        if(!accountsToUpdateMap.values().isEmpty()){
            RelationsTerritoryClass.disableTrigger();
            Database.update(accountsToUpdateMap.values());
            RelationsTerritoryClass.enableTrigger();
        }
    }

    public static Map<String, String> getOrderToAccountIdByApproval(List<Order> orderList){
        Map<String, String> approvedOrderToAccountIdMap = new Map<String, String>();
        for(Order order : orderList){
            if(order.StatusSF__c == 'Aprovado'){
                approvedOrderToAccountIdMap.put(order.Id, order.AccountId);
            }
        }
        return approvedOrderToAccountIdMap;
    }

    public static Map<String, Order> getOrderByOrderId(Set<Id> orderIds){
        Map<String, Order> orderMap = new Map<String, Order>(OrderDAO.getOrderById((List<String>)new List<Id>(orderIds), new Set<String>{'Id', 'RecordType.DeveloperName', 'AccountId', 'Account.ExternalId__c', 'DistributionChannel__c', 'ActivitySector__c',  'PaymentCondition__c', 'PaymentCondition__r.PaymentType__c', 'TotalAmount', 'TotalAmountWithFreight__c', 'PaymentDate__c', 'SalesTeam__c', 'SalesTeam__r.Manager__c', 'SalesOffice__c', 'SalesOffice__r.ParentId__r.Name', 'SalesOffice__r.GGN__c', 'SalesOffice__r.SalesDirector__c', 'SalesOffice__r.ParentId__c', 'SalesOffice__r.ParentId__r.Director__c', 'SalesOffice__r.ParentId__r.FinancialAdministrativeManager__c', 'SalesOffice__r.ParentId__r.MarketingManager__c','Currency__c', 'SalesOrg__c', 'SalesOrg__r.ExternalId__c', 'SalesOrg__r.Director__c','SalesOrg__r.ManagerValueApprovalLimit__c','SalesOrg__r.ManagerPercentApprovalLimit__c','SalesOrg__r.ManagerDolarApprovalLimit__c'}));
        return orderMap;
    }

    public static Map<String, List<OrderItem>> getOrderItemsByOrderId(Set<String> orderIds){
        Map<String, List<OrderItem>> orderIdToOrderItemsMap = new Map<String, List<OrderItem>>();
        //Order.Id -> OrderItems
        // 'DirectMargin__c','FamilyMargin__c' 'ProjectedMargin__c'
        for(OrderItem orderItem : OrderItemDAO.getOrderItemByOrderId(new List<String>(orderIds), new Set<String>{
                'Id', 'OrderId', 'Product2Id', 'Product2.Name', 'Product2.Family__c', 'ProductFamilyName__c', 'ProductFamily__c', 'DirectMargin__c','FamilyMargin__c',
                'InvalidCost__c', 'Cost__c',
                'Product2.Family__r.Name', 'ListPrice__c','DiscountAmount__c', 'Order.Currency__c', 
                'ListPrice__r.UnitPrice__c', 'ListPrice__r.EffectiveDate__c',
                'LowerMargin__c','DirectFamilyMargin__c', 'FamilyMargin__c', 'ProjectedMargin__c',
                'DiscountPercent__c', 'TotalPrice__c', 'UnitMeasure__c', 'Quantity__c', 'CustomListPrice__c'})){
            if(orderIdToOrderItemsMap.keySet().Contains(orderItem.OrderId)){
                orderIdToOrderItemsMap.get(orderItem.OrderId).add(orderItem);
            }
            else{
                orderIdToOrderItemsMap.put(orderItem.OrderId, new List<OrderItem>{orderItem});
            }
        }
        return orderIdToOrderItemsMap;
    }

    public static Map<String, List<OrderItem>> getOrderItemByFamily(List<OrderItem> orderItems){
        Map<String, List<OrderItem>> familyToOrderItemMap = new Map<String, List<OrderItem>>();
        for(OrderItem orderItem : orderItems){
            if(familyToOrderItemMap.containsKey(orderItem.Product2.Family__c)){
                familyToOrderItemMap.get(orderItem.Product2.Family__c).add(orderItem);
            }
            else{
                familyToOrderItemMap.put(orderItem.Product2.Family__c, new List<OrderItem>{orderItem});
            }
        }
        return familyToOrderItemMap;
    }

    //Check Comercial Approval Process Needed
    public static List<OrderItem> getOrderItemByWithouthRangeDiscount(List<OrderItem> orderItems, Map<String, RangeDiscount__c> orderItemToRangeDiscountMap){
        List<OrderItem> orderItemList = new List<OrderItem>();
        for(OrderItem orderItem : orderItems){
            if(!orderItemToRangeDiscountMap.containsKey(orderItem.Id)){
                orderItemList.add(orderItem);
            }
        }
        return orderItemList;
    }
    
    public static Map<String, CustomerPerOrg__c> getCustomerOrgBySalesOrg(List<Order> orders){
        Map<String, CustomerPerOrg__c> customerPerOrgMap = new Map<String, CustomerPerOrg__c>();

        Set<String> externalIds = new Set<String>();
        
        for(Order order:orders){
            externalIds.add(order.Account.ExternalId__c + '|' + order.SalesOrg__r.ExternalId__c + '|' + order.DistributionChannel__c + '|' + order.ActivitySector__c);
        }

        for(CustomerPerOrg__c customerPerOrg : CustomerPerOrgDAO.getCustomerPerOrgByExternalId(new List<String>(externalIds), new Set<String>{'Id', 'ExternalId__c', 'DistributionChannel__c', 'Customer__c', 'ClientGroup__c', 'SalesOrg__c', 'ActivitySector__c', 'SalesSector__c'})){
            customerPerOrgMap.put(customerPerOrg.ExternalId__c, customerPerOrg);
        }

        return customerPerOrgMap;
    }

    public static Map<String, List<RangeDiscount__c>> getRangeDiscountByFamily(List<Order> orders, Map<String, List<OrderItem>> orderItemsInOrder, Map<String, CustomerPerOrg__c> customerPerOrgMap){
        
        Map<String, List<RangeDiscount__c>> familyToRangeDiscountsMap = new Map<String, List<RangeDiscount__c>>();
        //Infos For minimum Records Query
        Set<String> customerCategorys = new Set<String>();
        Set<String> salesOffices = new Set<String>();
        Set<String> paymentTypes = new Set<String>();
        Set<String> familys = new Set<String>();

        //Populate Infos For minimum Records Query
        for(Order order: orders){
            if(orderItemsInOrder.containsKey(order.Id)){
                for(OrderItem orderItem : orderItemsInOrder.get(order.Id)){
                    familys.add(orderItem.Product2.Family__c);
                }
            }
            if(customerPerOrgMap.containsKey(order.Account.ExternalId__c + '|' + order.SalesOrg__r.ExternalId__c + '|' + order.DistributionChannel__c + '|' + order.ActivitySector__c)){
                customerCategorys.add(customerPerOrgMap.get(order.Account.ExternalId__c + '|' + order.SalesOrg__r.ExternalId__c + '|' + order.DistributionChannel__c + '|' + order.ActivitySector__c).ClientGroup__c);
            }
            //salesOffices.add(order.SalesTeam__r.ParentId__c);
            salesOffices.add(order.SalesOffice__c);
            paymentTypes.add(order.PaymentCondition__r.PaymentType__c);
        }
        System.debug('customerCategorys' + customerCategorys);
        System.debug('salesOffices' + salesOffices);
        System.debug('paymentTypes' + paymentTypes);
        System.debug('familys' + familys);
        
        //OrderItem.Product2.Family__c -> RangeDiscount
        for(RangeDiscount__c rangeDiscount : RangeDiscountDAO.getRangeDiscountByAllInfos(new List<String>(customerCategorys), new List<String>(salesOffices), new List<String>(paymentTypes), new List<String>(familys), new Set<String>{'Id', 'ApprovingAuthority__c', 'CustomerCategory__c', 'PaymentType__c', 'SalesOffice__c', 'FinalDate__c', 'InitialDate__c', 'Family__c', 'Family__r.Name', 'MaximaPercentage__c', 'MinimumPercentage__c'})){
            if(familyToRangeDiscountsMap.containsKey(rangeDiscount.Family__c)){
                familyToRangeDiscountsMap.get(rangeDiscount.Family__c).add(rangeDiscount);
            }
            else{
                familyToRangeDiscountsMap.put(rangeDiscount.Family__c, new List<RangeDiscount__c>{rangeDiscount});
            }
        }

        return familyToRangeDiscountsMap;
    }

    public static Map<String, RangeDiscount__c> getRangeDiscountByOrderItemId(List<Order> orders, Map<String, List<OrderItem>> orderItemsInOrder, Map<String, List<RangeDiscount__c>> familyToRangeDiscountsMap, Map<String, CustomerPerOrg__c> customerPerOrgMap){
        Map<String, RangeDiscount__c> orderItemToRangeDiscountMap = new Map<String, RangeDiscount__c>();

        System.debug('orders' + orders);
        System.debug('orderItemsInOrder' + orderItemsInOrder);
        System.debug('familyToRangeDiscountsMap' + familyToRangeDiscountsMap);
        //OrderItem.Id -> RangeDiscount
        for(Order order: orders){
            System.debug('Contains OrderId? ' + orderItemsInOrder.containsKey(order.Id));
            if(orderItemsInOrder.containsKey(order.Id)){
                for(OrderItem orderItem : orderItemsInOrder.get(order.Id)){
                    System.debug('Contains Family? ' + familyToRangeDiscountsMap.containsKey(orderItem.Product2.Family__c));
                    if(familyToRangeDiscountsMap.containsKey(orderItem.Product2.Family__c) && orderItem.DiscountPercent__c != null){
                        for(RangeDiscount__c rangeDiscount : familyToRangeDiscountsMap.get(orderItem.Product2.Family__c)){
                            if((customerPerOrgMap.containsKey(order.Account.ExternalId__c + '|' + order.SalesOrg__r.ExternalId__c + '|' + order.DistributionChannel__c + '|' + order.ActivitySector__c) 
                            && rangeDiscount.CustomerCategory__c == customerPerOrgMap.get(order.Account.ExternalId__c + '|' + order.SalesOrg__r.ExternalId__c + '|' + order.DistributionChannel__c + '|' + order.ActivitySector__c).ClientGroup__c)
                            && rangeDiscount.SalesOffice__c == order.SalesOffice__c && rangeDiscount.PaymentType__c == order.PaymentCondition__r.PaymentType__c 
                            && rangeDiscount.InitialDate__c <= Date.Today() && Date.Today() <= rangeDiscount.FinalDate__c 
                            && ((rangeDiscount.MinimumPercentage__c <= orderItem.DiscountPercent__c && orderItem.DiscountPercent__c <= rangeDiscount.MaximaPercentage__c) 
                            || (rangeDiscount.MinimumPercentage__c >= orderItem.DiscountPercent__c && rangeDiscount.ApprovingAuthority__c == 'Manager'))){
                                orderItemToRangeDiscountMap.put(orderItem.Id, rangeDiscount);
                            }
                        }
                    }
                }
            }
        }
        System.debug('orderItemToRangeDiscountMap' + orderItemToRangeDiscountMap);
        
        return orderItemToRangeDiscountMap;
    }
    
    public static void initIntegrationOrderBarterActive(List<Order> context, Map<Id, Order> oldContextMap){
        set<Id> approvedOrderBarterIds = new Set<Id>();
        for(Order ord : context){
            Order oldOrd = oldContextMap.get(ord.id);
            if(ord.StatusSF__c == 'Aprovado' && ord.RecordTypeId == barterId && ord.ContractGrainCode__c != null && 
            (ord.StatusSF__c != oldOrd.StatusSF__c || ord.ContractGrainCode__c != oldOrd.ContractGrainCode__c)){
                approvedOrderBarterIds.add(ord.Id);
            }
        }
        if(!approvedOrderBarterIds.isEmpty()){
            System.enqueueJob(new CalloutOrderQueueable(new List<Id>(approvedOrderBarterIds)));
        }
    }
    public static void initIntegrationOrderActive(List<Order> newOrderList, Map<Id, Order> oldContextMap){
        set<Id> approvedOrderBarterIds = new Set<Id>();
        set<Id> approvedOrderIds = new Set<Id>();
        Set<Id> recallProcessIdSet = new Set<Id>();
        for(Order ord : newOrderList){
            Order oldOrd = oldContextMap.get(ord.id);
            if(checkRecalculateApprovals(ord, oldOrd)){
                recallProcessIdSet.add(ord.Id);
            }else if(ord.StatusSF__c == 'Aprovado' && oldOrd.StatusSF__c != ord.StatusSF__c && ord.RecordTypeId != barterId){
                /*if(ord.RecordTypeId == barterId) 
                    approvedOrderBarterIds.add(ord.Id);
                else*/ 
                    approvedOrderIds.add(ord.Id);
            }
        }
        if(!recallProcessIdSet.isEmpty()){
            if(System.isFuture())
                checkProcessNotFuture(recallProcessIdSet);
            else
                checkprocess(recallProcessIdSet);
        }
        if(!approvedOrderIds.isEmpty()){
            System.debug('entrou no metodo de integração! segue os ids: ' + approvedOrderIds);
            changeShippingDivisionsDates(new List<Id>(approvedOrderIds));
            if(System.isFuture())
                System.enqueueJob(new CalloutOrderQueueable(new List<Id>(approvedOrderIds)));
            else
                futureCalloutIntegration(new List<Id>(approvedOrderIds));
        }
        /*System.debug(approvedOrderBarterIds);
        if(!approvedOrderBarterIds.isEmpty()){
            System.enqueueJob(new CalloutOrderQueueable(new List<Id>(approvedOrderBarterIds)));
        }*/
    }
    public static Boolean checkRecalculateApprovals(Order ord, Order oldOrd){
        return checkRecalculateApprovals(ord) && !oldOrd.RecalculateApprovals__c;
    }
    public static Boolean checkRecalculateApprovals(Order ord){
        return ord.RecalculateApprovals__c && 
        (ord.CommercialApproval__c || (ord.HasOrderItemWithoutMargin__c || ord.HasOrderItemWithoutCost__c));
    }
    public static void  changeShippingDivisionsDates(List<Id> ordIdSet){
        List<ShippingDivision__c> deleteShipList= new List<ShippingDivision__c>();
        Map<Id, ShippingDivision__c> insertShipList= new Map<Id, ShippingDivision__c>();
        for(ShippingDivision__c ship : [SELECT id, OrderItem__c, Quantity__c, Orderitem__r.Order.SalesTeam__r.DeliveryDays__c, Orderitem__r.Product2.Family__r.DeliveryDays__c FROM ShippingDivision__c WHERE DeliveryDate__c < TODAY AND OrderItem__r.OrderId IN :ordIdSet]){
            deleteShipList.add(ship);

            if(!insertShipList.containskey(ship.OrderItem__c))
                insertShipList.put(ship.OrderItem__c, getShip(ship));

            insertShipList.put(ship.OrderItem__c, updtShip(insertShipList.get(ship.OrderItem__c), ship));
        }
        if(!deleteShipList.isEmpty()){
            delete deleteShipList;
        }
        if(!insertShipList.isEmpty()){
            insert insertShipList.values();
            Map<Id, ShippingDivision__c[]> updateShipMap= new Map<Id, ShippingDivision__c[]>();
            List<ShippingDivision__c> updateShipList= new List<ShippingDivision__c>();
            for(ShippingDivision__c ship : [SELECT id, SAPNumber__c,ExternalId__c, OrderItem__c FROM ShippingDivision__c WHERE OrderItem__c IN :insertShipList.keySet()]){                
                if(!updateShipMap.containskey(ship.OrderItem__c))
                    updateShipMap.put(ship.OrderItem__c, new List<ShippingDivision__c>());
                updateShipMap.get(ship.OrderItem__c).add(ship);
            }
            for(Id ordId : updateShipMap.keySet()){
                integer i=0;
                for(ShippingDivision__c ship : updateShipMap.get(ordId)){
                    i++;
                    ship.SAPNumber__c = String.valueOf(i);
                    ship.ExternalId__c =  ship.OrderItem__c +'|'+i;
                    updateShipList.add(ship);
                }
            }
            update updateShipList;
        }
    }
    public static ShippingDivision__c getShip(ShippingDivision__c ship){   
        Decimal days = DeliveryDateValidation__c.getAll().get('Dias').Days__c;

        Integer correctDay = (ship.Orderitem__r.Product2.Family__r.DeliveryDays__c != null ? Integer.valueOf(ship.Orderitem__r.Product2.Family__r.DeliveryDays__c) : (ship.Orderitem__r.Order.SalesTeam__r.DeliveryDays__c != null ? Integer.valueOf(ship.Orderitem__r.Order.SalesTeam__r.DeliveryDays__c) : Integer.valueOf(days)));

        ShippingDivision__c sche = new ShippingDivision__c();
        sche.DeliveryDate__c = Date.today().addDays(correctDay);
        sche.OrderItem__c = ship.OrderItem__c;
        sche.Quantity__c = 0;
        return sche;
    }
    public static ShippingDivision__c updtShip(ShippingDivision__c oldShip, ShippingDivision__c ship){   
        Datetime dt =  datetime.newInstance(oldShip.DeliveryDate__c, Time.newInstance(23,59,59,59));

        oldShip.Quantity__c += ship.Quantity__c;
        oldShip.Name = dt.format('dd/MM/YYYY')+' - '+String.valueOf(oldShip.Quantity__c);
        return oldShip;
    }
    public static void calloutIntegrationNotFuture(List<Id> approvedOrderIds){
        CalloutOrder.invocableProcessIntegration(approvedOrderIds);
    }

    @future(callout=true)
    public static void futureCalloutIntegration(List<Id> approvedOrderIds){
        CalloutOrder.invocableProcessIntegration(approvedOrderIds);
    }

    public static void insertDML(string sharesCreate){
        Database.Insert((List<OrderShare>)JSON.deserialize(sharesCreate, List<OrderShare>.class), false);
    }
    public static void insertShippingDML(string shippingDivision){
        Database.Insert((List<ShippingDivision__c>)JSON.deserialize(shippingDivision, List<ShippingDivision__c>.class), false);
    }
    public static void insertUpdateFinancialDueDate(List<Order> newOrderList){
        Map<Id,String> cropIdToCommodityMap = new Map<Id,String>();
        Map<String, Date> cropIdToCommodityToDueDateMap = new Map<String, Date>();
        List<Order> orderList = new List<Order>();
        for(Order ord : newOrderList){
            if(ord.StatusSF__c != 'Aprovado' && ord.BarterType__c == 'Financeiro'){ 
                cropIdToCommodityMap.put(ord.Crop__r.Id, ord.Commodity__c);
            }
        }
        List<FinancialDueDate__c> financialDueDateList = [SELECT Id, Crop__c, Commodity__c, FinancialDueDate__c FROM FinancialDueDate__c WHERE Commodity__c IN: cropIdToCommodityMap.values() AND 
                                                    Crop__c IN: cropIdToCommodityMap.keySet()];   

        for(FinancialDueDate__c financialDueDate : financialDueDateList){
            cropIdToCommodityToDueDateMap.put(financialDueDate.Crop__c + cropIdToCommodityMap.get(financialDueDate.Crop__c), financialDueDate.FinancialDueDate__c);
        }

        for(Order ord : newOrderList){
            if(!cropIdToCommodityToDueDateMap.isEmpty()){
                ord.DueDateFinancial__c = cropIdToCommodityToDueDateMap.get(ord.Crop__c + ord.Commodity__c);
                orderList.add(ord);
            }
        }
        //disableTrigger();
        upsert orderList;
        //enableTrigger();
    }

    public static void verifyToCallApprovalProcess(List<Order> newOrderList){
        Set<Id> orderIdsToCallApprovalProcess = new Set<Id>();
        for(Order ord : newOrderList){
            if(checkSendApprovalGrain(ord)){
                orderIdsToCallApprovalProcess.add(ord.Id);
            }
        }
        if(!orderIdsToCallApprovalProcess.isEmpty()){
            disableTrigger();
            callApprovalProcessBarter(orderIdsToCallApprovalProcess);
            enableTrigger();
        }
    }

    public static void verifyToCallApprovalProcess(List<Order> newOrderList, Map<Id, Order> oldOrdMap){
        Set<Id> orderIdsToCallApprovalProcess = new Set<Id>();
        for(Order ord : newOrderList){
            Order oldOrd = oldOrdMap.get(ord.id);
            if(checkSendApprovalGrain(ord, oldOrd)){
                orderIdsToCallApprovalProcess.add(ord.Id);
            }
        }
        if(!orderIdsToCallApprovalProcess.isEmpty()){
            disableTrigger();
            callApprovalProcessBarter(orderIdsToCallApprovalProcess);
            enableTrigger();
        }
    }

    public static void sendToGrainTable(List<Order> newOrderList, Map<Id, Order> oldOrdMap) {
        for(Order ord : newOrderList){
            Order oldOrd = oldOrdMap.get(ord.id);
            if(checkSendApprovalGrain(ord, oldOrd)){
                ord.SubmitGrainTableApproval__c = true;
            }
        }
    }
    public static Boolean checkSendApprovalGrain( Order ord, Order oldOrd){
        return (ord.StatusSF__c == 'Em aprovação grãos' && oldOrd.StatusSF__c != ord.StatusSf__C && ord.RecordTypeId == barterId);
    }
    public static Boolean checkSendApprovalGrain( Order ord){
        return (ord.StatusSF__c == 'Em aprovação grãos'  && ord.RecordTypeId == barterId);
    }
  
    public static void callApprovalProcessBarter(Set<Id> ordIdSet){
        System.debug('DENTRO DO CODIGO - ORDIDSET: ' + ordIdSet);
        List<Order> ordList = [SELECT Id, DiscountApprovalNote__c, StatusSF__c FROM Order WHERE Id IN: ordIdSet AND StatusSF__c = 'Em aprovação grãos'];
        
        System.debug('ORD LIST: ' + ordList);
        List<approval.processSubmitRequest> approvalProcessSubmitRequestList = new List<approval.processSubmitRequest>();
        for(Order ord : ordList){
            System.debug('ORD DEPOIS: ' + ord);
            Approval.processSubmitRequest req = new Approval.processSubmitRequest();
            req.setObjectId(ord.Id);
            req.setProcessDefinitionNameOrId('AprovacaoBarterV2');
            req.setSubmitterId(UserInfo.getUserId());
            approvalProcessSubmitRequestList.add(req);
        }
        List<Approval.processResult> result = Approval.process(approvalProcessSubmitRequestList);
    }

    public static void initIntegrationGrainPurchaseContractOrderActive(List<Order> newOrderList){
        List<Id> approvedOrderIds = new List<Id>();
        for(Order ord : newOrderList){
            if(ord.GrainTableApproval__c == true){
                approvedOrderIds.add(ord.Id);
            }
        }
        if(!approvedOrderIds.isEmpty()){
            futureGrainPurchaseContractCalloutIntegration(approvedOrderIds);
        }
        //callApprovalProcessCommercial(approvedOrderIds);
    }

    @future(callout = true)
    public static void futureGrainPurchaseContractCalloutIntegration(List<Id> approvedOrderIds){
        CalloutGrainPurchaseContract.invocableProcessIntegration(approvedOrderIds);
    }


    public static void setApprovalJustification(Map<Id, Order>  newOrders, Map<String, List<OrderItem>> orderIdToOrderItemsMap){
        for(Order ord : newOrders.values()){
            Map<String, String> descriptionMap = new Map<String, String>();
            ord.MarginApprovalNote__c = '';
            if(ord.HasOrderItemWithoutMargin__c){
                for(OrderItem ordItem : orderIdToOrderItemsMap.get(ord.Id)){
                    if(ordItem.ProjectedMargin__c != null) continue;
                    descriptionMap.put(ordItem.ProductFamilyName__c, getMessageWithoutMargin(ordItem, descriptionMap));
                    break;
                }
            }
            if(ord.HasOrderItemWithoutCost__c){   
                for(OrderItem ordItem : orderIdToOrderItemsMap.get(ord.Id)){
                    if(!ordItem.InvalidCost__c) continue;             
                    descriptionMap.put(ordItem.ProductFamilyName__c, getMessageWithoutCost(ordItem, descriptionMap));
                    break;
                }
            }
            if(ord.HasOrderItemWithLowerMargin__c){
                for(OrderItem ordItem : orderIdToOrderItemsMap.get(ord.Id)){
                    if(!ordItem.LowerMargin__c) continue;   
                    descriptionMap.put(ordItem.ProductFamilyName__c, getMessageWithLowerMargin(ordItem, descriptionMap));
                    break;
                }
            }
            for(String fam : descriptionMap.keySet()){
                ord.MarginApprovalNote__c += fam+'\n';
                ord.MarginApprovalNote__c += descriptionMap.get(fam)+'\n';
                ord.MarginApprovalNote__c += '\n';                
            }
        }
    }
    public static String getMessageWithoutMargin(OrderItem ordItem,  Map<String, String> descriptionMap){
        String initial = descriptionMap.containsKey(ordItem.ProductFamilyName__c) ? descriptionMap.get(ordItem.ProductFamilyName__c) : '';
        initial += System.Label.margemNull+'\n';
        return initial;
    }
    public static String getMessageWithoutCost(OrderItem ordItem,  Map<String, String> descriptionMap){
        String initial = descriptionMap.containsKey(ordItem.ProductFamilyName__c) ? descriptionMap.get(ordItem.ProductFamilyName__c) : '';
        initial += System.Label.costNull+'\n';
        return initial;
    }
    public static String getMessageWithLowerMargin(OrderItem ordItem,  Map<String, String> descriptionMap){
        String initial = descriptionMap.containsKey(ordItem.ProductFamilyName__c) ? descriptionMap.get(ordItem.ProductFamilyName__c) : '';
        initial += roundMargin('Margem Projetada: ', ordItem.ProjectedMargin__c);
        initial += roundMargin('Margem Direta: ', ordItem.DirectMargin__c);
        initial += roundMargin('Margem Recomposta: ', ordItem.FamilyMargin__c);
        initial += '\n';
        return initial;
    }
    public static String roundMargin(String stringVal, Decimal val){
        return val == null ? '' : stringVal + String.valueOf(val?.setScale(4, RoundingMode.HALF_UP))+'% \n';
    }
    /*
        // System.debug('setApprovalJustification...');
        // Map<Id, Product2> products =new Map<Id, Product2>();
        Map<Id, SalesOrg__c> salesOrgs =new Map<Id, SalesOrg__c>();
        for(Order curOrder: newOrders.values()){            
            List<OrderItem> curItems =orderIdToOrderItemsMap.get(curOrder.Id);
            // for(OrderItem curItem: curItems){
            //     products.put(curItem.Product2Id, null);
            // }
            if (curOrder.SalesTeam__r.SalesOrg__c!=null){
                salesOrgs.put(curOrder.SalesTeam__r.SalesOrg__c, null);
            }
        }
        // products =new Map<Id, Product2>([
        //     SELECT Id, Family__r.Name, Family__c
        //     FROM Product2
        //     WHERE Id in :products.keySet()
        // ]);        

        // salesOrgs =new Map<Id, SalesOrg__c>([
        //     SELECT Id, Director__c
        //     FROM SalesOrg__c
        //     WHERE Id in: salesOrgs.keySet()
        // ]);

        
        Map<Id, Map<Id, List<OrderItem>>> orderFamilyItem =new Map<Id, Map<Id, List<OrderItem>>>();
        for(Order curOrder: newOrders.values()){
            Map<Id, List<OrderItem>> familyItems =new Map<Id, List<OrderItem>>();
            orderFamilyItem.put(curOrder.Id, familyItems);
            List<OrderItem> curItems =orderIdToOrderItemsMap.get(curOrder.Id);
            for(OrderItem curItem: curItems){
                // Product2 prod =products.get(curItem.Product2Id);
                List<OrderItem> famOrderItems =familyItems.get(curItem.ProductFamily__c);
                if (famOrderItems==null){
                    famOrderItems =new List<OrderItem>();
                    familyItems.put(curItem.ProductFamily__c, famOrderItems);
                }
                famOrderItems.add(curItem);
            }
        }        



        for(Order curOrder: newOrders.values()){
            curOrder.MarginApprovalNote__c =null;
            Map<Id, List<OrderItem>> familyItems = orderFamilyItem.get(curOrder.Id);
            for(Id familyId: familyItems.keySet()){
                // System.debug('Perrnechemos observação do pedido');
                List<OrderItem> curItems =familyItems.get(familyId);
                Boolean hasItemNulCost =false;
                Boolean hasItemNulProjMarg =false;

                String s =null;
                String familyName =null;
                // System.debug('setApprovalJustification: temos ' +curItems.size() +' itens');
                for(OrderItem curItem: curItems){
                    // Product2 curProd =products.get(curItem.Product2Id);
                    // if(famSet.contains(curProd.Family__r.Name)) continue;
    
    
                    // {NOME DA FAMILIA}
                    // Margem Projetada: {MARGEM PROJETADA DA FAMILIA}
                    // Margem Direta: {DirectMarginFamily}
                    // Margem Recomposta: {MarginFamily}

                    // familyName =curProd.Family__r.Name;
                    familyName =curItem.Product2.Family__r.Name;
                    if (curItem.Cost__c==null){
                        hasItemNulCost =true;
                        // System.debug('setApprovalJustification: Cost__c == null ');
                        if (curItem.ProjectedMargin__c ==null){
                            hasItemNulProjMarg =true;
                            // System.debug('setApprovalJustification: ProjectedMargin__c == null ');
                        }
                        continue;
                    }
                    else if (curItem.ProjectedMargin__c ==null){
                        hasItemNulProjMarg =true;
                        // System.debug('setApprovalJustification: ProjectedMargin__c == null ');
                        continue;
                    }
                    if (s!=null){
                        continue;
                    }                    
                    s =curItem.Product2.Family__r.Name +'\n';
                    s += 'Margem Projetada: ' +curItem.ProjectedMargin__c.setScale(4, RoundingMode.HALF_UP) +'%';
                    if (curItem.DirectMargin__c!=null){
                        s += '\nMargem Direta: ' +curItem.DirectMargin__c.setScale(4, RoundingMode.HALF_UP) +'%';
                    }
                    else{
                        s += '\nMargem Direta: ';
                    }                
                    if(curItem.FamilyMargin__c!=null){
                        s += '\nMargem Recomposta: ' +curItem.FamilyMargin__c.setScale(4, RoundingMode.HALF_UP) +'%';
                    }
                    else{
                        s += '\nMargem Recomposta: ';
                    }
                }
                if (familyName==null){
                    continue;
                }

                // System.debug('setApprovalJustification: hasItemNulCost = ' +hasItemNulCost );
                // System.debug('setApprovalJustification: hasItemNulProjMarg = ' +hasItemNulProjMarg);
                if (hasItemNulCost || hasItemNulProjMarg){
                    s =familyName;                    
                    String costMessage ='\n' +System.Label.costNull;
                    String margemMessage ='\n' +System.Label.margemNull;
                    if (hasItemNulCost && hasItemNulProjMarg){                    
                if (hasItemNulCost && hasItemNulProjMarg){                    
                    if (hasItemNulCost && hasItemNulProjMarg){                    
                        s +=margemMessage;
                        s +=costMessage;
                    }
                    else{
                        if (hasItemNulCost){
                            s +=costMessage;                        
                        s +=costMessage;                        
                            s +=costMessage;                        
                        }
                        if (hasItemNulProjMarg){
                            s +=margemMessage;                        
                        s +=margemMessage;                        
                            s +=margemMessage;                        
                        }                    
                    }                    
                        }                    
                    }
                }
                else{
                    if (s==null){
                        continue;
                    }
                }
                if (curOrder.MarginApprovalNote__c==null){
                    curOrder.MarginApprovalNote__c =s;
                }
                else{
                    curOrder.MarginApprovalNote__c +='\n'+s;
                }                 
            }
        }        
    }  
    */  

    /*
    public static void callApprovalProcessCommercial(List<Id> ordIdList){
        List<Order> ordList = [SELECT id, DiscountApprovalNote__c, Recordtype.DeveloperName, DiscountApprover__c,  CommercialApproval__c, FinancialAdministrativeManager__c FROM Order WHERE id IN: ordIdList AND StatusSF__c = 'Em Aprovação'];
        List<approval.processSubmitRequest> approvalProcessSubmitRequestList = new List<approval.processSubmitRequest>();
        System.debug('ORD LIST DO PROCESSO DE APROVAÇÃO: ' + ordList);

        for(Order ord : ordList){
            Approval.processSubmitRequest req1 = new Approval.processSubmitRequest();
            req1.setObjectId(ord.Id);
            req1.setProcessDefinitionNameOrId('OrderApproval2');
            req1.setSubmitterId(UserInfo.getUserId());    
            approvalProcessSubmitRequestList.add(req1); 
        }
        List<Approval.processResult> result = Approval.process(approvalProcessSubmitRequestList);        
    }
    */

}