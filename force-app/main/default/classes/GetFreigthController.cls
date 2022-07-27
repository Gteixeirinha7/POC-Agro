public class GetFreigthController {
    @AuraEnabled(cacheable=true)
    public static SObject getFreigth(String destinationCityId, String sourceCityId, String product2Id) {
        if(String.isNotBlank(destinationCityId) && String.isNotBlank(sourceCityId) && String.isNotBlank(product2Id)) {
            try {
                System.debug('TA DENTRO DO GET FREIGH, METODO DO APEX');
                Product2 prod = [SELECT id, Family__c FROM Product2 WHERE ID = :product2Id];
                SObject record = [SELECT 
                Id, 
                OwnerId, IsDeleted, 
                Name, CreatedDate, 
                CreatedById, LastModifiedDate, 
                LastModifiedById, SystemModstamp, 
                LastActivityDate, LastViewedDate, 
                LastReferencedDate, DestinationCity__c, 
                EndDate__c, ExternalIDIndex__c, 
                ExternalId__c, IsActive__c, 
                Product2Id__c, SourceCity__c,
                StartDate__c, ValuePerTonDolar__c,
                ValuePerTon__c 
                FROM Freight__c 
                WHERE IsActive__c = true AND DestinationCity__c =: destinationCityId AND SourceCity__c =: sourceCityId AND (Product2Id__c =: product2Id OR Family__c = :prod.Family__c) ORDER BY Priority__c DESC LIMIT 1];
                return record;
            } catch(Exception e) {
                return NULL;
            }
        }
        else {
            return NULL;
        }
    }
}
