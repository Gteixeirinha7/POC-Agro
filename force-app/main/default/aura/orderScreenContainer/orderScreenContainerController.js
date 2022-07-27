({
    navigateToeDiscoverySearchCmp : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef: "c:createOrder",
            componentAttributes: {
                recordId: component.get("v.recordId")
            }
        });
        evt.fire();
        //var workspaceAPI = component.find("workspace");
        //workspaceAPI = component.find("workspace");
        //workspaceAPI.navigateToeDiscoverySearchCmp({
            //url: '#/Pedidos', 
            //focus: true
        //})
        /*var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            url: '/Pedidos/n'

        })
        urlEvent.fire()*/

            /*var pageReference = {
                type: 'standard__navItemPage',
                attributes: {
                    apiName: 'Pedidos'
                },
                state: {
                    //c__refRecordId: component.get("v.recordId")
                }
            };

            component.set("v.pageReference", pageReference);

            const navService = component.find('navService');
            const pageRef = component.get('v.pageReference');

            const handleUrl = (url) => {
                window.open(url);
            };
            const handleError = (error) => {
                console.log(error);
            };

            navService.generateUrl(pageRef).then(handleUrl, handleError);*/
    }
})