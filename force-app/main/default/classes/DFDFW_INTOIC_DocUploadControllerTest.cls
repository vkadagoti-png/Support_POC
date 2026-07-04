/*
*********************************************************
Test Class Name    : DFDFW_INTOIC_DocUploadControllerTest
Date Created       : 12/11/2024
Description        : Test class for DFDFW_INTOIC_DocUploadController
*********************************************************
*/
@isTest
public class DFDFW_INTOIC_DocUploadControllerTest {

    @testSetup
    static void setup() {
        // Insert test Service Application Detail
        Service_Application_Detail__c serviceApp = new Service_Application_Detail__c(Case_Application_Id__c = 12345);
        insert serviceApp;

        // Insert test ContentVersion and ContentDocumentLink
        ContentVersion cv = new ContentVersion(
            Title = 'TestDocument',
            VersionData = Blob.valueOf('Test Data'),
            DFDFW_Synced_With_City_Works__c = false,
            PathOnClient = 'TestDocument.txt'
        );
        insert cv;

        String cdId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1].ContentDocumentId;
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = serviceApp.Id,
            ContentDocumentId = cdId
        );
        insert cdl;

        String userId = UserInfo.getUserId();
        DFD_User_Details__c ud = new DFD_User_Details__c();
        ud.SetupOwnerId = userId;
        ud.isRegistered__c = true;
        ud.Token_Part_1__c = 'daw3adaw3adaw';
        insert ud;
    }

    @isTest
    static void testInvokeMethod() {
        // Prepare input arguments
        Service_Application_Detail__c serviceApp = [SELECT Id FROM Service_Application_Detail__c LIMIT 1];
        Map<String, Object> inputMap = new Map<String, Object>{ 'ContextId' => serviceApp.Id };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Call invokeMethod
        DFDFW_INTOIC_DocUploadController helper = new DFDFW_INTOIC_DocUploadController();
        Boolean result = helper.invokeMethod('uploadFilesToCityWorks', inputMap, outputMap, options);

        // Assert result
        Assert.isTrue(result, 'Method should return true');
    }

    @isTest
    static void testFutureUploadFile_Success() {
        // Set up HTTP Mock
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, 'Success'));

        ContentVersion contentVers = [SELECT Id FROM ContentVersion LIMIT 1];
        // Call future method
        Test.startTest();
        DFDFW_INTOIC_DocUploadController.uploadFile(contentVers.Id, 12345);
        Test.stopTest();

        // Verify ContentVersion was updated
        ContentVersion cv = [SELECT DFDFW_Synced_With_City_Works__c FROM ContentVersion LIMIT 1];
        Assert.isTrue(cv.DFDFW_Synced_With_City_Works__c, 'ContentVersion should be marked as synced');
    }

    @isTest
    static void testFutureUploadFile_Failure() {
        // Set up HTTP Mock for failure
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(400, 'Bad Request'));

        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];
        // Call future method
        Test.startTest();
        DFDFW_INTOIC_DocUploadController.uploadFile(cv.Id, 12345);
        Test.stopTest();

        // Verify logger was inserted
        List<Exception_Logger__c> logs = [SELECT Exception_Message__c FROM Exception_Logger__c LIMIT 1];
        Assert.isTrue(!logs.isEmpty(), 'Exception Logger should contain an entry');
    }

    @isTest
    static void testCallMethod() {
        // Prepare arguments for Callable
        Service_Application_Detail__c serviceApp = [SELECT Id FROM Service_Application_Detail__c LIMIT 1];
        Map<String, Object> args = new Map<String, Object>{
            'input' => new Map<String, Object>{ 'ContextId' => serviceApp.Id },
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };

        // Call Callable method
        DFDFW_INTOIC_DocUploadController helper = new DFDFW_INTOIC_DocUploadController();
        Object result = helper.call('uploadFilesToCityWorks', args);

        // Assert result
        Assert.isNotNull(result, 'Callable method should return a non-null result');
    }

    // Mock HTTP Callout Generator
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;

        public MockHttpResponseGenerator(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            return res;
        }
    }
}