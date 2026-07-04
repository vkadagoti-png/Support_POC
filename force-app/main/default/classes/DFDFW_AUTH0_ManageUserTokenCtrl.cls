/*
*********************************************************
Apex Class Name    : DFDFW_AUTH0_ManageUserTokenCtrl
Created Date       : 9/30/2024
Author             : Cloud Synapps Inc.
Description        : Class used as controller for recent application view component.
*********************************************************
*/
global with sharing class DFDFW_AUTH0_ManageUserTokenCtrl {
  /*
  *********************************************************
  @method Name    : getUserAccessToken
  @description    : used to get access token
  @param          : userId
  @return         : String
  ********************************************************
  */
  global static string getUserAccessToken(String userId) {
    try {
      String accessToken;
      DFD_User_Details__c userDetails = DFD_User_Details__c.getInstance(userId);
      if (userDetails.Token_Part_1__c != null) {
        accessToken = userDetails.Token_Part_1__c;
      }
      if (userDetails.Token_Part_2__c != null) {
        accessToken += userDetails.Token_Part_2__c;
      }
      if (userDetails.Token_Part_3__c != null) {
        accessToken += userDetails.Token_Part_3__c;
      }
      if (userDetails.Token_Part_4__c != null) {
        accessToken += userDetails.Token_Part_4__c;
      }
      return accessToken;
    } catch (Exception e) {
      new DFDFW_LOG_AllException().Module('User detail custom setting controller').Log(e);
	  return null;
    }
  }

  /*
  *********************************************************
  @method Name    : saveAccessToken
  @description    : used to save access token
  @param          : accessToken
  @param		  : userId
  ********************************************************
  */
  global static void saveAccessToken(String accessToken, String userId) {
    try {
      DFD_User_Details__c usd = DFD_User_Details__c.getInstance(userId);
      Integer tokenLength = accessToken.length();
      if (tokenLength > 765) {
        usd.Token_Part_1__c = accessToken.subString(0, 255);
        usd.Token_Part_2__c = accessToken.subString(255, 510);
        usd.Token_Part_3__c = accessToken.subString(510, 765);
        usd.Token_Part_4__c = accessToken.subString(765, tokenLength);
      } else if (tokenLength > 510) {
        usd.Token_Part_1__c = accessToken.subString(0, 255);
        usd.Token_Part_2__c = accessToken.subString(255, 510);
        usd.Token_Part_3__c = accessToken.subString(510, tokenLength);
      } else if (tokenLength > 255) {
        usd.Token_Part_1__c = accessToken.subString(0, 255);
        usd.Token_Part_2__c = accessToken.subString(255, tokenLength);
      } else if (tokenLength > 0) {
        usd.Token_Part_1__c = accessToken.subString(0, tokenLength);
      }
      usd.isRegistered__c = true;
      if (usd.Id == null) {
        insert usd;
      } else {
        update usd;
      }
    } catch (Exception e) {
      new DFDFW_LOG_AllException().Module('User detail custom setting controller').Log(e);
    }
  }
}