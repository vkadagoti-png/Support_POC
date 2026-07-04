/*
*********************************************************
Apex Class Name    : DFDFW_INTOIC_GetCommentsWrapper
Created Date       : 11/08/2024
Author             : Cloud Synapps Inc.
Description        : Class used as wrapper to parse get all comments api response.
*********************************************************
*/
public with sharing class DFDFW_INTOIC_GetCommentsWrapper {
  public list<CaseComments> CaseComments { get; set; }
  public class CaseComments {
    public String DateCreated { get; set; }
    public String AuthorName { get; set; }
    public Integer AuthorSid { get; set; }
    public String Comments { get; set; }
    public Integer CommentId { get; set; }
  }
}