public with sharing class ObjectTerritory2AssociationDAO {
    
    public static List<ObjectTerritory2Association> getObjectTerritory2AssociationByTerritory2Id(List<String> acc2Ids, List<String> territory2Ids, Set<String> objectTerritory2AssociationUsedFields) {

        String query = new Q('ObjectTerritory2Association')
            .selectFields(objectTerritory2AssociationUsedFields)
            .add(Q.condition('Territory2Id').isIn(territory2Ids))
            .add(Q.condition('ObjectId').isIn(acc2Ids))
            .build();
            
        return Database.query(query);
    }

    public static List<ObjectTerritory2Association> getObjectTerritory2AssociationByObjectId(List<String> objectIds, Set<String> objectTerritory2AssociationUsedFields) {

        String query = new Q('ObjectTerritory2Association')
            .selectFields(objectTerritory2AssociationUsedFields)
            .add(Q.condition('ObjectId').isIn(objectIds))
            .build();
            
        return Database.query(query);
    }

}
