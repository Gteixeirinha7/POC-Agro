@RestResource(urlMapping='/upsertOrder/*')
global with sharing class IntegrationOrderIN {
     //Order and OrderItems upsert integration

    //      Endpoint -> /services/apexrest/upsertOrder/ 

    //      {
    //    "request": [
    //    {
    //        "CodigoSAP": "",
    //        "CodigoSalesforce": "",
    //        "DataPagamento": "YYYY-MM-DD",
    //        "TipoDocumento": "",
    //        "Safra": "",
    //        "CondicaoPagamento": "",
    //        "FormaPagamento": "",
    //        "DataVencimento": "YYYY-MM-DD",
    //        "Status": "",
    //        "NumeroPedidoCliente" : "",
    //        "MotivoOrdem" : "",
    //        "ValorFrete" : 0.0,
    //        "PrecoTotal" : 0.0,
    //        "PrecoTotalSemFrete" : 0.0,
    //        "PedidoPai": "",
    //        "TipoReferenciaPedidoPai": "",
    //        "OrganizacaoVendas": "",
    //        "CanalDistribuicao": "",
    //        "SetorAtividade": "",
    //        "EscritorioVendas": "",
    //        "EquipeVendas": "",
    //        "Incoterms1": "",
    //        "Incoterms2": "",
    //        "ModalidadeFrete": "",
    //        "DataPedido": "YYYY-MM-DD",
    //        "Textos" : [
    //            {
    //                "TextoId" : "",
    //                "Texto" : ""
    //            },
    //            {
    //                "TextoId" : "",
    //                "Texto" : ""
    //            }
    //        ],
    //        "Itens": [
    //            {
    //                "NoItemPedidoCliente" : "",
    //                "Quantidade" : 0,
    //                "Centro" : "",
    //                "QuantidadeFaturada" : 0,
    //                "Material" : "",
    //                "IDCultura" : "",
    //                "ModalidadeFrete" : "",
    //                "Status" : "",
    //                "UnidadeMedida" : "",
    //                "ListaPreco" : "",
    //                "MotivoRecusa" : "",
    //                "Incoterms1" : "",
    //                "Incoterms2" : "",
    //                "ValoresItem": [
    //                    {
    //                        "TipoCondicao" : "ZPR0",
    //                        "ValorCondicao" : 0.0,
    //                        "Moeda" : ""
    //                    },
    //                    {
    //                        "TipoCondicao" : "PR00",
    //                        "ValorCondicao" : 0.0,
    //                        "Moeda" : ""                        
    //                    },
    //                    {
    //                        "TipoCondicao" : "ZK07",
    //                        "ValorCondicao" : 0.0,
    //                        "Moeda" : ""
    //                    },
    //                    {
    //                        "TipoCondicao" : "ZDOF",
    //                        "ValorCondicao" : 0.0,
    //                        "Moeda" : ""
    //                    },
    //                    {
    //                        "TipoCondicao" : "ZF00",
    //                        "ValorCondicao" : 0.0,
    //                        "Moeda" : ""
    //                    }
    //                ],
    //                "DivisaoRemessa" : [
    //                    {
    //                        "NumeroDivisao" : "",
    //                        "DataDivisao" : "YYYY-MM-DD",
    //                        "Quantidade" : 0,
    //                        "QuantidadeConfirmada" : 0,
    //                "MotivoRecusa" : ""
    //                    },
    //                    {
    //                        "NumeroDivisao" : "",
    //                        "DataDivisao" : "YYYY-MM-DD",
    //                        "Quantidade" : 0,
    //                        "QuantidadeConfirmada" : 0,
    //                "MotivoRecusa" : ""
    //                    }
    //                ]
    //            }
    //        ],     
    //        "Parceiros": [
    //            {
    //                "TipoParceiro" : "AG",
    //                "CodigoSAP" : ""
    //            },
    //            {
    //                "TipoParceiro" : "WE",
    //                "CodigoSAP" : ""
    //            },
    //            {
    //                "TipoParceiro" : "ZV",
    //                "CodigoSAP" : ""
    //            }
    //        ]
    //    }
    //]}

        @HttpPost
        global static ResponseModel upsertOrder(List<TemplateDataIntegrationFields.OrderINData> request) {
            System.debug(JSON.serialize(request));
            
            Map<String,Integration__c> integrations = Integration__c.getAll();
		    if(integrations.containsKey('SAPPedido') && integrations.get('SAPPedido').Inactive__c){
                IntegrationLog.createIntegrationLog('Order Inbound Integration', 'Inbound', JSON.serialize(request), Label.InactiveIntegration, true, null);
                return new ResponseModel(new TemplateDataIntegrationFields.ResponseParent(Label.InactiveIntegration, null));
		    }

            Map<String, Id> lookups = new Map<String, Id>();
            Map<String,String> accountLookups = new Map<String,String>();
            Map<String, String> orderEffectiveDate = new Map<String, String>();
            Map<String, String> orderExternalMap = new Map<String, String>();

            Set<String> orderLookups = new Set<String>();
            Set<String> orderExIdLookups = new Set<String>();
            Set<String> recordTypeLookups = new Set<String>();
            Set<String> cropLookups = new Set<String>();
            Set<String> paymentConditionLookups = new Set<String>();
            Set<String> organizationLookups = new Set<String>();
            Set<String> officeLookups = new Set<String>();
            Set<String> teamLookups = new Set<String>();
            Set<String> userLookups = new Set<String>();

            List<String> orderList = new List<String>();
            List<TemplateDataIntegrationFields.ResponseParent> responseList = new List<TemplateDataIntegrationFields.ResponseParent>();
            Map<String, List<TemplateDataIntegrationFields.OrderItemINData>> orderItemMapToUpsert = new Map<String, List<TemplateDataIntegrationFields.OrderItemINData>>();
            Map<String, Order> orderMap = new Map<String, Order>();
            List<TemplateDataIntegrationFields.OrderItemINData> orderItemListToUpsert = new List<TemplateDataIntegrationFields.OrderItemINData>();
            List<Order> orderListToUpsert = new List<Order>();
    
            for (TemplateDataIntegrationFields.OrderINData order : request){
                if(order.CodigoSalesforce != null){
                    orderList.add(order.CodigoSalesforce);
                }
            }
            Map<String, String> ordMap = new Map<String, String>();
            Map<String, String> ordStatusOldMap = new Map<String, String>();
            for (Order ord : [SELECT Id, SalesTeam__r.ExternalId__c, OrderNumber, StatusSAP__c FROM Order WHERE OrderNumber IN: orderList]){
                ordMap.put(ord.OrderNumber, ord.SalesTeam__r.ExternalId__c);
                ordStatusOldMap.put(ord.id, ord.StatusSAP__c);
            }
            //Application of business rules
            for (TemplateDataIntegrationFields.OrderINData order : request){
                
                if(order.TipoDocumento == 'ZVNO'){
                    order.TipoDocumento = 'Venda Moeda';
                }
                else if(order.TipoDocumento == 'ZVBO'){
                    order.TipoDocumento = 'Bonificação origem Lavoro';
                }
                else if(order.TipoDocumento == 'ZVEF'){
                    order.TipoDocumento = 'Venda Futura';
                }
                else if(order.TipoDocumento == 'ZVTP'){
                    order.TipoDocumento = 'Venda Troca e Permuta';
                }
                else if(order.TipoDocumento == 'ZVTR'){
                    order.TipoDocumento = 'Negociação Barter';
                }

                //Getting Order parameters to search
                if(order.CodigoSalesforce != null)
                    orderLookups.add(order.CodigoSalesforce);
                if(order.PedidoPai != null)
                    orderExIdLookups.add(order.PedidoPai);
                //Getting RecordType parameters to search
                recordTypeLookups.add(order.TipoDocumento);
                //Getting Crop parameters to search
                cropLookups.add(order.Safra);
                //Getting PaymentCondition parameters to search
                paymentConditionLookups.add(order.CondicaoPagamento);
                //Getting SalesOrg parameters to search
                organizationLookups.add(order.OrganizacaoVendas);
                //Getting SalesOffice parameters to search
                officeLookups.add(order.EscritorioVendas);
                //Getting SalesTeam parameters to search
                if(order.CodigoSalesforce != null && ordMap.containsKey(order.CodigoSalesforce)){
                    order.EquipeVendas = ordMap.get(order.CodigoSalesforce);
                }
                teamLookups.add(order.EquipeVendas);

                //Getting Account parameters to search
                if(order.Textos != null) {
                    List<String> texts = new List<String>();
                    for(TemplateDataIntegrationFields.TextAreaINData text : order.Textos){
                        texts.add(text.Texto);
                    }
                    order.AllTextos = String.join(texts, '\n');
                }

                //Getting Account parameters to search
                if(order.Parceiros != null) {
                    for(TemplateDataIntegrationFields.PartnerINData partner : order.Parceiros){
                        
                        if(partner.TipoParceiro != 'ZV'){
                            accountLookups.put(partner.CodigoSAP + '|' + partner.TipoParceiro, partner.CodigoSAP);
                            if(partner.TipoParceiro == 'AG'){
                                order.CodigoSAPAG = partner.CodigoSAP;
                            }
                            else{
                                order.CodigoSAPWE = partner.CodigoSAP;
                            }
                        }
                        else{
                            userLookups.add(partner.CodigoSAP);
                            order.CodigoSAPZV = partner.CodigoSAP;
                        }
                    }
                }
                
                if(order.Itens != null) {
                    //Putting the Order's ExternalId parameter in the OrderItem
                    for (TemplateDataIntegrationFields.OrderItemINData orderItem : order.Itens){
                        if(orderItem.ValoresItem != null){
                            order.Moeda = orderItem.ValoresItem[0].Moeda;
                        }
                        orderItem.IsInsertSAP = String.isBlank(order.CodigoSalesforce);
                    }
                    //Getting list of order items
                    orderItemMapToUpsert.put(order.CodigoSAP, new List<TemplateDataIntegrationFields.OrderItemINData>(order.Itens));
                }
            }

            Map<String, String> ordErrorMap = new Map<String, String>();
            //Order search based on Order OrderNumber field sent
            for (Order order : OrderDAO.getOrderByOrderNumber(new List<String>(orderLookups), new Set<String>{'Id', 'OrderNumber', 'EffectiveDate', 'IntegrationErrorMessage__c', 'ExternalId__c'})) {
                if(order.ExternalId__c != null)
                    lookups.put('OrderExternal' + order.OrderNumber, order.Id);
                lookups.put('Order' + order.OrderNumber, order.Id);
                orderEffectiveDate.put(order.OrderNumber, String.valueOf(order.EffectiveDate));
                orderExternalMap.put(order.OrderNumber, order.ExternalId__C);
                orderExternalMap.put(order.Id, order.ExternalId__C);
                ordErrorMap.put(order.Id, order.IntegrationErrorMessage__c);
            }

            for(Order order : OrderDAO.getOrderByExternalId(new List<String>(orderExIdLookups), new Set<String>{'Id', 'ExternalId__c', 'IntegrationErrorMessage__c'})) {
                lookups.put('Order' + order.ExternalId__c, order.Id);
                ordErrorMap.put(order.Id, order.IntegrationErrorMessage__c);
            }

            //Modifying EffectiveDate if already exist
            for (TemplateDataIntegrationFields.OrderINData Order : request){
                Order.EffectiveDate = orderEffectiveDate.get(Order.CodigoSalesforce);
                Order.CodigoSAPInterno = orderExternalMap.get(Order.CodigoSalesforce);
            }
            
            //RecordType search based on RecordType Name field sent
            for (RecordType rType : RecordTypeDAO.getRecordTypeByNameAndSObjectType(new List<String>(recordTypeLookups), new List<String>{'Order'}, new Set<String>{'Id', 'Name'})) {
                lookups.put('RecordType' + rType.Name, rType.Id);
            }

            //Crop search based on Crop ExternalId field sent
            for (Crop__c crop : CropDAO.getCropByExternalId(new List<String>(cropLookups), new Set<String>{'Id', 'ExternalId__c'})) {
                lookups.put('Crop' + crop.ExternalId__c, crop.Id);
            }

            //Crop search based on Crop ExternalId field sent
            for (PaymentCondition__c paymentCondition : PaymentConditionDAO.getPaymentConditionByExternalId(new List<String>(paymentConditionLookups), new Set<String>{'Id', 'ExternalId__c'})) {
                lookups.put('PaymentCondition' + paymentCondition.ExternalId__c, paymentCondition.Id);
            }
            
            //SalesOrg search based on SalesOrg ExternalId field sent
            for (SalesOrg__c salesOrg : SalesOrgDAO.getSalesOrgByExternalId(new List<String>(organizationLookups), new Set<String>{'Id', 'ExternalId__c'})) {
                lookups.put('SalesOrg' + salesOrg.ExternalId__c, salesOrg.Id);
            }

            //SalesOffice search based on SalesOffice ExternalId field sent
            for (SalesOffice__c salesOffice : SalesOfficeDAO.getSalesOfficeByExternalId(new List<String>(officeLookups), new Set<String>{'Id', 'ExternalId__c'})) {
                lookups.put('SalesOffice' + salesOffice.ExternalId__c, salesOffice.Id);
            }

            //SalesTeam search based on SalesTeam ExternalId field sent
            for (SalesTeam__c salesTeam : SalesTeamDAO.getSalesTeamByExternalId(new List<String>(teamLookups), new Set<String>{'Id', 'ExternalId__c'})) {
                lookups.put('SalesTeam' + salesTeam.ExternalId__c, salesTeam.Id);
            }
    
            String standardPricebook = Pricebook2DAO.getStandardPricebook(new Set<String>{'Id'}).Id;
            lookups.put('StandardPricebook2', standardPricebook);
            
           //Account search based on Account ExternalId field sent
            for (Account account : AccountDAO.getAccountByExternalId(new List<String>(accountLookups.Values()), new Set<String>{'Id', 'ExternalId__c'})) {
                if(accountLookups.get(account.ExternalId__c + '|AG') == account.ExternalId__c){
                    lookups.put('Account' + account.ExternalId__c, account.Id);
                }
                if(accountLookups.get(account.ExternalId__c + '|WE') == account.ExternalId__c){
                    lookups.put('ShippingAccount' + account.ExternalId__c, account.Id);
                }
            }

            //User search based on User ExternalId field sent
            for (User user : UserDAO.getUserByExternalId(new List<String>(userLookups), new Set<String>{'Id', 'ExternalId__c'})) {
                lookups.put('RTV' + user.ExternalId__c, user.Id);
            }
            
            //Converting template to object list and validating required fields
            FactoryDataIntegration.convertSObject(new Order(), 'IN', request, responseList, orderListToUpsert, lookups);
            
            List<Order> ordUpdateList = new List<Order>();
            for (Order order : orderListToUpsert){
                String actualexternalId = orderExternalMap.containsKey(order.id) ? orderExternalMap.get(order.id) : ''; 
                String error = ordErrorMap.containsKey(order.id) ? ordErrorMap.get(order.id) : ''; 
                if(error != null && (error.contains('Read timed out') || error.contains('Connection reset'))){
                	order.ContainIntegrationError__c = false;
                	order.IntegrationErrorMessage__c = '';
                    if(order.id != null && order.ExternalId__c != null && actualexternalId == null){
                        ordUpdateList.add(new Order(Id = order.id, ExternalId__c = order.ExternalId__c));
                        order.id = null;
                    }
                }   
            }
            if(!ordUpdateList.isEmpty()){
                OrderHelper.disableTrigger();
                OrderItemHelper.disableTrigger();
                update ordUpdateList;
                OrderItemHelper.enableTrigger();
                OrderHelper.enableTrigger();
            }
            //Upserting records (Order)
            IntegrationUtils.upsertRecords(
                Database.upsert(orderListToUpsert, Order.Externalid__c, false), 
                responseList, 
                orderListToUpsert, 
                Order.Externalid__c
            );

            Set<Id> ordIdSet = new Set<Id>();
            Set<Id> ordCanceledIdSet = new Set<Id>();
            for(Order order: orderListToUpsert){
                if(orderItemMapToUpsert.containsKey(order.ExternalId__c) && order.Id != null){
                    for(TemplateDataIntegrationFields.OrderItemINData orderItemINData : orderItemMapToUpsert.get(order.ExternalId__c)){
                        orderItemINData.RelatedOrderId = order.Id;
                    }
                    orderItemListToUpsert.addAll(orderItemMapToUpsert.get(order.ExternalId__c));
                    ordIdSet.add(order.Id);
                }
                if(order.StatusSAP__c == 'X' &&  ordStatusOldMap.containsKey(order.Id) && ordStatusOldMap.get(order.Id) != order.StatusSAP__c){
                    ordCanceledIdSet.add(order.Id);
                }
            }
            if(!ordCanceledIdSet.isEmpty()){
                reduceCampaign(ordCanceledIdSet, new Set<Id>());
            }
            
            //Upserting records (OrderItem)
            Map<String, List<TemplateDataIntegrationFields.Response>> orderItemsResponse = new Map<String, List<TemplateDataIntegrationFields.Response>>();
            if(orderItemListToUpsert.size() != 0){
                orderItemsResponse.putAll(
                    IntegrationOrderItemIN.upsertOrderItem(orderItemListToUpsert, standardPricebook, ordCanceledIdSet)
                );
            }

            //System.debug('ResponseOrderItens' + orderItemsResponse);
            //System.debug('Response Outside For: ' + orderItemsResponse.get(responseList[0].idSalesforce));
            //System.debug('Response Outside For: ' + orderItemsResponse.get(responseList[0].externalId));
            //Associating child object's response with object response
            for(TemplateDataIntegrationFields.ResponseParent response : responseList){
                response.items = new List<TemplateDataIntegrationFields.Response>();
                if(orderItemsResponse.size() != 0 && orderItemsResponse.containsKey(response.idSalesforce)){
                    //System.debug('Response inside For: ' + orderItemsResponse.get(response.idSalesforce));
                    response.items.addAll(orderItemsResponse.get(response.idSalesforce));
                    //System.debug('Response after addAll : ' + response.items);
                } 
                if(orderItemsResponse.size() != 0 && orderItemsResponse.containsKey(response.externalId)){
                    //System.debug('Response inside For: ' + orderItemsResponse.get(response.externalId));
                    response.items.addAll(orderItemsResponse.get(response.externalId));
                    //System.debug('Response after addAll : ' + response.items);
                }
            }

            //System.debug('ResponseList' + responseList);
    
            //Checking integration errors to log
            Boolean hasError = false;
    
            for(TemplateDataIntegrationFields.ResponseParent responseOrder : responseList){
                if(responseOrder.status == false){
                    hasError = true;
                    break;
                } else {
                    for(TemplateDataIntegrationFields.Response response : responseOrder.items){
                        if(response.status == false){
                            hasError = true;
                            break;
                        }
                    }
                }
            }
            
            //Creating integration log
            IntegrationLog.createIntegrationLog('Order Inbound Integration', 'Inbound', JSON.serialize(request), JSON.serialize(responseList), hasError, IntegrationUtils.createExternalIdsString(orderListToUpsert));
            
            handleContractCredit(ordIdSet);
            //Returning response
            ResponseModel modelo = new ResponseModel();
            modelo.response = responseList;
            return modelo;
        }
        global static void reduceCampaign(Set<Id> ordIdSet, Set<Id> ordItemIdSet){
            Map<Id, CampaignProduct__c> campMap = new Map<Id, CampaignProduct__c>();
            for(CampaignOrderItem__c campOrder : [SELECT id, OrderItem__c, Campaign__r.Name, CampaignProduct__c, OrderItem__r.Quantity, CampaignProduct__r.MaxQuantity__c, CampaignProduct__r.UsedQuantity__c
                                                FROM CampaignOrderItem__c 
                                                WHERE (OrderItem__r.OrderId IN :ordIdSet OR OrderItem__C IN :ordItemIdSet)
                                                AND OrderItem__C != null
                                                AND CampaignProduct__c != null
                                                AND CampaignProduct__r.UsedQuantity__c != null]){
                if(!campMap.containsKey(campOrder.CampaignProduct__c))
                    campMap.put(campOrder.CampaignProduct__c, new CampaignProduct__c(Id = campOrder.CampaignProduct__c, UsedQuantity__c = campOrder.CampaignProduct__r.UsedQuantity__c));
                                                
                CampaignProduct__c campProd = campMap.get(campOrder.CampaignProduct__c);
                campProd.UsedQuantity__c -= campOrder.OrderItem__r.Quantity;
                campMap.put(campOrder.CampaignProduct__c, campProd); 
            }

            if(!campMap.isEmpty()){
                update campMap.values();
            }
        }
        global static void handleContractCredit(Set<Id> ordIdSet){
            Set<Id> prodIdSet = new Set<Id>();
            Set<Id> contractIdSet = new Set<Id>();
            Set<Id> orderIdSet = new Set<Id>();
            for(OrderItem ordItem : [SELECT id, Order.RecordType.Name, Product2Id, OrderId, Order.ContractOrder__c
                                    FROM OrderItem 
                                    WHERE OrderId IN :ordIdSet OR Order.ContractOrder__c IN :ordIdSet]){
                prodIdSet.add(ordItem.Product2Id);
                if(ordItem.Order.RecordType.Name.contains('Contrato') || ordItem.Order.RecordType.Name.contains('Barter')){
                    contractIdSet.add(ordItem.OrderId);
                }else{
                    orderIdSet.add(ordItem.OrderId);
                    contractIdSet.add(ordItem.Order.ContractOrder__c);
                }
            }
            CreateOrderController.updateProductContractLogic(orderIdSet, contractIdSet, prodIdSet);
        }
        global class ResponseModel {
    
            @TestVisible
            List<TemplateDataIntegrationFields.ResponseParent> response;
    
            public ResponseModel(TemplateDataIntegrationFields.ResponseParent response) {
    
                this.response = new List<TemplateDataIntegrationFields.ResponseParent>{response};
                
            }
            public ResponseModel(List<TemplateDataIntegrationFields.ResponseParent> response) {
    
                this.response = response;
                
            }
            public ResponseModel() {   
                this.response = new List<TemplateDataIntegrationFields.ResponseParent>();         
            }
        }
}