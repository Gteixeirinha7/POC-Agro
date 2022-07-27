({
    init : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();   
        var urlEvent = $A.get("e.force:createRecord");
        urlEvent.setParams({
            "entityApiName": "DelimitedLand__c",
            "defaultFieldValues": {
                'Account__c' : component.get("v.recordId")
            }
        });
        urlEvent.fire(); 
        $A.get("e.force:refreshView").fire();        
    }
})