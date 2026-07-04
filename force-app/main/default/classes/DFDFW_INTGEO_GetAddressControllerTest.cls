/*
*********************************************************
Apex Class Name    : DFDFW_INTGEO_GetAddressControllerClassTest
Created Date       : 9/4/2024
Author             : Cloud Synapps Inc.
Description        : Class used as test class for DFDFW_INTGEO_GetAddressControllerClass.
*********************************************************
*/
@isTest
public class DFDFW_INTGEO_GetAddressControllerTest {
  // Mock class for successful callout
  public class DFD_GeoCodeCalloutMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(200);

      // Mock JSON response with candidates
      String jsonResponse =
        '{"candidates":[' +
        '{"address":"123 Test St","location":{"x":10.0,"y":20.0},"score":100},' +
        '{"address":"456 Test Ave","location":{"x":15.0,"y":25.0},"score":85},' +
        '{"address":"789 Test Blvd","location":{"x":5.0,"y":10.0},"score":75}' +
        ']}';
      res.setBody(jsonResponse);
      return res;
    }
  }

  @isTest
  static void testGetAddressCandidate1() {
    // Set the mock callout
    Test.setMock(HttpCalloutMock.class, new DFD_GeoCodeCalloutMock());

    // Mock the callout controller and provide a test street
    String testStreet = 'Test Street';

    Test.startTest();

    // Call the method
    List<Object> addressList = DFDFW_INTGEO_GetAddressController.getAddressCandidate(
      testStreet, 'Address_Candidate'
    );

    Test.stopTest();

    // Assert the size of the result (only score >= 80 should be included)
    System.assertEquals(
      1,
      addressList.size(),
      'There should be one valid address candidates.'
    );

    // Assert that the first candidate is a perfect score (100)
    Map<String, Object> candidate1 = (Map<String, Object>) addressList[0];
    System.assertEquals(
      100,
      candidate1.get('score'),
      'First candidate should have a perfect score of 100.'
    );
    System.assertEquals(
      '123 Test St',
      candidate1.get('address'),
      'Address should match.'
    );

    
  }

  @isTest
  static void testGetAddressCandidateWithError() {
    // Mock error callout
    Test.setMock(HttpCalloutMock.class, new DFD_ErrorCalloutMock());

    // Test street input
    String testStreet = 'Invalid Street';

    Test.startTest();

    try {
      DFDFW_INTGEO_GetAddressController.getAddressCandidate(testStreet, 'Address_Candidate');
      System.assert(false, 'Expected AuraHandledException was not thrown.');
    } catch (Exception e) {
      System.assertEquals(e.getMessage(), 'Script-thrown exception');
    }

    Test.stopTest();
  }

  // Mock class for an error callout
  public class DFD_ErrorCalloutMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(500);
      res.setBody('{"error": "Internal Server Error"}');
      return res;
    }
  }
}