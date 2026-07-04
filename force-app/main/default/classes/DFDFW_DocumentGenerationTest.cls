/*
*********************************************************
Apex Class Name    : DFDFW_DocumentGeneration
Created Date       : 01/26/2025
Author             : Cloud Synapps Inc.
Description        : Class used to generate the documents for the users.
Test Class Name    : DFDFW_DocumentGenerationTest
*********************************************************
*/
@isTest
private class DFDFW_DocumentGenerationTest {
    @isTest(SeeAllData=true)
    static void testGenerateDocument_Success() {
        DocumentTemplate docTemplate = [
            SELECT Id, Name, IsActive
            FROM DocumentTemplate
            WHERE Name = 'Special_Event_Application'
            LIMIT 1
        ];
        // Fetch the corresponding DocumentTemplateContentDoc record
        DocumentTemplateContentDoc templateContentDoc = [
            SELECT Id, LatestContentVersionId, DocumentTemplateId 
            FROM DocumentTemplateContentDoc 
            WHERE DocumentTemplateId = :docTemplate.Id 
            LIMIT 1
        ];
        
        // Create the main object (Service_Application_Detail__c) to use in the test
        Service_Application_Detail__c serviceApplication = new Service_Application_Detail__c(
            Application_Submitted_Date__c = System.today()
        );
        insert serviceApplication;
        
        // Create minimal input for document generation
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('SpecialEventTransformOmniInputForPayload', new Map<String, Object>{
            'EventName' => 'Test Special Event',
                'EventSetupEndDate' => '2025-03-01',
                'Location' => 'Test Location'
                });
        
        // Prepare input for the call
        Map<String, Object> input = new Map<String, Object>();
        input.put('documentName', 'Special_Event_Application');
        input.put('mainId', serviceApplication.Id); // Use the ID of the inserted record
        input.put('payload', payload);
        
        Map<String, Object> args = new Map<String, Object>();
        args.put('input', input);
        
        // Call the method using the callable interface
        Test.startTest();
        DFDFW_DocumentGeneration callable = new DFDFW_DocumentGeneration();
        String result = (String) callable.call('generateDocument', args);
        Test.stopTest();
        
        // Verify results
        System.assertEquals('Document generation initiated successfully.', result, 'The response message is incorrect.');
        
        // Verify that the DocumentGenerationProcess record was created
        DocumentGenerationProcess request = [
            SELECT Id, DocumentTemplateId, ReferenceObject, TokenData
            FROM DocumentGenerationProcess
            WHERE ReferenceObject = :serviceApplication.Id
            LIMIT 1
        ];
        System.assertNotEquals(null, request, 'DocumentGenerationProcess record was not created.');
        System.assertEquals(serviceApplication.Id, request.ReferenceObject, 'ReferenceObject is incorrect.');
        System.assertNotEquals(null, request.TokenData, 'TokenData is incorrect.');
    }
    
    @isTest(SeeAllData=true)
    static void testSpecialEventWithoutParkGenerateDocument_Success() {
        DocumentTemplate docTemplate = [
            SELECT Id, Name, IsActive
            FROM DocumentTemplate
            WHERE Name = 'Special_Event_Without_Park_Acknowledgements'
            LIMIT 1
        ];
        // Fetch the corresponding DocumentTemplateContentDoc record
        DocumentTemplateContentDoc templateContentDoc = [
            SELECT Id, LatestContentVersionId, DocumentTemplateId 
            FROM DocumentTemplateContentDoc 
            WHERE DocumentTemplateId = :docTemplate.Id 
            LIMIT 1
        ];
        
        // Create the main object (Service_Application_Detail__c) to use in the test
        Service_Application_Detail__c serviceApplication = new Service_Application_Detail__c(
            Application_Submitted_Date__c = System.today()
        );
        insert serviceApplication;
        
        // Create minimal input for document generation
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('SpecialEventTransformOmniInputForPayload', new Map<String, Object>{
            'EventName' => 'Test Special Event',
                'EventSetupEndDate' => '2025-03-01',
                'Location' => 'Test Location'
                });
        
        // Prepare input for the call
        Map<String, Object> input = new Map<String, Object>();
        input.put('documentName', 'Special_Event_Without_Park_Acknowledgements');
        input.put('mainId', serviceApplication.Id); // Use the ID of the inserted record
        input.put('payload', payload);
        
        Map<String, Object> args = new Map<String, Object>();
        args.put('input', input);
        
        // Call the method using the callable interface
        Test.startTest();
        DFDFW_DocumentGeneration callable = new DFDFW_DocumentGeneration();
        String result = (String) callable.call('generateDocument', args);
        Test.stopTest();
        
        // Verify results
        System.assertEquals('Document generation initiated successfully.', result, 'The response message is incorrect.');
        
        // Verify that the DocumentGenerationProcess record was created
        DocumentGenerationProcess request = [
            SELECT Id, DocumentTemplateId, ReferenceObject, TokenData
            FROM DocumentGenerationProcess
            WHERE ReferenceObject = :serviceApplication.Id
            LIMIT 1
        ];
        System.assertNotEquals(null, request, 'DocumentGenerationProcess record was not created.');
        System.assertEquals(serviceApplication.Id, request.ReferenceObject, 'ReferenceObject is incorrect.');
        System.assertNotEquals(null, request.TokenData, 'TokenData is incorrect.');
    }
    
    @isTest
    static void testGenerateDocument_UnsupportedAction() {
        // Prepare arguments with unsupported action
        Map<String, Object> args = new Map<String, Object>();
        args.put('action', 'unsupportedAction');
        
        // Call the method and check for the exception
        try {
            DFDFW_DocumentGeneration callable = new DFDFW_DocumentGeneration();
            callable.call('unsupportedAction', args);
        } catch (AuraHandledException e) {
        }
    }
    
    @isTest
    static void testGenerateDocument_Failure() {
        // Prepare arguments with missing document name
        Map<String, Object> args = new Map<String, Object>();
        Map<String, Object> input = new Map<String, Object>();
        input.put('documentName', null);  // Missing document name
        input.put('mainId', null);
        input.put('payload', new Map<String, Object>());
        
        args.put('input', input);
        
        // Call the method and check for the exception
        try {
            DFDFW_DocumentGeneration callable = new DFDFW_DocumentGeneration();
            callable.call('generateDocument', args);
        } catch (AuraHandledException e) {
        }
    }
}