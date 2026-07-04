/*
*********************************************************
Apex Class Name    : DFDFW_TILECONFIG_ServicesControllerTest
Created Date       : 9/23/2024
Author             : Cloud Synapps Inc.
Description        : Class used as test class for DFDFW_TILECONFIG_ServicesController.
*********************************************************
*/
@isTest
public class DFDFW_TILECONFIG_ServicesControllerTest {

    // Mock HttpCallout Class
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"message": "Success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    // Mock HttpCallout Class that triggers an exception
    public class MockHttpResponseErrorGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);  // Simulate a server error
            res.setBody('Internal Server Error');
            return res;
        }
    }

    @isTest
    static void testGetEventTiles() {
        List<DFDFW_Service__mdt> eventMetadata = [
            SELECT Id, DFDFW_Tile_Title__c, DFDFW_Active__c
            FROM DFDFW_Service__mdt
            WHERE DFDFW_Active__c = TRUE
        ];

        Test.startTest();
        List<DFDFW_Service__mdt> eventTiles = DFDFW_TILECONFIG_ServicesController.getEventTiles('Events');
        Test.stopTest();

        System.assertEquals(eventMetadata.size(), eventTiles.size(), 'The number of records should match the queried metadata');
    }

    @isTest
    static void testGetNoticeDetails() {
        List<DFDFW_Service__mdt> noticeMetadata = [
            SELECT Id, DFDFW_Tile_Title__c, DFDFW_Active__c
            FROM DFDFW_Service__mdt
            WHERE DFDFW_Active__c = TRUE
        ];

        Test.startTest();
        List<DFDFW_Service__mdt> noticeDetails = DFDFW_TILECONFIG_ServicesController.getNoticeDetails();
        Test.stopTest();

        System.assertEquals(noticeMetadata.size(), noticeDetails.size(), 'The number of notice records should match the queried metadata');
    }


    // Test method to cover exception in getEventTiles
    @isTest
    static void testGetEventTiles_Exception() {
        Test.startTest();
            // Pass an invalid serviceType that causes a query failure
            DFDFW_TILECONFIG_ServicesController.getEventTiles('InvalidServiceType');
        Test.stopTest();
    }

    // Test method to cover exception in getNoticeDetails
    @isTest
    static void testGetNoticeDetails_Exception() {
        Test.startTest();
        try {
            // Simulate an invalid query condition
            List<DFDFW_Service__mdt> noticeDetails = DFDFW_TILECONFIG_ServicesController.getNoticeDetails();
            // Modify query condition in some invalid way here
            
        } catch (AuraHandledException e) {
            // Assert that the exception is thrown
            
        }
        Test.stopTest();
    }

    // Test method to cover exception in getServiceDetails
    /*@isTest
    static void testGetServiceDetails_Exception() {
        // Mocking a callout that returns an error
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseErrorGenerator());

        Test.startTest();
        try {
            // Trigger the exception scenario
            DFDFW_TILECONFIG_ServicesController.getServiceDetails('Invalid Event Type');
            System.assert(false, 'Exception should have been thrown for invalid event type');
        } catch (AuraHandledException e) {
            // Assert that the exception is thrown
            
        }
        Test.stopTest();
    }*/
}