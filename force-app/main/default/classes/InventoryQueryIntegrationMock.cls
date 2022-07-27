public with sharing class InventoryQueryIntegrationMock implements HttpCalloutMock {

    private final String  body;
    private final Integer status;

    public InventoryQueryIntegrationMock(Boolean isSuccess, String body) {
        this.body    = body;
        this.status  = isSuccess ? 200 : 400;
    }
    
    public HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(status);
		response.setBody(body);
        return response;
    }
}
