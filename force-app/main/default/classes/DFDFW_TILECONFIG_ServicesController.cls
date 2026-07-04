/*
*********************************************************
Apex Class Name    : DFDFW_TILECONFIG_ServicesController
Created Date       : 7/3/2024
Author             : Cloud Synapps Inc.
Description        : Class used as controller for getting details related to services.
Test Class Name    : DFDFW_TILECONFIG_ServicesControllerTest
*********************************************************
*/
public with sharing class DFDFW_TILECONFIG_ServicesController {
  /*
  *********************************************************
  @method Name    : getEventTiles
  @description    : used to get metadata for services.
  @param          : serviceType
  @return         : List<DFDFW_Service__mdt>
  ********************************************************
  */
  @AuraEnabled(cacheable=true)
  public static List<DFDFW_Service__mdt> getEventTiles(String serviceType) {
    try {
      List<DFDFW_Service__mdt> eventList = new List<DFDFW_Service__mdt>();
        eventList =[SELECT Id, DFDFW_Tile_Title__c, DFDFW_Active__c, DFDFW_Icon_File_Name__c, DFDFW_Notice_Text__c,
          			DFDFW_Service_URL__c, DFDFW_Tile_Subheading__c, DFDFW_Address_Validation__c,
          				DFDFW_Document_Upload__c FROM DFDFW_Service__mdt
                    	WHERE DFDFW_Active__c = TRUE];
      return eventList;
    } catch (Exception e) {new DFDFW_LOG_AllException().Module('Services Controller').Log(e); throw new AuraHandledException(e.getMessage() + '===>' + e.getLineNumber());}
  }

  /*
  *********************************************************
  @method Name    : getNoticeDetails
  @description    : used to get notice details from metadata.
  @param          : 
  @return         : List<DFDFW_Service__mdt>
  ********************************************************
  */
  @AuraEnabled(cacheable=true)
  public static List<DFDFW_Service__mdt> getNoticeDetails() {
    try {
      List<DFDFW_Service__mdt> noticeEventList = new List<DFDFW_Service__mdt>();
        noticeEventList = [SELECT Id, DFDFW_Tile_Title__c, DFDFW_Active__c, DFDFW_Notice_Text__c,
          					DFDFW_Tile_Subheading__c FROM DFDFW_Service__mdt
        					WHERE DFDFW_Active__c = TRUE];
      return noticeEventList;
    } catch (Exception e) {new DFDFW_LOG_AllException().Module('Services Controller').Log(e); throw new AuraHandledException(e.getMessage() + '===>' + e.getLineNumber());}
  }

  /*
  *********************************************************
  @method Name    : getServiceDetails
  @description    : used to get event informations
  @param          : evenType
  @return         : String
  ********************************************************
  */
  /*@AuraEnabled
  public static String getServiceDetails(String eventType) {
    try {
      DFDFW_Service__mdt ge = [SELECT EventPermitEndpoint__c, DFDFW_Address_Validation__c, DFDFW_Tile_Title__c
        					FROM DFDFW_Service__mdt WHERE DFDFW_Tile_Title__c = :eventType LIMIT 1];
      String endpoint = ge.EventPermitEndpoint__c;
      String jsonBody = DFDFW_INTGEN_CallOutController.callout( endpoint,'GET', false, null, false, null);
      return jsonBody;
    } 
      catch (Exception e) {new DFDFW_LOG_AllException().Module('Services controller').Log(e);throw new AuraHandledException(e.getMessage());}
  }*/
}