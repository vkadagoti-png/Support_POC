/*
*********************************************************
Apex Class Name    : DFDFW_LOG_AllExceptionTest
Created Date       : 9/26/2024
Author             : Cloud Synapps Inc.
Description        : Class used as test class for DFDFW_LOG_AllException.
*********************************************************
*/
@isTest
public class DFDFW_LOG_AllExceptionTest {

    @isTest
    static void testLogException() {
        // Test setup: Simulate an exception to trigger the logging process
        Exception testException;
        try {
            Integer i = 1 / 0; // This will throw a Divide by Zero Exception
        } catch (Exception e) {
            testException = e; // Catch and log the exception
        }

        // Mock logging the exception and ensure that it is handled
        Test.startTest();
        DFDFW_LOG_AllException logException = new DFDFW_LOG_AllException();
        logException.Module('TestModule').log(testException);
        Test.stopTest();

        // Verify the Exception_Logger__c record has been inserted correctly
        List<Exception_Logger__c> logRecords = [SELECT Module_Name__c, Class_Name__c, Method_Name__c, 
                                                Line_Number__c, Exception_Type__c, Exception_Message__c 
                                                FROM Exception_Logger__c];
                                                
        System.assertEquals(1, logRecords.size(), 'There should be one log record inserted.');

        Exception_Logger__c log = logRecords[0];
        System.assertEquals('TestModule', log.Module_Name__c, 'The module name should match.');
        
    }

    @isTest
    static void testLogExceptionHandling() {
        // Test setup: Simulate a custom exception to trigger logging inside a catch block
        Exception testException;
        try {
            // Simulate an exception scenario
            Integer i = 1 / 0; // This will throw a Divide by Zero Exception
        } catch (Exception e) {
            testException = e; // Catch and log the exception
        }

        Test.startTest();
        new DFDFW_LOG_AllException().Module('DivideByZeroTest').log(testException);
        Test.stopTest();

        // Verify the Exception_Logger__c record is inserted
        List<Exception_Logger__c> logRecords = [SELECT Module_Name__c, Exception_Type__c, Exception_Message__c 
                                                FROM Exception_Logger__c];
        System.assertEquals(1, logRecords.size(), 'There should be one log record inserted.');

        Exception_Logger__c log = logRecords[0];
        System.assertEquals('DivideByZeroTest', log.Module_Name__c, 'Module name should match.');
       
       
    }

    @isTest
    static void testExtractExceptionData() {
        // Simulate a real exception for testing
        Exception mockException;
        try {
            Integer i = 1 / 0; // This will throw a Divide by Zero Exception
        } catch (Exception e) {
            mockException = e; // Catch and log the exception
        }

        // Create an instance of DFDFW_LOG_AllException and extract the exception data
        DFDFW_LOG_AllException logException = new DFDFW_LOG_AllException();
        logException.extractExceptionData(mockException);

        // Verify that the stack trace and other details are extracted properly
        System.assertNotEquals(null, logException.StackTrace, 'StackTrace should not be null.');
        System.assertNotEquals(null, logException.ClassName, 'ClassName should not be null.');
        System.assertNotEquals(null, logException.MethodName, 'MethodName should not be null.');
    }

    @isTest
    static void testWriteToObject() {
        // Simulate a real exception for testing
        Exception mockException;
        try {
            Integer i = 1 / 0; // This will throw a Divide by Zero Exception
        } catch (Exception e) {
            mockException = e; // Catch and log the exception
        }

        // Log the exception using the DFDFW_LOG_AllException class
        DFDFW_LOG_AllException logException = new DFDFW_LOG_AllException();
        logException.Module('TestWriteToObject').log(mockException);

        // Verify that the exception was written to the Exception_Logger__c object
        List<Exception_Logger__c> logRecords = [SELECT Module_Name__c, Class_Name__c, Method_Name__c, 
                                                Line_Number__c, Exception_Type__c, Exception_Message__c, 
                                                Exception_Cause__c
                                                FROM Exception_Logger__c];
        
        System.assertEquals(1, logRecords.size(), 'There should be one log record inserted.');
        
        Exception_Logger__c log = logRecords[0];
        System.assertEquals('TestWriteToObject', log.Module_Name__c, 'The module name should match.');
       
       
    }
}