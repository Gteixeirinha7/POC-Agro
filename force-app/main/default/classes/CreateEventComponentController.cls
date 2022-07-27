public with sharing class CreateEventComponentController {
    @AuraEnabled(cacheable=true)
    public static User getUserDetails() {
        return  [Select Id , Name ,Email, Profile.Name	 from User where Id =:userInfo.getUserId()];
    }
    @AuraEnabled
    public static Event createEvent(String evt) {
        Event newEvt = (Event)JSON.deserialize(evt, Event.Class);
        insert newEvt;
        return newEvt;
    }
    @AuraEnabled
    public static Case getCaseDetails(String caseId) {
        return [SELECT Subject, AccountId, Account.Name, OwnerId, Description, CaseNumber, Crop__c, Crop__r.Name FROM Case WHERE Id =: caseId LIMIT 1];
    }
}
