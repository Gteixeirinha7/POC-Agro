({
    init : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();   
        var urlEvent = $A.get("e.force:createRecord");
        urlEvent.setParams({
            "entityApiName": "DelimitedLandCultures__c",
            "defaultFieldValues": {
                'DelimitedLand__c' : component.get("v.recordId"),
                'Name' : 'Nova Cultura do Talhão'
            }
        });
        urlEvent.fire(); 
        $A.get("e.force:refreshView").fire();        
    }
})