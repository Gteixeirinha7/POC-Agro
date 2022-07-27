@RestResource(urlMapping='/ForcaAgroApp/1_0/createContentDistribution/*')
global without sharing class CreateContentDistribution {
    
    @HttpPost
    global static Response createContentDistribuction(String contentVersionId, String recordId, String fileName){
        try {
            ContentDocumentLink contentDocumentLink = CreateDocumentLink.createContentLink(contentVersionId, recordId);
            ContentDistribution contentDistribution = new ContentDistribution(
                Name                             = fileName,
                ContentVersionId                 = contentVersionId,
                PreferencesAllowViewInBrowser    = true,
                PreferencesLinkLatestVersion     = true,
                PreferencesNotifyOnVisit         = false,
                PreferencesPasswordRequired      = false,
                PreferencesAllowOriginalDownload = true
            );
            insert contentDistribution;

            ContentDistribution contentDistributionInserted = [SELECT Id, DistributionPublicUrl FROM ContentDistribution WHERE Id = :contentDistribution.Id];

            Order order = [SELECT Id, DistributionPublicUrl__c FROM Order WHERE Id = :recordId LIMIT 1];
            order.DistributionPublicUrl__c = (String.isBlank(order.DistributionPublicUrl__c) ? '' : order.DistributionPublicUrl__c + ';') + 
                							 contentDistributionInserted.DistributionPublicUrl;
            update order;

            return new Response(contentDistributionInserted.DistributionPublicUrl);

        } catch(Exception ex) {
            return new Response(true, ex.getMessage());
        }
    }

    global class Response {
        public Boolean hasError                 {get;set;}
        public String  errorMsg                 {get;set;}
        public String  distributionPublicUrl    {get;set;}

        public Response(String distributionPublicUrl) {
            this.distributionPublicUrl = distributionPublicUrl;
            this.hasError = false;
        }

        public Response(Boolean hasError, String errorMsg) {
            this.hasError = hasError;
            this.errorMsg = errorMsg;
        }
    }
}