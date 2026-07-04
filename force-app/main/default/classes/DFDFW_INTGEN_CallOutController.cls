/*
*********************************************************
Apex Class Name    : DFDFW_INTGEN_CallOutController
Created Date       : 7/2/2024
Author             : Cloud Synapps Inc.
Description        : Class used as common controller for making api callouts
Test Class Name    : DFDFW_INTGEN_CallOutControllerTest
*********************************************************
*/
public class DFDFW_INTGEN_CallOutController {
  /*
  *********************************************************
  @method Name    : callout
  @description    : used to make api callouts
  @param          : endpoint
  @param          : method
  @param          : hasBody
  @param          : body
  @param          : hasHeader
  @return         : String
  ********************************************************
  */
  public static String callout(
    String endpoint,
    String method,
    Boolean hasBody,
    String body,
    Boolean hasHeader,
    Map<String, String> headerMap
  ) {
    try {
      Http http = new Http();
      HttpRequest req = new HttpRequest();
      req.setEndpoint(endpoint);
      req.setMethod(method);
      if (hasHeader) {
        for (String key : headerMap.keySet()) {
          req.setHeader(key, headerMap.get(key));
        }
      }
      if (hasBody) {
        req.setBody(body);
      }
      HttpResponse res = http.send(req);
      String jsonResponse;
      if (res.getStatusCode() == 200) {
        jsonResponse = res.getBody();
      } else {
          Exception_Logger__c logger = new Exception_Logger__c();
          logger.Module_Name__c = 'Error in Callouts';
          logger.Stack_Trace__c = jsonResponse;
          logger.Class_Name__c = 'DFDFW_INTGEN_CallOutController';
          logger.Method_Name__c = 'callout';
          logger.Exception_Type__c = 'API Callout Failure';
          logger.Exception_Cause__c = 'Status Code==> ' + res.getStatusCode();
          logger.Exception_Message__c = res.getBody();
          logger.DFD_X_Request_Id__c = headerMap.get('X-Request-Id');
          logger.Exception_Cause_Override__c = endpoint;
          insert logger;
      }
      return jsonResponse;
    } catch (Exception e) {new DFDFW_LOG_AllException().Module('callout controller').Log(e);return null;}
  }
}