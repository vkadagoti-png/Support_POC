/*
*********************************************************
Apex Class Name    : DFDFW_INTGEN_CallOutControllerTest
Created Date       : 9/4/2024
Author             : Cloud Synapps Inc.
Description        : Class used as test class for DFDFW_INTGEN_CallOutController.
*********************************************************
*/
@isTest
public class DFDFW_INTGEN_CallOutControllerTest {
  @isTest
  static void testCalloutWithBodyAndHeader() {
    // Set up the mock response
    Test.setMock(HttpCalloutMock.class, new DFD_CalloutMock());

    // Call the method under test
    String response = DFDFW_INTGEN_CallOutController.callout(
      'https://api.example.com/data',
      'POST',
      true,
      '{"key": "value"}',
      true,
      new Map<String, String>{ 'Content-Type' => 'application/json' }
    );

    // Verify the response
    System.assertEquals(
      '{"mockKey": "mockValue"}',
      response,
      'Response should match the expected mock response'
    );
  }

  @isTest
  static void testCalloutWithoutBodyAndHeader() {
    // Set up the mock response
    Test.setMock(HttpCalloutMock.class, new DFD_CalloutMock());

    // Call the method under test
    String response = DFDFW_INTGEN_CallOutController.callout(
      'https://api.example.com/data',
      'GET',
      false,
      null,
      false,
      new Map<String, String>()
    );

    // Verify the response
    System.assertEquals(
      '{"mockKey": "mockValue"}',
      response,
      'Response should match the expected mock response'
    );
  }

  @isTest
  static void testCalloutWithError() {
    // Set up the mock response to simulate an error
    Test.setMock(HttpCalloutMock.class, new DFD_CalloutErrorMock());

    // Call the method under test
    String response = DFDFW_INTGEN_CallOutController.callout(
      'https://api.example.com/data',
      'POST',
      true,
      '{"key": "value"}',
      true,
      new Map<String, String>{ 'Content-Type' => 'application/json' }
    );

    // Verify the response is null due to an error
    System.assertEquals(
      null,
      response,
      'Response should be null due to the simulated error'
    );
  }

  // Mock class for a successful callout response
  private class DFD_CalloutMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(200);
      res.setBody('{"mockKey": "mockValue"}');
      return res;
    }
  }

  // Mock class for an error callout response
  private class DFD_CalloutErrorMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(500);
      res.setBody('{"error": "Internal Server Error"}');
      return res;
    }
  }
}