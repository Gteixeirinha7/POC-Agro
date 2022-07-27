public with sharing class RangeDiscountDAO {
    
    public static List<RangeDiscount__c> getRangeDiscountByAllInfos(List<String> customerCategorys, List<String> salesOffices, List<String> paymentTypes, List<String> familys, Set<String> rangeDiscountUsedFields) {

        String query = new Q(RangeDiscount__c.SObjectType)
            .selectFields(rangeDiscountUsedFields)
            .add(Q.condition('CustomerCategory__c').isIn(customerCategorys))
            .add(Q.condition('SalesOffice__c').isIn(salesOffices))
            .add(Q.condition('PaymentType__c').isIn(paymentTypes))
            .add(Q.condition('Family__c').isIn(familys))
            .add(Q.condition('Status__c').equalsTo('Aprovado'))
            .build();
            
        return Database.query(query);
    }

}
