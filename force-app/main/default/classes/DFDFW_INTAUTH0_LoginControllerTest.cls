/*
*********************************************************
Apex Class Name    : DFDFW_INTAUTH0_LoginControllerTest
Created Date       : 8/2/2024
Author             : Cloud Synapps Inc.
Description        : Class used as test class for DFDFW_INTAUTH0_LoginController.
*********************************************************
*/
@isTest
public class DFDFW_INTAUTH0_LoginControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Insert mock data for the custom setting DFD_Redirect_URLs__c
        DFD_Redirect_URLs__c urls = new DFD_Redirect_URLs__c();
        urls.Register_Page_Redirect__c = 'https://auth0.example.com/register';
        insert urls;
    }
    
    @isTest
    static void testGetRedirectUrlSuccess() {
        // Call the method to be tested
        Test.startTest();
        Map<String, String> result = DFDFW_INTAUTH0_LoginController.getRedirectUrl();
        Test.stopTest();
        
        // Use the literal 'register' instead of the constant
        System.assert(result.containsKey('register'), 'The result should contain the "register" key.');
        System.assertEquals('https://auth0.example.com/register', result.get('register'), 'The redirect URL should match the one in the custom setting.');
    }

    @isTest
    static void testGetRedirectUrlExceptionHandling() {
        // Delete the custom setting to simulate an error scenario
        delete [SELECT Id FROM DFD_Redirect_URLs__c LIMIT 1];
        
        Test.startTest();
        try {
            // Call the method to test exception handling
            DFDFW_INTAUTH0_LoginController.getRedirectUrl();
            
        } catch (AuraHandledException e) {
            // Verify the exception is handled properly
            System.assert(e.getMessage().contains('No record found'), 'The exception message should indicate the error.');
        }
        Test.stopTest();
    }
}