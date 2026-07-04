@IsTest
public with sharing class MultiObjectAppDetailFlattenerTest {
 
    @TestSetup
    static void makeData() {

        Reference_Application__c refApp = new Reference_Application__c();
        refApp.Name = 'test';
        refApp.Display_Description__c = 'testDisplayDescription';
        refApp.Display_Name__c = 'testDisplayName';
        insert refApp;

        Reference_Application_Section__c refAppSection = new Reference_Application_Section__c();
        refAppSection.Name = 'testName';
        refAppSection.Reference_Application__c = refApp.Id;
        refAppSection.Display_Section_Name__c = 'testDisplaySectionName';
        refAppSection.Sort_Order__c = 1;
        insert refAppSection;

        Reference_Application_Detail__c refAppDetail = new Reference_Application_Detail__c();
        refAppDetail.App_Field_API_Name_with_Target_Record_Id__c = 'Account__c';
        refAppDetail.Field_Label__c = 'test text input';
        refAppDetail.Target_Field_API_Name__c = 'Name';
        refAppDetail.Reference_Application_Section__c = refAppSection.Id;
        refAppDetail.RecordTypeId = Schema.SObjectType.Reference_Application_Detail__c.getRecordTypeInfosByDeveloperName()
            .get('Input_Text')
            .getRecordTypeId();
        refAppDetail.Sort_Order__c = 1;
        insert refAppDetail;

        Reference_Application_Detail__c refAppDetailAddress = new Reference_Application_Detail__c();
        refAppDetailAddress.App_Field_API_Name_with_Target_Record_Id__c = 'Project__c';
        refAppDetailAddress.Field_Label__c = 'Address';
        refAppDetailAddress.Street_Target_Field_API_Name__c = 'Project_Title__c';
        refAppDetailAddress.City_Target_Field_API_Name__c = 'Project_Title__c';
        refAppDetailAddress.Province_Target_Field_API_Name__c = 'Project_Title__c';
        refAppDetailAddress.Postal_Code_Target_Field_API_Name__c = 'Project_Title__c';
        refAppDetailAddress.Country_Target_Field_API_Name__c = 'Project_Title__c';
        refAppDetailAddress.Reference_Application_Section__c = refAppSection.Id;
        refAppDetailAddress.RecordTypeId = Schema.SObjectType.Reference_Application_Detail__c.getRecordTypeInfosByDeveloperName()
            .get('Input_Address')
            .getRecordTypeId();
        refAppDetailAddress.Sort_Order__c = 2;
        insert refAppDetailAddress;
    }

    @IsTest
    private static void SetFieldsTest() {

        Reference_Application__c refApp = [SELECT Id FROM Reference_Application__c LIMIT 1];

        Account acct = new Account();
        acct.Name = 'Replace me';
        insert acct;

        Project__c project = new Project__c();
        insert project;

        Application__c app = new Application__c();
        app.Reference_Application__c = refApp.Id;
        app.Project__c = project.Id;
        app.Account__c = acct.Id;
        insert app;

        List<Application_Detail__c> details = [SELECT Id, RecordType.DeveloperName FROM Application_Detail__c];

        for (Application_Detail__c detail : details) {
            if (detail.RecordType.DeveloperName == 'Input_Text') {
                detail.Input_Text__c = 'Test Account Name';
            }
            if (detail.RecordType.DeveloperName == 'Input_Address') {
                detail.Input_Street__c = 'test';
                detail.Input_City__c = 'test';
                detail.Input_State_Province__c = 'test';
                detail.Input_Postal_Code__c = 'test';
                detail.Input_Country__c = 'test';            
            }
        }
        
        update details;

        MultiObjectAppDetailFlattener.Request req = new MultiObjectAppDetailFlattener.Request();
        req.application = app;
        
        MultiObjectAppDetailFlattener.SetFields(new List<MultiObjectAppDetailFlattener.Request>{ req });
        
        Account acctResult = [SELECT Id, Name FROM Account LIMIT 1];
        Project__c projectResult = [SELECT Id, Project_Title__c FROM Project__c LIMIT 1];
        System.assertEquals(acctResult.Name, 'Test Account Name');
        System.assertEquals(projectResult.Project_Title__c, 'test');
    }

}