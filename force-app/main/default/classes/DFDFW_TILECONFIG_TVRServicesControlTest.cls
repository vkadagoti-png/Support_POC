@isTest
public with sharing class DFDFW_TILECONFIG_TVRServicesControlTest {
    /*
*********************************************************
Apex Class Name    : DFDFW_TILECONFIG_ServicesControllerTest
Created Date       : 9/23/2024
Author             : Cloud Synapps Inc.
Description        : Class used as test class for DFDFW_TILECONFIG_ServicesController.
*********************************************************
*/


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
            WHERE DeveloperName =: 'X2025_Tornado'
        ];

        Test.startTest();
        List<DFDFW_Service__mdt> eventTiles = DFDFW_TILECONFIG_TVRServicesController.getTVREventTiles('Events');
        Test.stopTest();

        System.assertEquals(eventMetadata.size(), eventTiles.size(), 'The number of records should match the queried metadata');
    }
    
    // Test method to cover exception in getEventTiles
    @isTest
    static void testGetEventTiles_Exception() {
        Test.startTest();
            // Pass an invalid serviceType that causes a query failure
            DFDFW_TILECONFIG_TVRServicesController.getTVREventTiles('InvalidServiceType');
        Test.stopTest();
    }

}