public with sharing class PricebookEntryDAO {
    
    public static List<PricebookEntry> getStandardPricebookEntry(List<String> productIds, Set<String> pricebookEntryUsedFields) {

        String query = new Q(PricebookEntry.SObjectType)
            .selectFields(pricebookEntryUsedFields)
            .add(Q.condition('Product2Id').isIn(productIds))
            .add(Q.condition('Pricebook2Id').equalsTo(Pricebook2DAO.getStandardPricebook(new Set<String>{'Id'}).Id))
            .build();
            
        return Database.query(query);
    }

}
