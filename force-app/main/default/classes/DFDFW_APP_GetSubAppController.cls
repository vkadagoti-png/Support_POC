/*
*********************************************************
Apex Class Name    : DFDFW_APP_GetSubAppController
Created Date       : 11/28/2024
Author             : Cloud Synapps Inc.
Description        : Class containing the Related Sub Application controller methods. Gets the related Sub Applications
Test Class Name    : DFDFW_APP_GetSubAppControllerTest
*********************************************************
*/
public without sharing class DFDFW_APP_GetSubAppController {
    @AuraEnabled(cacheable=true)
    public static List<Sub_Application__c> getRelatedSubApplications(Id serviceApplicationId) {
        // Query related Sub_Application__c records
        return [SELECT Id, Name, Permit_Type__c, Status__c, Case_Number__c,Fee__c FROM Sub_Application__c WHERE Service_Application_Detail__c = :serviceApplicationId ORDER BY CreatedDate DESC];
    }
}