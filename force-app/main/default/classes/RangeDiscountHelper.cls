public with sharing class RangeDiscountHelper {
    private static Boolean isEnabled;
    private static Map<String, Set<String>> tableToKeyFields;
    private static Boolean isRunning;
    static{
        isEnabled = true;
    
        isRunning = false;      
    }

    public static Boolean isTriggerEnabled(){
        return isEnabled;
    }
    
    public static Boolean disableTrigger(){
        return isEnabled = false;
    }

    public static Boolean enableTrigger(){
        return isEnabled = true;
    }

    public static void initRangeDiscountValidation(List<RangeDiscount__c> newRangeDiscountList){
        System.debug('newRangeDiscountList: ' + newRangeDiscountList);
        Set<Id> familyIdSet = new Set<Id>();
        Set<Id> salesOfficeIdSet = new Set<Id>();
        for(RangeDiscount__c rd : newRangeDiscountList){
            familyIdSet.add(rd.Family__c);
            salesOfficeIdSet.add(rd.SalesOffice__c);
        }
        Map<Id,Family__c> familyIdMap = new Map<Id,Family__c>([SELECT Id, Name FROM Family__c WHERE Id IN :familyIdSet]);
        Map<Id,SalesOffice__c> salesOfficeIdMap = new Map<Id,SalesOffice__c>([SELECT Id, Name, ParentId__c, ParentId__r.ExternalId__c FROM SalesOffice__c WHERE Id IN :salesOfficeIdSet]);
        for (RangeDiscount__c rd : newRangeDiscountList) {
            rd.ExternalId__c = rd.ApprovingAuthority__c + ';' + rd.PaymentType__c + ';' + familyIdMap.get(rd.Family__c).Name + ';' + rd.CustomerCategory__c + ';' + salesOfficeIdMap.get(rd.SalesOffice__c).Name;
            rd.ClusterExternalId__c = salesOfficeIdMap.get(rd.SalesOffice__c).ParentId__r.ExternalId__c;
            System.debug('rd.ExternalId__c: ' + rd.ExternalId__c);
        }
    }
    public static void rangeDiscountValidation(Map<Id,RangeDiscount__c> rangeDiscountMap) {
        if(isRunning == true){
            return;
        }
        Set<String> approvedAuthoritySet = new Set<String> ();
        Set<String> paymentTypesSet = new Set<String> ();
        Set<Id> productFamilyIdSet = new Set<Id> ();
        Set<Id> salesOfficeIdSet = new Set<Id> ();
        Set<String> customerCategorySet = new Set<String> ();
        
        for (RangeDiscount__c rangeDiscount : rangeDiscountMap.values()) {
            approvedAuthoritySet.add(rangeDiscount.ApprovingAuthority__c);
            paymentTypesSet.add(rangeDiscount.PaymentType__c);
            productFamilyIdSet.add(rangeDiscount.Family__c);
            customerCategorySet.add(rangeDiscount.CustomerCategory__c);
            salesOfficeIdSet.add(rangeDiscount.SalesOffice__c);
        }
        Map<Id,RangeDiscount__c> changeRangeDiscountMap = new Map<Id,RangeDiscount__c> ([
            SELECT Id, ApprovingAuthority__c, FinalDate__c, PaymentType__c, Family__c, CustomerCategory__c,SalesOffice__c, Status__c
            FROM RangeDiscount__c WHERE ApprovingAuthority__c IN: approvedAuthoritySet AND PaymentType__c IN: paymentTypesSet AND
            Family__c IN: productFamilyIdSet AND CustomerCategory__c IN: customerCategorySet AND SalesOffice__c IN: salesOfficeIdSet AND Status__c = 'Aprovado'
        ]);

        //System.debug(changeRangeDiscountMap.values());
        Set<Id> changeRangeDiscountId = new Set<Id> ();
        if (!changeRangeDiscountMap.isEmpty()) {
            for (RangeDiscount__c rangeDiscount : rangeDiscountMap.values()) {
                for (RangeDiscount__c changeRangeDis : changeRangeDiscountMap.values()) {
                    if (changeRangeDis.ApprovingAuthority__c == rangeDiscount.ApprovingAuthority__c &&
                        changeRangeDis.PaymentType__c == rangeDiscount.PaymentType__c &&
                        changeRangeDis.Family__c == rangeDiscount.Family__c &&
                        changeRangeDis.CustomerCategory__c == rangeDiscount.CustomerCategory__c &&
                        changeRangeDis.SalesOffice__c == rangeDiscount.SalesOffice__c &&
                        changeRangeDis.Id != rangeDiscount.Id) {

                        if (!changeRangeDiscountId.contains(changeRangeDis.Id)) {
                            changeRangeDiscountId.add(rangeDiscount.Id);
                            changeRangeDiscountId.add(changeRangeDis.Id);
                            changeRangeDis.FinalDate__c = System.today()-1;  
                            changeRangeDis.Status__c = 'Bloqueado';             
                        }
                    }
                }  
            }
            isRunning = true;
            update changeRangeDiscountMap.values();
            isRunning = false;
        }
    }
}
