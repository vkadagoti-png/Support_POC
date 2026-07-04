@isTest
public class DFDFW_APPFILE_PDFPreviewControllerTest {
    
    // Helper method to create test data
    private static Service_Application_Detail__c createTestData() {
        Service_Application_Detail__c testService = new Service_Application_Detail__c(Permit_Type__c = 'Special Event');
        insert testService;
        return testService;
    }
    
    @isTest
    public static void testGetFileDetails() {
        // Create a test record
        Service_Application_Detail__c testService = new Service_Application_Detail__c();
        insert testService;
        List<Service_Application_Detail__c> serviceApplicationList = [SELECT Id, Name FROM Service_Application_Detail__c WHERE Id =: testService.Id];
        
        ContentVersion version = new ContentVersion();
        version.Title = serviceApplicationList[0].Name + '_' + 'Test File';
        version.PathOnClient = 'TestFile.pdf';
        version.VersionData = Blob.valueOf('Test Content');
        version.File_Category__c = 'Test Category';
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
        link.LinkedEntityId = testService.Id;
        link.ContentDocumentId = contentDocumentId;
        link.ShareType = 'V';
        insert link;
        // Invoke the method
        Test.startTest();
        List<String> fileNames = new List<String>{'Test File'};
        List<Object> result = DFDFW_APPFILE_PDFPreviewController.getfileDetails(serviceApplicationList[0].Id, fileNames);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should return one file');
    }
      
    
    @isTest
    public static void testGetFileDetails_NoFilesFound() {
        // Create a test Service_Application_Detail__c record
        Service_Application_Detail__c testService = createTestData();
        
        // Test: Invalid file retrieval scenario (no matching files)
        Test.startTest();
        List<String> fileNames = new List<String>{'NonExistingFile'};
        List<Object> result = DFDFW_APPFILE_PDFPreviewController.getfileDetails(testService.Id, fileNames);
        Test.stopTest();
        
        // Assertions for no files found
        System.assertEquals(0, result.size(), 'Result should be empty when no files are found');
    }
    
    @isTest
    public static void testCreateObjectList() {
        // Create a test Service_Application_Detail__c record
        Service_Application_Detail__c testService = createTestData();

        // Create ContentVersion
        ContentVersion version = new ContentVersion();
        version.Title = testService.Name + '_' + 'Test File';
        version.PathOnClient = 'TestFile.pdf';
        version.VersionData = Blob.valueOf('Test Content');
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
        link.LinkedEntityId = testService.Id;
        link.ContentDocumentId = contentDocumentId;
        link.ShareType = 'V';
        insert link;

        // Get download URL map
        List<ContentVersion> contentVersions = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId = :contentDocumentId];
        Map<String, String> downloadUrlMap = new Map<String, String>();
        downloadUrlMap.put(contentVersions[0].Id, '/sfc/servlet.shepherd/document/download/' + contentVersions[0].ContentDocumentId);
        
        // Test the createObjectList method
        Test.startTest();
        List<Object> result = DFDFW_APPFILE_PDFPreviewController.createObjectList(downloadUrlMap, contentVersions);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should return one file object');
    }
    
    @isTest
    public static void testGetDownloadURL() {
        // Create a test Service_Application_Detail__c record
        Service_Application_Detail__c testService = createTestData();

        // Create ContentVersion (file to attach)
        ContentVersion version = new ContentVersion();
        version.Title = testService.Name + '_' + 'Test File';
        version.PathOnClient = 'TestFile.pdf';
        version.VersionData = Blob.valueOf('Test Content');
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
        link.LinkedEntityId = testService.Id;
        link.ContentDocumentId = contentDocumentId;
        link.ShareType = 'V';
        insert link;

        // Create ContentDistribution
        ContentDistribution distribution = new ContentDistribution();
        distribution.ContentVersionId = version.Id;
        //distribution.DistributionPublicUrl = 'https://myfile.com/download';
        distribution.Name = 'Test Distribution';
        insert distribution;

        // Test: Getting download URL
        Test.startTest();
        Map<String, String> downloadUrls = DFDFW_APPFILE_PDFPreviewController.getDownloadURL(new List<Id>{version.Id});
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, downloadUrls, 'Download URLs map should not be null');
        System.assert(downloadUrls.containsKey(version.Id), 'Download URL should be present for the file');
    }

}