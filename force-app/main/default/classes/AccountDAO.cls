public with sharing class AccountDAO {

    public static List<Account> getAccount(Set<String> accountUsedFields) {

        String query = new Q(Account.SObjectType)
            .selectFields(accountUsedFields)
            .build();
            
        return Database.query(query);
    }

    public static List<Account> getAccount(Set<String> accountUsedFields, Integer limite) {

        String query = new Q(Account.SObjectType)
            .selectFields(accountUsedFields)
            .addLimit(limite)
            .build();
            
        return Database.query(query);
    }

    public static List<Account> getAccountById(List<String> ids, Set<String> accountUsedFields){

        String query = new Q(Account.SObjectType)
            .selectFields(accountUsedFields)
            .add(Q.condition('Id').isIn(ids))
            .build();
            
        return Database.query(query);

    }
    
    public static List<Account> getAccountByExternalId(List<String> externalIds, Set<String> accountUsedFields) {

        String query = new Q(Account.SObjectType)
            .selectFields(accountUsedFields)
            .add(Q.condition('ExternalId__c').isIn(externalIds))
            .add(Q.condition('ExternalId__c').isNotNull())
            .build();
            
        return Database.query(query);
    }

    public static List<Account> getAccountByExternalId(List<String> externalIds, Set<String> accountUsedFields, Integer limite) {

        String query = new Q(Account.SObjectType)
            .selectFields(accountUsedFields)
            .add(Q.condition('ExternalId__c').equalsTo(externalIds))
            .add(Q.condition('ExternalId__c').isNotNull())
            .addLimit(limite)
            .build();
            
        return Database.query(query);
    }
}