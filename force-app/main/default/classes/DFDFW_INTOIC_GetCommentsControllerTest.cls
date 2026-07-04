/*
*********************************************************
Apex Class Name    : DFDFW_INTOIC_GetCommentsControllerTest
Created Date       : 11/12/2024
Author             : Cloud Synapps Inc.
Description        : Class used as test class for DFDFW_INTOIC_GetCommentsController.
*********************************************************
*/
@isTest
private class DFDFW_INTOIC_GetCommentsControllerTest {
    
    // Test setup method to create necessary test data
    @testSetup
    static void setupTestData() {
        // Create a test Service_Application_Detail__c record
        Service_Application_Detail__c applicationDetail = new Service_Application_Detail__c(
            Case_Application_Id__c = 12345
        );
        insert applicationDetail;
        
        DFD_Comment__c comment = new DFD_Comment__c();
        comment.DFD_Comment__c = 'test new Comment';
        comment.DFD_CW_Comment_ID__c = 2;
        comment.DFD_Service_Application_Detail__c = applicationDetail.Id;
        comment.DFD_Type__c = 'Internal';
        insert comment;
        
        DFD_User_Details__c userDetail = new DFD_User_Details__c();
        userDetail.SetupOwnerId = UserInfo.getUserId();
        userDetail.Token_Part_1__c = 'mockAccessToken';
        insert userDetail;
    }
    
    // Mock callout class
    private class MockCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"CaseComments":[{"CommentId":1,"Comments":"Test comment","AuthorName":"Applicant"}, {"CommentId":2,"Comments":"test new Comment","AuthorName":"City Staff"},{"CommentId":3,"Comments":"Test comment 3","AuthorName":"City Staff"}]}');
            res.setStatusCode(200);
            return res;
        }
    }

    // Test method for the getComment method
    @isTest
    static void testGetComment() {
        // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new MockCallout());

        // Retrieve test application record
        Service_Application_Detail__c applicationDetail = [SELECT Id FROM Service_Application_Detail__c LIMIT 1];
        DFD_User_Details__c userDetail = [SELECT Id, SetupOwnerId, Token_Part_1__c   FROM DFD_User_Details__c  WHERE SetupOwnerId = :UserInfo.getUserId()  LIMIT 1];
        // Call the method under test
        Test.startTest();
        List<DFD_Comment__c> result = DFDFW_INTOIC_GetCommentsController.getComment(applicationDetail.Id, userDetail.SetupOwnerId);
        Test.stopTest();
    }

    // Test method for exception handling
    @isTest
    static void testGetCommentWithException() {
        // Use invalid Id to trigger an exception
        Id invalidApplicationId = Id.valueOf('a0X000000000001'); // Non-existent ID
        
        Test.startTest();
        List<DFD_Comment__c> result = DFDFW_INTOIC_GetCommentsController.getComment(invalidApplicationId, UserInfo.getUserId());
        Test.stopTest();

        // Assertions to verify exception handling
        System.assertEquals(null, result, 'Result should be null in case of exception');
    }
}