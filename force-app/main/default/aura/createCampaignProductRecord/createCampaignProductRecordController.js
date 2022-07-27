({
    init : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();   
        var campaignId = component.get("v.recordId"); 
        var urlEvent = $A.get("e.force:createRecord");
        urlEvent.setParams({
            "entityApiName": "CampaignProduct__c",
            "defaultFieldValues": {
                'Campaign__c' : campaignId,
                'Name' : 'Novo Produto da Campanha'
            }
        });
        urlEvent.fire(); 
        $A.get("e.force:refreshView").fire();        
    }
})
