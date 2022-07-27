@RestResource(urlMapping='/ForcaAgroApp/1_0/sendTransactionData/*')
global without sharing class CreateOrderController {

    @HttpPost
    global static OrderResponse createOrderApp(string orderReq){
        OrderResponse ordResp =  createOrder(orderReq);
        System.debug(JSON.serialize(ordResp));
        return ordResp;
    }

    @AuraEnabled
    global static OrderResponse createOrderScreen(string orderReq){
        return createOrder(orderReq);
    }

    global static OrderResponse createOrder(string orderReq){
        OrderResponse ordResponse = null;
        Savepoint sp = null;
        OrderRequest ordRequest = (OrderRequest)JSON.deserialize(orderReq, OrderRequest.class);
        try{
            sp = Database.setSavepoint();

            Set<Id> prodIdSet = new Set<Id>();
            Set<Id> listPriceId = new Set<Id>();

            for(OrderItemRequest ordItem : ordRequest.itens){
                if(ordItem.itens == null || ordItem.itens.isEmpty()){
                    throw new CustomException('Não é possivel criar um produto do pedido sem divisão de remessa (ERRO 003)');
                }
                prodIdSet.add(ordItem.productId);
                listPriceId.add(ordItem.listPriceId);
            }
            
            Map<Id, PricebookEntry> priceMap= new Map<Id, PricebookEntry>();
            Id pbId = Test.isRunningTest() ? Test.getStandardPricebookId() : [SELECT id FROM Pricebook2 WHERE isStandard = true LIMIT 1].id;
            for(PricebookEntry pbEntry : [SELECT id, Product2Id, Pricebook2Id, Product2.QuantityUnitOfMeasure FROM PricebookEntry WHERE Pricebook2.isStandard = true AND Product2id IN :prodIdSet AND CurrencyIsoCode =: ordRequest.currencys]){
                priceMap.put(pbEntry.Product2Id, pbEntry);
                pbId = pbEntry.Pricebook2Id;
            }

            Map<Id, ListPrice__c> listPriceMap= new Map<Id, ListPrice__c>([SELECT id, Cost__c, PriceMultiplier__c, OriginalUnitPrice__c, EffectiveDate__c, Product2Id__r.ProductCode, isActive__c, InitialDate__c, EndDate__c FROM ListPrice__c WHERE Id IN : listPriceId]);


            Set<Id> orderContractBoundIdSet = new Set<Id>();
            Set<Id> orderItemIdSet = new Set<Id>();

            Map<String, OrderItem> ordItemContractMap = getContractOrderItem(ordRequest.contractOrderId);

            if(ordRequest.contractOrderId != null && ordRequest.Status == 'Em Aprovação'){
               checkInvalidQuantityContract(ordRequest); 
            }
            
            ordResponse = upsertOrder(pbId, ordRequest, listPriceMap);

            if(ordResponse.hasError) return ordResponse;

            ordResponse.itens.addAll(upsertOrderItem(ordResponse, ordRequest, priceMap, listPriceMap, ordItemContractMap));
            
            upsertScheduleItem(ordResponse, ordRequest); 

            upsertCampaignItem(ordResponse, ordRequest); 

            if(ordResponse.Id != null){

                handleExcludedSapItens(ordResponse);

            }

            if (ordRequest.originalOrderId != null) {
                updateOriginalOrderOrderItems(ordRequest);
            }
            
            if(ordResponse.id != null && ordResponse.Status == 'Em Aprovação')
                callApprovalProcess(ordResponse.id);

            if(ordRequest.contractOrderId != null && ordResponse.Status == 'Em Aprovação')
                updateProductContract(ordResponse);
        }catch(Exception ex){
            Database.rollback(sp);
            ordResponse = new OrderResponse(ex, ordRequest);
        }

        return ordResponse;
    }
    global static Map<String, OrderItem> getContractOrderItem(Id ctId){
        Map<String, OrderItem> ordItemMap = new Map<String, OrderItem>();
        if(ctId == null) return ordItemMap;
        for(OrderItem ordItem : [SELECT id, Product2Id, OrderId, CampaignPercent__c, CampaigPercent__c, CampaignIndustryPercent__c FROM OrderItem WHERE OrderId = :ctId]){
            ordItemMap.put(ordItem.Product2Id+'_'+ordItem.OrderId, ordItem);
        }
        return ordItemMap;
    }
    global static void checkInvalidQuantityContract(OrderRequest ordRequest){
        Map<String,Decimal> shipMap = new Map <String,Decimal>();
        Map<String,Decimal> shipContractMap = new Map <String,Decimal>();
        for(ShippingDivision__c sd : [SELECT Id, OrderItem__c, Quantity__c, RefuseReason__c, OrderItem__r.OrderId, OrderItem__r.Product2Id, OrderItem__r.Order.ContractOrder__c
                                        FROM ShippingDivision__c 
                                        WHERE (OrderItem__r.Order.ContractOrder__c =: ordRequest.contractOrderId 
                                        OR OrderItem__r.OrderId = :ordRequest.contractOrderId)
                                        AND OrderItem__r.Order.StatusSF__c NOT IN ('Em digitação', 'Retorna RTV', 'Cancelado')
                                        AND OrderItem__r.Order.StatusSAP__C NOT IN ('X')]){
            String key = (sd.OrderItem__r.OrderId == ordRequest.contractOrderId ? sd.OrderItem__r.OrderId : sd.OrderItem__r.Order.ContractOrder__c)+'_'+sd.OrderItem__r.Product2Id;
            populateMapShip(key, (sd.OrderItem__r.OrderId == ordRequest.contractOrderId ? shipContractMap : shipMap), sd);
        }
        Map<Id, Decimal> balance = new Map<Id, Decimal>();
        for(OrderItemRequest ordItem : ordRequest.itens){
            String key = ordRequest.contractOrderId+'_'+ordItem.productId;
            Decimal qtdProduct = (shipMap.containsKey(key) ? shipMap.get(key) : 0) + ordItem.quantity;
            Decimal qtdContractProduct = shipContractMap.containsKey(key) ? shipContractMap.get(key) : 0;

            if(qtdProduct > qtdContractProduct)
                throw new CustomException(System.Label.ContractBalanceError);

            ordItem.balance = qtdContractProduct - qtdProduct;
        }
    }
    global static void populateMapShip(String key, Map<String, Decimal> shipMap, ShippingDivision__c sd){
        if(!shipMap.containsKey(key))
            shipMap.put(key, 0);
        shipMap.put(key, shipMap.get(key) + getQuantityShip(sd));
    }

    global static void updateProductContract(OrderResponse ordResponse){
        Set<Id> prod2IdSet = new Set<Id>();
        for(OrderItemResponse ordItem : ordResponse.itens){
            prod2IdSet.add(ordItem.productId);
        }
        updateProductContractLogic(ordResponse.Id, ordResponse.contractOrderId, prod2IdSet);
    }
    global static void updateProductContractLogic(Id ordId, Id ctId, Set<Id> prodIdSet){
        updateProductContractLogic(new Set<Id>{ordId}, new Set<Id>{ctId}, prodIdSet);
    }
    global static void updateProductContractLogic(Set<Id> ordId, Set<Id> ctId, Set<Id> prod2IdSet){
        System.debug(ordId);
        System.debug(ctId);
        System.debug(prod2IdSet);
        Set<Id> orderItemIdSet = new Set<Id>();
        Map<String, List<OrderItem>> ordItemMap= new Map<String, List<OrderItem>>();
        List<OrderItem> contractOrderItemList= new List<OrderItem>();
        Map<String, Decimal> shipMap = new Map<String, Decimal>();
        for(OrderItem ordItem : [SELECT id, OrderId, Product2Id, Quantity, ContractProductCredit__c, ContractOrderItem__c, Order.ContractOrder__c
                                FROM OrderItem 
                                WHERE (OrderId IN :ordId OR OrderId IN : ctId OR Order.ContractOrder__c IN : ctId) 
                                AND Product2Id IN :prod2IdSet
                                AND Order.StatusSF__c NOT IN ('Em digitação', 'Retorna RTV', 'Cancelado')
                                AND Order.StatusSAP__C NOT IN ('X')]){
            if(ctId.contains(ordItem.OrderId)){
                contractOrderItemList.add(ordItem);
            }else{
                if(!ordItemMap.containsKey(ordItem.Order.ContractOrder__c+'_'+orditem.Product2Id))
                    ordItemMap.put(ordItem.Order.ContractOrder__c+'_'+ordItem.Product2Id, new List<OrderItem>());
                ordItemMap.get(ordItem.Order.ContractOrder__c+'_'+orditem.Product2Id).add(ordItem);
            }
            orderItemIdSet.add(ordItem.id);

            shipMap.put(getKeyShip(ordItem), 0);
        }   

        for(ShippingDivision__c sd : [SELECT Id, OrderItem__c, Quantity__c, RefuseReason__c, OrderItem__r.OrderId, OrderItem__r.Product2Id 
                                        FROM ShippingDivision__c 
                                        WHERE OrderItem__c IN: orderItemIdSet
                                        AND OrderItem__r.Order.StatusSF__c NOT IN ('Em digitação', 'Retorna RTV', 'Cancelado')
                                        AND OrderItem__r.Order.StatusSAP__C NOT IN ('X')]){
            shipMap.put(getKeyShip(sd), shipMap.get(getKeyShip(sd)) + getQuantityShip(sd));
        }

        System.debug(contractOrderItemList);
        System.debug(ordItemMap);
        System.debug(shipMap);
        System.debug(shipMap);
        List<OrderItem> ordItemUpdateList = new List<OrderItem>();
        for(OrderItem ordItem : contractOrderItemList){
            ordItem.ContractProductCredit__c = shipMap.get(getKeyShip(ordItem));

            if(!ordItemMap.containsKey(ordItem.OrderId+'_'+ordItem.Product2Id)){
                ordItemUpdateList.add(ordItem); 
                continue;
            }

            for(OrderItem ordItemSales : ordItemMap.get(ordItem.OrderId+'_'+ordItem.Product2Id)){
                ordItemSales.ContractOrderItem__c = ordItem.Id;
                ordItemUpdateList.add(ordItemSales);

                ordItem.ContractProductCredit__c -= shipMap.get(getKeyShip(ordItemSales));
            }
            ordItemUpdateList.add(ordItem);
        }
        System.debug(ordItemUpdateList);
        if(!ordItemUpdateList.isEmpty()){
            OrderHelper.disableTrigger();
            update ordItemUpdateList;
            OrderHelper.enableTrigger();
        }
    }
    global static String getKeyShip(OrderItem ordItem){
        return ordItem.OrderId+'_'+ordItem.Product2Id;
    }
    global static String getKeyShip(ShippingDivision__c sd){
        return sd.OrderItem__r.OrderId +'_'+ sd.OrderItem__r.Product2Id;
    }
    global static Decimal getQuantityShip(ShippingDivision__c sd){
        return sd.Quantity__c * (sd.RefuseReason__c == null ? 1 : -1);
    }
    global static void checkOrderOldFields(Order ord){
        for(Order oldOrd : [SELECT id, type, CreatedDate FROM Order WHERE Id = :ord.id LIMIT 1]){
            ord.type = oldOrd.type;            
            ord.EffectiveDate = Date.valueOf(oldOrd.CreatedDate);
            if(ord.EffectiveDate < ord.EndDate){
                ord.EndDate = ord.EffectiveDate.addDays(1);
            }
        }
    }
    global static OrderResponse upsertOrder(Id pbId, OrderRequest ordRequest, Map<Id, ListPrice__c> listPriceMap){
        Map<Id, SalesTeam__c> salesTeamMap = new Map<Id, SalesTeam__c>([SELECT id, SalesOrg__c, SalesOrg__r.ExternalId__c, ParentId__c, DistributionCenter__c FROM SalesTeam__c WHERE Id  = :ordRequest.salesTeamId]);
        Order ord = ordRequest.getOrder(pbId, salesTeamMap, listPriceMap);
        Boolean updateContext = (ord.Id != null);

        if(updateContext) checkOrderOldFields(ord);

        List<Order> ordList = new List<Order>{ord};
		List<Database.SaveResult> listResults = updateContext ? Database.update(ordList, false) : Database.insert(ordList, false); 

		Id ordId = null;
        List<OrderShare> ordShareList = new List<OrderShare>();
        for(Integer i = 0; i < listResults.size(); i++){
		    Order ordResult = ordList[i];
		    Database.SaveResult upsResult = listResults[i];
		    if(upsResult.isSuccess()){
                ordId = upsResult.getId();
                if(ordResult.OwnerId != UserInfo.getUserId())
                    ordShareList.add(new OrderShare(OrderId = ordId, UserOrGroupId = UserInfo.getUserId(), OrderAccessLevel = 'Edit'));
		    } else {
               return new OrderResponse(upsResult.getErrors()[0].getMessage(), ordRequest);
		    }		        
		}
        insert ordShareList;
        
        if (ordRequest.recordTypeDeveloperName == 'BarterSale' && String.isNotBlank(ordRequest.contentVersionId)) {
            CreateDocumentLink.createContentLink(ordRequest.contentVersionId, ordId);
        }

        for(Order ords : [SELECT id, recordTypeId, salesOrg__c, totalFreightValue__c, totalAmountWithFreight__c, TotalAmount, salesOffice__c, distributionCenter__c, orderCreator__c, effectiveDate, pricebook2Id, status, statusSF__c, distributionChannel__c, ApprovalJustification__c, ApproverDiscountAmount__c, BonificationApprovalNote__c, CommercialApproval__c, DiscountApprovalNote__c, DiscountApprover__c, DiscountApprover2__c, DiscountApprover3__c, DiscountApprover4__c, FinancialAdministrativeManager__c, RegistrationApprovalNote__c, MarginApprover__c FROM Order WHERE id = :ordId]){
            return new OrderResponse(ordRequest, ords);
        }
        return new OrderResponse('Erro desconhecido', ordRequest);
    }

    global static List<OrderItemResponse> upsertOrderItem(OrderResponse ordResponse, OrderRequest ordRequest, Map<Id, PricebookEntry> priceMap, Map<Id, ListPrice__c> listPriceMap, Map<String, OrderItem> ordItemContractMap){
        List<OrderItemResponse> responseOrderItem = new List<OrderItemResponse>();
        Map<String, OrderItemRequest> orderItemRequestMap = new Map<String, OrderItemRequest>();
        
        List<OrderItem> ordItemUpdateList = new List<OrderItem>();
        List<OrderItem> ordItemInsertList = new List<OrderItem>();
        system.debug( ordRequest.itens);
        Set<Id> allProdSet = new Set<Id>();
        Integer initialVal = 10;
        Set<Id> ordIdSet = new Set<Id>();
        for(OrderItemRequest ordItem : ordRequest.itens){
            ordIdSet.add(ordItem.Id);
        }
        
        Map<Id, OrderItem> ordItemMap = new Map<Id, OrderItem>([SELECT Id, ListPrice__c, OriginalListPrice__c FROM OrderItem WHERE id IN :ordIdSet]);
        
        for(OrderItemRequest ordItem : ordRequest.itens){

            Boolean updateContext = (ordItem.Id != null);

            if(updateContext){                
                validateUpdateListPrice(ordItem, listPriceMap, ordItemMap);
                ordItemUpdateList.add(ordItem.getOrderItem(initialVal, priceMap, listPriceMap, ordResponse, updateContext, ordItemContractMap));
            }else
                ordItemInsertList.add(ordItem.getOrderItem(initialVal, priceMap, listPriceMap, ordResponse, updateContext, ordItemContractMap));

            orderItemRequestMap.put(ordItem.productId, ordItem);

            initialVal += 10;

            if(ordRequest.Id != null && ordItem.Id != null)
                allProdSet.add(ordItem.Id);
        }

        if(ordRequest.Id != null){
            Map<Id, OrderItem> ordItemDeleteMap = new Map<Id, OrderItem>();
            for(OrderItem ordItem : [SELECT id FROM OrderItem WHERE Id NOT IN :allProdSet AND OrderId = :ordRequest.Id ]){
                ordItemDeleteMap.put(ordItem.Id, ordItem);
            }

            List<ShippingDivision__c> schDeleteList = new List<ShippingDivision__c>();
            for(ShippingDivision__c schedules : [SELECT id FROM ShippingDivision__c WHERE OrderItem__c IN :ordItemDeleteMap.keySet() ]){
                schDeleteList.add(schedules);
            }

            if(!schDeleteList.isEmpty()){
                delete schDeleteList;
            }
            if(!ordItemDeleteMap.isEmpty()){
                delete ordItemDeleteMap.values();
            }
        }

        System.debug(ordItemUpdateList);
        System.debug(ordItemInsertList);

        List<Database.SaveResult> listResultsUpdate = new List<Database.SaveResult>();
        List<Database.SaveResult> listResultsInsert = new List<Database.SaveResult>();
        Set<Id> ordItemIdSet = new Set<Id>();
        if(!ordItemUpdateList.isEmpty()){
		    listResultsUpdate.addAll(Database.update(ordItemUpdateList, false));
            upsertOrderItemDML(listResultsUpdate, ordItemUpdateList, ordItemIdSet, responseOrderItem);
        }
        if(!ordItemInsertList.isEmpty()){
		    listResultsInsert.addAll(Database.insert(ordItemInsertList, false)); 
            upsertOrderItemDML(listResultsInsert, ordItemInsertList, ordItemIdSet, responseOrderItem);
        }

        for(OrderItemResponse ordItemResp : responseOrderItem){
            if(ordItemResp.hasError){
                throw new CustomException('Um produto teve erro ao ser inserido :'+ordItemResp.errorMsg+' ERRO (004)');
            }
        }
        
        for(OrderItem ordItem : [SELECT id, OrderId, Center__c, OrderItemNumber, Product2Id, ExternalIdApp__c FROM OrderItem WHERE id IN :ordItemIdSet]){
            responseOrderItem.add(new OrderItemResponse(orderItemRequestMap.get(ordItem.Product2Id), ordItem));
        }
        System.debug(responseOrderItem);
        return responseOrderItem;
    }

    global static void validateUpdateListPrice(OrderItemRequest ordItem, Map<Id, ListPrice__c> listPriceMap, Map<Id, OrderItem> ordItemRqeMap){
        ListPrice__c lists = listPriceMap.containsKey(ordItem.listPriceId) ? listPriceMap.get(ordItem.listPriceId) : null;
        OrderItem ordItemRqe = ordItemRqeMap.containsKey(ordItem.Id) ? ordItemRqeMap.get(ordItem.Id) : null;

        if(lists == null)
            throw new CustomException('Lista de preço não pode ser encontrada, entrar em contato com o Administrador do Sistema! ERRO (007)');

        if(!lists.isActive__c || !(lists.InitialDate__c <= Date.today() && lists.EndDate__c >= Date.today()))
            throw new CustomException('O Produto '+lists.Product2Id__r.ProductCode+' não pode ser inserido no pedido pois está com uma lista de preço inativa ou invalida ERRO (008)');
        
        //if(ordItemRqe != null && lists.Id == ordItemRqe.ListPrice__c && lists.OriginalUnitPrice__c != ordItemRqe.OriginalListPrice__c)
        //    throw new CustomException('O Produto '+lists.Product2Id__r.ProductCode+' não pode ser inserido no pedido seu preço de lista foi atualizado ERRO (00)');
    }

    global static void updateOriginalOrderOrderItems(OrderRequest ordRequest) {
        List<OrderItem> orderItemListToUncheck = new List<OrderItem>();
        for(OrderItem orderItem : [SELECT Id FROM OrderItem WHERE OrderId = :ordRequest.originalOrderId]){
            orderItem.HasRefuseReason__c = false;
            orderItemListToUncheck.add(orderItem);
        }
        if(!orderItemListToUncheck.isEmpty()){
            update orderItemListToUncheck;
        }
    }

    global static void upsertScheduleItem(OrderResponse ordResponse, OrderRequest ordRequest){
        Map<String, List<ScheduleItemResponse>> responseOrderItemMap = new Map<String, List<ScheduleItemResponse>>();
        List<ScheduleItemResponse> responseScheduleList = new List<ScheduleItemResponse>();
        Map<String, ScheduleItemRequest> shipRequestMap = new Map<String, ScheduleItemRequest>();
        
        List<ShippingDivision__c> shipUpdateList = new List<ShippingDivision__c>();
        List<ShippingDivision__c> shipInsertList = new List<ShippingDivision__c>();

        Map<String, OrderItemResponse> ordItemRespMap = new Map<String, OrderItemResponse>();
        for(OrderItemResponse ordItem : ordResponse.itens){
            ordItemRespMap.put(ordItem.productId, ordItem);
        }
        System.debug(ordItemRespMap);


        Set<Id> scheduleIdSet = new Set<Id>();
        for(OrderItemRequest ordItem : ordRequest.itens){
            OrderItemResponse ordItemresp = ordItemRespMap.get(ordItem.productId);
            Integer val = 1;
            for(ScheduleItemRequest schedule : ordItem.itens){
                Boolean updateContext = (schedule.Id != null);
                if(updateContext)
                    shipUpdateList.add(schedule.getScheduleItem(val, ordItemresp));
                else
                    shipInsertList.add(schedule.getScheduleItem(val, ordItemresp));
                
                shipRequestMap.put(ordItem.productId+''+schedule.deliveryDate, schedule);

                val += 1;

                if(updateContext)
                    scheduleIdSet.add(schedule.Id);
            }
        }

        if(ordRequest.Id != null){
            List<ShippingDivision__c> schDeleteList = new List<ShippingDivision__c>();
            for(ShippingDivision__c ordItem : [SELECT id FROM ShippingDivision__c WHERE Id NOT IN :scheduleIdSet AND OrderItem__r.OrderId = :ordRequest.Id ]){
                schDeleteList.add(ordItem);
            }
            if(!schDeleteList.isEmpty()){
                delete schDeleteList;
            }
        }

        List<Database.SaveResult> listResultsUpdate = new List<Database.SaveResult>();
        List<Database.SaveResult> listResultsInsert = new List<Database.SaveResult>();
        Set<Id> shipIdSet = new Set<Id>();
        if(!shipUpdateList.isEmpty()){
		    listResultsUpdate.addAll(Database.update(shipUpdateList, false));
            upsertScheduleItemDML(listResultsUpdate, shipUpdateList, shipIdSet, responseScheduleList);
        }
        if(!shipInsertList.isEmpty()){
		    listResultsInsert.addAll(Database.insert(shipInsertList, false)); 
            upsertScheduleItemDML(listResultsInsert, shipInsertList, shipIdSet, responseScheduleList);
        }

        for(ScheduleItemResponse ordItemResp : responseScheduleList){
            if(ordItemResp.hasError){
                throw new CustomException('Uma divisão de remessa teve erro ao ser inserida :'+ordItemResp.errorMsg+' ERRO (005)');
            }
        }
        
        for(ShippingDivision__c ordItem : [SELECT id, deliveryDate__c, OrderItem__c, OrderItem__r.Product2Id FROM ShippingDivision__c WHERE id IN :shipIdSet]){
            String key  = ordItem.OrderItem__r.Product2Id;
            ScheduleItemResponse sche  = new ScheduleItemResponse(shipRequestMap.get(key+''+ordItem.deliveryDate__c), ordItem);
            if(!responseOrderItemMap.containsKey(key))
                responseOrderItemMap.put(key, new List<ScheduleItemResponse>());
            responseOrderItemMap.get(key).add(sche);
        }

        for(OrderItemResponse ordReq : ordResponse.itens){
            ordReq.itens.addAll(responseOrderItemMap.get(ordReq.productId));
        }
    }
    global static void upsertCampaignItem(OrderResponse ordResponse, OrderRequest ordRequest){
        Map<String, List<CampaignResponse>> responseOrderItemMap = new Map<String, List<CampaignResponse>>();
        Map<String, CampaignRequest> shipRequestMap = new Map<String, CampaignRequest>();
        List<CampaignResponse> responseScheduleList = new List<CampaignResponse>();

        List<CampaignOrderItem__c> campaignInsertList = new List<CampaignOrderItem__c>();

        Map<String, OrderItemResponse> ordItemRespMap = new Map<String, OrderItemResponse>();
        for(OrderItemResponse ordItem : ordResponse.itens){
            ordItemRespMap.put(ordItem.productId, ordItem);
            ordItemRespMap.put(ordItem.id, ordItem);
        }
        System.debug(ordItemRespMap);


        for(OrderItemRequest ordItem : ordRequest.itens){
            OrderItemResponse ordItemresp = ordItemRespMap.get(ordItem.productId);
            if(ordItem.itensCampaign == null) continue;
            for(CampaignRequest schedule : ordItem.itensCampaign){
                campaignInsertList.add(schedule.getCampaignItem(ordItemresp));
                
                shipRequestMap.put(ordItem.productId+schedule.campaignId, schedule);

            }
        }

        if(ordRequest.Id != null){
            List<CampaignOrderItem__c> campaignDeleteList = new List<CampaignOrderItem__c>();
            for(CampaignOrderItem__c cmOrderItem : [SELECT id FROM CampaignOrderItem__c WHERE OrderItem__c IN :ordItemRespMap.keySet()]){
                campaignDeleteList.add(cmOrderItem);
            }
            if(!campaignDeleteList.isEmpty()){
                delete campaignDeleteList;
            }
        }

        List<Database.SaveResult> listResultsInsert = new List<Database.SaveResult>();
        Set<Id> shipIdSet = new Set<Id>();
        if(!campaignInsertList.isEmpty()){
		    listResultsInsert.addAll(Database.insert(campaignInsertList, false)); 
            upsertCampaignItemDML(listResultsInsert, campaignInsertList, shipIdSet, responseScheduleList);
        }

        for(CampaignResponse ordItemResp : responseScheduleList){
            if(ordItemResp.hasError){
                throw new CustomException('Uma Campanha do Produto teve erro ao ser inserida :'+ordItemResp.errorMsg+' ERRO (006)');
            }
        }
        
        for(CampaignOrderItem__c ordItem : [SELECT id, OrderItem__c, OrderItem__r.Product2Id, Campaign__c, CampaignProduct__c, Discount__c, DiscountValue__c, FixedUnitPriceCampaign__c, FixedUnitPrice__c FROM CampaignOrderItem__c WHERE id IN :shipIdSet]){
            String key  = ordItem.OrderItem__r.Product2Id;
            CampaignResponse sche  = new CampaignResponse(shipRequestMap.get(key+''+ordItem.Campaign__C), ordItem);
            if(!responseOrderItemMap.containsKey(key))
                responseOrderItemMap.put(key, new List<CampaignResponse>());
            responseOrderItemMap.get(key).add(sche);
        }

        for(OrderItemResponse ordReq : ordResponse.itens){
            if(responseOrderItemMap.containsKey(ordReq.productId))
                ordReq.itensCampaign.addAll(responseOrderItemMap.get(ordReq.productId));
        }
    }
    global static void upsertOrderItemDML(List<Database.SaveResult> listResults, List<OrderItem> ordItemList, Set<Id> ordItemIdSet, List<OrderItemResponse> responseOrderItem){
        for(Integer i = 0; i < listResults.size(); i++){
		    OrderItem ordResult = ordItemList[i];
		    Database.SaveResult upsResult = listResults[i];
		    if(upsResult.isSuccess()){
               ordItemIdSet.add(upsResult.getId());
		    } else {
                System.debug(upsResult.getErrors()[0].getMessage());
               responseOrderItem.add(new OrderItemResponse(upsResult.getErrors()[0].getMessage()));
		    }		        
		}
    }
    global static void upsertCampaignItemDML(List<Database.SaveResult> listResults, List<CampaignOrderItem__c> scheduleList, Set<Id> scheduleIdSet, List<CampaignResponse> responseSchedule){
        for(Integer i = 0; i < listResults.size(); i++){
		    CampaignOrderItem__c ordResult = scheduleList[i];
		    Database.SaveResult upsResult = listResults[i];
		    if(upsResult.isSuccess()){
               scheduleIdSet.add(upsResult.getId());
		    } else {
               responseSchedule.add(new CampaignResponse(upsResult.getErrors()[0].getMessage()));
		    }		        
		}
    }
    global static void upsertScheduleItemDML(List<Database.SaveResult> listResults, List<ShippingDivision__c> scheduleList, Set<Id> scheduleIdSet, List<ScheduleItemResponse> responseSchedule){
        for(Integer i = 0; i < listResults.size(); i++){
		    ShippingDivision__c ordResult = scheduleList[i];
		    Database.SaveResult upsResult = listResults[i];
		    if(upsResult.isSuccess()){
               scheduleIdSet.add(upsResult.getId());
		    } else {
               responseSchedule.add(new ScheduleItemResponse(upsResult.getErrors()[0].getMessage()));
		    }		        
		}
    }

    @AuraEnabled
    global static String uploadBarterTerm(String documentId, String recId){

        System.debug('documentId: ' + documentId);
        System.debug('RecordId: ' + recId);
        ContentDocumentLink cdl = createContentLink(documentId, recId);
        
        System.debug('CDL: ' + cdl);
        
        if (cdl == null) { 
            return null; 
        }
        System.debug('Anexado');
        return cdl.Id;
    }

    global static ContentDocumentLink createContentLink(String contentDocumentId, String recordId) {
        if (contentDocumentId == null || recordId == null) { 
            return null; 
        }
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentDocumentId;
        cdl.LinkedEntityId = recordId;
        // ShareType is either 'V', 'C', or 'I'
        // V = Viewer, C = Collaborator, I = Inferred
        cdl.ShareType = 'V';
        try {
            //delete [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
            insert cdl;
            return cdl;
        } catch(DMLException e) {
            System.debug(e);
            return null;
        }
    }

    global static void callApprovalProcess(Id ordId){
        update new Order(Id = ordId, StatusSF__c = 'Em Aprovação');

        Order ord = [SELECT id,DiscountApprovalNote__c, ContractOrder__c, Recordtype.DeveloperName , MarginApprover__c, DiscountApprover__c, DiscountApprover2__c, DiscountApprover3__c, DiscountApprover4__c,  CommercialApproval__c, FinancialAdministrativeManager__c FROM Order WHERE id = : ordId AND StatusSF__c = 'Em Aprovação'];
        
        System.debug(ord);
        
        Boolean isDiscountRecordType = !ord.Recordtype.DeveloperName.contains('Bonification');
        
        if((ord.CommercialApproval__c || 
        ord.FinancialAdministrativeManager__c != null ||
        (ord.MarginApprover__c != null ) ||
        (ord.DiscountApprover__c != null ) ||
        (ord.DiscountApprover2__c != null ) ||
        (ord.DiscountApprover3__c != null ) ||
        (ord.DiscountApprover4__c != null ) ) && ord.ContractOrder__c == null   ){
		    Approval.processSubmitRequest req1 = new Approval.processSubmitRequest();
		    req1.setComments(ord.DiscountApprovalNote__c);
		    req1.setObjectId(ordId);
		    req1.setProcessDefinitionNameOrId('OrderApproval3');
		    req1.setSubmitterId(UserInfo.getUserId());    

		    List<Approval.processResult> result = Approval.process(new List<Approval.processSubmitRequest>{req1});
        }else{
            ord.StatusSF__c = 'Aprovado';
            update ord;
        } 
    }
    global static void callApprovalProcess(Set<Id> ordId){
        List<Order> newOrder = new List<Order>();

        // recallProcess(ordIdSet);
        List<Order> ordUpdateLIst = new List<Order>();
        for(Id ordIds : ordId){
            ordUpdateLIst.add(new Order(Id = ordIds, StatusSF__c = 'Em Aprovação'));
        }

        System.debug(ordUpdateLIst);

        update ordUpdateLIst;

        System.debug(ordUpdateLIst);
        List<Order> order = [SELECT id, DiscountApprovalNote__c, Recordtype.DeveloperName , MarginApprover__c, DiscountApprover__c, DiscountApprover2__c, DiscountApprover3__c, DiscountApprover4__c, CommercialApproval__c, FinancialAdministrativeManager__c FROM Order WHERE id IN : ordId AND StatusSF__c = 'Em Aprovação' AND RecordType.DeveloperName != null];

        System.debug(order);
        List<Approval.processSubmitRequest> requests = new List<Approval.processSubmitRequest>();
        for(Order ord : order){
            
            Boolean isDiscountRecordType = !ord.Recordtype.DeveloperName.contains('Bonification');
            
            if(ord.CommercialApproval__c || 
               ord.FinancialAdministrativeManager__c != null ||
               (ord.MarginApprover__c != null ) ||
               (ord.DiscountApprover__c != null ) ||
               (ord.DiscountApprover2__c != null ) ||
               (ord.DiscountApprover3__c != null ) ||
               (ord.DiscountApprover4__c != null )){
                    Approval.processSubmitRequest req = new Approval.processSubmitRequest();
                    req.setComments(ord.DiscountApprovalNote__c);
                    req.setObjectId(ord.Id);
                    req.setProcessDefinitionNameOrId('OrderApproval3');
                    req.setSubmitterId(UserInfo.getUserId());    
                    requests.add(req);
            }else{
                newOrder.add(new Order(Id = ord.Id, StatusSF__c = 'Aprovado'));
            }
        }
        List<Approval.processResult> result = new List<Approval.processResult>();
        if(!requests.isEmpty()){
            result = Approval.process(requests);
        }
        if(!newOrder.isEmpty()){
            update newOrder;
        }
    }

    public static void handleExcludedSapItens(OrderResponse orderResponse){
        
        List<Order> orderList = [
            SELECT Id, DeletedProductProcessSap__c, StatusSF__c, ContainIntegrationError__c
            FROM Order
            WHERE Id =: orderResponse.Id
        ];

        Set<Id> ordIdSet = new Set<Id>(Collection.of(orderList).pluckIds());

        List<OrderItem> orderItemList = [
            SELECT Id, OrderId, Product2.ProductCode, DeletedProductSap__c
            FROM OrderItem
            WHERE OrderID IN: ordIdSet
        ];

        Map<Id, List<OrderItem>> orderIdToOrderItemList = new Map<Id, List<OrderItem>>();

        for(OrderItem orderItem : orderItemList){
        
            if (orderIdToOrderItemList.containsKey(orderItem.OrderId)) {
                orderIdToOrderItemList.get(orderItem.OrderId).add(orderItem);
            }
            else {
                orderIdToOrderItemList.put(orderItem.OrderId, new List<OrderItem>{orderItem});
            }
        }

        List<OrderItem> orderItemToUpdate = new List<OrderItem>();

        for(Order order : orderList){

            if(order.ContainIntegrationError__c && order.DeletedProductProcessSap__c){
                
                if (orderIdToOrderItemList.containsKey(order.Id)){
                    Boolean haveDeletedItem = false;

                    for (OrderItem orderItem : orderIdToOrderItemList.get(order.Id)){
                        if(orderItem.DeletedProductSap__c){
                            haveDeletedItem = true;
                        }
                    }
                    
                    order.DeletedProductProcessSap__c = false;
                    if(!haveDeletedItem){
                        orderResponse.Status = 'Em Aprovação';
                        Approval.unlock(order.id);
                        // callApprovalProcess(order.id); 
                    }else{
                        order.StatusSF__c = 'Aprovado';
                        orderResponse.Status = 'Aprovado'; 
                        for (OrderItem orderItem : orderIdToOrderItemList.get(order.Id)){
                            orderItem.DeletedProductSap__c = false;
                            orderItemToUpdate.add(orderItem);
                        }
                    }
                    
                } else {
                    order.StatusSF__c = 'Cancelado';
                    orderResponse.Status = 'Cancelado';
                }
            }
        }
        
        System.debug(orderItemToUpdate);

        if(!orderItemToUpdate.isEmpty()){
            update orderItemToUpdate;
        }
        System.debug(orderList);
        update orderList;
    }

	global class CustomException extends Exception {}
    
	global abstract class OrderBaseRequest{
        @AuraEnabled public String  id                      {get;set;}
        @AuraEnabled public String  marginApprover          {get;set;}
        @AuraEnabled public String types                   {get;set;}
        @AuraEnabled public String  appVersion              {get;set;}
        @AuraEnabled public Integer appCode                 {get;set;}
        @AuraEnabled public Date    appCreatedDate          {get;set;} //Data de criação  
        @AuraEnabled public String  status                  {get;set;}
        @AuraEnabled public String  statusSAP               {get;set;}
        @AuraEnabled public String  customerNumber          {get;set;}
        @AuraEnabled public String  currencys               {get;set;}
        @AuraEnabled public Date    expirationDate          {get;set;} //Data de validade
        @AuraEnabled public Date    paymentDate             {get;set;} //Data de Pagamento, Data de Vencimento
        @AuraEnabled public String  activitySector          {get;set;}
        @AuraEnabled public String  accountId               {get;set;}
        @AuraEnabled public String  billingLocationId       {get;set;}
        @AuraEnabled public String  shippingLocationId      {get;set;}
        @AuraEnabled public String  rtvId                   {get;set;}
        @AuraEnabled public String  salesTeamId             {get;set;}
        @AuraEnabled public String  cropId                  {get;set;}
        @AuraEnabled public String  freightType             {get;set;}
        @AuraEnabled public String  recordTypeDeveloperName {get;set;}
        @AuraEnabled public String  salesCondition          {get;set;}
        @AuraEnabled public String  observationNF           {get;set;}
        @AuraEnabled public String  paymentCondition        {get;set;}
        @AuraEnabled public String  paymentMethod           {get;set;}
        @AuraEnabled public String  originalOrderId         {get;set;}
        @AuraEnabled public Decimal oldOrderCredit          {get;set;}
        @AuraEnabled public String  customerGroup           {get;set;}
        @AuraEnabled public String  route                   {get;set;}
        @AuraEnabled public String  contentVersionId        {get;set;}
        @AuraEnabled public String  contractOrderId         {get;set;}
        //Barter Fields
        @AuraEnabled public String  barterType                 {get;set;}
        @AuraEnabled public String  commodity                  {get;set;}
        @AuraEnabled public String  shippingCrop               {get;set;}
        @AuraEnabled public String  billingCrop                {get;set;}
        @AuraEnabled public Decimal grossUnitPrice             {get;set;}
        @AuraEnabled public Decimal unitPrice                  {get;set;}
        @AuraEnabled public String  commercialMeasureUnit      {get;set;}
        @AuraEnabled public String  commodityShipping          {get;set;}
        @AuraEnabled public Date    initialDeliveryDate        {get;set;}
        @AuraEnabled public Date    endDeliveryDate            {get;set;}
        @AuraEnabled public Date    contractEndDate            {get;set;}
        @AuraEnabled public Date    contractStartDate          {get;set;}
        @AuraEnabled public Decimal totalDeliveryQuantity      {get;set;}

        //COMM -> CIF
        @AuraEnabled public String  productionDeliveryLocation {get;set;}

        //COMM -> FOB
        @AuraEnabled public String  productionPickupLocation   {get;set;}

        //FinancialBarter
        @AuraEnabled public Decimal strikePrice                {get;set;}
        @AuraEnabled public Date    dueDateFinancial           {get;set;}

        //TriangulationBarter
        @AuraEnabled public String  trade                      {get;set;}
        @AuraEnabled public Decimal balance                    {get;set;}
    }
	global abstract class OrderItemBaseRequest{
        @AuraEnabled public Decimal  margin                  {get;set;}
        @AuraEnabled public Decimal  projectedMargin         {get;set;}
        @AuraEnabled public Decimal  familyMargin            {get;set;}

        @AuraEnabled public String  Id                      {get;set;}
        @AuraEnabled public Integer Appcode                 {get;set;}
        @AuraEnabled public String  productId               {get;set;}
        @AuraEnabled public String  QuantityUnitOfMeasure   {get;set;}
        @AuraEnabled public String  listPriceId             {get;set;}
        @AuraEnabled public Decimal unitPrice               {get;set;}
        @AuraEnabled public Decimal listPrice               {get;set;}
        @AuraEnabled public Decimal quantity                {get;set;}
        @AuraEnabled public Decimal freightValue            {get;set;}
        @AuraEnabled public Decimal freightValuePerTon      {get;set;}
        @AuraEnabled public String  freightType             {get;set;}
        @AuraEnabled public Decimal discountPercent         {get;set;}
        @AuraEnabled public Decimal discountValue           {get;set;}
        @AuraEnabled public Decimal additionPercent         {get;set;}
        @AuraEnabled public Decimal additionValue           {get;set;}
        @AuraEnabled public String  cultureId               {get;set;}
        @AuraEnabled public String  refuseReason            {get;set;}
        @AuraEnabled public Decimal refuseReasonQuantity    {get;set;}
        @AuraEnabled public String  incoterms1              {get;set;}
        @AuraEnabled public String  incoterms2              {get;set;}
        @AuraEnabled public Decimal antecipationDiscount    {get;set;}
        @AuraEnabled public Decimal interestValue           {get;set;}
        @AuraEnabled public Decimal interest                {get;set;}
        @AuraEnabled public String  interestListPriceId     {get;set;}
        @AuraEnabled public String  destinationCityId       {get;set;} 
        @AuraEnabled public String  sourceCityId            {get;set;}
        @AuraEnabled public String  status                  {get;set;}
        @AuraEnabled public Date    lastChangedPriceList    {get;set;}
        @AuraEnabled public Decimal balance                 {get;set;}
    }
    global abstract class ScheduleItemBaseRequest{
        @AuraEnabled public String  Id              {get;set;}
        @AuraEnabled public Integer AppCode         {get;set;}
        @AuraEnabled public Date    deliveryDate    {get;set;}
        @AuraEnabled public Decimal quantity        {get;set;}
    }
    global abstract class CampaignBaseRequest{
        @AuraEnabled public String  Id                  {get;set;}
        @AuraEnabled public Integer AppCode             {get;set;}
        @AuraEnabled public String  campaignId          {get;set;}
        @AuraEnabled public String  productCampaignId   {get;set;}
        @AuraEnabled public Decimal  discount           {get;set;}
        @AuraEnabled public Decimal  fixedPrice         {get;set;}
        @AuraEnabled public Decimal  discountValue      {get;set;}
        @AuraEnabled public Boolean hasFixedUnitPrice  {get;set;}
    }

    global class OrderRequest extends OrderBaseRequest {   
        @AuraEnabled public OrderItemRequest[] itens {get;set;}
        @AuraEnabled public String  marginApprover {get;set;}
        public Order getOrder(Id pbId, Map<Id, SalesTeam__c> salesTeamMap, Map<Id, ListPrice__c> listPriceMap){

            Decimal toMargin =0;
            Decimal toMarginQtd =0;
            // Decimal toProjectedMargin =null;
            // Decimal toFamilyMargin =null;
            for(OrderItemRequest ordItem: this.itens){
                if (ordItem.margin!=null){
                    toMargin += ordItem.margin;
                    toMarginQtd++;
                }
            }
            Order ord = new Order();
            //Inactive Margin
            // ord.MarginApprover__c =this.marginApprover;
            System.debug('marginApprover -> ' +this.marginApprover);

            ord.DirectMargin__c = toMargin/(toMarginQtd == 0 ? 1 : toMarginQtd);
            ord.Id = this.id;
            ord.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(this.recordTypeDeveloperName).getRecordTypeId();
            ord.Currency__c = this.currencys;
            ord.AccountId = this.accountId;
            ord.BillingAccount__c = this.billingLocationId;
            ord.ShippingAccount__c = this.shippingLocationId;
            ord.Crop__c = this.cropId;
            ord.CustomerOrderNumber__c = this.customerNumber;
            ord.PaymentDate__c = this.paymentDate;
            ord.ActivitySector__c = this.activitySector;
            ord.SalesTeam__c = this.salesTeamId;
            ord.SalesOrg__c = salesTeamMap.containsKey(this.salesTeamId) ? salesTeamMap.get(this.salesTeamId).SalesOrg__c: null;
            ord.SalesOffice__c = salesTeamMap.containsKey(this.salesTeamId) ? salesTeamMap.get(this.salesTeamId).ParentId__c: null;
            ord.DistributionCenter__c = salesTeamMap.containsKey(this.salesTeamId) ? salesTeamMap.get(this.salesTeamId).DistributionCenter__c: null;
            ord.OwnerId = this.rtvId;
            ord.RTV__c = this.rtvId;
            ord.CurrencyIsoCode = this.currencys;
            ord.Freight__c = this.freightType;
            ord.StatusSF__c = this.status;
            ord.StatusSAP__c = this.statusSAP;
            ord.Description = this.observationNF;
            ord.OrderCreator__c = Userinfo.getUserId();
            ord.SalesCondition__c = this.salesCondition;
            ord.SalesConditionObject__r = new SalesCondition__c(ExternalId__c = this.salesCondition);
            ord.PaymentForm__c = this.paymentMethod;
            ord.PaymentCondition__c = this.paymentCondition;
            ord.EndDate = this.expirationDate;// data de validade
            ord.OriginalOrder__c = this.originalOrderId;
            ord.OldOrderCredit__c = this.oldOrderCredit;
            ord.CustomerGroup__c = this.customerGroup;
            ord.OrderRoute__c = this.route;

            // ord.Type = this.types == 'SFMP' ? this.types : 'SFOR'; 

            if (String.isNotBlank(this.customerGroup)) {
                ord.CustomerGroup__c = this.customerGroup;
            } else {
                Map<String, AccountGroupIntegration__c> accGroupMap = AccountGroupIntegration__c.getAll();   
                            
                if(String.isNotBlank(ord.SalesOrg__c) && accGroupMap.containsKey(salesTeamMap.get(this.salesTeamId).SalesOrg__r?.ExternalId__c))
                    ord.CustomerGroup__c = accGroupMap.get(salesTeamMap.get(this.salesTeamId).SalesOrg__r?.ExternalId__c).ClientGroup__c;
                else
                    ord.CustomerGroup__c = 'C2';
            }

            //App
            ord.ExternalIdApp__c = String.valueOf(this.appCode);
            ord.Type = (String.valueOf(this.appCode) == null || String.valueOf(this.appCode) == '' ? 'SFMP' : 'SFOR');
            ord.AppVersion__c    = this.appVersion;
            ord.CreatedDateApp__c = this.appCreatedDate;

            ord.EffectiveDate = Date.today();
            if(ord.EffectiveDate > ord.EndDate){
                ord.EndDate = ord.EffectiveDate.addDays(1);
            }
            ord.Pricebook2Id = pbId;
            ord.Status = 'Draft';
            ord.DistributionChannel__c = '10';
            ord.ContractOrder__c = this.contractOrderId;

            Set<String> recordTypesToContractDates = new Set<String>{'BarterSale', 'ZCCO', 'ZCEF', 'ZCNO'};
            if(recordTypesToContractDates.contains(this.recordTypeDeveloperName)) {
                ord.ContractEndDate__c   = this.contractEndDate;
                ord.ContractStartDate__c = this.contractStartDate;
            }

            //Barter Fields
            if(this.recordTypeDeveloperName == 'BarterSale'){
                ord.BarterType__c = this.barterType;
                ord.Commodity__c = this.commodity;
                ord.ShippingCrop__c = this.shippingCrop;
                ord.BillingCrop__c = this.billingCrop;
                ord.CommercialMeasureUnit__c = this.commercialMeasureUnit;
                ord.DeliveryQuantity__c = this.totalDeliveryQuantity;
                
                if(this.barterType == 'Financeiro'){
                    ord.StrikePrice__c = this.strikePrice;
                    ord.DueDateFinancial__c = this.dueDateFinancial;
                    ord.GrossUnitPrice__c = null;
                    ord.UnitPrice__c = null;
                    ord.InitialDeliveryDate__c = null;
                    ord.EndDeliveryDate__c = null;
                    ord.CommodityShipping__c = null;
                    ord.ProductionPickupLocation__c = null;
                    ord.ProductionDeliveryLocation__c = null;
                }
                else{
                    ord.GrossUnitPrice__c = this.grossUnitPrice;
                    ord.UnitPrice__c = this.unitPrice;
                    ord.InitialDeliveryDate__c = this.initialDeliveryDate;
                    ord.EndDeliveryDate__c = this.endDeliveryDate;
                    ord.CommodityShipping__c = this.commodityShipping;
                    ord.StrikePrice__c                = null;
                    ord.DueDateFinancial__c           = null;
                    if(this.commodityShipping == 'CIF'){
                        ord.ProductionDeliveryLocation__c = this.productionDeliveryLocation;
                        ord.ProductionPickupLocation__c = null;
                    }
                    else{
                        ord.ProductionDeliveryLocation__c = null;
                        ord.ProductionPickupLocation__c = this.productionPickupLocation;
                    }
                }
                if(this.barterType == 'Triangulação'){
                    ord.AccountTradeName__c = this.trade;
                } else{
                    ord.AccountTradeName__c = null;
                }
            } else{
                ord.BarterType__c                 = null;
                ord.Commodity__c                  = null;
                ord.ShippingCrop__c               = null;
                ord.BillingCrop__c                = null;
                ord.CommercialMeasureUnit__c      = null;
                ord.DeliveryQuantity__c           = null;
                ord.StrikePrice__c                = null;
                ord.DueDateFinancial__c           = null;
                ord.GrossUnitPrice__c             = null;
                ord.UnitPrice__c                  = null;
                ord.InitialDeliveryDate__c        = null;
                ord.EndDeliveryDate__c            = null;
                ord.CommodityShipping__c          = null;
                ord.ProductionDeliveryLocation__c = null;
                ord.ProductionPickupLocation__c   = null;
                ord.AccountTradeName__c           = null;
            }

            Set<String> financialString = new Set<String>();
            for(OrderItemRequest it : itens){
                Date dt = listPriceMap.containsKey(it.listPriceId) ? listPriceMap.get(it.listPriceId).EffectiveDate__c : null;
                financialString.add(formatDate(dt));
            }
            ord.FinancialApprovalNote__c = 'Datas efetivas das listas de preço dos Produtos: '+String.join(new List<String>(financialString), ',');
            return ord;
        }
    }
    public static String formatDate(Date dt){
        return  dt != null ? (dt.day() +'/'+ dt.month()+'/'+dt.year() ) : '';
    }
    global class OrderItemRequest extends OrderItemBaseRequest{
        @AuraEnabled public ScheduleItemRequest[] itens {get;set;}
        @AuraEnabled public CampaignRequest[] itensCampaign {get;set;}
        public OrderItem getOrderItem(Integer val, Map<Id, PricebookEntry> priceMap, Map<Id, ListPrice__c> listPriceMap, OrderResponse ordResp, Boolean updateContext, Map<String, OrderItem> ordItemContractMap){
            OrderItem ordItem = new OrderItem();
            ordItem.Id = this.id;
            if(!updateContext){
                ordItem.Product2Id = this.productId;
                ordItem.PricebookEntryId = priceMap.get(this.productId).Id;
                ordItem.OrderId = ordResp.id;   
            }

            ordItem.DirectMargin__c =this.margin;
            ordItem.ProjectedMargin__c =projectedMargin;
            ordItem.DirectFamilyMargin__c =this.familyMargin;
            ordItem.Cost__c = listPriceMap.containsKey(this.listPriceId) ? listPriceMap.get(this.listPriceId).Cost__c : null;
            
            if(ordItemContractMap.containsKey(this.productId+'_'+ordResp.contractOrderId)){
                ordItem.CampaignPercent__c         = ordItemContractMap.get(this.productId+'_'+ordResp.contractOrderId).CampaignPercent__c;
                ordItem.CampaignIndustryPercent__c = ordItemContractMap.get(this.productId+'_'+ordResp.contractOrderId).CampaignIndustryPercent__c;
                ordItem.CampaigPercent__c = ordItemContractMap.get(this.productId+'_'+ordResp.contractOrderId).CampaigPercent__c;
            }
            //ordItem.CurrencyIsoCode = ordResp.currencys;
            ordItem.Culture__c = this.cultureId;
            ordItem.UnitMeasure__c = this.QuantityUnitOfMeasure;
            ordItem.RefuseReason__c = this.refuseReason;
            //ordItem.Status__c = this.status;
            ordItem.ListPrice__c = this.listPriceId;
            ordItem.UnitPrice = this.unitPrice;
            ordItem.quantity = this.quantity;
            ordItem.Incoterms1__c = this.incoterms1;
            ordItem.Incoterms2__c = this.incoterms2;    
            ordItem.DestinationCity__c = this.destinationCityId;
            ordItem.SourceCity__c = this.sourceCityId;
            ordItem.AnticipationDiscount__c = this.antecipationDiscount;
            ordItem.InterestValue__c = this.interestValue;
            ordItem.CalculatedInterest__c = this.interest;
            // ordItem.quantity = this.quantity / listPriceMap.get(this.listPriceId).PriceMultiplier__c;
            ordItem.Quantity__c = this.quantity;            
            ordItem.ContractProductCredit__c = this.quantity;       
            ordItem.CustomListPrice__c = this.listPrice;
            ordItem.OriginalListPrice__c = listPriceMap.containsKey(this.listPriceId) ? listPriceMap.get(this.listPriceId).OriginalUnitPrice__c : 0;
            ordItem.PriceListEffectiveDate__c = listPriceMap.containsKey(this.listPriceId) ? listPriceMap.get(this.listPriceId).EffectiveDate__c : null;
            ordItem.ListPriceWithoutInterest__c = this.listPrice;
            ordItem.DiscountPercent__c = this.discountPercent;
            ordItem.DiscountAmount__c = this.discountValue;
            ordItem.AdditionPercent__c = this.additionPercent;
            ordItem.AdditionAmount__c = this.additionValue;
            ordItem.FreightValue__c = this.freightValue;
            ordItem.FreightValuePerTon__c = this.freightValuePerTon;
            ordItem.Freight__c = this.freightType;
            ordItem.BilledQuantity__c = 0;
            ordItem.ExternalIdApp__c = String.valueOf(this.AppCode);
            ordItem.LastChangedPriceList__c = this.lastChangedPriceList;
            ordItem.ExternalId__c = ordResp.id +'|'+ String.valueOf(val);
            ordItem.SAPNumber__c = String.valueOf(val);

            ordItem.RefuseCredit__c = this.refuseReasonQuantity;

            ordItem.Center__c = ordResp.distributionCenterId;

            if (String.isNotBlank(this.interestListPriceId) && this.interestListPriceId != 'undefined') {
                ordItem.InterestOrAntecipationDiscount__c = this.interestListPriceId;
            }

            return ordItem;
        }      
    }
    global class ScheduleItemRequest extends ScheduleItemBaseRequest{
        public ShippingDivision__c getScheduleItem(Integer val, OrderItemResponse ordItem){
            ShippingDivision__c scheduleObject = new ShippingDivision__c();
            scheduleObject.Id = this.Id;
            scheduleObject.DeliveryDate__c = this.deliveryDate;
            scheduleObject.OrderItem__c = ordItem.id;
            scheduleObject.Quantity__c = this.quantity;
            scheduleObject.SAPNumber__c = String.valueOf(val);
            scheduleObject.ExternalId__c =  ordItem.id+'|'+String.valueOf(val);
            Datetime dt =  datetime.newInstance(this.deliveryDate, Time.newInstance(23,59,59,59));
            scheduleObject.Name = dt.format('dd/MM/YYYY')+' - '+String.valueOf(this.Quantity);
            return scheduleObject;
        }        
    }
    global class CampaignRequest extends CampaignBaseRequest{
        public CampaignOrderItem__c getCampaignItem(OrderItemResponse ordItem){
            CampaignOrderItem__c campaignObject = new CampaignOrderItem__c();
            campaignObject.Campaign__c = this.campaignId;
            campaignObject.CampaignProduct__c = this.productCampaignId;
            campaignObject.OrderItem__c = ordItem.id;
            campaignObject.Discount__c = this.discount;
            campaignObject.DiscountValue__c = this.discountValue;
            campaignObject.FixedUnitPriceCampaign__c = this.hasFixedUnitPrice;
            campaignObject.FixedUnitPrice__c = this.fixedPrice;
            return campaignObject;
        }        
    }


    global class OrderResponse extends OrderBaseRequest{
        @AuraEnabled public Boolean hasError {get;set;}
        @AuraEnabled public String errorMsg {get;set;}
        @AuraEnabled public String marginApprover {get;set;}

        @AuraEnabled public String recordTypeId {get;set;}
        @AuraEnabled public String salesOrgId {get;set;}
        @AuraEnabled public String salesOfficeId {get;set;}
        @AuraEnabled public String distributionCenterId {get;set;}
        @AuraEnabled public String orderCreatorId {get;set;}
        @AuraEnabled public Date   effectiveDate {get;set;}
        @AuraEnabled public String pricebook2Id {get;set;}
        @AuraEnabled public String status {get;set;}
        @AuraEnabled public String statusSAP {get;set;}
        @AuraEnabled public String distributionChannel {get;set;}

        @AuraEnabled public Decimal totalAmount {get;set;}
        @AuraEnabled public Decimal totalAmountWithFreight {get;set;}
        @AuraEnabled public Decimal totalFreightValue {get;set;}

        @AuraEnabled public String approvalJustification {get;set;}
        @AuraEnabled public Decimal approverDiscountAmount {get;set;}
        @AuraEnabled public String bonificationApprovalNote {get;set;}
        @AuraEnabled public Boolean commercialApproval {get;set;}
        @AuraEnabled public String discountApprovalNote {get;set;}
        @AuraEnabled public String discountApprover {get;set;}
        @AuraEnabled public String discountApprover2 {get;set;}
        @AuraEnabled public String discountApprover3 {get;set;}
        @AuraEnabled public String discountApprover4 {get;set;}
        @AuraEnabled public String financialApproval {get;set;}
        @AuraEnabled public String registrationApprovalNote {get;set;}

        @AuraEnabled public OrderItemResponse[] itens {get;set;}

        public OrderResponse(Exception ex, OrderRequest ordReq){
            this.hasError = true;
            this.errorMsg = ex.getMessage();//+'\n Erro :'+ex.getStackTraceString();

            this.appCode                 = ordReq.appCode;
        } 
        public OrderResponse(String error, OrderRequest ordReq){
            this.hasError = true;
            this.errorMsg = error;

            this.appCode                 = ordReq.appCode;
        }
        public OrderResponse(OrderRequest ordReq, Order ord){
            this.hasError                = false;
            this.marginApprover          = ord.MarginApprover__c;
            this.errorMsg                = 'Sucesso!';

            this.itens = new List<OrderItemResponse>();

            this.id                      = ord.id;
            this.recordTypeId            = ord.recordTypeId;
            this.salesOrgId              = ord.salesOrg__c;
            this.salesOfficeId           = ord.salesOffice__c;
            this.distributionCenterId    = ord.distributionCenter__c;
            this.orderCreatorId          = ord.orderCreator__c;
            this.effectiveDate           = ord.effectiveDate;
            this.pricebook2Id            = ord.pricebook2Id;
            this.status                  = ord.statusSF__c;
            this.distributionChannel     = ord.distributionChannel__c;
            this.approvalJustification   = ord.ApprovalJustification__c;
            this.approverDiscountAmount  = ord.ApproverDiscountAmount__c;
            this.bonificationApprovalNote= ord.BonificationApprovalNote__c;
            this.commercialApproval      = ord.CommercialApproval__c;
            this.discountApprovalNote    = ord.DiscountApprovalNote__c;
            this.discountApprover        = ord.DiscountApprover__c;
            this.discountApprover2       = ord.DiscountApprover2__c;
            this.discountApprover3       = ord.DiscountApprover3__c;
            this.discountApprover4       = ord.DiscountApprover4__c;
            this.financialApproval       = ord.FinancialAdministrativeManager__c;
            this.registrationApprovalNote= ord.RegistrationApprovalNote__c;

            this.totalFreightValue       = ord.totalFreightValue__c;
            this.totalAmountWithFreight  = ord.totalAmountWithFreight__c;
            this.totalAmount             = ord.totalAmount;

            this.appCode                 = ordReq.appCode;
            this.appVersion              = ordReq.appVersion;
            this.appCreatedDate          = ordReq.appCreatedDate;
            this.customerNumber          = ordReq.customerNumber;
            this.currencys               = ordReq.currencys;
            this.paymentDate             = ordReq.paymentDate;
            this.activitySector          = ordReq.activitySector;
            this.accountId               = ordReq.accountId;
            this.billingLocationId       = ordReq.billingLocationId;
            this.shippingLocationId      = ordReq.shippingLocationId;
            this.rtvId                   = ordReq.rtvId;
            this.salesTeamId             = ordReq.salesTeamId;
            this.cropId                  = ordReq.cropId;
            this.freightType             = ordReq.freightType;
            this.recordTypeDeveloperName = ordReq.recordTypeDeveloperName;
            this.salesCondition          = ordReq.salesCondition;
            this.observationNF           = ordReq.observationNF;
            this.paymentCondition        = ordReq.paymentCondition;
            this.paymentMethod           = ordReq.paymentMethod;
            this.expirationDate          = ordReq.expirationDate;
            this.originalOrderId         = ordReq.originalOrderId;
            this.oldOrderCredit          = ordReq.oldOrderCredit;
            this.customerGroup           = ordReq.customerGroup;
            this.statusSAP               = ordReq.statusSAP;
            this.route                   = ordReq.route;

            //Barter Fields
            this.barterType                 = ordReq.barterType;
            this.commodity                  = ordReq.commodity;
            this.shippingCrop               = ordReq.shippingCrop;
            this.billingCrop                = ordReq.billingCrop;
            this.grossUnitPrice             = ordReq.grossUnitPrice;
            this.unitPrice                  = ordReq.unitPrice;
            this.commodityShipping          = ordReq.commodityShipping;
            this.initialDeliveryDate        = ordReq.initialDeliveryDate;
            this.endDeliveryDate            = ordReq.endDeliveryDate;
            this.commercialMeasureUnit      = ordReq.commercialMeasureUnit;
            this.contractEndDate            = ordReq.contractEndDate;
            this.contractStartDate          = ordReq.contractStartDate;
            this.totalDeliveryQuantity      = ordReq.totalDeliveryQuantity;
            this.productionDeliveryLocation = ordReq.productionDeliveryLocation;
            this.productionPickupLocation   = ordReq.productionPickupLocation;
            this.strikePrice                = ordReq.strikePrice;
            this.dueDateFinancial           = ordReq.dueDateFinancial;
            this.trade                      = ordReq.trade;

            this.contractOrderId            = ordReq.contractOrderId;
            
        }  
    }
    global class OrderItemResponse extends OrderItemBaseRequest{
        @AuraEnabled public Boolean hasError {get;set;}
        @AuraEnabled public String errorMsg {get;set;}
        
        @AuraEnabled public String orderId {get;set;}
        @AuraEnabled public String distributionCenterId {get;set;}
        @AuraEnabled public String OrderItemNumber {get;set;}

        @AuraEnabled public ScheduleItemResponse[] itens {get;set;}
        @AuraEnabled public CampaignResponse[] itensCampaign {get;set;}
        public OrderItemResponse(Exception ex){
            this.hasError = true;
            this.errorMsg = ex.getMessage()+'\n Erro :'+ex.getStackTraceString();
        } 
        public OrderItemResponse(String error){
            this.hasError = true;
            this.errorMsg = error;
        }
        public OrderItemResponse(OrderItemRequest ordReq, OrderItem ordItem){
            this.hasError                = false;
            this.errorMsg                = 'Sucesso!';

            this.id                    = ordItem.id;
            this.productId             = ordReq.productId;
            this.cultureId             = ordReq.cultureId;
            this.QuantityUnitOfMeasure = ordReq.QuantityUnitOfMeasure;
            this.refuseReason          = ordReq.refuseReason;
            this.status                = ordReq.status;
            this.listPriceId           = ordReq.listPriceId;
            this.unitPrice             = ordReq.unitPrice;
            this.quantity              = ordReq.quantity;
            this.quantity              = ordReq.quantity;            
            this.listPrice             = ordReq.listPrice;
            this.listPrice             = ordReq.listPrice;
            this.discountPercent       = ordReq.discountPercent;
            this.discountValue         = ordReq.discountValue;
            this.additionPercent       = ordReq.additionPercent;
            this.additionValue         = ordReq.additionValue;
            this.freightValue          = ordReq.freightValue;
            this.freightValuePerTon    = ordReq.freightValuePerTon;
            this.freightType           = ordReq.freightType;
            this.incoterms1            = ordReq.incoterms1;
            this.incoterms2            = ordReq.incoterms2;
            this.interestListPriceId   = ordReq.interestListPriceId;
            this.destinationCityId     = ordReq.destinationCityId;
            this.sourceCityId          = ordReq.sourceCityId;
            this.antecipationDiscount  = ordReq.antecipationDiscount;
            this.interestValue         = ordReq.interestValue;
            this.interest              = ordReq.interest;
            this.orderId               = ordItem.OrderId;
            this.distributionCenterId  = ordItem.Center__c;
            this.OrderItemNumber       = ordItem.OrderItemNumber;
            this.refuseReasonQuantity  = ordReq.refuseReasonQuantity;

            this.AppCode               = ordItem.ExternalIdApp__c == null ? null : Integer.valueOf(ordItem.ExternalIdApp__c);

            this.itens = new List<ScheduleItemResponse>();
            this.itensCampaign = new List<CampaignResponse>();
        }
    }
    global class ScheduleItemResponse extends ScheduleItemBaseRequest {
        @AuraEnabled public Boolean hasError {get;set;}
        @AuraEnabled public String errorMsg {get;set;}
        public ScheduleItemResponse(Exception ex){
            this.hasError = true;
            this.errorMsg = ex.getMessage()+'\n Erro :'+ex.getStackTraceString();
        } 
        public ScheduleItemResponse(String error){
            this.hasError = true;
            this.errorMsg = error;
        }
        public ScheduleItemResponse(ScheduleItemRequest schedule, ShippingDivision__c scheduleObject){
            this.hasError                = false;
            this.errorMsg                = 'Sucesso!';

            this.AppCode       = schedule.AppCode;
            this.Id           = scheduleObject.Id;
            this.deliveryDate = schedule.deliveryDate;
            this.quantity     = schedule.quantity;
        }        
    }
    global class CampaignResponse extends CampaignBaseRequest {
        @AuraEnabled public Boolean hasError {get;set;}
        @AuraEnabled public String errorMsg {get;set;}
        public CampaignResponse(Exception ex){
            this.hasError = true;
            this.errorMsg = ex.getMessage()+'\n Erro :'+ex.getStackTraceString();
        } 
        public CampaignResponse(String error){
            this.hasError = true;
            this.errorMsg = error;
        }
        public CampaignResponse(CampaignRequest schedule, CampaignOrderItem__c campaignObject){
            this.hasError                = false;
            this.errorMsg                = 'Sucesso!';

            this.AppCode           = schedule.AppCode;
            this.campaignId        = campaignObject.Campaign__c;        
            this.productCampaignId = campaignObject.CampaignProduct__c; 
            this.id                = campaignObject.Id;       
            this.discount          = campaignObject.Discount__c;        
            this.discountValue     = campaignObject.DiscountValue__c;   
            this.fixedPrice        = campaignObject.FixedUnitPrice__c;  
        }        
    }
}