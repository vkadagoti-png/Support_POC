/*
*********************************************************
Apex Class Name    : DFDFW_INTOIC_AddCommentControllerTest
Created Date       : 11/4/2024
Author             : Cloud Synapps Inc.
Description        : Class used as test class for DFDFW_INTOIC_AddCommentController.
*********************************************************
*/
@isTest
private class DFDFW_INTOIC_AddCommentControllerTest {
    
    // Mock implementation for HTTP Callouts
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) { // Change to public
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Message": "Comment successfully created"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    @testSetup
    static void setupTestData() {
        // Creating test data for Service_Application_Detail__c
        Service_Application_Detail__c appDetail = new Service_Application_Detail__c();
        appDetail.Case_Application_Id__c = 123456789;
        insert appDetail;

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(
            LastName = 'Test Contact',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        // Setting up a custom setting or test data for user access token
        DFD_User_Details__c userDetails = new DFD_User_Details__c();
        userDetails.Token_Part_1__c = 'testAccessToken123';
        insert userDetails;
    }

    @isTest
    static void testCreateCommentOnOIC() {
        // Setup mock callout
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Test data setup
        Service_Application_Detail__c appDetail = [
            SELECT Id, Case_Application_Id__c 
            FROM Service_Application_Detail__c
            LIMIT 1
        ];

        String applicationId = appDetail.Id;
        String commentString = 'This is a test comment';
        String userId = UserInfo.getUserId();

        // Invoking the method
        String response = DFDFW_INTOIC_AddCommentController.createCommentOnOIC(
            commentString, 
            applicationId, 
            userId
        );

        Test.stopTest();

        // Validating the response
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assert(response.contains('Comment successfully created'), 'Response should indicate success');

        // Validating that a DFD_Comment__c record was created
        DFD_Comment__c createdComment = [
            SELECT Id, DFD_Comment__c, DFD_Service_Application_Detail__c
            FROM DFD_Comment__c
            WHERE DFD_Service_Application_Detail__c = :applicationId
            LIMIT 1
        ];
        System.assertEquals(commentString, createdComment.DFD_Comment__c, 'Comment text should match');
    }
    
    @isTest
    static void testGetErrorMessageFromMetadata() {
        Test.startTest();
        String component = 'dfdAddServiceComment';
        String errorMessage = DFDFW_INTOIC_AddCommentController.getErrorMessageFromMetadata(component);
        Test.stopTest();
        System.assertEquals('Cannot save comment.', errorMessage, 'The returned error message should match the expected value');
    }
    
    @isTest
    static void testGetServiceAPplicationStatustrue() {
        Service_Application_Detail__c appDetail = new Service_Application_Detail__c();
        appDetail.Case_Application_Id__c = 123456789;
        appDetail.Status__c = 'Submitted';
        appDetail.Synced_With_City_Works__c = true;
        appDetail.Application_Number__c = '123456';
        insert appDetail;
        Test.startTest();
       	Boolean result = DFDFW_INTOIC_AddCommentController.checkApplicationStatus(appDetail.Id);
        System.assertEquals(true, result, 'Result should be true');
    }
    
    @isTest
    static void testGetServiceAPplicationStatusFalse() {
        Service_Application_Detail__c appDetail = new Service_Application_Detail__c();
        appDetail.Case_Application_Id__c = 123456789;
        appDetail.Status__c = 'Submitted';
        appDetail.Application_Number__c = '123456';
        insert appDetail;
        Test.startTest();
       	Boolean result = DFDFW_INTOIC_AddCommentController.checkApplicationStatus(appDetail.Id);
        System.assertEquals(true, result, 'Result should be true');
    }
}