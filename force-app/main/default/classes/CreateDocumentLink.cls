global with sharing class CreateDocumentLink {

    @InvocableMethod
    global static void getFile(List<Id> recordId){
        System.debug('recordId: ' + recordId);
        Order ord = [SELECT Id, Account.Name,AccountId FROM Order WHERE Id =: recordId[0]];
        String record = recordId[0];

        PageReference reportPage = Page.PdfGeneratorTemplate;
        reportPage.getParameters().put('id',ord.AccountId);
        Blob reportPdf;
        try {
            reportPdf = reportPage.getContentAsPDF();
        }
        catch (Exception e) {
            reportPdf = Blob.valueOf(e.getMessage());
        }

        string paramvalue = EncodingUtil.base64Encode(reportPdf);

        uploadFile(paramvalue,ord.Account.Name,record);
    }
    global static String uploadFile(String base64, String filename, String recordId){

        System.debug('base64: ' + base64);
        System.debug('filename: ' + filename);
        System.debug('RecordId: ' + recordId);
        ContentVersion cv = createContentVersion(base64, filename);
        ContentDocumentLink cdl = createContentLink(cv.Id, recordId);
        
        System.debug('CV: ' + cv);
        System.debug('CDL: ' + cdl);
        
        if (cv == null || cdl == null) { 
            return null; 
        }
        System.debug('Anexado');
        return cdl.Id;
    }

    global static ContentVersion createContentVersion(String base64, String filename) {
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.Title = filename +'.pdf';
        cv.PathOnClient = filename;
        try {
          insert cv;
          return cv;
        } catch(DMLException e) {
          System.debug(e);
          return null;
        }
    }

    global static ContentDocumentLink createContentLink(String contentVersionId, String recordId) {
        if (contentVersionId == null || recordId == null) { 
            return null; 
        }
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: contentVersionId].ContentDocumentId;
        cdl.LinkedEntityId = recordId;
        // ShareType is either 'V', 'C', or 'I'
        // V = Viewer, C = Collaborator, I = Inferred
        cdl.ShareType = 'V';
        try {
            //delete [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
            insert cdl;
            return cdl;
        } catch(DMLException e) {
            System.debug(e);
            return null;
        }
    }
}

