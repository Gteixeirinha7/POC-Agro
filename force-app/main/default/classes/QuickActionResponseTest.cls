@isTest
public with sharing class QuickActionResponseTest {
    @isTest
    public static void QuickActionResponseTestSuccess(){
        QuickActionResponse.Response qarResponse = new QuickActionResponse.Response(false, false, 'Teste', 'Teste');
    }
}
