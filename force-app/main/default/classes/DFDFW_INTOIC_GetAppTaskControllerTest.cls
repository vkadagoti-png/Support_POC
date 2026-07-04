/*
*********************************************************
Apex Class Name    : DFDFW_INTOIC_GetAppTaskControllerTest
Created Date       : 11/21/2024
Author             : Cloud Synapps Inc.
Description        : Class used as test class for DFDFW_INTOIC_GetAppTaskController.
*********************************************************
*/
@IsTest
private class DFDFW_INTOIC_GetAppTaskControllerTest {

    @TestSetup
    static void setupTestData() {

        //Create User Detail record
        String userId = UserInfo.getUserId();
        DFD_User_Details__c ud = new DFD_User_Details__c();
        ud.SetupOwnerId = userId;
        ud.isRegistered__c = true;
        ud.Token_Part_1__c = 'daw3adaw3adaw';
        insert ud;

        Id rt = Schema.SObjectType.Service_Application_Detail__c.getRecordTypeInfosByDeveloperName().get('DFDFW_Permits').getRecordTypeId();

        // Create a test Service_Application_Detail__c record
        Service_Application_Detail__c sad = new Service_Application_Detail__c(
            Case_Application_Id__c = 123456,
            OIC_Status__c = 'OPEN',
            Email__c = 'testingemail@testemailteststlouis.com',
            RecordtypeId = rt
        );
        insert sad;
    }

    @IsTest
    static void testGetColumns() {
        Test.startTest();
        List<Map<String, String>> columns = DFDFW_INTOIC_GetAppTaskController.getColumns('Display_Application_Tasks');
        Test.stopTest();

        Assert.isNotNull(columns, 'Columns should not return null');
    }

    @IsTest
    static void testGetTasksWithMockCallout() {
        // Setup mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '{"Case":[{"CaObjectId":123456,"CaseStatus":"OPEN"}],"Tasks":[{"Name":"Task 1","TaskDesc":"OPEN","ResultDisplay":"IN REVIEW"}],"LinkedPermits":[{"SourceSid":123456,"DestSid":97066}],"Fees":[{"Amount":150,"CaFeeId":323977,"CaObjectId":123456}]}'));

        // Query a test record
        Service_Application_Detail__c sad = [SELECT Id, OIC_Status__c FROM Service_Application_Detail__c LIMIT 1];

        Test.startTest();
        List<Object> tasks = (List<Object>) DFDFW_INTOIC_GetAppTaskController.getTasks(sad.Id).get('Tasks');
        Test.stopTest();

     //   Assert.isNotNull(tasks, 'Tasks should not be null');
     //   Assert.areEqual(1, tasks.size(), 'One task should be available');
    }

    @IsTest
    static void testGetErrorMessage() {
        Test.startTest();
        String errorMessage = DFDFW_INTOIC_GetAppTaskController.getErrorMessage();
        Test.stopTest();

        Assert.isNotNull(errorMessage, 'errorMessage should have a return value');
    }

    @IsTest
    static void testGetPDFDocument() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '[{"CA_REL_DOC_ID": "1235", "DOC_NAME": "Test_Document_1.pdf"}]'));

        // Query a test record
        Service_Application_Detail__c sad = [SELECT Id, Case_Application_Id__c FROM Service_Application_Detail__c LIMIT 1];

        Test.startTest();
        DFDFW_INTOIC_GetAppTaskController.getPDFDocument(sad.Id, (Integer)sad.Case_Application_Id__c);
        Test.stopTest();

        List<ContentVersion> versions = [SELECT Id FROM ContentVersion WHERE FirstPublishLocationId = :sad.Id];
        Assert.areEqual(1, versions.size(), 'A ContentVersion should have been created.');
    }

    @IsTest
    static void testDocumentDownloadApiError() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(500, '{"Error"}'));

        // Query a test record
        Service_Application_Detail__c sad = [SELECT Id, Case_Application_Id__c FROM Service_Application_Detail__c LIMIT 1];

        Test.startTest();
        ContentVersion cv = DFDFW_INTOIC_GetAppTaskController.documentDownload(sad.Id, (Integer)sad.Case_Application_Id__c, 12345, 'TestFile.pdf');
        Test.stopTest();

        Exception_Logger__c el = [SELECT Id FROM Exception_Logger__c LIMIT 1];
        Assert.isNotNull(el, 'One Exception Log should have been created');
    }

    @IsTest
    static void testGetTasksFailAPICallout() {
        // Setup mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(500, '{"Error":"Error reaching endpoint"}'));

        // Query a test record
        Service_Application_Detail__c sad = [SELECT Id, OIC_Status__c FROM Service_Application_Detail__c LIMIT 1];
        
        Test.startTest();
        try{
            List<Object> tasks = (List<Object>) DFDFW_INTOIC_GetAppTaskController.getTasks(sad.Id).get('Tasks');
        }
        catch(Exception e){}
        Test.stopTest();

        Exception_Logger__c el = [SELECT Id FROM Exception_Logger__c LIMIT 1];
        Assert.isNotNull(el, 'One Exception Log should have been created');
    }

    @isTest
    static void testGetSubApplication(){

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '{"Case":[{"CaObjectId":97066, "CaseStatus":"Issued", "CaseType": "STREETS", "CaseNumber": "ST-0023"}]}'));

        // Create test data for Sub_Application__c
        Integer applicationId = 97066; // Application ID to match in the case response

        Service_Application_Detail__c sad = [SELECT Id FROM Service_Application_Detail__c LIMIT 1];
        String serviceAppId = sad.Id;

        // Insert a Sub_Application__c record for testing
        Sub_Application__c existingSubApp = new Sub_Application__c(
            Case_Application_Id__c = applicationId,
            Status__c = 'Draft' // Set initial status as Draft
        );
        insert existingSubApp;

        Test.startTest();
        DFDFW_INTOIC_GetAppTaskController.getSubApplication(applicationId, serviceAppId);
        Test.stopTest();
        
        // Verify the behavior - make assertions about the created Sub_Application__c record
        List<Sub_Application__c> subApps = [SELECT Id, Permit_Type__c, Case_Number__c, Status__c, Service_Application_Detail__c 
                                            FROM Sub_Application__c WHERE Case_Application_Id__c = :applicationId];

        Assert.areEqual(1, subApps.size(), 'Sub Application record should be upserted');
     //   Assert.areEqual('Streets', subApps[0].Permit_Type__c);

    }


    // Mock HTTP response class
    private class MockHttpResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String body;

        public MockHttpResponse(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            
            if(req.getEndpoint().contains('download/case')){
                res.setStatusCode(statusCode);
                res.setBodyAsBlob(Blob.valueOf('Test File Content'));
            }
            else{
                res.setStatusCode(statusCode);
                res.setBody(body);
            }
            
            return res;
        }
    }
}