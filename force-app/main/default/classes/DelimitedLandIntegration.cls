public without sharing class DelimitedLandIntegration {

	@InvocableMethod
    public static void invocableProcessIntegration(List<Id> listDelimitedLandId){
        IntegrationUtils.CalloutResponse calloutResponse = processIntegration(listDelimitedLandId);
    }

    public static IntegrationUtils.CalloutResponse processIntegration(List<Id> listDelimitedLandId) {
        IntegrationUtils.CalloutResponse calloutResponse = null;

        try{
            Set<Id> delimitedLandIdSet = new Set<Id>();
            //HttpResponse response;
            List<DelimitedLand__c> delimitedLandList = [
                SELECT Id, Account__c, Account__r.Parent.ExternalId__c, Account__r.ExternalId__c, Account__r.CNPJ__c, Account__r.CPF__c, TotalArea__c, Description__c, Name, AreaCultivatedLand__c, AreaCultivatedLandMeters__c, UnitMeasurement__c, AreaPasture__c, AreaPastureMeteers__c, AreaCultivated__c,
                       AreaCultivatedMeteers__c, AreaPreservation__c, AreaPreservationMeters__c, AreaNotAllocated__c, AreaNotAllocatedMeters__c, AreaTotal__c, ArealTotalMeters__c, AreaCultivatedCulture__c, AreaTotalHec__c
                FROM DelimitedLand__c 
                WHERE Id IN: listDelimitedLandId]; //Culturas_dos_Talhoes

            List<String> accountIds = new List<String>();

            for (DelimitedLand__c delimitedLand : delimitedLandList) {
                accountIds.add(delimitedLand.Account__c);
            }

            List<DelimitedLand__c> completeDelimitedLandList = [
                SELECT Id, Account__c, Account__r.ParentId, Account__r.Parent.Name, Account__r.Parent.ExternalId__c, Account__r.ExternalId__c, TenantCulture__r.AgrometrikaExternalId__c, Account__r.FiscalDomicile__c, Account__r.CNPJ__c, Account__r.CPF__c, TotalArea__c, Description__c, Name, AreaCultivatedLand__c, AreaCultivatedLandMeters__c, UnitMeasurement__c, AreaPasture__c, AreaPastureMeteers__c, AreaCultivated__c,
                       AreaCultivatedMeteers__c, AreaPreservation__c, AreaPreservationMeters__c, AreaNotAllocated__c, AreaNotAllocatedMeters__c, AreaTotal__c, ArealTotalMeters__c, AreaCultivatedCulture__c, AreaTotalHec__c, Tenant__c, TenantArea__c, OwnerName__c, ContractDate__c, TenantCulture__c, TenantTax__c, TenantValue__c
                    //(
                    //    SELECT Id, Culture__c, Crop__r.ExternalId__c, Culture__r.ExternalId__c, Date__c, Crop__c, DelimitedLand__c, AreaCultivated__c, TotalAreaMeters__c
                    //    FROM Culturas_dos_Talhoes
                    //) 
                FROM DelimitedLand__c 
                WHERE Account__c IN: accountIds
                AND (ContractDate__c > TODAY OR ContractDate__c = null)];

            if(!completeDelimitedLandList.isEmpty()){
                for(DelimitedLand__c delimitedLand : completeDelimitedLandList){
                    delimitedLandIdSet.add(delimitedLand.Id);
                }

                List<DelimitedLandCultures__c> delimitedLandCultureList = [
                    SELECT Id, Culture__c, Culture__r.AgrometrikaExternalId__c, Crop__r.ExternalId__c, Culture__r.ExternalId__c, Date__c, Crop__c, DelimitedLand__c, AreaCultivated__c, TotalAreaMeters__c, WarehouseCapability__c, TechnologicalLevel__c
                    FROM DelimitedLandCultures__c
                    WHERE DelimitedLand__c IN: delimitedLandIdSet
                ];

                Map<Id, List<DelimitedLand__c>> delimitedLandMap = new Map<Id, List<DelimitedLand__c>>();

                for (DelimitedLand__c delimitedLand : completeDelimitedLandList) {
                    if (!delimitedLandMap.containsKey(delimitedLand.Account__r.ParentId)){
                        delimitedLandMap.put(delimitedLand.Account__r.ParentId, new List<DelimitedLand__c>());
                    }
                        delimitedLandMap.get(delimitedLand.Account__r.ParentId).add(delimitedLand);
                }

                Map<Id, List<DelimitedLandCultures__c>> delimitedLandCultureMap = new Map<Id, List<DelimitedLandCultures__c>>();

                for (DelimitedLandCultures__c delimitedLandCulture : delimitedLandCultureList) {
                    if (!delimitedLandCultureMap.containsKey(delimitedLandCulture.DelimitedLand__c)){
                        delimitedLandCultureMap.put(delimitedLandCulture.DelimitedLand__c, new List<DelimitedLandCultures__c>());
                    }
                        delimitedLandCultureMap.get(delimitedLandCulture.DelimitedLand__c).add(delimitedLandCulture);
                }
                //  
                calloutResponse = sendDelimitedLand(delimitedLandMap, delimitedLandCultureMap);
            
                //if(!campaignMap.isEmpty()){
                //    update campaignMap.values();
                //}
            } else {
                return calloutResponse;
            }

            
        } catch(Exception ex) {
            System.debug('deu ruim');

            IntegrationLog.createIntegrationLog('DelimitedLand Outbound Integration Exception', 'Outbound', ex.getMessage()+', '+ex.getStackTraceString(), JSON.serialize(listDelimitedLandId), true, JSON.serialize(listDelimitedLandId));
        }
        return calloutResponse;
    }

    public static IntegrationUtils.CalloutResponse sendDelimitedLand(Map<Id,List<DelimitedLand__c>> delimitedLandMap, Map<Id,List<DelimitedLandCultures__c>> delimitedLandCultureMap) {
		List<RequestParameters> request = new List<RequestParameters>();

        String payload;
        
        Map<String,Integration__c> integrations = Integration__c.getAll();
        String integrationMethod = integrations.get('IntegrationDelimitedLand').Method__c;
        String integrationEndPoint = integrations.get('IntegrationDelimitedLand').Endpoint__c;
        String integrationUser = integrations.get('IntegrationDelimitedLand').Username__c;
        String integrationPassword = integrations.get('IntegrationDelimitedLand').Password__c;
        String integrationMethodToken = integrations.get('IntegrationDelimitedLandToken').Method__c;
        String integrationEndPointToken = integrations.get('IntegrationDelimitedLandToken').Endpoint__c;
        String integrationUserToken = integrations.get('IntegrationDelimitedLandToken').Username__c;
        String integrationPasswordToken = integrations.get('IntegrationDelimitedLandToken').Password__c;

        Set<Id> accountIdSet = delimitedLandMap.keySet();

        for(Id accountId : accountIdSet) {
            //System.debug('dentro do for de Id');
            List<DelimitedLand__c> auxList = new List<DelimitedLand__c>();
            List<DelimitedLand__c> auxListCulture = new List<DelimitedLand__c>();
		    for (DelimitedLand__c delimitedLand : delimitedLandMap.get(accountId)) {
                //auxList.add(delimitedLand);
            //System.debug('dentro do for de DelimitedLand');
                if (delimitedLandCultureMap.containsKey(delimitedLand.Id)) {
                    auxListCulture.add(delimitedLand);
                    //System.debug('dentro do if');
                    //List<DelimitedLandCultures__c> delimitedLandCultureList = delimitedLandCultureMap.get(delimitedLand.Id);
                    //System.debug('delimitedLandCultureList' + delimitedLandCultureList);
		    	    //request.add(new RequestParameters(delimitedLandMap.get(accountId), delimitedLandCultureList));
                    //System.debug('request ok');
                    //payload = JSON.serialize(new RequestParameters(delimitedLandMap.get(accountId), delimitedLandCultureList));
                    //System.debug('payload ok');
                } else {
                    auxList.add(delimitedLand);
		    	    //request.add(new RequestParameters(delimitedLandMap.get(accountId)));
                    //System.debug('else request');
                    //payload = JSON.serialize(new RequestParameters(delimitedLandMap.get(accountId)));
                    //System.debug('else payload');
                }
		    }
            if (!auxList.isEmpty()){
		    	request.add(new RequestParameters(auxList));
                System.debug('else request');
                payload = JSON.serialize(new RequestParameters(auxList));
                System.debug('else payload');
            }
            if (!auxListCulture.isEmpty()){
		    	request.add(new RequestParameters(auxListCulture, delimitedLandCultureMap));
                System.debug('request ok');
                payload = JSON.serialize(new RequestParameters(auxListCulture, delimitedLandCultureMap));
                System.debug('payload ok');
            }
        }

        System.debug('request' + request);
        System.debug('payload' + payload);

		if(integrations.get('IntegrationDelimitedLand').Inactive__c){
            List<DelimitedLand__c> delimitedLandList = new List<DelimitedLand__c>();
            for (Id accountId : accountIdSet) {
                for (DelimitedLand__c delimitedLand : delimitedLandMap.get(accountId)){
                    delimitedLandList.add(delimitedLand);
                }
            }
            IntegrationUtils.updateErrorDelimitedLand(delimitedLandList);
			IntegrationLog.createIntegrationLog('DelimitedLand Outbound Integration', 'Outbound', Label.InactiveIntegration, payload, true);
            return new IntegrationUtils.CalloutResponse(Label.InactiveIntegration, null);
		}

		//String payload = JSON.serialize(new Request(request));
        // -> DEU CERTO PARCIALMENTE String payload = JSON.serialize(request);
        String payloadToken = '{"ID":"'+integrationUserToken+'","Chave":"'+integrationPasswordToken+'"}';
        Blob headerValue = Blob.valueOf(integrationUserToken + ':' + integrationPasswordToken);
		Map<String, String> headersMapToken = new Map<String, String>();
		headersMapToken.put('Content-type', 'application/json');
		String endpointToken = (!Test.isRunningTest() ? integrationEndPointToken : 'http://callout.My_Named_Credential.com/some/path');
        IntegrationUtils.RequestResponseObject responseObjectToken = IntegrationUtils.executeCallout(endpointToken, payloadToken, headersMapToken, integrationMethodToken);
        HttpResponse responseToken = responseObjectToken.response;
        TokenResponse tokenResponse = (TokenResponse)JSON.deserialize(responseToken.getBody(), TokenResponse.class);
        //IntegrationLog.createIntegrationLog('DelimitedLand Outbound Integration', 'Outbound', responseToken.getBody(), payloadToken, false, IntegrationUtils.createExternalIdsDelimitedLand(delimitedLandList));
		//Metodo para busca de Access Token, depende de cada projeto, podendo estar presente dentro de uma custom settings ou relacionado com outra requisição.
		
        //String accessToken = 'Basic Uy1JRlNGT1JDRTpjNHEkNkQlL1QjQTZZOHVhR2Q0TGNBO0JJXC1cJ3NeYA==';
        String accessToken = tokenResponse.Token;
		
		//Path geralmente cadastrado dentro de ua customSettings
		String endpoint = (!Test.isRunningTest() ? integrationEndPoint : 'http://callout.My_Named_Credential.com/some/path');
		Map<String, String> headersMap = new Map<String, String>();
		headersMap.put('Content-type', 'application/json');
		headersMap.put('X-Authentication-Token', accessToken);
		
		IntegrationUtils.RequestResponseObject responseObject = IntegrationUtils.executeCallout(endpoint, payload, headersMap, integrationMethod);
        System.debug('response Object: ' + responseObject);
        HttpResponse response = responseObject.response;
        IntegrationUtils.CalloutResponse calloutResponse;
        System.debug('Response Body - ' + response.getBody());
		if (responseObject.success) {
            System.debug('RESPONSESENDDELIMITEDLAND: ' + responseObject);
            try {
				ResponseParametersWrapper responses = (ResponseParametersWrapper) JSON.deserialize(response.getBody(), ResponseParametersWrapper.class);
				calloutResponse = new IntegrationUtils.CalloutResponse(new ResponseParameters(responses), response);
			} catch (Exception e) {
				String defaultErrorMessage = 'Malformatted HTTP Response Exception: ' + e.getMessage();

				calloutResponse = new IntegrationUtils.CalloutResponse(defaultErrorMessage, response);
			}
            List<DelimitedLand__c> delimitedLandList = new List<DelimitedLand__c>();
            for (Id accountId : accountIdSet) {
                for (DelimitedLand__c delimitedLand : delimitedLandMap.get(accountId)){
                    delimitedLandList.add(delimitedLand);
                }
            }
            updateDelimitedLands(delimitedLandList, calloutResponse);
			IntegrationLog.createIntegrationLog('DelimitedLand Outbound Integration', 'Outbound', response.getBody(), payload, false, IntegrationUtils.createExternalIdsDelimitedLand(delimitedLandList));
		} else {
            List<DelimitedLand__c> delimitedLandList = new List<DelimitedLand__c>();
            for (Id accountId : accountIdSet) {
                for (DelimitedLand__c delimitedLand : delimitedLandMap.get(accountId)){
                    delimitedLandList.add(delimitedLand);
                }
            }
            calloutResponse = new IntegrationUtils.CalloutResponse(responseObject.exceptionObject.getMessage(), response);
            updateDelimitedLands(delimitedLandList, calloutResponse);
			IntegrationLog.createIntegrationLog('DelimitedLand Outbound Integration', 'Outbound', responseObject.exceptionObject.getMessage(), payload, true, IntegrationUtils.createExternalIdsStringOut(delimitedLandList));
		}
        return calloutResponse;
    }

    public static void updateDelimitedLands(List<DelimitedLand__c> allDelimitedLands, IntegrationUtils.CalloutResponse calloutResponse){
        try{
            System.debug('calloutResponse: ' + calloutResponse);
            List<DelimitedLand__c> delimitedLandList = new List<DelimitedLand__c>();
            if (calloutResponse.success) {
                
                ResponseParameters resp = (ResponseParameters) calloutResponse.parsedResponseDelimitedLand;
                List<ResponseMessageWrapper> respMessageWrapperList = (List<ResponseMessageWrapper>) resp.responses.Mensagens;
                HttpResponse requisitionResponse = (HttpResponse) calloutResponse.requisition;
                Map<String, DelimitedLand__c> delimitedLandMap = new Map<String, DelimitedLand__c>();

                for (DelimitedLand__c delimitedLand : allDelimitedLands) {
                    delimitedLandMap.put(delimitedLand.Id, delimitedLand);
                }

                System.debug('delimitedLandMap: ' + delimitedLandMap);
                System.debug('resp: ' + resp);
                System.debug('respMessageWrapperList: ' + respMessageWrapperList);
                System.debug('requisitionResponse.getStatusCode(): ' + String.valueOf(requisitionResponse.getStatusCode()));
                

                /////
                if (delimitedLandMap.containsKey(resp.responses.Id)) {
                ////
                    System.debug('deu certo confia');
                    DelimitedLand__c delimitedLand = delimitedLandMap.get(resp.responses.Id);
                    if(requisitionResponse != null){
                        System.debug('resp.responses.NumeroOrdemVenda: ' + resp.responses.NumeroOrdemVenda);
                        if (requisitionResponse.getStatusCode() != 200) {
                            System.debug('Error Possibility2');
                            //
                            delimitedLand.MessageOutbound__c = requisitionResponse.getStatus();
                            //
                        }
                        else{
                            if(resp.responses.NumeroOrdemVenda != null){
                                //delimitedLand.CodigoAgrometrika__c = resp.responses.NumeroOrdemVenda;
                            }
                            //
                            delimitedLand.MessageOutbound__c = '';
                            //
                            //System.debug('delimitedLand.CodigoAgrometrika__c: ' + delimitedLand.CodigoAgrometrika__c);
                        } 
                    }
                    else{
                        //
                        delimitedLand.MessageOutbound__c = calloutResponse.errorMessage;
                        //
                    }
                    if(respMessageWrapperList != null){
                        for(ResponseMessageWrapper respMessageWrapper : respMessageWrapperList){
                            if(respMessageWrapper.Tipo == 'E'){
                                delimitedLand.MessageOutbound__c = delimitedLand.MessageOutbound__c + ' | ' + respMessageWrapper.Mensagem;
                            }
                        }
                    }               
                    delimitedLandList.add(delimitedLand);
                    System.debug('delimitedLandList: ' + delimitedLandList);
                }else{
                    for(DelimitedLand__c delimitedLand : allDelimitedLands){
                        System.debug('bacana banana');

                        if(requisitionResponse != null){
                            if (requisitionResponse.getStatusCode() != 200) {
                                System.debug('caiu no erro emmm 2');
                                delimitedLand.MessageOutbound__c = requisitionResponse.getStatus();
                            }
                            else{
                                if(resp.responses.NumeroOrdemVenda != null){
                                    //delimitedLand.CodigoAgrometrika__c = resp.responses.NumeroOrdemVenda;
                                }
                                delimitedLand.MessageOutbound__c = '';
                            }
                        }
                        else{
                            delimitedLand.MessageOutbound__c = calloutResponse.errorMessage;
                        }
                        if(respMessageWrapperList != null){
                            for(ResponseMessageWrapper respMessageWrapper : respMessageWrapperList){
                                if(respMessageWrapper.Tipo == 'E'){
                                    delimitedLand.MessageOutbound__c = delimitedLand.MessageOutbound__c + ' | ' + respMessageWrapper.Mensagem;
                                }
                            }
                        }
                        delimitedLandList.add(delimitedLand);
                    }
                }
            }else{
                System.debug('DEU ERRO - SUCCESS FALSE');
                
                HttpResponse requisitionResponse = (HttpResponse) calloutResponse.requisition;

                Map<String, DelimitedLand__c> delimitedLandMap = new Map<String, DelimitedLand__c>();

                for (DelimitedLand__c delimitedLand : allDelimitedLands) {
                    delimitedLandMap.put(delimitedLand.Id, delimitedLand);
                }

                System.debug('delimitedLandMap: ' + delimitedLandMap);

                for(DelimitedLand__c delimitedLand : allDelimitedLands){
                    if(requisitionResponse != null){
                        if (requisitionResponse.getStatusCode() != 200) {
                            delimitedLand.MessageOutbound__c = requisitionResponse.getStatus();
                        }
                        else{
                            delimitedLand.MessageOutbound__c = calloutResponse.errorMessage;
                        }
                    }
                    else{
                        delimitedLand.MessageOutbound__c = calloutResponse.errorMessage;
                    }
                    delimitedLandList.add(delimitedLand);
                }
            }

            if (!delimitedLandList.isEmpty()) {

                DelimitedLandTriggerHelper.disableTrigger();
                update delimitedLandList;
                DelimitedLandTriggerHelper.enableTrigger();

                //if(!delimitedLandList.isEmpty()){
                //    update delimitedLandList;
                //}
                //if(!ordIdObServationSet.isEmpty())
                //    DelimitedLandHelper.sendNotificationRTV(ordIdObServationSet);
                //for(Id ordId : ordIdSet){
                //    Approval.lock(ordId);
                //}
            }
        }catch(Exception ex){
            IntegrationLog.createIntegrationLog('DelimitedLand Outbound Integration Exception', 'Outbound', ex.getMessage()+', '+ex.getStackTraceString(), JSON.serialize(allDelimitedLands), true, IntegrationUtils.createExternalIdsStringOut(allDelimitedLands));
        }
	}

    public static Decimal formatNumber(Decimal val){
        return val != null ? val : 0;
    }

    public static Decimal formatYear(String val){
        return Decimal.valueOf('20' + val);
    }

	public class RequestParameters {
        public String NumCPF;
        public String NumCNPJ;
		public String CodClienteERP;
        public DelimitedLandParameters[] AreasCultivo;

		public RequestParameters(List<DelimitedLand__c> delimitedLand, Map<Id, List<DelimitedLandCultures__c>> delimitedLandCulture) {
            this(delimitedLand[0]);
            for (DelimitedLand__c delimitedLandObj : delimitedLand) {
                List<DelimitedLandCultures__c> cultureList = delimitedLandCulture.containsKey(delimitedLandObj.Id) ? delimitedLandCulture.get(delimitedLandObj.Id) : new List<DelimitedLandCultures__c>();
                if(delimitedLandObj.ContractDate__c != null )
                    this.AreasCultivo.add(new DelimitedLandParametersContract(delimitedLandObj, cultureList));
                else
                    this.AreasCultivo.add(new DelimitedLandParameters(delimitedLandObj, cultureList));
            }
		}

		public RequestParameters(List<DelimitedLand__c> delimitedLand) {
            this(delimitedLand[0]);
            for (DelimitedLand__c delimitedLandObj : delimitedLand) {
                if(delimitedLandObj.ContractDate__c != null )
                    this.AreasCultivo.add(new DelimitedLandParametersContract(delimitedLandObj));
                else
                    this.AreasCultivo.add(new DelimitedLandParameters(delimitedLandObj));
            }
		}
		public RequestParameters(DelimitedLand__c delimitedLand) {
            this.NumCPF = delimitedLand.Account__r.CPF__c;
            this.NumCNPJ = delimitedLand.Account__r.CNPJ__c;
		    this.CodClienteERP = delimitedLand.Account__r.Parent.ExternalId__c;
            this.AreasCultivo = new List<DelimitedLandParameters>();
        }
	}

	public virtual class DelimitedLandParameters {
        public Decimal CodMunicipio;
        public String NomFazenda;
		public Boolean FlgProprietarioRural;
        public Decimal QtdHecProprietarioRural;
        public Boolean FlgArrendatario;
        public Decimal QtdHecArrendatario;
        public String NomProprietario;
        public Decimal CodCulturaArrendamento;
        public Decimal ValTaxaArrendamento;
        public Decimal ValArrendamento;
        public CultureParameters[] MatrizProducao;
		public DelimitedLandParameters(DelimitedLand__c delimitedLand, List<DelimitedLandCultures__c> delimitedLandCultureList) {
            this(delimitedLand);
            for (DelimitedLandCultures__c delimitedLandCulture : delimitedLandCultureList) {
                this.MatrizProducao.add(new CultureParameters(delimitedLandCulture));
            }
		}

		public DelimitedLandParameters(DelimitedLand__c delimitedLand) {
            this.CodMunicipio = Decimal.valueOf(delimitedLand.Account__r.FiscalDomicile__c.replaceAll('[a-zA-Z]{1,}|\\-','').subString(1,7));
            this.NomFazenda = delimitedLand.Name;
		    this.FlgProprietarioRural = true;
            this.QtdHecProprietarioRural = delimitedLand.AreaTotalHec__c;
            this.FlgArrendatario = delimitedLand.Tenant__c;
            this.QtdHecArrendatario = formatNumber(delimitedLand.TenantArea__c);
            this.NomProprietario = delimitedLand.Tenant__c? delimitedLand.Account__r.Parent.Name : null;
            this.CodCulturaArrendamento = delimitedLand.TenantCulture__r.AgrometrikaExternalId__c != null ? Decimal.valueOf(delimitedLand.TenantCulture__r.AgrometrikaExternalId__c) : 1074;
            this.ValTaxaArrendamento = formatNumber(delimitedLand.TenantTax__c);
            this.ValArrendamento = formatNumber(delimitedLand.TenantValue__c);
            this.MatrizProducao = new List<CultureParameters>();
		}
    }
	public class DelimitedLandParametersWithoutContract extends DelimitedLandParameters {
		public DelimitedLandParametersWithoutContract(DelimitedLand__c delimitedLand, List<DelimitedLandCultures__c> delimitedLandCultureList) {
            super(delimitedLand, delimitedLandCultureList);		}

		public DelimitedLandParametersWithoutContract(DelimitedLand__c delimitedLand) {
            super(delimitedLand);
		}
	}
	public class DelimitedLandParametersContract extends DelimitedLandParameters {
        public DateTime DatContratoVencimento;
		public DelimitedLandParametersContract(DelimitedLand__c delimitedLand, List<DelimitedLandCultures__c> delimitedLandCultureList) {
            super(delimitedLand, delimitedLandCultureList);
            this.DatContratoVencimento = (Datetime)delimitedLand.ContractDate__c;
		}
		public DelimitedLandParametersContract(DelimitedLand__c delimitedLand) {
            super(delimitedLand);
            this.DatContratoVencimento = (Datetime)delimitedLand.ContractDate__c;
		}
	}

	public class CultureParameters {
        public Decimal CodTipoCultura;
        public Decimal QtdAreaCultivada;
		public Decimal NumAnoPlantio;
        public Decimal NumAnoColheita;
		public Decimal PerCapaciArmaze;
        public Decimal CodNivelTecnologico;
		public Boolean FlgUtilCultura;

		public CultureParameters(DelimitedLandCultures__c delimitedLandCulture) {
            this.CodTipoCultura = Decimal.valueOf(delimitedLandCulture.Culture__r.AgrometrikaExternalId__c);
            this.QtdAreaCultivada = delimitedLandCulture.AreaCultivated__c;
		    String auxAnoPlantio = delimitedLandCulture.Crop__r.ExternalId__c.subString(0,2);
            String auxAnoColheita = delimitedLandCulture.Crop__r.ExternalId__c.subString(delimitedLandCulture.Crop__r.ExternalId__c.length() - 2, delimitedLandCulture.Crop__r.ExternalId__c.length());
            this.NumAnoColheita = formatYear(auxAnoColheita);
            this.NumAnoPlantio = formatYear(auxAnoPlantio) - (auxAnoPlantio != auxAnoColheita ? 0 : 1);
		    this.PerCapaciArmaze = formatNumber(delimitedLandCulture.WarehouseCapability__c);
            this.CodNivelTecnologico = Decimal.valueOf(delimitedLandCulture.TechnologicalLevel__c);
		    this.FlgUtilCultura = true;
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
        public String Id;
        public List<ResponseMessageWrapper> Mensagens;
	}

    public class ResponseMessageWrapper {
        public String Tipo;
        public String Mensagem;
    }

    public class TokenResponse {
        public Boolean Autenticado;
        public String Token;
    }
}