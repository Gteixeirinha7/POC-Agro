public with sharing class Territory2ModelDAO {
    
    public static List<Territory2Model> getTerritory2ModelByDeveloperName(String developerNames, Set<String> territory2ModelUsedFields) {

        String query = new Q(Territory2Model.SObjectType)
            .selectFields(territory2ModelUsedFields)
            .add(Q.condition('DeveloperName').equalsTo(developerNames))
            .build();
            
        return Database.query(query);
    }

}
