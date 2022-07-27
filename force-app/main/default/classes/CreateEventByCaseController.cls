public class CreateEventByCaseController {
    public CreateEventByCaseController() {}

    @AuraEnabled
    public static Case getCaseData(String caseId) {
        System.debug('PAssou aqui na controller');
        return [SELECT Subject, AccountId, Account.Name, OwnerId, Description, CaseNumber FROM Case WHERE Id =:caseId LIMIT 1];
    }
}
