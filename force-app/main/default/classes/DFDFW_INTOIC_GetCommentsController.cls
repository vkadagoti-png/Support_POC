/*
*********************************************************
Apex Class Name    : DFDFW_INTOIC_GetCommentsController
Created Date       : 11/08/2024
Author             : Cloud Synapps Inc.
Description        : Class used as controller for get Comments from City Works.
Test Class Name    : DFDFW_INTOIC_GetCommentsControllerTest
*********************************************************
*/
public with sharing class DFDFW_INTOIC_GetCommentsController {
  /*
  *********************************************************
  @method Name    : getComment
  @description    : used to get table configurations
  @param          : applicationId
  @param          : userId
  @return         : List<DFD_Comment__c>
  ********************************************************
  */
  @AuraEnabled
  public static List<DFD_Comment__c> getComment(Id applicationId, Id userId) {
    try {
      List<Service_Application_Detail__c> appList = [
        SELECT Id, Case_Application_Id__c
        FROM Service_Application_Detail__c
        WHERE Id = :applicationId
        LIMIT 1
      ];

      List<DFD_Comment__c> newComments = new List<DFD_Comment__c>();
      DFD_CityWorks_Endpoint__mdt mdt = DFD_CityWorks_Endpoint__mdt.getInstance(
        'GetPermitCommets'
      );
      String endpoint =
        'callout:DFDFW_OIC_Endpoint' +
        mdt.Endpoint_URI__c +
        appList[0].Case_Application_Id__c;

      String accessToken = DFDFW_AUTH0_ManageUserTokenCtrl.getUserAccessToken(
        userId
      );
      UUID randomUUID = UUID.randomUUID();

      Map<String, String> headerMap = new Map<String, String>{
        'X-Access-Token' => accessToken,
        'X-Request-Id' => randomUUID.toString()
      };
      String response = DFDFW_INTGEN_CallOutController.callout(
        endpoint,
        mdt.Method__c,
        false,
        null,
        true,
        headerMap
      );

      if (response != null && response != '') {
        List<Integer> commentNumberList = new List<Integer>();
        DFDFW_INTOIC_GetCommentsWrapper responseWrapper = (DFDFW_INTOIC_GetCommentsWrapper) JSON.deserialize(
          response,
          DFDFW_INTOIC_GetCommentsWrapper.class
        );
        Map<Integer, DFDFW_INTOIC_GetCommentsWrapper.CaseComments> caseNumberToCaseComment = new Map<Integer, DFDFW_INTOIC_GetCommentsWrapper.CaseComments>();
        for (
          DFDFW_INTOIC_GetCommentsWrapper.CaseComments commentObj : responseWrapper.CaseComments
        ) {
          caseNumberToCaseComment.put(commentObj.CommentId, commentObj);
        }
        if (!caseNumberToCaseComment.isEmpty()) {
          List<DFD_Comment__c> oldComment = [
            SELECT
              Id,
              Name,
              DFD_Service_Application_Detail__c,
              DFD_Comment__c,
              DFD_Type__c,
              DFD_Comment_User__c,
              DFD_CW_Comment_ID__c
            FROM DFD_Comment__c
            WHERE
              DFD_Service_Application_Detail__c = :applicationId
              AND DFD_CW_Comment_ID__c IN :caseNumberToCaseComment.keySet()
          ];
          if (!oldComment.isEmpty()) {
            for (DFD_Comment__c comment : oldComment) {
              if (
                caseNumberToCaseComment.containsKey(
                  Integer.ValueOf(comment.DFD_CW_Comment_ID__c)
                )
              ) {
                caseNumberToCaseComment.remove(
                  Integer.ValueOf(comment.DFD_CW_Comment_ID__c)
                );
              }
            }
          }
          if (!caseNumberToCaseComment.isEmpty()) {
            for (Integer key : caseNumberToCaseComment.keySet()) {
              DFD_Comment__c comment = new DFD_Comment__c();
              DFDFW_INTOIC_GetCommentsWrapper.CaseComments caseComment = caseNumberToCaseComment.get(
                key
              );
              comment.DFD_Service_Application_Detail__c = applicationId;
              comment.DFD_Comment__c = caseComment.Comments;
              comment.DFD_CW_Comment_ID__c = caseComment.CommentId;
              if (caseComment.AuthorName == 'Applicant') {
                comment.DFD_Type__c = 'External';
              } else {
                comment.DFD_Type__c = 'Internal';
              }
              comment.DFD_Comment_User__c = caseComment.AuthorName;
              newComments.add(comment);
            }
          }

          if (!newComments.isEmpty()) {
            insert newComments;
          }
        }
      }
      return newComments;
    } catch (Exception e) {
      new DFDFW_LOG_AllException().Module('Get all comments controller').Log(e);
      return null;
    }
  }
}