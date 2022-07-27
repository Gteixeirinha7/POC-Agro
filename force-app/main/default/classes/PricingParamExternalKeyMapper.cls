public with sharing class PricingParamExternalKeyMapper {
    private static Map<String, Set<String>> tableToKeyFields;
    static {
        tableToKeyFields = new Map<String, Set<String>>{
            'Freight__c'             => new Set<String>{ 'DestinationCity__c', 'SourceCity__c', 'Product2Id__c', 'Family__c' }
        };       
    }

    public static void mapRecords(SObject[] records, SObjectType sobjectType){
        PricingParamValidator.assignExternalId(records, tableToKeyFields.get(sobjectType.getDescribe().getName()));
    }
}
