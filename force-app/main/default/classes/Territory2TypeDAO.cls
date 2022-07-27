public with sharing class Territory2TypeDAO {
    
    public static List<Territory2Type> getTerritory2TypeByDeveloperName(String developerNames, Set<String> territory2TypeUsedFields) {

        String query = new Q(Territory2Type.SObjectType)
            .selectFields(territory2TypeUsedFields)
            .add(Q.condition('DeveloperName').equalsTo(developerNames))
            .build();
            
        return Database.query(query);
    }

}
