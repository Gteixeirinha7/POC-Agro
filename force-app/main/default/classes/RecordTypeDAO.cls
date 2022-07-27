public with sharing class RecordTypeDAO {

    public static List<RecordType> getRecordTypeBySObjectType(List<String> sobjTypes, Set<String> recordTypeUsedFields) {

        String query = new Q('RecordType')
            .selectFields(recordTypeUsedFields)
            .add(Q.condition('SObjectType').isIn(sobjTypes))
            .build();
            
        return Database.query(query);
    }

    public static List<RecordType> getRecordTypeByNameAndSObjectType(List<String> names, List<String> sobjTypes, Set<String> recordTypeUsedFields) {

        String query = new Q('RecordType')
            .selectFields(recordTypeUsedFields)
            .add(Q.condition('Name').isIn(names))
            .add(Q.condition('SObjectType').isIn(sobjTypes))
            .build();
            
        return Database.query(query);
    }
}
