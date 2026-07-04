/*
*********************************************************
Apex Class Name    : DFDFW_INTAUTH0_LoginController
Created Date       : 8/2/2024
Author             : Cloud Synapps Inc.
Description        : Class used to get redirect url form custom setting to redirect on auth0 login page. 
Test Class Name    : DFD_RecentApplicationsViewControllerTest
*********************************************************
*/

global without sharing class DFDFW_INTAUTH0_LoginController {
  static String REDIRECT_REGISTER = 'register';

  /*
  *********************************************************
  @method Name    : getRedirectUrl
  @description    : used to get redirect urls
  @param          : 
  @return         : Map<String, String>
  ********************************************************
  */
  @AuraEnabled
  global static Map<String, String> getRedirectUrl() {
    try {
      Map<String, String> returnMap = new Map<String, String>();
      DFD_Redirect_URLs__c urls = DFD_Redirect_URLs__c.getInstance();
      returnMap.put(REDIRECT_REGISTER, urls.Register_Page_Redirect__c);
      return returnMap;
    } catch (Exception e) {new DFDFW_LOG_AllException().Module('Redirect Auth0 Login Controller').Log(e); throw new AuraHandledException(e.getMessage());}
  }
}