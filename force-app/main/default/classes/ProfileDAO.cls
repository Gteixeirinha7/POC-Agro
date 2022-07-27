public with sharing class ProfileDAO {
    
    public static List<Profile> getProfileByName(List<String> names, Set<String> profileUsedFields, Integer limite) {

        String query = new Q(Profile.SObjectType)
            .selectFields(profileUsedFields)
            .add(Q.condition('Name').isIn(names))
            .addLimit(limite)
            .build();
            
        return Database.query(query);
    }

}
