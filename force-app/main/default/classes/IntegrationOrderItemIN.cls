//@RestResource(urlMapping='/upsertOrderItem/*')
global with sharing class IntegrationOrderItemIN {
    //OrderItem upsert integration

    //@HttpPost
    global static Map<String, List<TemplateDataIntegrationFields.Response>> upsertOrderItem(List<TemplateDataIntegrationFields.OrderItemINData> request, String standardPricebook, Set<Id> ordInvalidIdSet){
        Map<String, Id> lookups = new Map<String, Id>();

        Set<String> orderItemLookups = new Set<String>();
        Set<String> orderLookups = new Set<String>();
        Set<String> distributionCenterLookups = new Set<String>();
        Set<String> productLookups = new Set<String>();
        Set<String> cultureLookups = new Set<String>();
        Set<String> priceListLookups = new Set<String>();

        Map<String, List<TemplateDataIntegrationFields.Response>> responseMap = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        Map<String, List<TemplateDataIntegrationFields.ShippingDivisionINData>> shippingDivisionMapToUpsert = new Map<String, List<TemplateDataIntegrationFields.ShippingDivisionINData>>();
        List<TemplateDataIntegrationFields.ShippingDivisionINData> shippingDivisionListToUpsert = new List<TemplateDataIntegrationFields.ShippingDivisionINData>();
        
        List<OrderItem> orderItemListToUpsert = new List<OrderItem>();

        Set<Id> ordIdSet = new Set<Id>();
        //Application of business rules
        for(TemplateDataIntegrationFields.OrderItemINData orderItem : request){

            //Getting orderItem parameters to search
            orderItemLookups.add(orderItem.RelatedOrderId + '|' + orderItem.NoItemPedidoCliente);
            ordIdSet.add(orderItem.RelatedOrderId);
            //Getting order parameters to search
            //orderLookups.add(orderItem.RelatedOrderExternalId);
            //Getting distributionCenter parameters to search
            distributionCenterLookups.add(orderItem.Centro);
            //Getting product parameters to search
            productLookups.add(orderItem.Material);
            //Getting culture parameters to search
            cultureLookups.add(orderItem.IDCultura);
            //Getting priceList parameters to search
            priceListLookups.add(orderItem.ListaPreco);

            //Getting Values parameters
            if(orderItem.ValoresItem != null) {
                for(TemplateDataIntegrationFields.ItemValueINData valoresItem : orderItem.ValoresItem){
                    if(valoresItem.TipoCondicao == 'ZPR0' || valoresItem.TipoCondicao == 'ICMI'){
                        orderItem.PrecoUnitario = valoresItem.ValorCondicao;
                    }
                    else if(valoresItem.TipoCondicao == 'PR00'){
                        orderItem.PrecoLista = valoresItem.ValorCondicao;
                    }
                    else if(valoresItem.TipoCondicao == 'ZK07'){
                        orderItem.Desconto = valoresItem.ValorCondicao;
                    }
                    else if(valoresItem.TipoCondicao == 'ZDOF'){
                        orderItem.DescontoOferta = valoresItem.ValorCondicao;
                    }
                    else if(valoresItem.TipoCondicao == 'ZF00'){
                        orderItem.ValorFrete = valoresItem.ValorCondicao;
                    }
                }
            }

            if(orderItem.DivisaoRemessa != null) {
                Decimal quantityShip = 0;
                
                for(TemplateDataIntegrationFields.ShippingDivisionINData shippingDivision: orderItem.DivisaoRemessa){
                    shippingDivision.RelatedOrderItemExternalId = orderItem.NoItemPedidoCliente;

                    //quantityShip = shippingDivision.QuantidadeConfirmada != null ? shippingDivision.QuantidadeConfirmada : (shippingDivision.Quantidade != null ? shippingDivision.Quantidade : 0);
                }
                if(orderItem.MotivoRecusa != null){
                    orderItem.DivisaoRemessa.add(new TemplateDataIntegrationFields.ShippingDivisionINData((orderitem.Quantidade != null ? orderitem.Quantidade : 0) - (orderitem.QuantidadeFaturada != null ? orderitem.QuantidadeFaturada : 0), orderItem));
                }
                //Getting list of order items schedules
                //system.debug(orderItem.DivisaoRemessa);
                shippingDivisionMapToUpsert.put(orderItem.RelatedOrderId + '|' + orderItem.NoItemPedidoCliente, new List<TemplateDataIntegrationFields.ShippingDivisionINData>(orderItem.DivisaoRemessa));
            }
            
        }

        Map<Id, String> ordStatusOldMap = new Map<Id, String>();
        //OrderItem search based on ExternalId__c field sent
        for (OrderItem orderItem : OrderItemDAO.getOrderItemByExternalId(new List<String>(orderItemLookups), new Set<String>{'Id', 'ExternalId__c', 'OrderId', 'Status__c'})) {
            //Map structure for the model -> object name + parameter to record id
            lookups.put('OrderItem' + orderItem.OrderId + '|' + orderItem.ExternalId__c, orderItem.Id);
            ordStatusOldMap.put(orderItem.id, orderItem.Status__c);
        }

        for(Order ord : [SELECT id, RTV__c FROM Order WHERE id IN : ordIdSet]){
            lookups.put('OrderRTV' + ord.Id, ord.RTV__c);
        }
        
        //Order search based on ExternalId__c field sent
        //for (Order order : OrderDAO.getOrderByExternalId(new List<String>(orderLookups), new Set<String>{'Id', 'ExternalId__c'})) {
        //    //System.debug(order);
        //    //Map structure for the model -> object name + parameter to record id
        //    lookups.put('Order' + order.ExternalId__c, order.Id);
        //}

        //DistributionCenter search based on ExternalId__c field sent
        for (DistributionCenter__c distributionCenter : DistributionCenterDAO.getDistributionCenterByExternalId(new List<String>(distributionCenterLookups), new Set<String>{'Id', 'ExternalId__c'})) {
            //Map structure for the model -> object name + parameter to record id
            lookups.put('DistributionCenter' + distributionCenter.ExternalId__c, distributionCenter.Id);
        }
        
        ////Product2 search based on ExternalId__c field sent
        //for (Product2 product : [SELECT Id, ExternalId__c, (Select Id FROM PricebookEntries WHERE Pricebook2Id =: standardPricebook ) FROM Product2 WHERE ExternalId__c IN: productLookups]) {
        //    //Map structure for the model -> object name + parameter to record id
        //    lookups.put('Product2' + product.ExternalId__c, product.Id);
        //    system.debug(product.PricebookEntries[0]);
        //    lookups.put('PricebookEntry' + product.ExternalId__c, product.PricebookEntries[0].Id);
        //}

        //Product2 search based on ExternalId field sent
        for (Product2 product : [SELECT Id, ExternalId__c, (Select Id FROM PricebookEntries WHERE Pricebook2Id =: standardPricebook ) FROM Product2 WHERE ExternalId__c IN: productLookups]) {
            //Map structure for the model -> object name + parameter to record id
            lookups.put('Product2' + product.ExternalId__c, product.Id);
            //system.debug(product.PricebookEntries[0]);
            lookups.put('PricebookEntry' + product.ExternalId__c, product.PricebookEntries[0].Id);
        }

        //Culture search based on ExternalId__c field sent
        for (Culture__c culture : CultureDAO.getCultureByExternalId(new List<String>(cultureLookups), new Set<String>{'Id', 'ExternalId__c'})) {
            //Map structure for the model -> object name + parameter to record id
            lookups.put('Culture' + culture.ExternalId__c, culture.Id);
        }

        //ListPrice search based on ExternalId__c field sent
        for (ListPrice__c listPrice : ListPriceDAO.getListPriceByExternalId(new List<String>(priceListLookups), new Set<String>{'Id', 'ExternalId__c'})) {
            //Map structure for the model -> object name + parameter to record id
            lookups.put('PriceList' + listPrice.ExternalId__c, listPrice.Id);
        }
        
        //OrderItem ExternalId Map to Order ExternalId for association of responses
        Map<String, String> parentMapKeys = new Map<String, String>();
        for(TemplateDataIntegrationFields.OrderItemINData orderItem : request) {
            parentMapKeys.put(orderItem.RelatedOrderId + '|' + orderItem.NoItemPedidoCliente, orderItem.RelatedOrderId);
        }
        //System.debug('parentMapKeys: ' + parentMapKeys);

        //Converting template to object list and validating required fields
        FactoryDataIntegration.convertSObjectChild(
            new OrderItem(), 
            'IN', 
            request, 
            responseMap, 
            orderItemListToUpsert, 
            lookups, 
            parentMapKeys
        );

        system.debug(responseMap);

        //Upserting records
        IntegrationUtils.upsertChildRecords(
            Database.upsert(orderItemListToUpsert, OrderItem.ExternalId__c, false), 
            responseMap, 
            orderItemListToUpsert, 
            OrderItem.ExternalId__c
        );

        system.debug(responseMap);
        

        Set<Id> ordCanceledIdSet = new Set<Id>();
        for(OrderItem orderItem: orderItemListToUpsert){
            if(shippingDivisionMapToUpsert.containsKey(orderItem.ExternalId__c) && orderItem.Id != null){
                for(TemplateDataIntegrationFields.ShippingDivisionINData shippingDivisionINData : shippingDivisionMapToUpsert.get(orderItem.ExternalId__c)){
                    shippingDivisionINData.RelatedOrderItemId = orderItem.Id;
                }
                shippingDivisionListToUpsert.addAll(shippingDivisionMapToUpsert.get(orderItem.ExternalId__c));
            }
            if(!ordInvalidIdSet.contains(orderItem.OrderId) && orderItem.Status__c == 'X' && ordStatusOldMap.containsKey(orderItem.Id) && ordStatusOldMap.get(orderItem.Id) != orderItem.Status__c){
                ordCanceledIdSet.add(orderItem.Id);
            }
        }
            if(!ordCanceledIdSet.isEmpty()){
                IntegrationOrderIN.reduceCampaign(new Set<Id>(), ordCanceledIdSet);
            }


        //system.debug(shippingDivisionListToUpsert);
        //Upserting records (ShippingDivision)
        Map<String, List<TemplateDataIntegrationFields.Response>> shippingDivisionsResponse = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        if(shippingDivisionListToUpsert.size() != 0){
            shippingDivisionsResponse.putAll(
                IntegrationShippingDivisionIN.upsertShippingDivision(shippingDivisionListToUpsert)
            );
        }
        
        //Associating child object's response with object response
        for(String orderId : responseMap.keySet()){
            for(TemplateDataIntegrationFields.Response orderItemResponse : responseMap.get(orderId)){
                if(orderItemResponse.errorMessage.isEmpty()){
                    List<String> warningList = new List<String>();
                    if(shippingDivisionsResponse.size() != 0 && shippingDivisionsResponse.containsKey(orderItemResponse.idSalesforce)){
                        for(TemplateDataIntegrationFields.Response response: shippingDivisionsResponse.get(orderItemResponse.idSalesforce)){
                            if(response.status == false){
                                warningList.add('Divisão de Remessa ' + response.externalId + ':' + String.join(response.errorMessage, ', '));
                            }
                        }
                    } 
                    if(shippingDivisionsResponse.size() != 0 && shippingDivisionsResponse.containsKey(orderItemResponse.externalId)){
                        system.debug(shippingDivisionsResponse.get(orderItemResponse.externalId));
                        for(TemplateDataIntegrationFields.Response response: shippingDivisionsResponse.get(orderItemResponse.externalId)){
                            if(response.status == false){
                                warningList.add('Divisão de Remessa ' + response.externalId + ':' + String.join(response.errorMessage, ', '));
                            }
                        }
                    }
                    if(!warningList.isEmpty()){
                        orderItemResponse.errorMessage = warningList;
                    }
                    if(shippingDivisionsResponse.size() == 0){
                        orderItemResponse.errorMessage.add('Não há Divisões de Remessa para este Produto do Pedido nesta requisição!');
                    }
                    system.debug('error:' + orderItemResponse.errorMessage);
                }
            }
        }

        //Returning response
        return responseMap;
    }
}