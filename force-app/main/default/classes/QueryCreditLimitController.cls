@RestResource(urlMapping='/ForcaAgroApp/1_0/getCreditLimitData/*')
global class QueryCreditLimitController {
    @HttpPost
    global static CreditLimitResponse queryCreditLimitApp(string payload){
        IntegrationUtils.CalloutResponseCreditLimit response = CalloutCreditLimit.queryCreditLimit(payload);
        System.debug('Response' + JSON.serialize(response.parsedResponse));
        String respPayload = JSON.serialize(response.parsedResponse);
        return (CreditLimitResponse)JSON.deserialize(respPayload, CreditLimitResponse.Class);
    }

    @AuraEnabled
    global static CreditLimitResponse queryCreditLimitScreen(string payload){
        IntegrationUtils.CalloutResponseCreditLimit response = CalloutCreditLimit.queryCreditLimit(payload);
        System.debug('Response' + JSON.serialize(response.parsedResponse));
        String respPayload = JSON.serialize(response.parsedResponse);
        return (CreditLimitResponse)JSON.deserialize(respPayload, CreditLimitResponse.Class);
    }

    //global class CreditLimitRequest{
    //    @AuraEnabled public String  Account                      {get;set;}
    //    @AuraEnabled public String  Culture                      {get;set;}
    //    @AuraEnabled public String  Currency                     {get;set;}
    //}

    global class CreditLimitResponse{
        @AuraEnabled public String  Rating                      {get;set;}
        @AuraEnabled public String  Valor                       {get;set;}
        @AuraEnabled public Boolean Bloqueio                    {get;set;}
        @AuraEnabled public List<ErrorMessage> Mensagens;
    }

    global class ErrorMessage {
        @AuraEnabled public String Tipo;
        @AuraEnabled public String Mensagem;
    }
}
