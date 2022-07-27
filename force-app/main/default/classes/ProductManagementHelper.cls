public with sharing class ProductManagementHelper {

    private static Boolean isEnabled;
    private static id exclusionListId;
    static{
        isEnabled = true;
        exclusionListId = Schema.SObjectType.ProductManagement__c.getRecordTypeInfosByDeveloperName().get('ExclusionList').getRecordTypeId();
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

    public static void setSalesOrgname(List<ProductManagement__c> productManagementList) {
        Map<Id, SalesTeam__c> salesMap = new Map<Id, SalesTeam__c>([SELECT Id, SalesOrg__r.ExternalId__c FROM SalesTeam__c WHERE Id IN :Collection.of(productManagementList).pluckIds(ProductManagement__c.SalesTeam__c)]);
        
        Map<Id, List<String>> distMap = new Map<Id, List<String>>();
        for(SalesTeam__c slTeam : [SELECT Id, SalesOrg__r.ExternalId__c, DistributionCenter__c FROM SalesTeam__c WHERE DistributionCenter__c IN :Collection.of(productManagementList).pluckIds(ProductManagement__c.DistributionCenter__c)]){
            if(!distMap.containsKey(slTeam.DistributionCenter__c))
                distMap.put(slTeam.DistributionCenter__c, new List<String>());
            distMap.get(slTeam.DistributionCenter__c).add(slTeam.SalesOrg__r.ExternalId__c);
        }
        
        for(ProductManagement__c productManagement : productManagementList){
            List<String> salesOrgList = new List<String>();

            if(productManagement.SalesTeam__c != null && salesMap.containsKey(productManagement.SalesTeam__c))
                salesOrgList.add(salesMap.get(productManagement.SalesTeam__c).SalesOrg__r.ExternalId__c);
                
            if(productManagement.DistributionCenter__c != null && distMap.containsKey(productManagement.DistributionCenter__c))
                salesOrgList.addAll(distMap.get(productManagement.DistributionCenter__c));

            productManagement.SalesOrgName__c = String.join(salesOrgList, ';');
        }
    }
    public static void setExternalId(List<ProductManagement__c> productManagementList) {
        List<String> salesTeamIds = new List<String>();
        List<String> distributionCenterIds = new List<String>();
        List<String> productIds = new List<String>();
        List<String> cropIds = new List<String>();

        for (ProductManagement__c productManagement : productManagementList) {
            if (productManagement.RecordTypeId == exclusionListId) {
                salesTeamIds.add(productManagement.SalesTeam__c);
                cropIds.add(productManagement.Crop__c);
            }
            cropIds.add(productManagement.Crop__c);
            distributionCenterIds.add(productManagement.DistributionCenter__c);
            productIds.add(productManagement.Product2__c);
        }

        Map<Id, SalesTeam__c> salesTeamMap = new Map<Id, SalesTeam__c>(
            SalesTeamDAO.getSalesTeamById(salesTeamIds, new Set<String>{'Id', 'ExternalId__c'})
        );
        Map<Id, DistributionCenter__c> distributionCenterMap = new Map<Id, DistributionCenter__c>(
            DistributionCenterDAO.getDistributionCenterBylId(distributionCenterIds, new Set<String>{'Id', 'ExternalId__c'})
        );
        Map<Id, Product2> productMap = new Map<Id, Product2>(
            Product2DAO.getProduct2ById(productIds, new Set<String>{'Id', 'ExternalId__c'})
        );
        Map<Id, Crop__c> cropMap = new Map<Id, Crop__c>(
            CropDAO.getCropById(cropIds, new Set<String>{'Id', 'ExternalId__c'})
        );

        for (ProductManagement__c productManagement : productManagementList) {
            if (productManagement.RecordTypeId == exclusionListId) {
                String initialDate = productManagement.InitialDate__c != null ? String.valueOf(productManagement.InitialDate__c).replaceAll('-', '') : ''; 
                String endDate     = productManagement.EndDate__c != null ? String.valueOf(productManagement.EndDate__c).replaceAll('-', '') : ''; 
                productManagement.ExternalId__c = productMap.get(productManagement.Product2__c)?.ExternalId__c      + '-' +
                                                  salesTeamMap.get(productManagement.SalesTeam__c)?.ExternalId__c   + '-' +
                                                  cropMap.get(productManagement.Crop__c)?.ExternalId__c;
            } else {
                productManagement.ExternalId__c = productMap.get(productManagement.Product2__c)?.ExternalId__c + '-' +
                                                  distributionCenterMap.get(productManagement.DistributionCenter__c)?.ExternalId__c+ '-' +
                                                  cropMap.get(productManagement.Crop__c)?.ExternalId__c;
            }
        }
    }
}
