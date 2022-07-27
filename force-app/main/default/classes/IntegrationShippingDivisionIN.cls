//@RestResource(urlMapping='/upsertShippingDivision/*')
global with sharing class IntegrationShippingDivisionIN {
    //ShippingDivision upsert integration

    //@HttpPost
    global static Map<String, List<TemplateDataIntegrationFields.Response>> upsertShippingDivision(List<TemplateDataIntegrationFields.ShippingDivisionINData> request){
        
        Map<String, Id> lookups = new Map<String, Id>();

        Set<String> shippingDivisionLookups = new Set<String>();
        Set<String> orderItemLookups = new Set<String>();

        Map<String, List<TemplateDataIntegrationFields.Response>> responseMap = new Map<String, List<TemplateDataIntegrationFields.Response>>();
        
        List<ShippingDivision__c> shippingDivisionListToUpsert = new List<ShippingDivision__c>();

        //Application of business rules
        for(TemplateDataIntegrationFields.ShippingDivisionINData shippingDivision : request){

            //Getting shippingDivision parameters to search
            shippingDivisionLookups.add(shippingDivision.RelatedOrderItemId + '|' + shippingDivision.NumeroDivisao);
            //Getting orderItem parameters to search
            //orderItemLookups.add(shippingDivision.RelatedOrderItemExternalId);

        }

        //ShippingDivision search based on ExternalId__c field sent
        for (ShippingDivision__c shippingDivision : ShippingDivisionDAO.getShippingDivisionByExternalId(new List<String>(shippingDivisionLookups), new Set<String>{'Id', 'ExternalId__c', 'OrderItem__c'})) {
            //Map structure for the model -> object name + parameter to record id
            lookups.put('ShippingDivision' + shippingDivision.OrderItem__c + '|' + shippingDivision.ExternalId__c, shippingDivision.Id);
        }
        
        //OrderItem search based on ExternalId__c field sent
        //for (OrderItem orderItem : OrderItemDAO.getOrderItemByExternalId(new List<String>(orderItemLookups), new Set<String>{'Id', 'ExternalId__c'})) {
        //    //Map structure for the model -> object name + parameter to record id
        //    lookups.put('OrderItem' + orderItem.ExternalId__c, orderItem.Id);
        //}
        
        //ShippingDivision ExternalId Map to OrderItem ExternalId for association of responses if needed
        Map<String, String> parentMapKeys = new Map<String, String>();
        for(TemplateDataIntegrationFields.ShippingDivisionINData shippingDivision : request) {
            parentMapKeys.put(shippingDivision.RelatedOrderItemId + '|' + shippingDivision.NumeroDivisao, shippingDivision.RelatedOrderItemId);
            //system.debug(parentMapKeys);
        }

        //Converting template to object list and validating required fields
        FactoryDataIntegration.convertSObjectChild(
            new ShippingDivision__c(), 
            'IN', 
            request, 
            responseMap, 
            shippingDivisionListToUpsert, 
            lookups, 
            parentMapKeys
        );
        system.debug('Responses' + responseMap);

        //Upserting records
        IntegrationUtils.upsertChildRecords(
            Database.upsert(shippingDivisionListToUpsert, ShippingDivision__c.ExternalId__c, false), 
            responseMap, 
            shippingDivisionListToUpsert, 
            ShippingDivision__c.ExternalId__c
        );



        //Returning response
        return responseMap;
    }
}