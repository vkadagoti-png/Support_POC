/*
*********************************************************
Apex Class Name    : DFDFW_INTOIC_GetPermitsControllerTest
Created Date       : 10/30/2024
Author             : Cloud Synapps Inc.
Description        : Class used as test class for DFDFW_INTOIC_GetPermitsController.
*********************************************************
*/
@isTest
private class DFDFW_INTOIC_GetPermitsControllerTest {
    
    @testSetup
    static void setup() {
        // Set up a mock Custom Setting for the user access token
        DFD_User_Details__c userSetting = new DFD_User_Details__c(
            Name = 'User_' + UserInfo.getUserId(),
            Token_Part_1__c = 'testAccessToken1',
            Token_Part_2__c = 'testAccessToken2',
            Token_Part_3__c = 'testAccessToken3',
            Token_Part_4__c = 'testAccessToken4'
        );
        insert userSetting;
    }

    @isTest
    static void testGetDataFromOIC() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Use the helper method to return mock data
        DFD_CityWorks_Endpoint__mdt cityWorksMdt = new DFD_CityWorks_Endpoint__mdt();
        cityWorksMdt.Endpoint_URI__c = '/api/getApplications';
        cityWorksMdt.Method__c = 'GET';

        System.Test.stopTest();

        // Validate results
        String testUserId = UserInfo.getUserId();
        List<Object> result = DFDFW_INTOIC_GetPermitsController.getDataFromOIC(testUserId);
        System.assertNotEquals(null, result, 'The result should not be null');
        System.assertEquals(2, result.size(), 'The result should contain two objects');
    }

    @isTest
    static void testGetColumnNamesFromMetadata() {
        // Mock metadata fields directly using helper method
        Test.startTest();
        String metadataLabel = 'permitApplication';
        String columnNames = DFDFW_INTOIC_GetPermitsController.getColumnNamesFromMetadata(metadataLabel);
        Test.stopTest();

        // Validate results
        System.assertEquals('CASE_NUMBER,LOCATION,DATE_CREATED', columnNames, 'The returned column names should match the expected value');
    }
    
    @isTest
    static void testGetErrorMessageFromMetadata() {
        Test.startTest();
        String component = 'dfdMyApplications';
        String errorMessage = DFDFW_INTOIC_GetPermitsController.getErrorMessageFromMetadata(component);
        Test.stopTest();
        System.assertEquals('The system is not able to pull permit history at this time. Please try again later.', errorMessage, 'The returned error message should match the expected value');
    }

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('[{"Name":"Application1","Status":"Active"},{"Name":"Application2","Status":"Closed"}]');
            return res;
        }
    }
}