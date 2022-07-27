public with sharing class OpenMapsController {

    @AuraEnabled
    public static Event getLocalization (String eventId) {
        return [SELECT Id, Checkin__c FROM Event WHERE Id =: eventId LIMIT 1];
    }
}
