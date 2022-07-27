@RestResource(urlMapping='/ForcaAgroApp/1_0/createDocumentLink/*')
global with sharing class CreateContentDocumentLink {
    
    @HttpPost
    global static DocumentResponse createDocumentLink(String documentReq) {

        DocumentResponse documentResponse = null;
        Savepoint sp = null;

        DocumentRequest documentRequest = (DocumentRequest)JSON.deserialize(documentReq, DocumentRequest.class);
        try{
            sp = Database.setSavepoint();

            if (documentRequest.deleted) {
                List<ContentVersion> contentVersionList = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :documentRequest.contentVersionId];
                if (contentVersionList.size() > 0) {
                    ContentDocument contentDocument = new ContentDocument(
                        Id = contentVersionList[0].ContentDocumentId
                    );
                    Database.DeleteResult delResult = Database.delete(contentDocument, false);

                    if(delResult.isSuccess()){
                        return new DocumentResponse(documentRequest);
                    } else {
                        return new DocumentResponse(delResult.getErrors()[0].getMessage(), documentRequest);
                    }
                } else {
                    return new DocumentResponse(documentRequest);
                }
            } else {
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: documentRequest.contentVersionId].ContentDocumentId;
                cdl.LinkedEntityId = documentRequest.recordId;
                cdl.ShareType = 'V';
                insert cdl;

                return new DocumentResponse(documentRequest);
            }

        } catch (Exception e) {
            Database.rollback(sp);
            documentResponse = new DocumentResponse(e, documentRequest);
        }

        return documentResponse;
    }

    global class DocumentRequest extends DocumentBaseRequest{}

    global abstract class DocumentBaseRequest{
        public String  appCode             {get;set;}
        public String  contentVersionId    {get;set;}
        public String  recordId            {get;set;}
        public Boolean deleted             {get;set;}
    }

    global class DocumentResponse extends DocumentBaseRequest{
        public Boolean hasError {get;set;}
        public String errorMsg  {get;set;}

        public DocumentResponse(Exception ex, DocumentRequest documentRequest){
            this.hasError = true;
            this.errorMsg = ex.getMessage() + '\n Erro :' + ex.getStackTraceString();
            this.appCode  = documentRequest.appCode;
            this.deleted  = documentRequest.deleted;
        } 
        public DocumentResponse(String error, DocumentRequest documentRequest){
            this.hasError = true;
            this.errorMsg = error;
            this.appCode  = documentRequest.appCode;
            this.deleted  = documentRequest.deleted;
        }
        public DocumentResponse(DocumentRequest documentRequest){
            this.hasError = false;
            this.errorMsg = null;
            this.contentVersionId = documentRequest.contentVersionId;
            this.appCode  = documentRequest.appCode;
            this.deleted  = documentRequest.deleted;
        }  
    }

}
