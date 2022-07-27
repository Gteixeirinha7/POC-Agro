public without sharing class CalloutGrainPurchaseContract {
    @InvocableMethod
    public static void invocableProcessIntegration(List<Id> listOrderId){
        IntegrationUtils.CalloutResponse calloutResponse = processIntegration(listOrderId);
    }
    
    // CalloutGrainPurchaseContract.processIntegration(new List<Id>{'8015Y000002rPttQAE'});
    public static IntegrationUtils.CalloutResponse processIntegration(List<Id> listOrderId){
        Set<Id> orderItemIdSet = new Set<Id>();
        //HttpResponse response;
		List<Order> parentOrders = [
            SELECT Id, RecordType.DeveloperName, OrderNumber, BarterType__c, ShippingCrop__r.ExternalId__c, Currency__c, DistributionCenter__r.ExternalId__c, EndDate, Incoterms1__c, CommodityProduct2Id__r.ConvertWeightbags__c,  CommodityProduct2Id__r.ExternalId__c, CommodityShipping__c, TotalDeliveryQuantity__c, PaymentDate__c,
            InitialDeliveryDate__c, EndDeliveryDate__c, CreatedDateApp__c, CreatedDate, GrossUnitPrice__c, ProductionPickupLocation__c, ProductionDeliveryLocation__c, UnitPrice__c, Account.ExternalId__c, Commodity__c, ShippingCrop__c, ShippingCrop__r.StartDate__c, ShippingCrop__r.EndDate__c, DeliveryQuantity__c,
            BillingCrop__c, BillingCrop__r.StartDate__c, BillingCrop__r.EndDate__c,
                (
                    SELECT Id, ExternalId__c, Product2.ExternalId__c
                    FROM OrderItems
                )
            FROM Order 
            WHERE Id IN: listOrderId];


		List<Order> allOrders = parentOrders;
		Set<Id> approvedOrderIdsSet = new Set<Id>();

		IntegrationUtils.CalloutResponse calloutResponse = sendOrder(allOrders);
        System.debug('CalloutResponse Results: ' + calloutResponse);
		if (calloutResponse.success) {
			ResponseParameters resp = (ResponseParameters) calloutResponse.parsedResponseGrainPurchaseContract;
            List<ResponseMessageWrapper> respMessageWrapperList = (List<ResponseMessageWrapper>) resp.responses.Mensagens;
            HttpResponse requisitionResponse = (HttpResponse) calloutResponse.requisition;
			Map<String, Order> orderMap = new Map<String, Order>();

			for (Order ord : allOrders) {
				orderMap.put(ord.OrderNumber, ord);
			}

			List<Order> orderList = new List<Order>();
            for(Order ord : allOrders){

                if(requisitionResponse != null){
                    if (requisitionResponse.getStatusCode() != 200) {
                        ord.ContainIntegrationError__c = true;
                        ord.IntegrationErrorMessage__c = requisitionResponse.getStatus();
                    }
                    else{
                        if(resp.responses.NumeroNegociacao != null && resp.responses.NumeroNegociacao != '0000000000'){
                            ord.GrainTableApproval__c = false;
                            approvedOrderIdsSet.add(ord.Id);
                            ord.TradeSlipCode__c = resp.responses.NumeroNegociacao;
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
            //}

			if (!orderList.isEmpty()) {
                OrderHelper.disableTrigger();
				update orderList;
                OrderHelper.enableTrigger();
			}
            if(!approvedOrderIdsSet.isEmpty()){
                //OrderHelper.disableTrigger();
                CreateOrderController.callApprovalProcess(approvedOrderIdsSet);
                //OrderHelper.enableTrigger();
            }
		}
		else{
            System.debug('DEU ERRO - SUCCESS FALSE');
            
            HttpResponse requisitionResponse = (HttpResponse) calloutResponse.requisition;

            Map<String, Order> orderMap = new Map<String, Order>();
            List<Order> orderList = new List<Order>();	

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

            if (!orderList.isEmpty()) {
                OrderHelper.disableTrigger();
				update orderList;
                OrderHelper.enableTrigger();
			}
        }
		return calloutResponse;
	}

	public static IntegrationUtils.CalloutResponse sendOrder(List<Order> orders) {

		List<RequestParameters> request = new List<RequestParameters>();

        String payload;
        
        Map<String,Integration__c> integrations = Integration__c.getAll();
        System.debug('integrations: ' + integrations);
        String integrationMethod = integrations.get('IntegrationGrainPurchaseContract').Method__c;
        String integrationEndPoint = integrations.get('IntegrationGrainPurchaseContract').Endpoint__c;
        String integrationUser = integrations.get('IntegrationGrainPurchaseContract').Username__c;
        String integrationPassword = integrations.get('IntegrationGrainPurchaseContract').Password__c;

		for (Order ord : orders) {
			request.add(new RequestParameters(ord));
            payload = JSON.serialize(new RequestParameters(ord));
		}

		if(integrations.get('IntegrationGrainPurchaseContract').Inactive__c){
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
        System.debug('response Objecto: ' + responseObject);
        HttpResponse response = responseObject.response;
		if (responseObject.success) {
            System.debug('RESPONSESENDORDER: ' + responseObject);
			IntegrationLog.createIntegrationLog('Order Grain Purchase Contract Outbound Integration', 'Outbound', response.getBody(), payload, false);
            System.debug('Response Try: ' + response);
            System.debug('Response getBody Try: ' + response.getBody());

			try {
				ResponseParametersWrapper responses = (ResponseParametersWrapper) JSON.deserialize(response.getBody(), ResponseParametersWrapper.class);
                System.debug('Responses do Try: ' + responses);
				return new IntegrationUtils.CalloutResponse(new ResponseParameters(responses), response);
			} catch (Exception e) {
				
				String defaultErrorMessage = 'Malformatted HTTP Response Exception: ' + e.getMessage();

				return new IntegrationUtils.CalloutResponse(defaultErrorMessage, response);
			}
		} else {
			IntegrationLog.createIntegrationLog('Order Outbound Integration', 'Outbound', responseObject.exceptionObject.getMessage(), payload, true);
			return new IntegrationUtils.CalloutResponse(responseObject.exceptionObject.getMessage(), response);
		}
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
		public String CodigoSalesforce;
        public String TipoDocumento;
        public String TipoContrato;
        public String Moeda;
        public String Centro;
        public Date DataEntrega;
        public String Incoterms1;
        public String Quantidade;
        public Date DataPagamento;
        public String AnoSafra;
        public Date DataNegociacao;
        public Double PrecoFechado;
        public String Parceiro;
        public String ProdutoAgricola;

        public Double PrecoUnitario;
        public Date DataInicioEntrega;
        public Date DataFimEntrega;
        public String LocalRetirada;

        String Material;

		public RequestParameters(Order ord) {

			this.CodigoSalesforce = ord.OrderNumber;
            //this.TipoDocumento = ord.RecordType.DeveloperName;
            if(ord.RecordType.DeveloperName != 'BarterSale'){
                this.TipoDocumento = 'ZVNO';
            }
            else{
                this.TipoDocumento = 'ZBPD';
            }
            this.TipoContrato = ord.BarterType__c;
            this.Moeda = ord.Currency__c;
            this.Centro = ord.DistributionCenter__r.ExternalId__c;
            this.DataEntrega = ord.EndDate;
            this.Incoterms1 = ord.CommodityShipping__c;
            this.Quantidade = String.valueof(ord.DeliveryQuantity__c * (ord.CommodityProduct2Id__r.ConvertWeightbags__c == null ? 60 : ord.CommodityProduct2Id__r.ConvertWeightbags__c));
            this.DataPagamento = Date.valueOf(ord.PaymentDate__c);
            this.AnoSafra = getCorrectCrop(ord.ShippingCrop__r.ExternalId__c);
            if(ord.CreatedDateApp__c != null){
                this.DataNegociacao = ord.CreatedDateApp__c;
            }
            else{
                this.DataNegociacao = ord.CreatedDate.date();
            }
            this.PrecoFechado = ord.GrossUnitPrice__c;
            this.PrecoUnitario = ord.UnitPrice__c;
            this.DataInicioEntrega = ord.InitialDeliveryDate__c;
            this.DataFimEntrega = ord.EndDeliveryDate__c;


            if(ord.CommodityShipping__c == 'CIF' || ord.CommodityShipping__c == 'FCA'){
                this.LocalRetirada = ord.ProductionDeliveryLocation__c;    
            }
            else{
                this.LocalRetirada = ord.ProductionPickupLocation__c;
            }

            this.Parceiro = ord.Account.ExternalId__c;
            this.ProdutoAgricola = ord.CommodityProduct2Id__r.ExternalId__c;
            
            for(OrderItem ordIt : ord.OrderItems){
                this.Material = ordIt.Product2.ExternalId__c;
            }
		}
        public string getCorrectCrop(String crop){
            return crop == null ? null : '20'+crop.split('/')[0]+'/'+'20'+crop.split('/')[1]; 
        }
	}

	public class ResponseParameters {
		public ResponseParametersWrapper responses;
        
		public ResponseParameters(ResponseParametersWrapper responses) {
			this.responses = responses;
		}
	}

	public class ResponseParametersWrapper {
        public String CodigoSalesforce;
        public String NumeroNegociacao;
        public List<ResponseMessageWrapper> Mensagens;
	}

    public class ResponseMessageWrapper {
        public String Tipo;
        public String Mensagem;
    }
}