({
    navigateToeDiscoverySearchCmp : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef: "c:orderScreen",
            componentAttributes: {
                orderTypeMP: 'SFMP'
            }
        });
        evt.fire();
        window.sessionStorage.setItem('OrderType', 'SFMP');
    }
})