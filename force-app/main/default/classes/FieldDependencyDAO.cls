public with sharing class FieldDependencyDAO {
    
    public static FieldDependency__c getFieldDependency(String dependencyFieldKey, String dependencyField, String value, Set<String> fieldDependencyUsedFields) {

        String query = new Q(FieldDependency__c.SObjectType)
            .selectFields(fieldDependencyUsedFields)
            .add(Q.condition('DependencyFieldKey__c').equalsTo(dependencyFieldKey))
            .add(Q.condition('DependencyField__c').equalsTo(dependencyField))
            .add(Q.condition('Value__c').equalsTo(value))
            .addLimit(1)
            .build();
            
        return Database.query(query);
    }


}
