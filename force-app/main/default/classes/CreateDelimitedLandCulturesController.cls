@RestResource(urlMapping='/ForcaAgroApp/1_0/sendDelimitedLandCulturesData/*')
global with sharing class CreateDelimitedLandCulturesController {

    @HttpPost
    global static DelimitedLandCulturesResponse createDelimitedLandCulturesApp(String delimitedLandCulturesReq){
        DelimitedLandCulturesResponse delimitedLandCulturesResponse = null;
        Savepoint sp = null;

        DelimitedLandCulturesRequest delimitedLandCulturesRequest = (DelimitedLandCulturesRequest)JSON.deserialize(delimitedLandCulturesReq, DelimitedLandCulturesRequest.class);
        try{
            sp = Database.setSavepoint();

            DelimitedLandCultures__c delimitedLandCultures = serializeDelimitedLandCultures(delimitedLandCulturesRequest);

            if (delimitedLandCulturesRequest.deleted) {
                List<DelimitedLandCultures__c> delimitedLandCulturesList = [
                    SELECT Id FROM DelimitedLandCultures__c WHERE Id = :delimitedLandCultures.Id
                ];
                if (delimitedLandCulturesList.size() > 0) {
                    Database.DeleteResult delResult = Database.delete(delimitedLandCultures, false);

                    if(delResult.isSuccess()){
                        return new DelimitedLandCulturesResponse(delimitedLandCulturesRequest, delResult.getId());
                    } else {
                        return new DelimitedLandCulturesResponse(delResult.getErrors()[0].getMessage(), delimitedLandCulturesRequest);
                    }
                } else {
                    return new DelimitedLandCulturesResponse(delimitedLandCulturesRequest, delimitedLandCultures.Id);
                }
            } else {
                Boolean updateContext = (delimitedLandCultures.Id != null);

                Database.SaveResult upsResult = updateContext ? Database.update(delimitedLandCultures, false) : Database.insert(delimitedLandCultures, false); 

                if(upsResult.isSuccess()){
                    return new DelimitedLandCulturesResponse(delimitedLandCulturesRequest, upsResult.getId());
                } else {
                    return new DelimitedLandCulturesResponse(upsResult.getErrors()[0].getMessage(), delimitedLandCulturesRequest);
                }
            }

        } catch (Exception e) {
            Database.rollback(sp);
            delimitedLandCulturesResponse = new DelimitedLandCulturesResponse(e, delimitedLandCulturesRequest);
        }

        return delimitedLandCulturesResponse;
    }

    global abstract class DelimitedLandCulturesBaseRequest{
        public String  id                   {get;set;}
        public Integer appCode              {get;set;}
        public String  cropId               {get;set;}
        public String  cultureId            {get;set;}
        public String  plantingDate         {get;set;}
        public String  delimitedLand        {get;set;}
        public Decimal areaCultivated       {get;set;}
        public String  technologicalLevel   {get;set;}
        public Decimal warehouseCapability  {get;set;}
        public Boolean deleted              {get;set;}
    }

    global class DelimitedLandCulturesRequest extends DelimitedLandCulturesBaseRequest{}

    public static DelimitedLandCultures__c serializeDelimitedLandCultures(DelimitedLandCulturesRequest delimitedLandCulturesRequest) {
        DelimitedLandCultures__c delimitedLandCultures = new DelimitedLandCultures__c(
            Id                      = delimitedLandCulturesRequest.id,
            AreaCultivated__c       = delimitedLandCulturesRequest.areaCultivated,
            Crop__c                 = delimitedLandCulturesRequest.cropId,
            Culture__c              = delimitedLandCulturesRequest.cultureId,
            Date__c                 = Date.valueOf(delimitedLandCulturesRequest.plantingDate),
            DelimitedLand__c        = delimitedLandCulturesRequest.delimitedLand,
            WarehouseCapability__c  = delimitedLandCulturesRequest.warehouseCapability
        );
        if (!String.isBlank(delimitedLandCulturesRequest.technologicalLevel)) {
            delimitedLandCultures.TechnologicalLevel__c = delimitedLandCulturesRequest.technologicalLevel;
        }
        return delimitedLandCultures;
    }

    global class DelimitedLandCulturesResponse extends DelimitedLandCulturesBaseRequest{
        @AuraEnabled public Boolean hasError {get;set;}
        @AuraEnabled public String errorMsg  {get;set;}

        public DelimitedLandCulturesResponse(Exception ex, DelimitedLandCulturesRequest delimitedLandCulturesRequest){
            this.hasError = true;
            this.errorMsg = ex.getMessage() + '\n Erro :' + ex.getStackTraceString();
            this.appCode  = delimitedLandCulturesRequest.appCode;
            this.deleted  = delimitedLandCulturesRequest.deleted;
        } 
        public DelimitedLandCulturesResponse(String error, DelimitedLandCulturesRequest delimitedLandCulturesRequest){
            this.hasError = true;
            this.errorMsg = error;
            this.appCode  = delimitedLandCulturesRequest.appCode;
            this.deleted  = delimitedLandCulturesRequest.deleted;
        }
        public DelimitedLandCulturesResponse(DelimitedLandCulturesRequest delimitedLandCulturesRequest, String accountId){
            this.hasError = false;
            this.errorMsg = null;
            this.id       = accountId;
            this.appCode  = delimitedLandCulturesRequest.appCode;
            this.deleted  = delimitedLandCulturesRequest.deleted;
        }  
    }
}