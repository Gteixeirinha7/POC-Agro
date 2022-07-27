public class IntegrationUtils {
    //#region IN
    //String check
    public static Boolean convertEmptyString(String str) {
        return ((String.isBlank(str) || str == 'null' || str == null || str == '') ? true : false); 
    }
    
    //Records upsert validation, adding results to the response list
    public static Boolean upsertRecords(List<Database.UpsertResult> upsResults, List<TemplateDataIntegrationFields.Response> responseList, List<SObject> sObjectListToUpsert, Schema.SObjectField field){
        TemplateDataIntegrationFields.Response responseData;
        Boolean hasError = false;
        for (TemplateDataIntegrationFields.Response response : responseList) {
            if(response.status == false)
				hasError = true;                
        }

        for(Integer i = 0; i < upsResults.size(); i++){
            responseData = new TemplateDataIntegrationFields.Response();

            SObject objResult = sObjectListToUpsert[i];
            Database.UpsertResult upsResult = upsResults[i];

            if (upsResult.isSuccess()) {
                responseData.success(
                    upsResult.getId(), 
                    String.valueOf(objResult.get(field)), 
                    String.valueOf(objResult.getSObjectType())
                );
            }
            else if(upsResult.getId() != null){
                responseData.error(
                    upsResult.getId(),
                    String.valueOf(objResult.get(field)),
                    upsResult.getErrors()[0].getMessage().replace('Campos obrigatórios ausentes', 'Valor inválido para o campo obrigatório'), 
                    String.valueOf(objResult.getSObjectType())
                );
                System.debug('responseData2' + responseData);
                hasError = true;
            }
            else {
                responseData.error(
                    String.valueOf(objResult.get(field)),
                    upsResult.getErrors()[0].getMessage().replace('Campos obrigatórios ausentes', 'Valor inválido para o campo obrigatório'), 
                    String.valueOf(objResult.getSObjectType())
                );
                System.debug('responseData3' + responseData);
                hasError = true;
            }
            responseList.add(responseData);
        }
        System.debug('responseDatareturn');
        return hasError;
    }

    //Records upsert validation for Parent Records, adding results to the response list
    public static Boolean upsertRecords(List<Database.UpsertResult> upsResults, List<TemplateDataIntegrationFields.ResponseParent> responseList, List<SObject> sObjectListToUpsert, Schema.SObjectField field){
        TemplateDataIntegrationFields.ResponseParent responseData;
        Boolean hasError = false;
        for (TemplateDataIntegrationFields.Response response : responseList) {
            if(response.status == false)
				hasError = true;                
        }

        for(Integer i = 0; i < upsResults.size(); i++){
            responseData = new TemplateDataIntegrationFields.ResponseParent();

            SObject objResult = sObjectListToUpsert[i];
            Database.UpsertResult upsResult = upsResults[i];

            if (upsResult.isSuccess()) {
                responseData.success(
                    upsResult.getId(), 
                    String.valueOf(objResult.get(field)), 
                    String.valueOf(objResult.getSObjectType())
                );
            }
            else if(upsResult.getId() != null){
                responseData.error(
                    upsResult.getId(),
                    String.valueOf(objResult.get(field)),
                    upsResult.getErrors()[0].getMessage().replace('Campos obrigatórios ausentes', 'Valor inválido para o campo obrigatório'), 
                    String.valueOf(objResult.getSObjectType())
                );
                hasError = true;
            }
            else {
                responseData.error(
                    String.valueOf(objResult.get(field)),
                    upsResult.getErrors()[0].getMessage().replace('Campos obrigatórios ausentes', 'Valor inválido para o campo obrigatório'), 
                    String.valueOf(objResult.getSObjectType())
                );
                hasError = true;
            }
            responseList.add(responseData);
        }
        return hasError;
    }

    //Child records upsert validation, adding results to the response list
    public static void upsertChildRecords(List<Database.UpsertResult> upsResults, Map<String, List<TemplateDataIntegrationFields.Response>> responseMap, List<SObject> sObjectListToUpsert, Schema.SObjectField field){
        TemplateDataIntegrationFields.Response responseData;
        System.debug('upsResults'+upsResults);
        for(Integer i = 0; i < upsResults.size(); i++){
            responseData = new TemplateDataIntegrationFields.Response();

            SObject objResult = sObjectListToUpsert[i];

            Database.UpsertResult upsResult = upsResults[i];
            
            if(upsResult.isSuccess()){
                responseData.success(
                    upsResult.getId(), 
                    String.valueOf(objResult.get(field)), 
                    String.valueOf(objResult.getSObjectType())
                ); 
            }
            else {
                responseData.error(
                    String.valueOf(objResult.get(field)), 
                    upsResult.getErrors()[0].getMessage().replace('Campos obrigatórios ausentes', 'Valor inválido para o campo obrigatório'), 
                    String.valueOf(objResult.getSObjectType())
                );
            }
            
            //Associating child object's response with object response
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
            if (objResult.getSObjectType() == globalDescribe.get('AccountTeamMember')) {
                AccountTeamMember aux = (AccountTeamMember)objResult;
                if(responseMap.keySet().contains(aux.AccountId)){
                    responseMap.get(aux.AccountId).add(responseData);
                }
                else{
                    responseMap.put(aux.AccountId, new List<TemplateDataIntegrationFields.Response>{responseData});
                }
            }
            else if (objResult.getSObjectType() == globalDescribe.get('OrderItem')) {
                OrderItem aux = (OrderItem)objResult;
                if(responseMap.keySet().contains(aux.OrderId)){
                    responseMap.get(aux.OrderId).add(responseData);
                }
                else{
                    responseMap.put(aux.OrderId, new List<TemplateDataIntegrationFields.Response>{responseData});
                }
            }
            else if (objResult.getSObjectType() == globalDescribe.get('ShippingDivision__c')) {
                ShippingDivision__c aux = (ShippingDivision__c)objResult;
                if(responseMap.keySet().contains(aux.OrderItem__c)){
                    responseMap.get(aux.OrderItem__c).add(responseData);
                }
                else{
                    responseMap.put(aux.OrderItem__c, new List<TemplateDataIntegrationFields.Response>{responseData});
                }
            }
        }
    }
    //#endregion

    public static String createExternalIdsString(List<Sobject> objectList){
        List<String> externalIds = new List<String>();

        List<String> externalKeyFields = new List<String>{
            'OVSAP__c',
            'ExternalId__c',
            'Codigo__c',
            'IdSAP__c',
            'IDMetaSAP__c'
        };

        String externalKeyField;

        if (objectList != null && objectList.size() != 0) {
            String externalId = null;
            for (String field : externalKeyFields) {
                try {
                    objectList[0].getSObjectType().newSObject().get(field);
                    externalKeyField = field;
                    break;
                } catch (Exception e) {}
            }
            if (!String.isEmpty(externalKeyField)) {
                for (SObject obj : objectList) {
                    externalId = String.valueOf(obj.get(externalKeyField));
                    if((String.join(externalIds, '-').length() + externalId.length()) < 255) externalIds.add(externalId);
                    else return String.join(externalIds, '-');
                }
                return String.join(externalIds, '-');
            }
        }
        return null;
    }

    public static String createExternalIdsStringOut(List<Sobject> objectList){
        List<String> externalIds = new List<String>();

        List<String> externalKeyFields = new List<String>{
            'OrderNumber',
            'ExternalId__c',
            'Id'
        };

        String externalKeyField;

        if (objectList != null && objectList.size() != 0) {
            String externalId = null;
            for (String field : externalKeyFields) {
                try {
                    objectList[0].getSObjectType().newSObject().get(field);
                    externalKeyField = field;
                    break;
                } catch (Exception e) {}
            }
            if (!String.isEmpty(externalKeyField)) {
                for (SObject obj : objectList) {
                    externalId = String.valueOf(obj.get(externalKeyField));
                    if((String.join(externalIds, '-').length() + externalId.length()) < 255) externalIds.add(externalId);
                    else return String.join(externalIds, '-');
                }
                return String.join(externalIds, '-');
            }
        }
        return null;
    }

    public static String createExternalIdsDelimitedLand(List<Sobject> objectList){
        List<String> externalIds = new List<String>();

        List<String> externalKeyFields = new List<String>{
            'CodigoAgrometrika__c '
        };

        String externalKeyField;

        if (objectList != null && objectList.size() != 0) {
            String externalId = null;
            for (String field : externalKeyFields) {
                try {
                    objectList[0].getSObjectType().newSObject().get(field);
                    externalKeyField = field;
                    break;
                } catch (Exception e) {}
            }
            if (!String.isEmpty(externalKeyField)) {
                for (SObject obj : objectList) {
                    externalId = String.valueOf(obj.get(externalKeyField));
                    if((String.join(externalIds, '-').length() + externalId.length()) < 255) externalIds.add(externalId);
                    else return String.join(externalIds, '-');
                }
                return String.join(externalIds, '-');
            }
        }
        return null;
    }

    //#region OUT
    public static Boolean SYSTEM_DEBUG_ENABLED   = true;

    public class RequestResponseObject {
        // Response object, in case the callout was successful.
        public HttpResponse response;
        // Boolean that determines if there is an exception or a HttpResponse.
        public Boolean success;
        // Exception object, in case there is any.
        public Exception exceptionObject;

        public RequestResponseObject(HttpResponse response){
            this.success = true;
            this.response = response;
            this.exceptionObject = null;
        }

        public RequestResponseObject(Exception ex){
            this.success = false;
            this.response = null;
            this.exceptionObject = ex;
        }
    }

    
    // CALLOUT STANDARD RESPONSE OUTTER CLASS
    public class CalloutResponse{
		public CalloutOrder.ResponseParameters parsedResponse;
		public DelimitedLandIntegration.ResponseParameters parsedResponseDelimitedLand;
        public CalloutGrainPurchaseContract.ResponseParameters parsedResponseGrainPurchaseContract;   
        public Boolean success;
		public String errorMessage;
        public HttpResponse requisition;

        public CalloutResponse(String errorMessage, HttpResponse requisition){
			this.success = false;
			this.errorMessage = errorMessage;
			this.parsedResponse = null;
            this.parsedResponseGrainPurchaseContract = null;
            this.requisition = requisition;
		}

        //#region CalloutOrderResponse
		public CalloutResponse(CalloutOrder.ResponseParameters response, HttpResponse requisition){
			this.success = true;
			this.errorMessage = '';
			this.parsedResponse = response;
            this.requisition = requisition;
		}

        public CalloutResponse(String errorMessage, CalloutOrder.ResponseParameters response, HttpResponse requisition){
			this.success = false;
			this.errorMessage = errorMessage;
			this.parsedResponse = response;
            this.requisition = requisition;
		}
        //#endregion

        //#region DelimitedLandResponse
		public CalloutResponse(DelimitedLandIntegration.ResponseParameters response, HttpResponse requisition){
			this.success = true;
			this.errorMessage = '';
			this.parsedResponseDelimitedLand = response;
            this.requisition = requisition;
		}

        public CalloutResponse(String errorMessage, DelimitedLandIntegration.ResponseParameters response, HttpResponse requisition){
			this.success = false;
			this.errorMessage = errorMessage;
			this.parsedResponseDelimitedLand = response;
            this.requisition = requisition;
		}
        //#endregion

        //#region CalloutGrainPurchaseContractResponse
        public CalloutResponse(CalloutGrainPurchaseContract.ResponseParameters response, HttpResponse requisition){
			this.success = true;
			this.errorMessage = '';
			this.parsedResponseGrainPurchaseContract = response;
            this.requisition = requisition;
		}

        public CalloutResponse(String errorMessage, CalloutGrainPurchaseContract.ResponseParameters response, HttpResponse requisition){
			this.success = false;
			this.errorMessage = errorMessage;
			this.parsedResponseGrainPurchaseContract = response;
            this.requisition = requisition;
		}
        //#endregion
    
	}
    // CALLOUT PARSING INNER INTERFACE
    public interface CalloutResponseParsedData{}

    public class CalloutResponseCreditLimit{
		public CalloutCreditLimit.ResponseParametersWrapper parsedResponse;      
        public Boolean success;
		public String errorMessage;
        public HttpResponse requisition;
		public CalloutResponseCreditLimit(CalloutCreditLimit.ResponseParametersWrapper response, HttpResponse requisition){
			this.success = true;
			this.errorMessage = '';
			this.parsedResponse = response;
            this.requisition = requisition;
		}

		public CalloutResponseCreditLimit(String errorMessage, HttpResponse requisition){
			this.success = false;
			this.errorMessage = errorMessage;
			this.parsedResponse = null;
            this.requisition = requisition;
		}

        public CalloutResponseCreditLimit(String errorMessage, CalloutCreditLimit.ResponseParametersWrapper response, HttpResponse requisition){
			this.success = false;
			this.errorMessage = errorMessage;
			this.parsedResponse = response;
            this.requisition = requisition;
		}
	}

    public static RequestResponseObject executeCallout(String namedCredential, String payload, Map<String, String> requestHeaders, String method){
        HttpRequest request = new HttpRequest();
        request.setMethod(method);
        // Timeout reduced in 10000 miliseconds in order to avoid timeouts in invoke actions through javascript.
        request.setTimeout(110000);
        request.setEndpoint(namedCredential);
        if(payload != '' || method != 'GET')
            request.setBody(payload);

        
        if (requestHeaders != null && requestHeaders.size() > 0){
            for (String headerKey : requestHeaders.keySet()){
                request.setHeader(headerKey, requestHeaders.get(headerKey));
            }
        }

        Long microtime = (Datetime.now()).getTime();
        if (SYSTEM_DEBUG_ENABLED){
            System.debug('EXECUTING WITH NAMED CREDENTIAL: '+namedCredential);
            System.debug('METHOD USED: '+request.getMethod());
            System.debug('SENT PAYLOAD: '+payload);
            System.debug('payload: ' + JSON.serializePretty(payload));
            System.debug('SENT HEADERS: '+JSON.serializePretty(requestHeaders));
        }

        HttpResponse response;
        try {
            response = (new Http()).send(request);

            if (SYSTEM_DEBUG_ENABLED){
                System.debug('RESPONSE IN '+((Datetime.now()).getTime() - microtime));
                System.debug('RESPONSE STATUS: '+response.getStatus()+' - '+String.valueOf(response.getStatusCode()));
                for (String headerKey : response.getHeaderKeys()){
                    if (String.isNotBlank(headerKey)) System.debug('HEADER KEY: '+headerKey+' | VALUE: '+response.getHeader(headerKey));
                }

                System.debug(response);
                System.debug('RESPONSE BODY: '+response.getBody());
            }

            return new RequestResponseObject(response);
        } catch (Exception ex) {
            if (SYSTEM_DEBUG_ENABLED) System.debug('CALLOUT EXCEPTION: '+ex.getMessage());

            return new RequestResponseObject(ex);
        }
    }
    

	public static String validSpecialCaracter(String value){
		Map<String,String> mapaAcentosHex = new Map<String, String>{
			'a' => '[à-æ]',
			'A' => '[À-Æ]',
			'e' => '[è-ë]',
			'E' => '[È-Ë]',
			'o' => '[ò-ö]',
			'O' => '[Ò-Ö]',
			'u' => '[ù-ü]',
			'U' => '[Ù-Ü]',
			'i' => '[ì-ï]',
			'c' => '[ç]',
			'C' => '[Ç]',
			'n' => '[ñ]',
			'N' => '[Ñ]',
			'I' => '[Ì-̈Ï]'};

		for (String letra : mapaAcentosHex.keySet()) {
			value = value.replaceAll(mapaAcentosHex.get(letra), letra);
		}
		return value;
	}
    //#endregion
    public static void updateErrorOrder(Order [] orders){
        for(Order ord : orders){
            ord.ContainIntegrationError__c = true;
            ord.IntegrationErrorMessage__c = Label.InactiveIntegration;
        }
        OrderHelper.disableTrigger();
        update orders;
        OrderHelper.enableTrigger();
    }

    public static void updateErrorDelimitedLand(DelimitedLand__c [] delimitedLandList){
        for(DelimitedLand__c delimitedLand : delimitedLandList){
            delimitedLand.MessageOutbound__c = Label.InactiveIntegration;
        }
        DelimitedLandTriggerHelper.disableTrigger();
        update delimitedLandList;
        DelimitedLandTriggerHelper.enableTrigger();
    }
}