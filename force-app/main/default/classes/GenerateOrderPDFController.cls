public with sharing class GenerateOrderPDFController {

    public GenerateOrderPDFController(ApexPages.StandardController stdController) {}

    @RemoteAction
    public static String getOrderPDFPageUrl(String negotiationId){
        PageReference pageRef = Page.OrderPDF;
        pageRef.getParameters().put('Id', negotiationId);

        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        
        return baseUrl + pageRef.getUrl();
    }

}
