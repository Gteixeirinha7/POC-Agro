({    
    doInit : function(component, event, helper) {
       var action = component.get("c.getEventData");
        action.setParams({"eventid": component.get("v.recordId")});

        action.setCallback(this, function(response) {
        $A.get("e.force:closeQuickAction").fire();   
            var eventId = component.get("v.recordId"); 
            var urlEvent = $A.get("e.force:createRecord");
            urlEvent.setParams({
                "entityApiName": "Case",
                "defaultFieldValues": {
                    'Comments' : eventId,
                    'Origin'  : 'Presencial',
                    'Crop__c' :  response.getReturnValue().Crop__c,
                    'AccountId' :  response.getReturnValue().AccountId,
                    'Subject' :  response.getReturnValue().Subject,
                    'Description' :  response.getReturnValue().Description
                }
            });
            urlEvent.fire(); 
            $A.get("e.force:refreshView").fire();        
        });
        
        $A.enqueueAction(action);
	},
    invoke : function(component, event, helper) {
       var action = component.get("c.getEventData");
        action.setParams({"eventid": component.get("v.recordId")});

        action.setCallback(this, function(response) {
        $A.get("e.force:closeQuickAction").fire();   
            var eventId = component.get("v.recordId"); 
            var urlEvent = $A.get("e.force:createRecord");
            urlEvent.setParams({
                "entityApiName": "Case",
                "defaultFieldValues": {
                    'Comments' : eventId,
                    'Origin'  : 'Presencial',
                    'AccountId' :  response.getReturnValue().AccountId,
                    'Crop__c' :  response.getReturnValue().Crop__c,
                    'Subject' :  response.getReturnValue().Subject,
                    'Description' :  response.getReturnValue().Description
                }
            });
            urlEvent.fire(); 
            $A.get("e.force:refreshView").fire();        
        });
        
        $A.enqueueAction(action);
    }
})