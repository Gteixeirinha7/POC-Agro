public with sharing class FactoryDataIntegration {
       
    //Object validation of required fields, adding error response and objects for upsert
    @TestVisible
    private static void validateObject(String fieldId, String fieldKey, SObject data, List<SObject> listToUpsert, List<TemplateDataIntegrationFields.Response> responseList, List<String> requiredField){
        validateObject(fieldId, fieldKey, data, listToUpsert, responseList, requiredField, false);
    }

    @TestVisible
    private static void validateObject(String fieldId, String fieldKey, SObject data, List<SObject> listToUpsert, List<TemplateDataIntegrationFields.Response> responseList, List<String> requiredField, Boolean verifySpecificError){
        TemplateDataIntegrationFields.Response response = new TemplateDataIntegrationFields.Response();
        
        if (responseList instanceOf List<TemplateDataIntegrationFields.ResponseParent>) {
			response = new TemplateDataIntegrationFields.ResponseParent();
        }
        
        response.status = true;
        
        for (String field : requiredField) {
            if (IntegrationUtils.convertEmptyString(data.get(field) + '')) {
                if (String.isNotEmpty((String)data.get(fieldId))){
                    response.error(
                        data.get(fieldId) + '',
                        data.get(fieldKey) + '',
                        'Valor inválido para o campo obrigatório: ' + field,
                        String.valueOf(listToUpsert.getSObjectType())
                    );
                }
                else {
                    response.error(
                        data.get(fieldKey) + '',
                        'Valor inválido para o campo obrigatório: ' + field,
                        String.valueOf(listToUpsert.getSObjectType())
                    );
                }
                //System.debug(response);
            	//break;
            }
        }

        if(verifySpecificError){
            response.error(
                data.get(fieldKey) + '',
                'Campos insuficientes para a regra de especificidade do Catálogo de Preços.',
                String.valueOf(listToUpsert.getSObjectType())
            );
        }
    
        if(response.status){
            listToUpsert.add(data);
        }
        else{
            responseList.add(response);
        }

        
    }

    
    //Conversion of the template list into the object list
    public static void convertSObject(SObject sObj, String service, List<TemplateDataIntegrationFields.FieldData> fieldDataList, List<TemplateDataIntegrationFields.Response> responseList, List<SObject> listToUpsert, Map<String, String> lookups){

        String sObjectName = String.valueOf(sObj.getSObjectType());

        Type t = Type.forName('TemplateDataIntegrationFields.' + sObjectName.replaceAll('__c|__mdt|__|_', '') +service+ 'Data');

        if (t == null) {
            throw new FactoryDataIntegrationException('Invalid defaults class.');
        }

        TemplateDataIntegrationFields.FieldData defaults = (TemplateDataIntegrationFields.FieldData) t.newInstance();

        for (TemplateDataIntegrationFields.FieldData Obj : fieldDataList) {
            validateObject(defaults.getFieldId(), defaults.getFieldKey(), Obj.serialize(lookups), listToUpsert, responseList, defaults.getRequiredFields(Obj));                 
        }
    }

    public static void convertListPrice(SObject sObj, String service, List<TemplateDataIntegrationFields.ListPriceINData> fieldDataList, List<TemplateDataIntegrationFields.Response> responseList, List<SObject> listToUpsert, Map<String, String> lookups) {
        for (TemplateDataIntegrationFields.ListPriceINData Obj : fieldDataList) {
            validateObject(Obj.getFieldId(), Obj.getFieldKey(), Obj.serialize(lookups), listToUpsert, responseList, Obj.getRequiredFields(Obj), Obj.hasError);                 
        }
    }

    //Object child validation of required fields, adding error response and objects for upsert
    @TestVisible
    private static void validateObjectChild(String fieldKey, SObject data, List<SObject> listToUpsert, Map<String, List<TemplateDataIntegrationFields.Response>> responseMap, List<String> requiredField, Map<String, String> parentMapKeys){
        TemplateDataIntegrationFields.Response response = new TemplateDataIntegrationFields.Response();
        response.status = true;
        System.debug(requiredField);
        for (String field : requiredField) {
            System.debug(data.get(field)+'');

            if(IntegrationUtils.convertEmptyString(data.get(field)+'')){
                response.error(data.get(fieldKey)+'', 'Valor inválido para o campo obrigatório: '+field, String.valueOf(listToUpsert.getSObjectType()));
                System.debug(String.valueOf(listToUpsert.getSObjectType()));
                System.debug(response);
            	//break;
            }
        }
        if(response.status){
            listToUpsert.add(data);
        }
        else {
            //System.debug('ParentMapKeys' + parentMapKeys);
            //System.debug('ParentMapKeys.get(Key)' + parentMapKeys.get(data.get(fieldKey) + ''));
            if(responseMap.keySet().contains(parentMapKeys.get(data.get(fieldKey) + ''))){
                responseMap.get(parentMapKeys.get(data.get(fieldKey) + '')).add(response);
            }
            else{
                responseMap.put(parentMapKeys.get(data.get(fieldKey) + ''), new List<TemplateDataIntegrationFields.Response>{response});
            }
        }
    }

    //Object child validation of required fields, adding error response and objects for upsert
    @TestVisible
    private static void validateObjectChild(String fieldKey, String fieldExternalKey,SObject data, List<SObject> listToUpsert, Map<String, List<TemplateDataIntegrationFields.Response>> responseMap, List<String> requiredField, Map<String, String> parentMapKeys){
        TemplateDataIntegrationFields.Response response = new TemplateDataIntegrationFields.Response();
        response.status = true;
        //System.debug(requiredField);
        for (String field : requiredField) {
            //System.debug(data.get(field)+'');

            if(IntegrationUtils.convertEmptyString(data.get(field)+'')){
                response.error(data.get(fieldKey)+'', data.get(fieldExternalKey)+'', 'Valor inválido para o campo obrigatório: '+field, String.valueOf(listToUpsert.getSObjectType()));
                //System.debug('fieldKey: ' + data.get(fieldKey));
                //System.debug(String.valueOf(listToUpsert.getSObjectType()));
                //System.debug(response);
            	//break;
            }
        }
        if(response.status){
            listToUpsert.add(data);
        }
        else {
            //System.debug('fieldKey: ' + data.get(fieldKey));
            //System.debug('ParentMapKeys' + parentMapKeys);
            //System.debug('ParentMapKeys.get(fieldExternalKey)' + parentMapKeys.get(data.get(fieldExternalKey) + ''));
            //System.debug('ParentMapKeys.get(fieldKey)' + parentMapKeys.get(data.get(fieldKey) + ''));
            if(responseMap.keySet().contains(parentMapKeys.get(data.get(fieldExternalKey) + ''))){
                responseMap.get(parentMapKeys.get(data.get(fieldExternalKey) + '')).add(response);
            }
            else{
                responseMap.put(parentMapKeys.get(data.get(fieldExternalKey) + ''), new List<TemplateDataIntegrationFields.Response>{response});
            }
        }
    }

    //Conversion of the template list into the object child list
    public static void convertSObjectChild(SObject sObj, String service, List<TemplateDataIntegrationFields.FieldDataChild> fieldDataList, Map<String, List<TemplateDataIntegrationFields.Response>> responseMap, List<SObject> listToUpsert, Map<String, String> lookups, Map<String, String> parentMapKeys) {

        String sObjectName = String.valueOf(sObj.getSObjectType());

        Type t = Type.forName('TemplateDataIntegrationFields.' + sObjectName.replaceAll('__c|mdt||', '') +service+ 'Data');

        if (t == null) {
            throw new FactoryDataIntegrationException('Invalid defaults class.');
        }
        TemplateDataIntegrationFields.FieldDataChild defaults = (TemplateDataIntegrationFields.FieldDataChild) t.newInstance();

        for(TemplateDataIntegrationFields.FieldDataChild Obj : fieldDataList){
            SObject serializedObject = Obj.serialize(lookups);
            
			String serializedKey = (String)serializedObject.get(defaults.getFieldKey());
            String fieldKey = String.isNotEmpty(serializedKey) ? defaults.getFieldKey() : null;
            String fieldExternalKey = defaults.getFieldExternal();
            if(String.isNotEmpty(serializedKey)){
                validateObjectChild(fieldKey, fieldExternalKey, serializedObject, listToUpsert, responseMap, defaults.getRequiredFields(Obj), parentMapKeys);
            }
            else{
                validateObjectChild(fieldExternalKey, serializedObject, listToUpsert, responseMap, defaults.getRequiredFields(Obj), parentMapKeys);
            }
        }
    }

    public class FactoryDataIntegrationException extends Exception {}
}