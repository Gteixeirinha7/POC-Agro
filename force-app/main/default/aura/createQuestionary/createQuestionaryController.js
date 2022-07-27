({
    init: function(component, event, helper) {
        //var evt = $A.get("e.force:navigateToComponent");
        //evt.setParams({
        //    componentDef: "c:answersAndQuestionsScreen",
        //    componentAttributes: {
        //        recordId: component.get("v.recordId"),
        //    }
        //});
        //evt.fire();
        //window.sessionStorage.setItem('', '');
    },

    handleClose: function() {
        $A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
        //window.location.reload();
    }
})