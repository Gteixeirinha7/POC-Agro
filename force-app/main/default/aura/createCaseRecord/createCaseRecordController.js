({
    init : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();   
        var campaignId = component.get("v.recordId"); 
        var urlEvent = $A.get("e.force:createRecord");
        urlEvent.setParams({
            "entityApiName": "Case",
            "defaultFieldValues": {
                'RecordTypeId' : '0128a000000dPthAAE',
                'AccountId' : campaignId,
            }
        });
        urlEvent.fire(); 
        $A.get("e.force:refreshView").fire();        
    }
})