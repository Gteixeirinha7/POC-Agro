public with sharing class CalloutCreditLimit {
    
    @InvocableMethod
    public static void invocableQueryCreditLimit(List<String> requests){
        
        IntegrationUtils.CalloutResponseCreditLimit calloutResponse = queryCreditLimit(requests[0]);
    }
    
    //public static IntegrationUtils.CalloutResponseCreditLimit queryCreditLimit(String request){
    //    
    //
	//	RequestParameters creditLimit = (RequestParameters)JSON.deserialize(request, RequestParameters.class);
	//	
	//	IntegrationUtils.CalloutResponseCreditLimit calloutResponse = sendCreditLimitRequest(creditLimit);
    //    System.debug('calloutResponse: ' + calloutResponse);
	//	return calloutResponse;
	//}

	public static IntegrationUtils.CalloutResponseCreditLimit queryCreditLimit(String payload) {
        
        //Metodo para busca de Access Token, depende de cada projeto, podendo estar presente dentro de uma custom settings ou relacionado com outra requisição.
        Map<String,Integration__c> integrations = Integration__c.getAll();
        //System.debug('integrations: ' + integrations);
        String integrationMethod = integrations.get('IntegrationCreditLimit').Method__c;
        String integrationEndPoint = integrations.get('IntegrationCreditLimit').Endpoint__c;
        String integrationUser = integrations.get('IntegrationCreditLimit').Username__c;
        String integrationPassword = integrations.get('IntegrationCreditLimit').Password__c;

		if(integrations.get('IntegrationCreditLimit').Inactive__c){
			IntegrationLog.createIntegrationLog('Credit Limit Query', 'Outbound', Label.InactiveIntegration, payload, true);
			return new IntegrationUtils.CalloutResponseCreditLimit(Label.InactiveIntegration, null);
		}

        Blob headerValue = Blob.valueOf(integrationUser + ':' + integrationPassword);
		
        //String accessToken = 'Basic Uy1JRlNGT1JDRTpjNHEkNkQlL1QjQTZZOHVhR2Q0TGNBO0JJXC1cJ3NeYA==';
        String accessToken = 'Basic ' + EncodingUtil.base64Encode(headerValue);
		
		//Path geralmente cadastrado dentro de uma customSettings
		String endpoint = (!Test.isRunningTest() ? integrationEndPoint : 'http://callout.My_Named_Credential.com/some/path');
		Map<String, String> headersMap = new Map<String, String>();
		headersMap.put('Content-type', 'application/json');
		headersMap.put('Authorization', accessToken);
		
		IntegrationUtils.RequestResponseObject responseObject = IntegrationUtils.executeCallout(endpoint, payload, headersMap, integrationMethod);
        System.debug('response Object: ' + responseObject);
        HttpResponse response = responseObject.response;
		if (responseObject.success) {
            System.debug('RESPONSESCREDITLIMIT: ' + responseObject);
			IntegrationLog.createIntegrationLog('Credit Limit Query', 'Outbound', response.getBody(), payload, false);
            
			try {
				ResponseParametersWrapper responses = (ResponseParametersWrapper) JSON.deserialize(response.getBody(), ResponseParametersWrapper.class);
				return new IntegrationUtils.CalloutResponseCreditLimit(responses, response);
			} catch (Exception e) {
				
				String defaultErrorMessage = 'Malformatted HTTP Response Exception: ' + e.getMessage();

				return new IntegrationUtils.CalloutResponseCreditLimit(defaultErrorMessage, response);
			}
		} else {
			IntegrationLog.createIntegrationLog('Credit Limit Query', 'Outbound', responseObject.exceptionObject.getMessage(), payload, true);
			return new IntegrationUtils.CalloutResponseCreditLimit(responseObject.exceptionObject.getMessage(), response);
		}
	}

    //public class Request {
    //    public List<RequestParameters> request;
    //    public Request(List<RequestParameters> request) {
    //        this.request = request;
    //    }
    //}

	//public class RequestParameters {
	//	//Integration Fields
	//	//Example
    //    public String Cliente;
	//	  public String Cultura;
    //    public String Moeda;
	//}

	//public class ResponseParameters {
	//	public ResponseParametersWrapper responses;
    //    
	//	public ResponseParameters(ResponseParametersWrapper responses) {
	//		this.responses = responses;
	//	}
	//}

	public class ResponseParametersWrapper {
        public String  Rating;
        public String  Valor;
        public Boolean Bloqueio;
        public List<ResponseMessageWrapper> Mensagens;
	}

    public class ResponseMessageWrapper {
        public String Tipo;
        public String Mensagem;
    }
}