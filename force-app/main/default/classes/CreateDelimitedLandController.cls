@RestResource(urlMapping='/ForcaAgroApp/1_0/sendDelimitedLandData/*')
global with sharing class CreateDelimitedLandController {

    @HttpPost
    global static DelimitedLandResponse createDelimitedLandApp(String delimitedLandReq){
        DelimitedLandResponse delimitedLandResponse = null;
        Savepoint sp = null;

        DelimitedLandRequest delimitedLandRequest = (DelimitedLandRequest)JSON.deserialize(delimitedLandReq, DelimitedLandRequest.class);
        try{
            sp = Database.setSavepoint();

            DelimitedLand__c delimitedLand = serializeDelimitedLand(delimitedLandRequest);

            if (delimitedLandRequest.deleted) {
                List<DelimitedLand__c> delimitedLandList = [SELECT Id FROM DelimitedLand__c WHERE Id = :delimitedLand.Id];
                if (delimitedLandList.size() > 0) {
                    Database.DeleteResult delResult = Database.delete(delimitedLand, false);

                    if(delResult.isSuccess()){
                        return new DelimitedLandResponse(delimitedLandRequest, delResult.getId());
                    } else {
                        return new DelimitedLandResponse(delResult.getErrors()[0].getMessage(), delimitedLandRequest);
                    }
                } else {
                    return new DelimitedLandResponse(delimitedLandRequest, delimitedLand.Id);
                }
            } else {
                Boolean updateContext = (delimitedLand.Id != null);

                Database.SaveResult upsResult = updateContext ? Database.update(delimitedLand, false) : Database.insert(delimitedLand, false); 

                if(upsResult.isSuccess()){
                    return new DelimitedLandResponse(delimitedLandRequest, upsResult.getId());
                } else {
                    return new DelimitedLandResponse(upsResult.getErrors()[0].getMessage(), delimitedLandRequest);
                }
            }

        } catch (Exception e) {
            Database.rollback(sp);
            delimitedLandResponse = new DelimitedLandResponse(e, delimitedLandRequest);
        }

        return delimitedLandResponse;
    }

    global abstract class DelimitedLandBaseRequest{
        public String  id                {get;set;}
        public Integer appCode           {get;set;}
        public String  name              {get;set;}
        public String  description       {get;set;}
        public String  accountId         {get;set;}
        public String  unitMeasurement   {get;set;}
        public Decimal areaCultivated    {get;set;}
        public Decimal areaNotAllocated  {get;set;}
        public Decimal areaPasture       {get;set;}
        public Decimal areaPreservation  {get;set;}
        public String  ownerName         {get;set;}
        public String  tenantCultureId   {get;set;}
        public Decimal tenantValue       {get;set;}
        public Decimal tenantTax         {get;set;}
        public Boolean tenant            {get;set;}
        public Decimal tenantArea        {get;set;}
        public String  contractDate      {get;set;}
        public Boolean deleted           {get;set;}
    }

    global class DelimitedLandRequest extends DelimitedLandBaseRequest{}

    public static DelimitedLand__c serializeDelimitedLand(DelimitedLandRequest delimitedLandRequest) {
        DelimitedLand__c delimitedLand = new DelimitedLand__c(
            Id                  = delimitedLandRequest.id,
            Name                = delimitedLandRequest.name,
            Description__c      = delimitedLandRequest.description,
            Account__c          = delimitedLandRequest.accountId,
            AreaCultivated__c   = delimitedLandRequest.areaCultivated,
            AreaNotAllocated__c = delimitedLandRequest.areaNotAllocated,
            AreaPasture__c      = delimitedLandRequest.areaPasture,
            AreaPreservation__c = delimitedLandRequest.areaPreservation,
            UnitMeasurement__c  = delimitedLandRequest.unitMeasurement,
            OwnerName__c        = delimitedLandRequest.ownerName,
            TenantValue__c      = delimitedLandRequest.tenantValue,
            TenantTax__c        = delimitedLandRequest.tenantTax,
            Tenant__c           = delimitedLandRequest.tenant,
            TenantArea__c       = delimitedLandRequest.tenantArea
        );
        if (delimitedLandRequest.tenantCultureId != null) {
            delimitedLand.TenantCulture__c = delimitedLandRequest.tenantCultureId;
        }
        if (delimitedLandRequest.contractDate != null) {
            delimitedLand.ContractDate__c = Date.valueOf(delimitedLandRequest.contractDate);
        }
        return delimitedLand;
    }


    global class DelimitedLandResponse extends DelimitedLandBaseRequest{
        @AuraEnabled public Boolean hasError {get;set;}
        @AuraEnabled public String errorMsg  {get;set;}

        public DelimitedLandResponse(Exception ex, DelimitedLandRequest delimitedLandRequest){
            this.hasError = true;
            this.errorMsg = ex.getMessage() + '\n Erro :' + ex.getStackTraceString();
            this.appCode  = delimitedLandRequest.appCode;
            this.deleted  = delimitedLandRequest.deleted;
        } 
        public DelimitedLandResponse(String error, DelimitedLandRequest delimitedLandRequest){
            this.hasError = true;
            this.errorMsg = error;
            this.appCode  = delimitedLandRequest.appCode;
            this.deleted  = delimitedLandRequest.deleted;
        }
        public DelimitedLandResponse(DelimitedLandRequest delimitedLandRequest, String delimitedLandId){
            this.hasError = false;
            this.errorMsg = null;
            this.id       = delimitedLandId;
            this.appCode  = delimitedLandRequest.appCode;
            this.deleted  = delimitedLandRequest.deleted;
        }  
    }
}
