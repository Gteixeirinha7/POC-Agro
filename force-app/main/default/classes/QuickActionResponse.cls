public with sharing class QuickActionResponse {
    public QuickActionResponse() {}

    public class ToastInfo {
        @AuraEnabled public String Title         {get;set;}
        @AuraEnabled public String Message       {get;set;}
        @AuraEnabled public String Type          {get;set;}

        public ToastInfo(String title, String message, String type) {
            this.Title = title;
            this.Message = message;
            this.Type = type;
        }
    }

    public class Response {

        @AuraEnabled public Boolean HasError         {get;set;}
        @AuraEnabled public Boolean BusinessError    {get;set;}
        @AuraEnabled public String Message           {get;set;}
        @AuraEnabled public String ResponseJSON      {get;set;}
        @AuraEnabled public ToastInfo ToastInfo      {get;set;}

        public Response(Boolean hasError, Boolean businessError, String message, String responseJSON) {
            this.HasError      = hasError;
            this.BusinessError = businessError;
            this.Message       = message;
            this.ResponseJSON  = responseJSON;

            this.fillToastInfo();
        }

        public Response(Exception e) {
            this.HasError = true;
            this.BusinessError = false;
            this.Message  = e.getMessage();

            this.fillToastInfo();
        }

        public void fillToastInfo() {
            if (!this.HasError) this.ToastInfo = new ToastInfo('Sucesso', this.Message, 'success');
            else {
                if (this.BusinessError) this.ToastInfo = new ToastInfo('Alerta', this.Message, 'warning');
                else this.ToastInfo = new ToastInfo('Erro', this.message, 'error');
            }
        }
    }
}