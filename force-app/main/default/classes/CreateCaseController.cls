@RestResource(urlMapping='/ForcaAgroApp/1_0/sendCaseData/*')
global with sharing class CreateCaseController {

    @HttpPost
    global static CaseResponse createCaseApp(String caseReq){
        CaseResponse caseResponse = null;
        Savepoint sp = null;

        CaseRequest caseRequest = (CaseRequest)JSON.deserialize(caseReq, CaseRequest.class);
        try{
            sp = Database.setSavepoint();

            Case caseObj = serializeCase(caseRequest);

            if (caseRequest.deleted) {
                List<Case> caseList = [SELECT Id FROM Case WHERE Id = :caseObj.Id];
                if (caseList.size() > 0) {
                    Database.DeleteResult delResult = Database.delete(caseObj, false);

                    if(delResult.isSuccess()){
                        return new CaseResponse(caseRequest, delResult.getId());
                    } else {
                        return new CaseResponse(delResult.getErrors()[0].getMessage(), caseRequest);
                    }
                } else {
                    return new CaseResponse(caseRequest, caseObj.Id);
                }
            } else {
                Boolean updateContext = (caseObj.Id != null);

                Database.SaveResult upsResult = updateContext ? Database.update(caseObj, false) : Database.insert(caseObj, false); 

                if(upsResult.isSuccess()){
                    return new CaseResponse(caseRequest, upsResult.getId());
                } else {
                    return new CaseResponse(upsResult.getErrors()[0].getMessage(), caseRequest);
                }
            }

        } catch (Exception e) {
            Database.rollback(sp);
            caseResponse = new CaseResponse(e, caseRequest);
        }

        return caseResponse;
    }

    global class CaseRequest extends CaseBaseRequest{}

    global abstract class CaseBaseRequest{
        public String  id                   {get;set;}
        public Integer appCode              {get;set;}
        public String  subject              {get;set;}
        public String  description          {get;set;}
        public String  incidentTypePicklist {get;set;}
        public String  origin               {get;set;}
        public String  accountId            {get;set;}
        public String  cropId               {get;set;}
        public String  plotId               {get;set;}
        public String  culturePlotId        {get;set;}
        public Decimal damagedArea          {get;set;}
        public Boolean deleted              {get;set;}
    }

    public static Case serializeCase(CaseRequest caseRequest) {
        Case caseObj = new Case(
            Id                      = caseRequest.id,
            Subject                 = caseRequest.subject,
            Description             = caseRequest.description,
            IncidentTypePicklist__c = caseRequest.incidentTypePicklist,
            Origin                  = caseRequest.origin,
            Status                  = 'New',
            AccountId               = caseRequest.accountId,
            Crop__c                 = caseRequest.cropId,
            Plot__c                 = caseRequest.plotId,
            CulturePlot__c          = caseRequest.culturePlotId,
            DamagedArea__c          = caseRequest.damagedArea
        );

        return caseObj;
    }

    global class CaseResponse extends CaseBaseRequest{
        public Boolean hasError {get;set;}
        public String errorMsg  {get;set;}

        public CaseResponse(Exception ex, CaseRequest caseRequest){
            this.hasError = true;
            this.errorMsg = ex.getMessage() + '\n Erro :' + ex.getStackTraceString();
            this.appCode  = caseRequest.appCode;
            this.deleted  = caseRequest.deleted;
        } 
        public CaseResponse(String error, CaseRequest caseRequest){
            this.hasError = true;
            this.errorMsg = error;
            this.appCode  = caseRequest.appCode;
            this.deleted  = caseRequest.deleted;
        }
        public CaseResponse(CaseRequest caseRequest, String caseId){
            this.hasError = false;
            this.errorMsg = null;
            this.id       = caseId;
            this.appCode  = caseRequest.appCode;
            this.deleted  = caseRequest.deleted;
        }  
    }
}
