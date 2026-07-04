/*
*********************************************************
Apex Class Name    : DFDFW_INTOIC_GetPermitsController
Created Date       : 09/30/2024
Author             : Cloud Synapps Inc.
Description        : Class used as controller for My application history coponent
Test Class Name    : DFDFW_INTOIC_GetPermitsController
*********************************************************
*/
public with sharing class DFDFW_INTOIC_GetPermitsController {
  /*
  *********************************************************
  @method Name    : getDataFromOIC
  @description    : used to get data from City Works
  @param          : userId
  @return         : List<Object>
  ********************************************************
  */
  @AuraEnabled
  public static List<Object> getDataFromOIC(String userId) {
    try {
      String accesstoken = DFDFW_AUTH0_ManageUserTokenCtrl.getUserAccessToken(
        userId
      );
      DFD_CityWorks_Endpoint__mdt mdt = DFD_CityWorks_Endpoint__mdt.getInstance(
        'GetAllForUser'
      );
      String endpoint = 'callout:DFDFW_OIC_Endpoint' + mdt.Endpoint_URI__c;
      UUID randomUUID = UUID.randomUUID();
      Map<String, String> headerMap = new Map<String, String>{
        'X-Access-Token' => accessToken, 'X-Request-Id' => String.valueOf(randomUUID)
      };

      String method = mdt.Method__c;
      String response = DFDFW_INTGEN_CallOutController.callout(
        endpoint,
        method,
        false,
        null,
        true,
        headerMap
      );
      List<Object> responseList = (List<Object>) JSON.deserializeUntyped(
        response
      );
      return responseList;
    } catch (Exception e) {new DFDFW_LOG_AllException().Module('My Application controller').Log(e);return null;}
  }

  /*
  *********************************************************
  @method Name    : getColumnNamesFromMetadata
  @description    : used to get table configurations from metadata
  @param          : metadataLabel
  @return         : String
  ********************************************************
  */
  @AuraEnabled
  public static string getColumnNamesFromMetadata(String metadataLabel) {
    try {
      String fieldString;
      Community_Dashboard_Endpoint__mdt mdt = Community_Dashboard_Endpoint__mdt.getInstance(
        metadataLabel
      );
      if (mdt != null) {
        fieldString = mdt.Fields_To_Display__c;
      }
      return fieldString;
    } catch (Exception e) {new DFDFW_LOG_AllException().Module('My Application controller').Log(e);throw new AuraHandledException(e.getMessage());}
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
            DFD_Error_Messages__mdt mdt = DFD_Error_Messages__mdt.getInstance(component);
            errorString = mdt.Error_Message__c;
        } catch (Exception e) { new DFDFW_LOG_AllException().Module('My Application controller').Log(e); }
        return errorString;
    }
}