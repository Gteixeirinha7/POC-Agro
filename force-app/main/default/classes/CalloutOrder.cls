public without sharing class CalloutOrder {
    public static Map<Id, CampaignProduct__c> campaignMap {get;set;}
    static{
        campaignMap = new Map<Id, CampaignProduct__c>();
    }
	@InvocableMethod
    public static void invocableProcessIntegration(List<Id> listOrderId){
        IntegrationUtils.CalloutResponse calloutResponse = processIntegration(listOrderId);
    }
    
    public static IntegrationUtils.CalloutResponse processIntegration(List<Id> listOrderId){
        IntegrationUtils.CalloutResponse calloutResponse = null;
        try{
            Set<Id> orderItemIdSet = new Set<Id>();
            //HttpResponse response;
            List<Order> parentOrders = [
                SELECT Id, Type, OrderRoute__c, ExternalId__c, ContractGrainCode__c, OrderNumber, PaymentDate__c, RecordTypeId, RecordType.DeveloperName, Crop__r.ExternalId__c, Crop__c, SalesCondition__c, PaymentCondition__c, PaymentCondition__r.ExternalId__c, PaymentForm__c, EndDate, StatusSF__c,
                StatusSAP__c, CustomerOrderNumber__c, OrderMotive__c, TotalFreightValue__c, TotalAmount, TotalAmountWithFreight__c, OriginalOrder.ExternalId__c,
                ParentOrderReferenceType__c, SalesOrg__r.ExternalId__c, DistributionChannel__c, ActivitySector__c, SalesOffice__r.ExternalId__c, SalesTeam__r.ExternalId__c, SalesTeam__r.BillingSalesTeam__r.ExternalId__c, SalesTeam__r.BillingSalesTeam__c, SalesTeam__r.DistributionCenter__r.ExternalId__c,
                Freight__c, CreatedDate, Description, ContractStartDate__c, ContractEndDate__c, AccountId, RTV__c, ShippingAccount__r.ExternalId__c, Currency__c, Account.ExternalId__c, RTV__r.ExternalId__c, ContractOrder__c, ContractOrder__r.ExternalId__c, TradeSlipCode__c,
                    (
                        SELECT Id, ContractOrderItem__r.SAPNumber__c, ContractOrderItem__r.ExternalId__c, FixedUnitPriceCampaign__c, CampaignPercent__c, CampaigPercent__c, CampaignIndustryPercent__c, ExternalId__c, SAPNumber__c, Quantity, Center__c, BilledQuantity__c, Product2.Name, Order.Crop__r.ExternalId__c, Product2.ProductCode, LastChangedPriceList__c, Product2.ExternalId__c, Product2.GrossWeightUnity__c, Product2.GrossWeight__c, Culture__c, Freight__c, Status__c, Center__r.ExternalId__c,
                        UnitMeasure__c, ListPrice__r.ExternalId__c, RefuseReason__c, UnitPrice, CustomListPrice__c, OriginalListPrice__c, InterestOrAntecipationDiscount__r.interestValue__c, DiscountPercent__c, AdditionPercent__c, OfferDiscount__c, FreightValue__c, Culture__r.ExternalId__c, Incoterms1__c, Incoterms2__c
                        FROM OrderItems
                    ) 
                FROM Order 
                WHERE Id IN: listOrderId];

            for(Order order : parentOrders){
                for(OrderItem orderIt : order.OrderItems){
                    orderItemIdSet.add(orderIt.Id);
                }
            }

            Map<Id, OrderItem> parentOrderItem = new Map<Id,OrderItem>([
                SELECT Id, OrderId, Quantity, Product2.ProductCode, Product2Id,
                    (
                        SELECT Id, ExternalId__c, Quantity__c, DeliveryDate__c, ConfirmedQuantity__c, SAPNumber__c
                        FROM ShippingDivisions__r
                    )
                FROM OrderItem
                WHERE Id IN: orderItemIdSet
            ]);

            Map<Id, Map<Id, List<ShippingDivision__c>>> orderIdToOrderItemIdToShippingDivisionListMap = new Map<Id, Map<Id, List<ShippingDivision__c>>>();
            
            for(OrderItem orderIt : parentOrderItem.values()){
                if(!orderIdToOrderItemIdToShippingDivisionListMap.containsKey(orderIt.OrderId)){
                    orderIdToOrderItemIdToShippingDivisionListMap.put(orderIt.OrderId, new Map<Id,List<ShippingDivision__c>>()); 
                }
                orderIdToOrderItemIdToShippingDivisionListMap.get(orderIt.OrderId).put(orderIt.Id, orderIt.ShippingDivisions__r);
            }

            List<Order> allOrders = parentOrders;

            Map<Id, Order> invalidMap = checkCampaignData(allOrders, parentOrderItem);
            if(invalidMap.containsKey(allOrders.get(0).Id))
                return calloutResponse;

            Set<String> notCheckInventory = new Set<String>{'IndustryBonification'};
            if (allOrders.get(0).ContractOrder__c == null && !notCheckInventory.contains(allOrders.get(0).RecordType.DeveloperName)) {
                InventoryQuery inventoryQuery = queryInventory(allOrders.get(0));
                if (inventoryQuery.saleAvailable) {
                    calloutResponse = sendOrder(allOrders, orderIdToOrderItemIdToShippingDivisionListMap);
                } 

                if (inventoryQuery.inventoryList.size() > 0) {
                    Database.upsert(inventoryQuery.inventoryList, ProductManagement__c.ExternalId__c, false);
                }

            } else {
                calloutResponse = sendOrder(allOrders, orderIdToOrderItemIdToShippingDivisionListMap);
            }
            
            if(!campaignMap.isEmpty()){
                update campaignMap.values();
            }
            
        }
        catch(Exception ex){
            IntegrationLog.createIntegrationLog('Order Outbound Integration Exception', 'Outbound', ex.getMessage()+', '+ex.getStackTraceString(), JSON.serialize(listOrderId), true, JSON.serialize(listOrderId));
        }
        return calloutResponse;
    }
    public static Map<Id, Order> checkCampaignData(List<Order> allOrders, Map<Id, OrderItem> parentOrderItem){
        Map<Id, CampaignProduct__c> campMap = new Map<Id, CampaignProduct__c>();
        Map<Id, Set<Id>> campIdSetMap = new Map<Id, Set<Id>>();
        for(CampaignOrderItem__c campOrder : [SELECT id, OrderItem__c, Campaign__r.Name, CampaignProduct__c, OrderItem__r.Quantity, CampaignProduct__r.MaxQuantity__c, CampaignProduct__r.UsedQuantity__c FROM CampaignOrderItem__c WHERE OrderItem__c IN :parentOrderItem.keySet() AND CampaignProduct__c != null]){
            if(!campMap.containsKey(campOrder.CampaignProduct__c))
                campMap.put(campOrder.CampaignProduct__c, new CampaignProduct__c(Id = campOrder.CampaignProduct__c, MaxQuantity__c = campOrder.CampaignProduct__r.MaxQuantity__c, UsedQuantity__c = campOrder.CampaignProduct__r.UsedQuantity__c));

            OrderItem ordItem = parentOrderItem.get(campOrder.OrderItem__c);

            CampaignProduct__c campProd = campMap.get(campOrder.CampaignProduct__c);
    
            campProd.UsedQuantity__c = campProd.UsedQuantity__c != null ? campProd.UsedQuantity__c : 0;
            campProd.UsedQuantity__c += ordItem.Quantity;
            campMap.put(campOrder.CampaignProduct__c, campProd); 

            if(!campIdSetMap.containsKey(campOrder.CampaignProduct__c))
                campIdSetMap.put(campOrder.CampaignProduct__c, new Set<Id>());
            campIdSetMap.get(campOrder.CampaignProduct__c).add(campOrder.OrderItem__c);

        }
        Map<Id, Order> invalidOrderMap = new Map<Id, Order>();
        campaignMap = new Map<Id, CampaignProduct__c>();
        for(CampaignProduct__c camProd : campMap.values()){
            if(camProd.UsedQuantity__c > camProd.MaxQuantity__c && camProd.MaxQuantity__c != 0){
                if(!campIdSetMap.containsKey(camProd.Id)) continue;

                for(Id ordItemId : campIdSetMap.get(camProd.Id)){

                    OrderItem ordItem = parentOrderItem.get(ordItemId);
                    
                    Order ords = new Order(Id = ordItem.OrderId);
                    
                    ords.StatusSF__c = 'Retorna RTV';
                    ords.ObservationRTV__c = Label.CampaignError.replace('{prodCode}', ordItem?.Product2?.ProductCode == null ? '' : ordItem?.Product2?.ProductCode )?.replace('{campName}', camProd?.Campaign__r?.Name == null ? '' : camProd?.Campaign__r?.Name);

                    invalidOrderMap.put(ordItem.OrderId, ords);
                }
            }else{
                campaignMap.put(camProd.id, camProd);
            }
        }
        if(!invalidOrderMap.isEmpty()){
            OrderHelper.disableTrigger();
            OrderHelper.updatePath(invalidOrderMap.values());
            update invalidOrderMap.values();
            OrderHelper.enableTrigger();
            System.debug(invalidOrderMap);

            OrderHelper.sendNotificationRTV(invalidOrderMap.keySet());
        }
        return invalidOrderMap;
    }

    public static InventoryQuery queryInventory(Order order) {
        InventoryQuery inventoryQuery = new InventoryQuery();
        inventoryQuery.saleAvailable = true;

        String distributionCenterExternalId = order.SalesTeam__r?.DistributionCenter__r?.ExternalId__c;

        List<String> productExternalIds = new List<String>();
        for (OrderItem orderItem : order.OrderItems) {
            productExternalIds.add(orderItem.Product2.ExternalId__c);
        }

        Map<String, ProductManagement__c> inventoryMapToUpsert = InventoryQueryIntegration.queryInventory(
            new List<String>{distributionCenterExternalId}, productExternalIds, false
        );
        
        Map<String, ProductManagement__c> inventoryKeyToInventory = new Map<String, ProductManagement__c>();
        for (ProductManagement__c inventoryObj : [SELECT Id, ExternalId__c, Block__c, Tolerance__c FROM ProductManagement__c WHERE ExternalId__c IN :inventoryMapToUpsert.keySet()]) {
            inventoryKeyToInventory.put(inventoryObj.ExternalId__c, inventoryObj);
        }

        inventoryQuery.inventoryList = !inventoryMapToUpsert.isEmpty() ? inventoryMapToUpsert.values() : new List<ProductManagement__c>();

        for (OrderItem orderItem : order.OrderItems) {
            String inventoryExternalId = orderItem.Product2.ExternalId__c + '-' + distributionCenterExternalId+'-'+ orderItem.Order.Crop__r.ExternalId__c;
            if (inventoryMapToUpsert.containsKey(inventoryExternalId)) {
                ProductManagement__c inventory = inventoryMapToUpsert.get(inventoryExternalId);

                Decimal tolerance = inventoryKeyToInventory.containsKey(inventoryExternalId) ? inventoryKeyToInventory.get(inventoryExternalId).Tolerance__c : 0;

                Decimal availableStock = inventory.Inventory__c + inventory.FutureInventory__c - inventory.SalesInventory__c + (tolerance == null ? 0 : tolerance);

                if (inventory.UnitMeasurement__c == orderItem.UnitMeasure__c && availableStock < orderItem.Quantity) {
                    if (inventoryKeyToInventory.containsKey(inventoryExternalId) && inventoryKeyToInventory.get(inventoryExternalId).Block__c) {
                        inventoryQuery.saleAvailable = false;

                        order.DeletedProductProcessSap__c = true;
                        order.StatusSF__c = 'Retorna RTV';
                        order.ContainStockError__c = true;
                        order.ObservationRTV__c = Label.StockError.replace('{productName}', orderItem.Product2.Name);
    
                        OrderHelper.updatePath(new List<Order>{order});
                        
                        orderItem.DeletedProductSAP__c = true;
                        orderItem.ContainStockError__c  = true;
                    }

                }
            }
        }

        if (inventoryQuery.saleAvailable == false) {            
            if(Approval.isLocked(order.id)) Approval.unlock(order.id);
            
            OrderHelper.disableTrigger();
            OrderHelper.updatePath(new List<Order>{order});
            OrderHelper.sendNotificationRTV(new Set<Id>{order.Id});
            update order;
            OrderHelper.enableTrigger();
        }

        return inventoryQuery;

    }

    public static void updateOrders(List<Order> allOrders, IntegrationUtils.CalloutResponse calloutResponse){
        try{
            System.debug('calloutResponse: ' + calloutResponse);
            List<Order> orderList = new List<Order>();
            if (calloutResponse.success) {
                
                ResponseParameters resp = (ResponseParameters) calloutResponse.parsedResponse;
                List<ResponseMessageWrapper> respMessageWrapperList = (List<ResponseMessageWrapper>) resp.responses.Mensagens;
                HttpResponse requisitionResponse = (HttpResponse) calloutResponse.requisition;
                Map<String, Order> orderMap = new Map<String, Order>();

                for (Order ord : allOrders) {
                    orderMap.put(ord.OrderNumber, ord);
                }

                System.debug('orderMap: ' + orderMap);
                System.debug('resp: ' + resp);
                System.debug('respMessageWrapperList: ' + respMessageWrapperList);
                System.debug('requisitionResponse.getStatusCode(): ' + String.valueOf(requisitionResponse.getStatusCode()));
                
                if (orderMap.containsKey(resp.responses.OrderNumber)) {
                    System.debug('deu certo confia');
                    Order ord = orderMap.get(resp.responses.OrderNumber);
                    if(requisitionResponse != null){
                        System.debug('resp.responses.NumeroOrdemVenda: ' + resp.responses.NumeroOrdemVenda);
                        if (requisitionResponse.getStatusCode() != 200) {
                            System.debug('Error Possibility2');
                            ord.ContainIntegrationError__c = true;
                            ord.IntegrationErrorMessage__c = requisitionResponse.getStatus();
                        }
                        else{
                            if(resp.responses.NumeroOrdemVenda != null){
                                ord.ExternalId__c = resp.responses.NumeroOrdemVenda;
                                ord.StatusSF__c = 'Integrado';
                                ord.StatusSAP__c = '1';
                            }
                            ord.ContainIntegrationError__c = false;
                            ord.IntegrationErrorMessage__c = '';
                            System.debug('ordExternalId: ' + ord.ExternalId__c);
                        } 
                    }
                    else{
                        ord.ContainIntegrationError__c = true;
                        ord.IntegrationErrorMessage__c = calloutResponse.errorMessage;
                    }
                    if(respMessageWrapperList != null){
                        for(ResponseMessageWrapper respMessageWrapper : respMessageWrapperList){
                            if(respMessageWrapper.Tipo == 'E'){
                                ord.ContainIntegrationError__c = true;
                                ord.IntegrationErrorMessage__c = ord.IntegrationErrorMessage__c + ' | ' + respMessageWrapper.Mensagem;
                            }
                        }
                    }               
                    orderList.add(ord);
                    System.debug('orderList: ' + orderList);
                }else{
                    for(Order ord : allOrders){
                        System.debug('bacana banana');

                        if(requisitionResponse != null){
                            if (requisitionResponse.getStatusCode() != 200) {
                                System.debug('caiu no erro emmm 2');
                                ord.ContainIntegrationError__c = true;
                                ord.IntegrationErrorMessage__c = requisitionResponse.getStatus();
                            }
                            else{
                                if(resp.responses.NumeroOrdemVenda != null){
                                    ord.ExternalId__c = resp.responses.NumeroOrdemVenda;
                                    ord.StatusSF__c = 'Integrado';
                                    ord.StatusSAP__c = '1';
                                }
                                ord.ContainIntegrationError__c = false;
                                ord.IntegrationErrorMessage__c = '';
                            }
                        }
                        else{
                            ord.ContainIntegrationError__c = true;
                            ord.IntegrationErrorMessage__c = calloutResponse.errorMessage;
                        }
                        if(respMessageWrapperList != null){
                            for(ResponseMessageWrapper respMessageWrapper : respMessageWrapperList){
                                if(respMessageWrapper.Tipo == 'E'){
                                    ord.ContainIntegrationError__c = true;
                                    ord.IntegrationErrorMessage__c = ord.IntegrationErrorMessage__c + ' | ' + respMessageWrapper.Mensagem;
                                }
                            }
                        }
                        orderList.add(ord);
                    }
                }
            }else{
                System.debug('DEU ERRO - SUCCESS FALSE');
                
                HttpResponse requisitionResponse = (HttpResponse) calloutResponse.requisition;

                Map<String, Order> orderMap = new Map<String, Order>();

                for (Order ord : allOrders) {
                    orderMap.put(ord.CustomerOrderNumber__c, ord);
                }

                System.debug('orderMap: ' + orderMap);

                for(Order ord : allOrders){
                    if(requisitionResponse != null){
                        if (requisitionResponse.getStatusCode() != 200) {
                            ord.ContainIntegrationError__c = true;
                            ord.IntegrationErrorMessage__c = requisitionResponse.getStatus();
                        }
                        else{
                            ord.ContainIntegrationError__c = true;
                            ord.IntegrationErrorMessage__c = calloutResponse.errorMessage;
                        }
                    }
                    else{
                        ord.ContainIntegrationError__c = true;
                        ord.IntegrationErrorMessage__c = calloutResponse.errorMessage;
                    }
                    orderList.add(ord);
                }
            }

            if (!orderList.isEmpty()) {
                Set<Id> ordIdSet = new Set<Id>(Collection.of(orderList).pluckIds());
                Map<Id, Order> ordExtenalIdMap = new Map<Id, Order>([SELECT id, ExternalId__c, StatusSAP__c FROM Order WHERE Id IN :ordIdSet AND ExternalId__c != null]);
                List<OrderItem> orderItemList = [
                    SELECT Id, Product2.ProductCode, OrderId, Product2.Name
                    FROM OrderItem
                    WHERE OrderID IN: ordIdSet
                ];
                Map<Id, List<OrderItem>> orderIdToOrderItemList = new Map<Id, List<OrderItem>>();
                for (OrderItem orderItem : orderItemList) {
                    if (orderIdToOrderItemList.containsKey(orderItem.OrderId)) {
                        orderIdToOrderItemList.get(orderItem.OrderId).add(orderItem);
                    } else {
                        orderIdToOrderItemList.put(orderItem.OrderId, new List<OrderItem>{orderItem});
                    }
                }
                List<OrderItem> orderItemToUpdate = new List<OrderItem>();
                Set<Id> ordIdObServationSet = new Set<Id>();
                Map<Id, String> prodStringMap = new Map<Id, String>();
                for(Order ord : orderList){
                    if (ord.ContainIntegrationError__c == true) {
                        Boolean integrationError = false;
                        Boolean hasIntegrationSOPError = false;
                        for (OrderItem orderItem : orderIdToOrderItemList.get(ord.Id)) {
                            if(ord.IntegrationErrorMessage__c.contains(orderItem.Product2.ProductCode)){
                                if(ord.IntegrationErrorMessage__c.contains(Label.ErrorIntegrationProduct) || ord.IntegrationErrorMessage__c.contains(Label.ErrorIntegrationBloqueioSOPProduct)){
                                    orderItem.DeletedProductSAP__c = true;
                                    prodStringMap.put(ord.id, orderItem.Product2.Name);
                                    integrationError = true;
                                }
                                hasIntegrationSOPError =  ord.IntegrationErrorMessage__c.contains(Label.ErrorIntegrationBloqueioSOPProduct);
                            }
                            else {
                                orderItem.DeletedProductSap__c = false;      
                            } 
                            orderItemToUpdate.add(orderItem);
                        }
                        if(integrationError){
                            OrderHelper.clearFields(ord);
                            ord.DeletedProductProcessSap__c = true;
                            ord.StatusSF__c = 'Retorna RTV';
                            ord.ObservationRTV__c = hasIntegrationSOPError ? Label.ReturnProductSOP.replace('{prodCode}', prodStringMap.get(ord.id)) : Label.ReturnProductDeletedOrder.replace('{prodCode}', prodStringMap.get(ord.id));
                            ordIdObServationSet.add(ord.id);
                        }
                        else{
                            ord.DeletedProductProcessSap__c = false;
                        }    
                    }
                    
                    if(Approval.isLocked(ord.id)){
                        Approval.unlock(ord.id);
                    }
                    
                    if(ordExtenalIdMap.containsKey(ord.id)){
                        ord.ContainIntegrationError__c = false;
                        ord.IntegrationErrorMessage__c = '';                 
                        ord.StatusSAP__c = ordExtenalIdMap.get(ord.id).StatusSAP__c;                 
                    }
                }

                OrderHelper.disableTrigger();
                OrderHelper.updatePath(orderList);
                update orderList;
                OrderHelper.enableTrigger();

                if(!orderItemToUpdate.isEmpty()){
                    update orderItemToUpdate;
                }
                if(!ordIdObServationSet.isEmpty())
                    OrderHelper.sendNotificationRTV(ordIdObServationSet);
                for(Id ordId : ordIdSet){
                    Approval.lock(ordId);
                }
            }
        }catch(Exception ex){
            IntegrationLog.createIntegrationLog('Order Outbound Integration Exception', 'Outbound', ex.getMessage()+', '+ex.getStackTraceString(), JSON.serialize(allOrders), true, IntegrationUtils.createExternalIdsStringOut(allOrders));
        }
	}

	public static IntegrationUtils.CalloutResponse sendOrder(List<Order> orders, Map<Id, Map<Id, List<ShippingDivision__c>>> orderIdToOrderItemIdToShippingDivisionListMap) {

		List<RequestParameters> request = new List<RequestParameters>();

        String payload;
        
        Map<String,Integration__c> integrations = Integration__c.getAll();
        System.debug('integrations: ' + integrations);
        String integrationMethod = integrations.get('IntegrationOrder').Method__c;
        String integrationEndPoint = integrations.get('IntegrationOrder').Endpoint__c;
        String integrationUser = integrations.get('IntegrationOrder').Username__c;
        String integrationPassword = integrations.get('IntegrationOrder').Password__c;

		for (Order ord : orders) {
			request.add(new RequestParameters(ord, orderIdToOrderItemIdToShippingDivisionListMap.get(ord.Id)));
            payload = JSON.serialize(new RequestParameters(ord, orderIdToOrderItemIdToShippingDivisionListMap.get(ord.Id)));
		}

		if(integrations.get('IntegrationOrder').Inactive__c){
            IntegrationUtils.updateErrorOrder(orders);
			IntegrationLog.createIntegrationLog('Order Outbound Integration', 'Outbound', Label.InactiveIntegration, payload, true);
            return new IntegrationUtils.CalloutResponse(Label.InactiveIntegration, null);
		}

		//String payload = JSON.serialize(new Request(request));
        // -> DEU CERTO PARCIALMENTE String payload = JSON.serialize(request);
        Blob headerValue = Blob.valueOf(integrationUser + ':' + integrationPassword);

		//Metodo para busca de Access Token, depende de cada projeto, podendo estar presente dentro de uma custom settings ou relacionado com outra requisição.
		
        //String accessToken = 'Basic Uy1JRlNGT1JDRTpjNHEkNkQlL1QjQTZZOHVhR2Q0TGNBO0JJXC1cJ3NeYA==';
        String accessToken = 'Basic ' + EncodingUtil.base64Encode(headerValue);
		
		//Path geralmente cadastrado dentro de ua customSettings
		String endpoint = (!Test.isRunningTest() ? integrationEndPoint : 'http://callout.My_Named_Credential.com/some/path');
		Map<String, String> headersMap = new Map<String, String>();
		headersMap.put('Content-type', 'application/json');
		headersMap.put('Authorization', accessToken);
		
		IntegrationUtils.RequestResponseObject responseObject = IntegrationUtils.executeCallout(endpoint, payload, headersMap, integrationMethod);
        System.debug('response Object: ' + responseObject);
        HttpResponse response = responseObject.response;
        IntegrationUtils.CalloutResponse calloutResponse;
		if (responseObject.success) {
            System.debug('RESPONSESENDORDER: ' + responseObject);
            try {
				ResponseParametersWrapper responses = (ResponseParametersWrapper) JSON.deserialize(response.getBody(), ResponseParametersWrapper.class);
				calloutResponse = new IntegrationUtils.CalloutResponse(new ResponseParameters(responses), response);
			} catch (Exception e) {
				
				String defaultErrorMessage = 'Malformatted HTTP Response Exception: ' + e.getMessage();

				calloutResponse = new IntegrationUtils.CalloutResponse(defaultErrorMessage, response);
			}
            updateOrders(orders, calloutResponse);
			IntegrationLog.createIntegrationLog('Order Outbound Integration', 'Outbound', response.getBody(), payload, false, IntegrationUtils.createExternalIdsStringOut(orders));
		} else {
            calloutResponse = new IntegrationUtils.CalloutResponse(responseObject.exceptionObject.getMessage(), response);
            updateOrders(orders, calloutResponse);
			IntegrationLog.createIntegrationLog('Order Outbound Integration', 'Outbound', responseObject.exceptionObject.getMessage(), payload, true, IntegrationUtils.createExternalIdsStringOut(orders));
		}
        return calloutResponse;
	}

    public class Request {
        public List<RequestParameters> request;
        public Request(List<RequestParameters> request) {
            this.request = request;
        }
    }

	public class RequestParameters {
		//Order Fields
		//Example
        public String CodigoSAP;
        public String TipoPedido;
		public String CodigoSalesforce;
        public String TradeSlipCode;
        public Date DataPagamento;
        public String TipoDocumento;
        public String Safra;
        public String CondicaoPagamento;
        public String FormaPagamento;
        public Date DataVencimento;
        //public String Status;
        public String NumeroPedidoCliente;
        public String MotivoOrdem;
        //public Decimal ValorFrete;
        //public Decimal PrecoTotal;
        //public Decimal PrecoTotalSemFrete;
        public String PedidoPai;
        //public String TipoReferenciaPedidoPai;
        public String OrganizacaoVendas;
        public String CanalDistribuicao;
        public String SetorAtividade;
        public String EscritorioVendas;
        public String EquipeVendas;
        public String ModalidadeFrete;
        public Date DataPedido;
        public String NumeroContrato;
        public Date DataInicioContrato;
        public Date DataFimContrato;
        public TextosParameters[] Textos;
		public OrderItemParameters[] Itens;
        public PartnersParameters[] Parceiros;

		public RequestParameters(Order ord, Map<Id,List<ShippingDivision__c>> orderItemIdToShippingDivisionListMap) {
            Map<String,String> MapStringToString = new Map<String,String>();
            Boolean hasFreight = false;

            this.TipoPedido = ord.Type == null ? 'SFOR' : ord.Type;
            this.CodigoSAP = ord.ExternalId__c;
			this.CodigoSalesforce = ord.OrderNumber;
            this.DataPagamento = ord.PaymentDate__c;
            this.TradeSlipCode = ord.TradeSlipCode__c;
            //this.TipoDocumento = ord.RecordType.DeveloperName;

            System.Debug('DeveloperName: ' + ord.RecordType.DeveloperName);
            if(ord.RecordType.DeveloperName == 'CurrencySale'){
                this.TipoDocumento = 'ZVNO';
            }
            else if((ord.RecordType.DeveloperName == 'IndustryBonification') || (ord.RecordType.DeveloperName == 'LavoroBonification')){
                this.TipoDocumento = 'ZVBO';
            }
            else if(ord.RecordType.DeveloperName == 'FutureSale'){
                this.TipoDocumento = 'ZVEF';
            }
            else if(ord.RecordType.DeveloperName == 'ExchangeSale'){
                this.TipoDocumento = 'ZVTP';
            }
            else if(ord.RecordType.DeveloperName == 'BarterSale'){
                //this.TipoDocumento = 'ZVTR';
                this.TipoDocumento = 'ZCTR';
                //Barter ContractField
                this.DataInicioContrato = ord.ContractStartDate__c;
                this.DataFimContrato = ord.ContractEndDate__c;
            }
            else if(ord.RecordType.DeveloperName == 'AccountOrder'){
                this.TipoDocumento = 'ZVC0';
            }
            else if(ord.RecordType.DeveloperName == 'ZVTR'){
                this.TipoDocumento = 'ZVTR';
            }
            else if(ord.RecordType.DeveloperName == 'ZVTF'){
                this.TipoDocumento = 'ZVTF';
            }
            else if(ord.RecordType.DeveloperName == 'ZVTS'){
                this.TipoDocumento = 'ZVTS';
            }
            else if(ord.RecordType.DeveloperName == 'ZCCO'){
                this.TipoDocumento = 'ZCCO';
                this.DataInicioContrato = ord.ContractStartDate__c;
                this.DataFimContrato = ord.ContractEndDate__c;
            }
            else if(ord.RecordType.DeveloperName == 'ZCNO'){
                this.TipoDocumento = 'ZCNO';
                this.DataInicioContrato = ord.ContractStartDate__c;
                this.DataFimContrato = ord.ContractEndDate__c;
            }
            else if(ord.RecordType.DeveloperName == 'ZCEF'){
                this.TipoDocumento = 'ZCEF';
                this.DataInicioContrato = ord.ContractStartDate__c;
                this.DataFimContrato = ord.ContractEndDate__c;
            }
            else{
                this.TipoDocumento = 'ZVNO';
            }

            List<Date> dateList = new List<Date>();
            for(List<ShippingDivision__c> sdList : orderItemIdToShippingDivisionListMap.values()){
                for(ShippingDivision__c sd : sdList){
                    dateList.add(sd.DeliveryDate__c);
                }
            }
            dateList.sort();
            if(DataPagamento <= dateList[0] && this.TipoDocumento == 'ZVNO'){
                this.TipoDocumento = 'ZVAV';
            }
            

            this.Safra = ord.Crop__r.ExternalId__c;
            this.CondicaoPagamento = ord.PaymentCondition__r.ExternalId__c;
            this.FormaPagamento = ord.PaymentForm__c;
            this.DataVencimento = ord.EndDate;
            //this.Status = ord.StatusSAP__c;
            this.NumeroPedidoCliente = ord.CustomerOrderNumber__c;
            this.MotivoOrdem = ord.OrderMotive__c;
            //this.ValorFrete = ord.TotalFreightValue__c;
            //this.PrecoTotal = ord.TotalAmount;
            //this.PrecoTotalSemFrete = ord.TotalAmountWithFreight__c;
            this.PedidoPai = ord.OriginalOrder.ExternalId__c;
            //this.TipoReferenciaPedidoPai = ord.ParentOrderReferenceType__c;
            this.OrganizacaoVendas = ord.SalesOrg__r.ExternalId__c;
            this.CanalDistribuicao = ord.DistributionChannel__c;
            this.SetorAtividade = ord.ActivitySector__c;
            this.EscritorioVendas = ord.SalesOffice__r.ExternalId__c;

            if(ord.SalesTeam__r.BillingSalesTeam__c != null) {
                this.EquipeVendas = ord.SalesTeam__r.BillingSalesTeam__r.ExternalId__c;
            }
            else{
                this.EquipeVendas = ord.SalesTeam__r.ExternalId__c;
            }
            
            
            //this.ModalidadeFrete = ord.Freight__c;
            this.DataPedido = ord.CreatedDate.date();

            if(ord.Description != null){
                this.Textos = getTextList(ord.Description);
            }
            else{
                List<TextosParameters> textList = new List<TextosParameters>();
                TextosParameters text = new TextosParameters(null,'');
                textList.add(text);
                this.Textos = textList;
            }
            this.Textos.add(new TextosParameters('TX03', ord.OrderRoute__c));
			this.Itens = new List<OrderItemParameters>();
			for (OrderItem ordIt : Ord.OrderItems) {
				Itens.add(new OrderItemParameters(ord, ordIt, ord.SalesCondition__c, ord.Currency__c, orderItemIdToShippingDivisionListMap.get(ordIt.Id)));
                if(ordIt.FreightValue__c != null){
                    hasFreight = true;
                }
			}

            if(hasFreight){
                this.ModalidadeFrete = 'Y1';
            }
            else{
                this.ModalidadeFrete = 'Z1';
            }
            if(ord.AccountId != null){
                MapStringToString.put('AG', ord.Account.ExternalId__c);
            }
            if(ord.RTV__c != null){
                MapStringToString.put('ZV',ord.RTV__r.ExternalId__c);
            }
            if(ord.ShippingAccount__c != null){
                //MapStringToString.put('WE',ord.ShippingAccount__c);
                MapStringToString.put('WE', ord.ShippingAccount__r.ExternalId__c);
            }
            this.Parceiros = new List<PartnersParameters>();
            for(String typeKey : MapStringToString.keySet()){
                Parceiros.add(new PartnersParameters(typeKey, MapStringToString.get(typeKey)));
            }
		}
	}

    public class TextosParameters{
        public String TextoId {get;set;}
        public String  Texto {get;set;}

        public TextosParameters(String i, String description){
            this.TextoId = i;
            this.Texto = description;
        }
    }
     
    public static TextosParameters[] getTextList(String descriptionsAll){
        List<TextosParameters> textsList = new List<TextosParameters>();
        List<String> allStringList = descriptionsAll.split('\n');
    
        for(String descriptions : allStringList){
            Integer maxSize = Integer.valueOf((descriptions.length() < 132 ? 1 : Decimal.valueOf(descriptions.length()/132)).round(System.RoundingMode.CEILING));
            for(integer i = 0; i < maxSize; i++){
                Integer finalLength = (i*132) + 132;        
                textsList.add(new TextosParameters(String.valueOf(i), Descriptions.subString((i*132), finalLength > Descriptions.length() ? Descriptions.length() : finalLength )));
            }
        }
        return textsList;
    }

    public class PartnersParameters {
        public String TipoParceiro;
        public String CodigoSAP;

        public PartnersParameters(String typeKey, String values){
            this.TipoParceiro = typeKey;
            this.CodigoSAP = values;
        }
    }

	public class OrderItemParameters {
		//OrderItem Fields
		//Example
        public String NoItemPedidoCliente;
        public Decimal Quantidade;
        public String Centro;
        public String NumeroContrato;
        public String ItemContrato;
        public Decimal QuantidadeFaturada;
        public String Material;
        public String IDCultura;
        public String ModalidadeFrete;
        //public String Status;
        public String UnidadeMedida;
        public String ListaPreco;
        public String MotivoRecusa;
        public String Incoterms1;
        public Date DataListaPreco;
        public String Incoterms2;
        public ItemValuesParameters[] ValoresItem;
        public ShippingDivisionParameters[] DivisaoRemessa;

        

		public OrderItemParameters(Order ord, OrderItem ordIt, string listPriceType, String moeda, List<ShippingDivision__c> shippingDivisionList) {
            Map<String,Decimal> MapTypeToValue = new Map<String,Decimal>();
            Boolean hasFreight = false;

            this.NoItemPedidoCliente = ordIt.SAPNumber__c;
            this.NumeroContrato = ord.ContractOrder__c != null ? ord.ContractOrder__r.ExternalId__c : null;
            this.ItemContrato = ord.ContractOrder__c != null ? ordIt.ContractOrderItem__r.SAPNumber__c : null;
            this.Quantidade = ordIt.Quantity;
            this.Centro = ordIt.Center__r.ExternalId__c;
            this.QuantidadeFaturada = ordIt.BilledQuantity__c;
            this.Material = ordIt.Product2.ExternalId__c;
            this.IDCultura = ordIt.Culture__r.ExternalId__c;
            //this.ModalidadeFrete = ordIt.Freight__c;
            //this.Status = ordIt.Status__c;
            this.UnidadeMedida = ordIt.UnitMeasure__c;
            this.ListaPreco = listPriceType;
            this.MotivoRecusa = ordIt.RefuseReason__c;
            this.DataListaPreco = ordIt.LastChangedPriceList__c;

            if(ordIt.Freight__c == 'CIF'){
                this.ModalidadeFrete = 'Y1';
            }
            else{
                this.ModalidadeFrete = 'Z1';
            }

            this.Incoterms1 = ordIt.Incoterms1__c;
            this.Incoterms2 = ordIt.Incoterms2__c;
            
            if(ordIt.CustomListPrice__c == null || ordIt.FixedUnitPriceCampaign__c){
                MapTypeToValue.put((ordIt.FixedUnitPriceCampaign__c ? 'ZPR1' : 'ZPR0'), ordIt.UnitPrice.setScale(2));
            } 
            else{
                MapTypeToValue.put((ordIt.FixedUnitPriceCampaign__c ? 'ZPR1' : 'ZPR0'),ordIt.CustomListPrice__c.setScale(2));
            }
            //if(ordIt.CustomListPrice__c != null){
            //    MapTypeToValue.put('PR00',ordIt.CustomListPrice__c);
            //}
            if(ordIt.DiscountPercent__c != null && ordIt.DiscountPercent__c > 0){
                MapTypeToValue.put('ZK07',ordIt.DiscountPercent__c * -1);
            }
            if(ordIt.AdditionPercent__c != null && ordIt.AdditionPercent__c > 0){
                MapTypeToValue.put('ZK07', ordIt.AdditionPercent__c);
            }
            if(ordIt.CampaigPercent__c != null && ordIt.CampaigPercent__c != 0){
                MapTypeToValue.put('ZK09', ordIt.CampaigPercent__c * -1);
            }
            if(ordIt.CampaignIndustryPercent__c != null && ordIt.CampaignIndustryPercent__c != 0){
                MapTypeToValue.put('ZPCA', ordIt.CampaignIndustryPercent__c * -1);
            }
            //if(ordIt.InterestOrAntecipationDiscount__r.interestValue__c != null){
            //    MapTypeToValue.put('ZD01',ordIt.InterestOrAntecipationDiscount__r.interestValue__c);
            //}
            if(ordIt.OfferDiscount__c != null){
                MapTypeToValue.put('ZDOF',ordIt.OfferDiscount__c);
            }
            if(ordIt.FreightValue__c != null){
                MapTypeToValue.put('ZF00',ordIt.FreightValue__c);
            }

            this.ValoresItem = new List<ItemValuesParameters>();
            for(String typeKey : MapTypeToValue.keySet()){
                ValoresItem.add(new ItemValuesParameters(typeKey, MapTypeToValue.get(typeKey), moeda));
            }

            this.DivisaoRemessa = new List<ShippingDivisionParameters>();
            for(ShippingDivision__c division : shippingDivisionList){
                DivisaoRemessa.add(new ShippingDivisionParameters(division));
            }
		}
	}

    public class ItemValuesParameters{
        public String TipoCondicao;
        public Decimal ValorCondicao;
        public String Moeda;

        public ItemValuesParameters(String typeKey, Decimal valueCondition, String moeda){
            this.TipoCondicao = typeKey;
            this.ValorCondicao = valueCondition;
            this.Moeda = moeda;
        }
    }

    public class ShippingDivisionParameters{
        public String NumeroDivisao;
        public Date DataDivisao;
        public Decimal Quantidade;
        //public Decimal QuantidadeConfirmada;
        
        public ShippingDivisionParameters(ShippingDivision__c division){
            this.NumeroDivisao = division.SAPNumber__c;
            this.DataDivisao = division.DeliveryDate__c;
            this.Quantidade = division.Quantity__c;
            //this.QuantidadeConfirmada = division.ConfirmedQuantity__c;
        }
    }
	public class ResponseParameters {
		public ResponseParametersWrapper responses;
        
		public ResponseParameters(ResponseParametersWrapper responses) {
			this.responses = responses;
		}
	}

	public class ResponseParametersWrapper {
        public String NumeroOrdemVenda;
        public String OrderNumber;
        public List<ResponseMessageWrapper> Mensagens;
	}

    public class ResponseMessageWrapper {
        public String Tipo;
        public String Mensagem;
    }

    
    public class InventoryQuery {
        public Boolean saleAvailable;
        public List<ProductManagement__c> inventoryList;
    }

    /*
    public static HttpResponse getInfoFromExternalService(){
        Map<String,Integration__c> integrations = Integration__c.getAll();
        String integrationEndPoint = integrations.get('IntegrationOrder').Endpoint__c;
        String integrationMethod = integrations.get('IntegrationOrder').Method__c;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(integrationEndPoint);
        req.setMethod(integrationMethod);
        Http h = new Http();
        HttpResponse res = h.send(req);
        return res;
    }
    */
}