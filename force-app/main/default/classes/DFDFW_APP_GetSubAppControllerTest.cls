/*
*********************************************************
Apex Class Name    : DFDFW_APP_GetSubAppControllerTest
Created Date       : 12/2/2024
Author             : Cloud Synapps Inc.
Description        : Class used as test class for DFDFW_APP_GetSubAppController.
*********************************************************
*/
@isTest
private class DFDFW_APP_GetSubAppControllerTest {
    @isTest
    static void testGetRelatedSubApplications() {

        // Create a test Service Application Detail record
        Service_Application_Detail__c testServiceApplicationDetail = new Service_Application_Detail__c();
        insert testServiceApplicationDetail;

        // Create related Sub_Application__c records
        Sub_Application__c subApp1 = new Sub_Application__c(
            Permit_Type__c = 'Streets',
            Service_Application_Detail__c = testServiceApplicationDetail.Id
        );
        Sub_Application__c subApp2 = new Sub_Application__c(
            Permit_Type__c = 'Parks',
            Service_Application_Detail__c = testServiceApplicationDetail.Id
        );

       
        insert new List<Sub_Application__c>{subApp1, subApp2};
        

        Test.startTest();
        // Call the method and store the result
        List<Sub_Application__c> relatedSubApplications = DFDFW_APP_GetSubAppController.getRelatedSubApplications(testServiceApplicationDetail.Id);
        Test.stopTest();
        // Assertions to verify the results
        Assert.areEqual(2, relatedSubApplications.size(), 'There should be 2 related sub-applications.');

        Sub_Application__c subApp3 = new Sub_Application__c(
            Permit_Type__c = 'Parks',
            Service_Application_Detail__c = testServiceApplicationDetail.Id,
            Status__c = 'Pending'        );
        insert subApp3;

    }
}