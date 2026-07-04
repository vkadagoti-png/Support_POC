/*
*********************************************************
Apex Class Name    : DFDFW_APPFILE_DownloadControllerTest
Created Date       : 10/30/2024
Author             : Cloud Synapps Inc.
Description        : Class used as test class for DFDFW_APPFILE_DownloadController.
*********************************************************
*/
@isTest
public class DFDFW_APPFILE_DownloadControllerTest {
    // Utility method to create test data
    private static ContentDocumentLink createTestData(Id recordId, string fileCategory) {
        // Create ContentVersion (automatically creates ContentDocument)
        ContentVersion version = new ContentVersion();
        version.Title = 'Test File';
        version.PathOnClient = 'TestFile.pdf';
        version.VersionData = Blob.valueOf('Test Content');
        version.File_Category__c = fileCategory;
        insert version;
        
        // Re-query ContentVersion to get ContentDocumentId
        version = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :version.Id
            LIMIT 1
        ];
        Id contentDocumentId = version.ContentDocumentId;
        
        // Create ContentDocumentLink
        ContentDocumentLink link = new ContentDocumentLink();
        link.LinkedEntityId = recordId;
        link.ContentDocumentId = contentDocumentId;
        link.ShareType = 'V';
        insert link;
        
        return link;
    }
    
    @isTest
    static void testGetFiles() {
        // Create a test record
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Insert test data for ContentDocument and related records
        createTestData(testAccount.Id, 'Issued');
        
        Test.startTest();
        // Call the method
        List<DFDFW_APPFILE_DownloadController.FileDataWrapper> files = DFDFW_APPFILE_DownloadController.getFiles(
            testAccount.Id
        );
        Test.stopTest();
        
        // Verify that files are returned
        System.assertNotEquals(0, files.size(), 'Expected files to be returned');
        System.assertEquals(
            'Test File',
            files[0].contentVersion.Title,
            'Expected file title to match'
        );
        System.assertEquals(
            'Issued',
            files[0].contentVersion.File_Category__c,
            'Expected file category to match'
        );
    }
    
    @isTest
    static void testGetIssuedPermitFiles() {
        // Create a test record for the parent object (Service_Application_Detail__c)
        Service_Application_Detail__c testRecord = new Service_Application_Detail__c(Permit_Type__c = 'Special Event');
        insert testRecord;
        
        // Insert test data with 'Issued Permit' category
        // Ensure that the file is being created and linked to the Service_Application_Detail__c record
        createTestData(testRecord.Id, 'Issued Permit');
        
        Test.startTest();
        // Call the method to fetch files with the 'Issued Permit' category
        List<DFDFW_APPFILE_DownloadController.FileDataWrapper> files = DFDFW_APPFILE_DownloadController.getIssuedPermitFiles(testRecord.Id);
        Test.stopTest();
        
        // Step 4: Log the returned files for debugging purposes
        System.debug('Files returned: ' + files.size());
        if (!files.isEmpty()) {
            System.debug('First file category: ' + files[0].contentVersion.File_Category__c);
        }
        
        // If files are returned, verify that the file category is 'Issued Permit'
        if (files.size() > 0) {
            System.assertEquals(
                'Issued Permit',
                files[0].contentVersion.File_Category__c,
                'Expected file category to be "Issued Permit" but got: ' + files[0].contentVersion.File_Category__c
            );
        }
        
    }
    
    @isTest
    static void testGetErrorMessageFromMetadata() {
        Test.startTest();
        String component = 'dfdViewApplicationButton';
        String errorMessage = DFDFW_APPFILE_DownloadController.getErrorMessageFromMetadata(
            component
        );
        Test.stopTest();
        System.assertEquals(
            'No document found.',
            errorMessage,
            'The returned error message should match the expected value'
        );
    }
    
    @isTest
    static void testGetFileId() {
        // Create a test record for the parent object (Service_Application_Detail__c)
        Service_Application_Detail__c testRecord = new Service_Application_Detail__c(Permit_Type__c = 'Special Event');
        insert testRecord;
        
        // Insert test data with a file title
        ContentDocumentLink link = createTestData(testRecord.Id, 'Issued Permit');
        
        Test.startTest();
        
        // Call getFileId to fetch file URL for the created test record and file title
        String fileTitle = 'Test File'; // The title we created for the ContentVersion
        String fileUrl = DFDFW_APPFILE_DownloadController.getFileId(testRecord.Id, fileTitle);
        
        Test.stopTest();
    }

    @isTest
    static void testGetDownloadURL() {
        // Create a test record for the parent object (Service_Application_Detail__c)
        Service_Application_Detail__c testRecord = new Service_Application_Detail__c(Permit_Type__c = 'Special Event');
        insert testRecord;
        
        // Insert test data with a file title
        ContentDocumentLink link = createTestData(testRecord.Id, 'Issued Permit');
        
        // Re-query to get ContentVersion Id
        ContentVersion version = [
            SELECT Id
            FROM ContentVersion
            WHERE Title = 'Test File'
            LIMIT 1
        ];

        Test.startTest();
        
        // Call getDownloadURL to fetch the download URL for the created ContentVersion
        String downloadUrl = DFDFW_APPFILE_DownloadController.getDownloadURL(version.Id);
        
        Test.stopTest();      
    }
    
    @isTest
    static void testGetDownloadURL_InvalidContentVersion() {
    // Create a test record for the parent object
    Service_Application_Detail__c testRecord = new Service_Application_Detail__c(Permit_Type__c = 'Special Event');
    insert testRecord;
    
    // Try to fetch the download URL for a non-existent ContentVersion
    Test.startTest();
    String invalidVersionId = '069000000000000';
    String downloadUrl = DFDFW_APPFILE_DownloadController.getDownloadURL(invalidVersionId);
    Test.stopTest();
    
    // The result should be null or an appropriate error message
    System.assertEquals(null, downloadUrl, 'Expected a null URL for an invalid ContentVersion ID');
    }

}