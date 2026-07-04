/*
*********************************************************
Apex Class Name    : DFDFW_INTOIC_AddCommentController
Created Date       : 10/21/2024
Author             : Cloud Synapps Inc.
Description        : Class used as controller for add service comment button.
Test Class Name    : DFDFW_INTOIC_AddCommentControllerTest
*********************************************************
*/
public class DFDFW_INTOIC_AddCommentController {
  /*
  *********************************************************
  @method Name    : createCommentOnOIC
  @description    : used to create service comment on application
  @param          : commentString
  @param          : applicationId
  @param          : userId
  @return         :  String
  ********************************************************
  */
  @AuraEnabled
  public static String createCommentOnOIC(
    String commentString,
    String applicationId,
    String userId
  ) {
    try {
      List<Service_Application_Detail__c> appList = [
        SELECT Id, Case_Application_Id__c
        FROM Service_Application_Detail__c
        WHERE Id = :applicationId
        LIMIT 1
      ];
      DFD_CityWorks_Endpoint__mdt mdt = DFD_CityWorks_Endpoint__mdt.getInstance(
        'ServiceComments'
      );
      String endpoint =
        'callout:DFDFW_OIC_Endpoint' +
        mdt.Endpoint_URI__c +
        appList[0].Case_Application_Id__c;

      String accessToken = DFDFW_AUTH0_ManageUserTokenCtrl.getUserAccessToken(
        userId
      );
        
      String commentBody = '{"CommentText": "' + commentString + '"}';
      Map<String, String> headerMap = new Map<String, String>{
        'X-Access-Token' => accessToken,
        'Content-Type' => 'application/json'
      };
      String response = DFDFW_INTGEN_CallOutController.callout(
        endpoint,
        mdt.Method__c,
        true,
        commentBody,
        true,
        headerMap
      );
      Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeuntyped(
        response
      );
      if (responseMap.containsKey('Message')) {
        DFD_Comment__c scom = new DFD_Comment__c();
        scom.DFD_Comment__c = commentString;
        scom.DFD_Service_Application_Detail__c = applicationId;
        scom.DFD_CW_Comment_ID__c = Integer.valueOf(
          responseMap.get('CommentId')
        );
        scom.DFD_Comment_User__c = 'Applicant';
        scom.DFD_Type__c = 'External';
        insert scom;
      }

      return response;
    } catch (Exception e) {
      new DFDFW_LOG_AllException().Module('Service comment controller').Log(e);
      return null;
    }
  }

  /*
    *********************************************************
    @method Name    : getErrorMessageFromMetadata
    @description    : used to get error message from custom metadata
    @param          : component
    @return         : String
    ********************************************************
    */
  @AuraEnabled
  public static String getErrorMessageFromMetadata(String component) {
    String errorString;
    try {
      DFD_Error_Messages__mdt mdt = DFD_Error_Messages__mdt.getInstance(
        component
      );
      errorString = mdt.Error_Message__c;
    } catch (Exception e) {
      new DFDFW_LOG_AllException().Module('My Application controller').Log(e);
    }
    return errorString;
  }
    
    @AuraEnabled
    public static Boolean checkApplicationStatus(String recordId) {
        Boolean showButton = false;
        try {
            List<Service_Application_Detail__c> sa = [SELECT Id, Status__c, Synced_With_City_Works__c, Case_Application_Id__c, Application_Number__c FROM Service_Application_Detail__c WHERE Id =: recordId];
            if(!sa.isEmpty() && sa[0].Status__c != 'Draft' && sa[0].Case_Application_Id__c != null && sa[0].Application_Number__c != null) {
                showButton = true;
            } else {
                showButton = false;
            }
        } catch (Exception e) {
            new DFDFW_LOG_AllException().Module('My Application controller').Log(e);
        }
        return showButton;
    }
}