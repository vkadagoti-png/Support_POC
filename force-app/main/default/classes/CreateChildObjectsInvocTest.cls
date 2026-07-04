@isTest
private class CreateChildObjectsInvocTest {

    @TestSetup
    public static void makeData(){
        
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

        Reference_Application_Section__c refAppSection2 = new Reference_Application_Section__c();
        refAppSection2.Name = 'testName2';
        refAppSection2.Reference_Application__c = refApp.Id;
        refAppSection2.Display_Section_Name__c = 'testDisplaySectionName2';
        refAppSection2.Sort_Order__c = 2;
        insert refAppSection2;

        Reference_Application_Detail__c refAppDetail = new Reference_Application_Detail__c();  
        refAppDetail.Field_Label__c = 'test text input';
        refAppDetail.Reference_Application_Section__c = refAppSection.Id;
        refAppDetail.RecordTypeId = Schema.SObjectType.Reference_Application_Detail__c.getRecordTypeInfosByDeveloperName()
        .get('Input_Text')
        .getRecordTypeId();
        refAppDetail.Sort_Order__c = 1;
        insert refAppDetail;

        Reference_Application_Detail__c refAppDetailPicklist = new Reference_Application_Detail__c();  
        refAppDetailPicklist.Field_Label__c = 'test picklist input';
        refAppDetailPicklist.Reference_Application_Section__c = refAppSection.Id;
        refAppDetailPicklist.Picklist_Values__c = 'Yes;No';
        refAppDetailPicklist.Parent_Dependent_Answer__c = 'Yes';
        refAppDetailPicklist.RecordTypeId = Schema.SObjectType.Reference_Application_Detail__c.getRecordTypeInfosByDeveloperName()
        .get('Input_Picklist')
        .getRecordTypeId();
        refAppDetailPicklist.Sort_Order__c = 2;
        insert refAppDetailPicklist;

        Reference_Application_Detail__c refAppDetailPicklistChild = new Reference_Application_Detail__c();  
        refAppDetailPicklistChild.Field_Label__c = 'test picklist input Child';
        refAppDetailPicklistChild.Reference_Application_Section__c = refAppSection.Id;
        refAppDetailPicklistChild.Reference_Parent_Application_Detail__c = refAppDetailPicklist.Id;
        refAppDetailPicklistChild.Picklist_Values__c = 'Yes;No';
        refAppDetailPicklistChild.RecordTypeId = Schema.SObjectType.Reference_Application_Detail__c.getRecordTypeInfosByDeveloperName()
        .get('Input_Picklist')
        .getRecordTypeId();
        refAppDetailPicklistChild.Sort_Order__c = 3;
        insert refAppDetailPicklistChild;

        Reference_Application_Detail__c refAppDetail2 = new Reference_Application_Detail__c();  
        refAppDetail2.Field_Label__c = 'test text input';
        refAppDetail2.Reference_Application_Section__c = refAppSection2.Id;
        refAppDetail2.RecordTypeId = Schema.SObjectType.Reference_Application_Detail__c.getRecordTypeInfosByDeveloperName()
        .get('Input_Text')
        .getRecordTypeId();
        refAppDetail2.Sort_Order__c = 4;
        insert refAppDetail2;

        Reference_Application_Detail__c refAppDetailRequired = new Reference_Application_Detail__c();  
        refAppDetailRequired.Field_Label__c = 'test text input';
        refAppDetailRequired.Reference_Application_Section__c = refAppSection.Id;
        refAppDetailRequired.RecordTypeId = Schema.SObjectType.Reference_Application_Detail__c.getRecordTypeInfosByDeveloperName()
        .get('Input_Text')
        .getRecordTypeId();
        refAppDetailRequired.Sort_Order__c = 5;
        refAppDetailRequired.Required__c = true;
        insert refAppDetailRequired;
    }

    @isTest static void testCreateChildObjects() {
        Reference_Application__c refApp = [SELECT Id FROM Reference_Application__c LIMIT 1];

        Application__c app = new Application__c();
        app.Reference_Application__c = refApp.Id;
        insert app;

        CreateChildObjectsInvoc.Request req = new CreateChildObjectsInvoc.Request();
        req.recordId = app.Id;
        req.parentObjectApiName = 'Application__c';
        req.jsonObjectString = '[{"childObjectApiName":"Project__c","childFieldForRecordId":"Application__c","parentFieldForChildId":"Project__c"}]';

        Test.startTest();
        List<CreateChildObjectsInvoc.Result> results = CreateChildObjectsInvoc.createChildBojects(new List<CreateChildObjectsInvoc.Request> {req});
        Test.stopTest();

        System.assertEquals(1, results.size(), 'There should be one result');
        System.assertEquals(true, results[0].success, 'The operation should be successful');
        Project__c[] projects = [SELECT Id, Application__c FROM Project__c WHERE Application__c = :app.Id];
        System.assertEquals(1, projects.size(), 'One Project should be linked to the test account');
    }
}