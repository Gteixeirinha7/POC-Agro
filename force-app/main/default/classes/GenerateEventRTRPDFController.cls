public with sharing class GenerateEventRTRPDFController {

    public GenerateEventRTRPDFController(ApexPages.StandardController stdController) {}

    @RemoteAction
    public static String getEventRTRPDFPageUrl(String eventId){
        PageReference pageRef = Page.EventRTRPDF;
        pageRef.getParameters().put('Id', eventId);

        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        
        return baseUrl + pageRef.getUrl();
    }

}
