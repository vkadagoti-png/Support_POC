@isTest
public with sharing class ApplicationHelperTest {
    
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

        Reference_Application_Section__c refAppSection3 = new Reference_Application_Section__c();
        refAppSection3.Name = 'testName2';
        refAppSection3.Reference_Application__c = refApp.Id;
        refAppSection3.Display_Section_Name__c = 'General Information';
        refAppSection3.Sort_Order__c = 3;
        insert refAppSection3;

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

        Reference_Application_Detail__c refAppDetailCurrency = new Reference_Application_Detail__c();  
        refAppDetailCurrency.Field_Label__c = 'Project Cost';
        refAppDetailCurrency.Reference_Application_Section__c = refAppSection3.Id;
        refAppDetailCurrency.RecordTypeId = Schema.SObjectType.Reference_Application_Detail__c.getRecordTypeInfosByDeveloperName()
        .get('Input_Currency')
        .getRecordTypeId();
        refAppDetailCurrency.Sort_Order__c = 50;
        insert refAppDetailCurrency;
        Reference_Application_Detail__c refAppDetailCurrency2 = new Reference_Application_Detail__c();  
        refAppDetailCurrency2.Field_Label__c = 'Amount of Funds Requested';
        refAppDetailCurrency2.Reference_Application_Section__c = refAppSection3.Id;
        refAppDetailCurrency2.RecordTypeId = Schema.SObjectType.Reference_Application_Detail__c.getRecordTypeInfosByDeveloperName()
        .get('Input_Currency')
        .getRecordTypeId();
        refAppDetailCurrency2.Sort_Order__c = 100;
        insert refAppDetailCurrency2;
    }

    @isTest
    private static void getFieldSetTest(){
        ApplicationHelper.getFieldSet('Reference_Application_Detail__c', 'App_Details');
    }

    @isTest
    private static void getFieldSetDataTest() {

        Reference_Application__c refApp = [SELECT Id FROM Reference_Application__c LIMIT 1];

        Application__c app = new Application__c();
            app.Reference_Application__c = refApp.Id;
        insert app;

        Application_Section__c section = [
            SELECT Id
            FROM Application_Section__c
            LIMIT 1
        ];

        ApplicationHelper.getFieldSetData(
            section.Id,
            'Reference_Application_Detail__c',
            'App_Details',
            'Reference_Application_Section__c',
            null
        );
    }
    
    @isTest
    private static void setApplicationDefaultsTest() {

        Reference_Application__c refApp = [SELECT Id FROM Reference_Application__c LIMIT 1];

        Application__c app = new Application__c();
        app.Reference_Application__c = refApp.Id;
        insert app;
    }

    @isTest
    private static void getApplicationTest() {

        Reference_Application__c refApp = [SELECT Id FROM Reference_Application__c LIMIT 1];

        Application__c app = new Application__c();
        app.Reference_Application__c = refApp.Id;
        insert app;

        ApplicationHelper.getApplication(app.Id);
    }

    @isTest 
    private static void getApplicationLanguagesTest() {
        Reference_Application__c refApp = [SELECT Id FROM Reference_Application__c LIMIT 1];

        Application__c app = new Application__c();
        app.Reference_Application__c = refApp.Id;
        insert app;

        ApplicationHelper.getApplicationLanguages(app.Id);
    }

    @isTest 
    private static void getApplicationSectionLanguagesTest() {
        Reference_Application__c refApp = [SELECT Id FROM Reference_Application__c LIMIT 1];

        Application__c app = new Application__c();
        app.Reference_Application__c = refApp.Id;
        insert app;

        ApplicationHelper.getApplicationSectionLanguages([
            SELECT Id 
            FROM Application_Section__c 
            WHERE Application__c =: app.Id 
            LIMIT 1].Id
        );
    }

    @isTest 
    private static void getApplicationDetailLanguagesTest() {
        Reference_Application__c refApp = [SELECT Id FROM Reference_Application__c LIMIT 1];

        Application__c app = new Application__c();
        app.Reference_Application__c = refApp.Id;
        insert app;

        ApplicationHelper.getApplicationDetailLanguages([
            SELECT Id 
            FROM Application_Section__c 
            WHERE Application__c =: app.Id 
            LIMIT 1].Id
        );
    }

    @isTest
    private static void getApplicationDetailsTest() {

        Reference_Application__c refApp = [SELECT Id FROM Reference_Application__c LIMIT 1];

        Application__c app = new Application__c();
        app.Reference_Application__c = refApp.Id;
        insert app;

        Application_Section__c appSection = [
            SELECT Id
            FROM Application_Section__c 
            WHERE Application__c = : app.Id
            LIMIT 1
        ];

        ApplicationHelper.getApplicationDetails(appSection.Id);
    }

    @isTest
    private static void saveApplicationRequiredDetailsTest() {

        Reference_Application__c refApp = [SELECT Id FROM Reference_Application__c LIMIT 1];

        Application__c app = new Application__c();
        app.Reference_Application__c = refApp.Id;
        insert app;

        Application_Section__c appSection = [
            SELECT Id
            FROM Application_Section__c 
            WHERE Application__c = : app.Id
            AND Display_Section_Label__c = 'testDisplaySectionName'
            LIMIT 1
        ];

        Application_Detail__c appDetail = [
            SELECT Id
            FROM Application_Detail__c 
            WHERE Application_Section__c = : appSection.Id
            AND Required__c = true
            LIMIT 1
        ];

        appDetail.Input_Text__c = 'inputedtext';

        List<Application_Detail__c> appDetails = new List<Application_Detail__c>();
        appDetails.add(appDetail);

        ApplicationHelper.saveApplicationDetails(
            app.Id,    
            appSection.Id,    
            appDetails,
            true
        );
    }

    @isTest
    private static void saveApplicationNonRequiredDetailsTest() {

        Reference_Application__c refApp = [SELECT Id FROM Reference_Application__c LIMIT 1];

        Application__c app = new Application__c();
        app.Reference_Application__c = refApp.Id;
        insert app;

        Application_Section__c appSection = [
            SELECT Id
            FROM Application_Section__c 
            WHERE Application__c = : app.Id
            AND Display_Section_Label__c = 'testDisplaySectionName2'
            LIMIT 1
        ];

        Application_Detail__c appDetail = [
            SELECT Id
            FROM Application_Detail__c 
            WHERE Application_Section__c = : appSection.Id
            LIMIT 1
        ];

        appDetail.Input_Text__c = 'inputedtext';

        List<Application_Detail__c> appDetails = new List<Application_Detail__c>();
        appDetails.add(appDetail);

        ApplicationHelper.saveApplicationDetails(
            app.Id,    
            appSection.Id,    
            appDetails,
            true
        );

        appDetails[0].Input_Text__c = 'meow 🐈‍⬛';
        ApplicationHelper.updateSobs(
            appDetails
        );
    }

    @isTest
    private static void saveApplicationTest() {
        Reference_Application__c refApp = [SELECT Id FROM Reference_Application__c LIMIT 1];

        Application__c app = new Application__c();
        app.Reference_Application__c = refApp.Id;
        insert app;

        app.Status__c = 'Submitted';
        ApplicationHelper.saveApplication(app);
    }

    @isTest
    private static void filesTest() {
        Reference_Application__c refApp = [SELECT Id FROM Reference_Application__c LIMIT 1];

        Application__c app = new Application__c();
        app.Reference_Application__c = refApp.Id;
        insert app;

        ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = 'Cat';
            contentVersion.PathOnClient = 'meow.jpg';
            contentVersion.VersionData = Blob.valueOf('I am Cat');
            contentVersion.IsMajorVersion = true;
        insert contentVersion; 

        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = app.Id;
            cdl.ContentDocumentId = documents[0].Id;
            cdl.shareType = 'V';
        insert cdl;

        List<ContentVersion> files = ApplicationHelper.getFiles(app.Id, 'Cat');

        List<Id> cvids = new List<Id>{files[0].Id};

        ApplicationHelper.renameFiles(cvids, 'test');
        ApplicationHelper.deleteFile(files[0].ContentDocumentId);
    }

    @isTest
    private static void fetchRecordsTest() {

        insert new Account(
            Name = 'Tokyo'
        );

        ApplicationHelper.SearchWrapper input = new ApplicationHelper.SearchWrapper(
            'Account',
            'Name',
            'Type',
            'Tokyo',
            '',
            '',
            ''
        );

        ApplicationHelper.fetchRecords(input);
    }

    @isTest
    private static void checkApplicationCriteriaTest() {

        Reference_Application__c refApp = [SELECT Id FROM Reference_Application__c LIMIT 1];

        Application__c app = new Application__c();
        app.Reference_Application__c = refApp.Id;
        insert app;

        Application_Detail__c det = [SELECT Id, Input_Currency__c FROM Application_Detail__c WHERE Sort_Order__c = 50 
                                    AND Application_Section__r.Application__c = :app.Id];
        det.Input_Currency__c = 5;
        update det;

        Application_Detail__c det2 = [SELECT Id, Input_Currency__c FROM Application_Detail__c WHERE Sort_Order__c = 100 
                                    AND Application_Section__r.Application__c = :app.Id];
        det2.Input_Currency__c = 10;
        update det2;

        Budget bud = new Budget();
        bud.Name = 'Expense Budget';
        bud.Application__c = app.Id;
        insert bud;

        BudgetCategory budcat = new BudgetCategory();
        budcat.Name = 'Salaries';
        budcat.BudgetId = bud.Id;
        insert budcat;

        BudgetCategoryValue bcv = new BudgetCategoryValue();
        bcv.Amount = 6;
        bcv.BudgetCategoryId = budcat.Id;
        insert bcv;

        Personnel_Schedule__c ps1 = new Personnel_Schedule__c();
        ps1.Hourly_Rate__c = 6;
        ps1.Total_Number_of_Annual_Activity_Hours__c = 1;
        ps1.Percent_Charged_to_CDBG_Activity__c = 50;
        ps1.Application__c = app.Id;
        insert ps1;

        Personnel_Schedule__c ps2 = new Personnel_Schedule__c();
        ps2.Hourly_Rate__c = 6;
        ps2.Total_Number_of_Annual_Activity_Hours__c = 1;
        ps2.Percent_Charged_to_CDBG_Activity__c = 50;
        ps2.Application__c = app.Id;
        insert ps2;

        Reimbursement_Table__c rt = new Reimbursement_Table__c();
        rt.Application__c = app.Id;
        rt.Amount_Requested_for_This_Output__c = 10;
        insert rt;

        bud = [SELECT Id, Total_Planned_Amount__c FROM Budget WHERE Id = :bud.Id];
        budcat = [SELECT Id, Total_Activity_Budget__c FROM BudgetCategory WHERE Id = :budcat.Id];
        ps1 = [SELECT Id, Annual_Total_for_CDBG_Activity__c FROM Personnel_Schedule__c WHERE Id = :ps1.Id];
        ps2 = [SELECT Id, Annual_Total_for_CDBG_Activity__c FROM Personnel_Schedule__c WHERE Id = :ps2.Id];

        Test.startTest();
        ApplicationHelper.checkApplicationCriteria(app);

        bcv.Amount = 10;
        update bcv;

        bud = [SELECT Id, Total_Planned_Amount__c FROM Budget WHERE Id = :bud.Id];
        budcat = [SELECT Id, Total_Activity_Budget__c FROM BudgetCategory WHERE Id = :budcat.Id];

        ApplicationHelper.checkApplicationCriteria(app);

        rt.Amount_Requested_for_This_Output__c = 0;
        update rt;

        bcv.Amount = 6;
        update bcv;
        
        ApplicationHelper.checkApplicationCriteria(app);

        bcv.Amount = 10;
        update bcv;
        
        ps1.Hourly_Rate__c = 14;
        update ps1;
        ApplicationHelper.checkApplicationCriteria(app);
        Test.stopTest();
    }
}