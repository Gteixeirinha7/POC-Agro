public with sharing class UserDAO {
    
    public static List<User> getUserByExternalId(List<String> externalIds, Set<String> userUsedFields) {

        String query = new Q(User.SObjectType)
            .selectFields(userUsedFields)
            .add(Q.condition('ExternalId__c').isIn(externalIds))
            .build();
            
        return Database.query(query);
    }

    public static User getUserById(String id, Set<String> userUsedFields) {

        String query = new Q(User.SObjectType)
            .selectFields(userUsedFields)
            .add(Q.condition('Id').equalsTo(id))
            .addLimit(1)
            .build();
            
        return Database.query(query);
    }

}
