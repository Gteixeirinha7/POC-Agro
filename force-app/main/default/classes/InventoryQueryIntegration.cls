public with sharing class InventoryQueryIntegration {

    //System.debug(InventoryQueryIntegration.queryInventory(new List<String>{'1001'}, new List<String>{'100231'}, false));
    public static Map<String, ProductManagement__c> queryInventory(List<String> distributionCenterExternalIds, List<String> productExternalIds, Boolean generateLog) {

		List<RequestParameters> request = new List<RequestParameters>();


        List<ProductRequestParameter> productRequestParameters = new List<ProductRequestParameter>(); 
        List<CenterRequestParameter> centerRequestParametera = new List<CenterRequestParameter>();

        for (String distributionCenterExternalId : distributionCenterExternalIds) {
            centerRequestParametera.add(new CenterRequestParameter(distributionCenterExternalId));
        }

        for (String productExternalId : productExternalIds) {
            productRequestParameters.add(new ProductRequestParameter(productExternalId));
        }

        String payload = JSON.serialize(new RequestParameters(centerRequestParametera, productRequestParameters));
        
        Map<String,Integration__c> integrations = Integration__c.getAll();
        String integrationMethod    = integrations.get('IntegrationInventory').Method__c;
        String integrationEndPoint  = integrations.get('IntegrationInventory').Endpoint__c;
        String integrationUser      = integrations.get('IntegrationInventory').Username__c;
        String integrationPassword  = integrations.get('IntegrationInventory').Password__c;

		if(integrations.get('IntegrationInventory').Inactive__c){
			IntegrationLog.createIntegrationLog('Inventory Outbound Integration', 'Outbound', Label.InactiveIntegration, payload, true);
            return null;
		}

        Blob headerValue = Blob.valueOf(integrationUser + ':' + integrationPassword);

        String accessToken = 'Basic ' + EncodingUtil.base64Encode(headerValue);
		
		String endpoint = (!Test.isRunningTest() ? integrationEndPoint : 'http://callout.My_Named_Credential.com/some/path');
		Map<String, String> headersMap = new Map<String, String>();
		headersMap.put('Content-type', 'application/json');
		headersMap.put('Authorization', accessToken);
		
		IntegrationUtils.RequestResponseObject responseObject = IntegrationUtils.executeCallout(endpoint, payload, headersMap, integrationMethod);
        System.debug('response Object: ' + responseObject);
        HttpResponse response = responseObject.response;
        Map<String, ProductManagement__c> externalIdToInventory = new Map<String, ProductManagement__c>();
		if (responseObject.success) {
            try {
                System.debug(response.getBody());
				Inventory inventorySAPs = (Inventory) JSON.deserialize(response.getBody(), Inventory.class);
                System.debug(inventorySAPs);
                Inventory inventory = formatData(inventorySAPs);
                if (inventory.Estoques != null && !inventory.Estoques.isEmpty()) {
                    Set<String> cropSet = new Set<String>();
                    for (InventoryParameters inventoryParameters : inventory.Estoques) {
                        cropSet.add(inventoryParameters.Safra);
                    }
                    System.debug(cropSet);
                    Map<String, Boolean> cropMap = new Map<String, Boolean>();
                    for(Crop__c crop : [SELECT ExternalId__c, StartDate__c, EndDate__c, id FROM Crop__c WHERE ExternalId__c IN :cropSet]){
                        Boolean isActualCrop = (crop.StartDate__c <= Date.Today() && crop.EndDate__c >= Date.Today());
                        cropMap.put(crop.ExternalId__c, isActualCrop);
                    }

                    Map<String, List<String>> distMap = new Map<String, List<String>>();
                    for(SalesTeam__c slTeam : [SELECT Id, SalesOrg__r.ExternalId__c, DistributionCenter__r.ExternalId__c FROM SalesTeam__c WHERE DistributionCenter__r.ExternalId__c IN :distributionCenterExternalIds]){
                        if(!distMap.containsKey(slTeam.DistributionCenter__r.ExternalId__c))
                            distMap.put(slTeam.DistributionCenter__r.ExternalId__c, new List<String>());
                        distMap.get(slTeam.DistributionCenter__r.ExternalId__c).add(slTeam.SalesOrg__r.ExternalId__c);
                    }

                    for (InventoryParameters inventoryParameters : inventory.Estoques) {
                        if(inventoryParameters.Safra == null || !cropMap.containsKey(inventoryParameters.Safra)) continue;
                        String externalId = inventoryParameters.Material + '-' + inventoryParameters.Centro+ '-' + inventoryParameters.Safra;
                        
        
                        List<String> salesOrgList = new List<String>();
                                
                        if(distMap.containsKey(inventoryParameters.Centro))
                            salesOrgList.addAll(distMap.get(inventoryParameters.Centro));

                        externalIdToInventory.put(
                            externalId,
                            new ProductManagement__c(
                                Product2__r             = new Product2(ExternalId__c = inventoryParameters.Material),
                                DistributionCenter__r   = new DistributionCenter__c(ExternalId__c = inventoryParameters.Centro),
                                Crop__r                 = new Crop__c(ExternalId__c = inventoryParameters.Safra),
                                Inventory__c            = inventoryParameters.Safra != null && cropMap.containsKey(inventoryParameters.Safra) && cropMap.get(inventoryParameters.Safra) ? (inventoryParameters.QtdEstoque == null ? 0 : inventoryParameters.QtdEstoque) : 0,
                                FutureInventory__c      = inventoryParameters.QtdCompra == null ? 0 : inventoryParameters.QtdCompra ,
                                SalesInventory__c       = inventoryParameters.QtdVenda == null ? 0 : inventoryParameters.QtdVenda ,
                                UnitMeasurement__c      = inventoryParameters.UnidadeMedidaEstoque,
                                ExternalId__c           = externalId,
                                SalesOrgName__c         = String.join(salesOrgList, ';'),
                                RecordTypeId            = Schema.SObjectType.ProductManagement__c.getRecordTypeInfosByDeveloperName().get('SalesStock').getRecordTypeId()
                            )
                        );
                    }
                }
                
			} catch (Exception e) {
				String defaultErrorMessage = 'Malformatted HTTP Response Exception: ' + e.getMessage() + ' - '+ e.getStackTraceString();
                throw new InventoryException(defaultErrorMessage);
			}

            if (generateLog) {
			    IntegrationLog.createIntegrationLog('Inventory Outbound Integration', 'Outbound', response.getBody(), payload, false, IntegrationUtils.createExternalIdsString(externalIdToInventory.values()));
            }
		} else {
            if (generateLog) {
			    IntegrationLog.createIntegrationLog('Inventory Outbound Integration', 'Outbound', responseObject.exceptionObject.getMessage(), payload, true, IntegrationUtils.createExternalIdsString(externalIdToInventory.values()));
            }
		}

        deleteInvalidProduct(distributionCenterExternalIds, productExternalIds, externalIdToInventory);
        
        System.debug(externalIdToInventory);
        return externalIdToInventory;
	}
    public static void deleteInvalidProduct(List<String> distributionCenterExternalIds, List<String> productExternalIds, Map<String, ProductManagement__c> externalIdToInventory){
        List<ProductManagement__c> prodList = new List<ProductManagement__c>();
        System.debug(distributionCenterExternalIds);
        System.debug(productExternalIds);
        System.debug(externalIdToInventory);
        for(ProductManagement__c prod : [SELECT id 
                                        FROM ProductManagement__c 
                                        WHERE Product2__r.ProductCode IN :productExternalIds 
                                        AND RecordType.DeveloperName = 'SalesStock'
                                        AND DistributionCenter__r.ExternalId__c IN :distributionCenterExternalIds
                                        AND ExternalId__c NOT IN :externalIdToInventory.keySet()]){
            prodList.add(prod);
        }
        System.debug(prodList);
        if(!prodList.isEmpty()){
            delete prodList;
        }
    }
    public static Inventory formatData(Inventory inventorySAPs){
        Inventory returnVal = new Inventory(inventorySAPs);

        Map<String, InventoryParameters> paramsMap = new Map<String, InventoryParameters>();
        
        if(inventorySAPs.Estoques == null)
            return returnVal;

        List<CropValues> cropIdSet = getCurrentCrop();

        for(InventoryParameters paramSap : inventorySAPs.Estoques){

            Map<String, CropValues> cropMap = new Map<String, CropValues>();

            if(paramSap.Compras != null)
                inputCropMap(paramSap.Compras, cropMap);
            
            if(paramSap.Vendas != null)
                inputCropMap(paramSap.Vendas, cropMap);

            inputCropMap(cropIdSet, cropMap);

            for(CropValues crops : cropMap.values()){
                paramsMap.put(paramSap.Material+'-'+paramSap.Centro+'-'+crops.Safra, new InventoryParameters(paramSap, crops));
            }
        }

        returnVal.Estoques.addAll(paramsMap.values());
        System.debug(paramsMap.values());
        return returnVal;
    }
    public static void inputCropMap(CropValues[] paramSapData, Map<String, CropValues> cropMap){        
        for(CropValues stockVal : paramSapData){
            if(stockVal.Safra == null ) continue;
            if(!cropMap.containsKey(stockVal.Safra))
                cropMap.put(stockVal.Safra, new CropValues(stockVal));

            CropValues val = cropMap.get(stockVal.Safra);
            val.inputVal(stockVal);
            
            cropMap.put(stockVal.Safra, val);
        }
    }
    public static List<CropValues>  getCurrentCrop(){
        List<CropValues> cropIdSet = new List<CropValues>();
        for(Crop__c crop : [SELECT id, ExternalId__c FROM Crop__c WHERE StartDate__c <= TODAY AND EndDate__c >= TODAY] ){
            cropIdSet.add(new CropValues(crop.ExternalId__c));
        }
        return cropIdSet;
    }

    public class Inventory {
        public List<InventoryParameters> Estoques;
        public List<Message> Mensagens;
        public Inventory(Inventory inventory){
            this.Estoques = new List<InventoryParameters>();
            this.Mensagens = Inventory.Mensagens;
        }
    }

    public class InventoryParameters {
        public String  Material;
        public String  Centro;
        public Decimal QtdEstoque;
        public Decimal QtdCompra;
        public Decimal QtdVenda;
        public String  UnidadeMedidaEstoque;

        public String  Safra;

        public CropValues[] Compras;
        public CropValues[] Vendas;

        public InventoryParameters(InventoryParameters invent, CropValues crops){
            this.Material             = invent.Material;
            this.Centro               = invent.Centro;
            this.QtdEstoque           = invent.QtdEstoque;
            this.UnidadeMedidaEstoque = invent.UnidadeMedidaEstoque;
            this.QtdCompra            = crops.QtdCompra;
            this.QtdVenda             = crops.QtdVenda;
            this.Safra                = crops.Safra;
        }
    }
    public class CropValues{
        public String  Safra;
        public Decimal QtdVenda;
        public Decimal QtdCompra;
        public CropValues(String crop){
            this.Safra = crop;
            this.QtdVenda = 0;
            this.QtdCompra = 0;
        }
        public CropValues(CropValues stockVal){
            this.Safra = stockVal.Safra;
            this.QtdVenda = 0;
            this.QtdCompra = 0;
        }
        public void inputVal(CropValues stockVal){
            this.QtdVenda   = stockVal.QtdVenda   != null ? stockVal.QtdVenda   : this.QtdVenda;
            this.QtdCompra  = stockVal.QtdCompra  != null ? stockVal.QtdCompra  : this.QtdCompra;
        }
    }

    public class RequestParameters {
        public List<ProductRequestParameter> Materiais; 
        public List<CenterRequestParameter> Centros; 

        public RequestParameters(List<CenterRequestParameter> distributionCenterExternalIds, List<ProductRequestParameter> productExternalIds) {
            this.Centros    = distributionCenterExternalIds;
            this.Materiais  = productExternalIds;
        }
    }

    public class ProductRequestParameter {
        public String CodMaterial; 

        public ProductRequestParameter(String productExternalId) {
            this.CodMaterial  = productExternalId;
        }
    }

    public class CenterRequestParameter {
        public String CodCentro; 

        public CenterRequestParameter(String distributionCenterExternalId) {
            this.CodCentro  = distributionCenterExternalId;
        }
    }

    public class Message {
        public String  Tipo;
        public String  Mensagem;
    }
    
    public class InventoryException extends Exception {} 

}