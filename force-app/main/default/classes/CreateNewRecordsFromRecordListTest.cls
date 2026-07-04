@IsTest
public with sharing class CreateNewRecordsFromRecordListTest {

    @TestSetup
    static void makeData() {
        Reference_Checks__c refCheck = new Reference_Checks__c();
        refCheck.Name = 'Test Reference Checks';
        insert refCheck;

        Reference_Checks_Details__c refCheckDetail = new Reference_Checks_Details__c();
        refCheckDetail.Reference_Checks__c = refCheck.Id;
        refCheckDetail.Display_Name__c = 'Test Reference Checks Detail';
        refCheckDetail.Sort_Order__c = 1;
        insert refCheckDetail;

        Reference_Checks_Details__c refCheckDetail2 = new Reference_Checks_Details__c();
        refCheckDetail2.Reference_Checks__c = refCheck.Id;
        refCheckDetail2.Display_Name__c = 'Test Reference Checks Detail 2';
        refCheckDetail2.Sort_Order__c = 2;
        insert refCheckDetail2;

        Account acct = new Account();
        acct.Name = 'Test Account';
        acct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Organizations').getRecordTypeId();
        insert acct;

        Contract contract = new Contract();
        contract.AccountId = acct.Id;
        contract.Status = 'Draft';
        contract.RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('CDAProgramatic').getRecordTypeId();
        insert contract;

        Checklist_Details__c checklistDetail = new Checklist_Details__c();
        checklistDetail.Contract__c = contract.Id;
        checklistDetail.Display_Name__c = 'Test Reference Checks Detail';
        checklistDetail.Sort_Order__c = 1;
        insert checklistDetail;
    }

    @isTest
    private static void createRecordsTest() {
        Reference_Checks__c refCheck = [SELECT Id FROM Reference_Checks__c LIMIT 1];
        Contract contract = [SELECT Id FROM Contract LIMIT 1];

        List<CreateNewRecordsFromRecordList.Request> requests = new List<CreateNewRecordsFromRecordList.Request>();
        CreateNewRecordsFromRecordList.Request request = new CreateNewRecordsFromRecordList.Request();
        request.sourceObjectApiName = 'Reference_Checks_Details__c';
        request.sourceObjectFilterString = 'Reference_Checks__c = \'' + refCheck.Id + '\'';
        request.sourceDupMatchFieldApiName = 'Display_Name__c';
        request.targetDupMatchFieldApiName = 'Display_Name__c';
        request.targetObjectApiName = 'Checklist_Details__c';
        request.jsonFieldMappings = '{"Display_Name__c":"Display_Name__c","Sort_Order__c":"Sort_Order__c"}';
        request.parentRecordId = contract.Id;
        request.parentLookupFieldApiName = 'Contract__c';
        requests.add(request);

        List<CreateNewRecordsFromRecordList.Result> results = CreateNewRecordsFromRecordList.createNewRecords(requests);
        
        System.assertEquals(results[0].success, true);
    }

    @isTest
    private static void failCreateRecordsTest() {
        List<CreateNewRecordsFromRecordList.Request> requests = new List<CreateNewRecordsFromRecordList.Request>();
        CreateNewRecordsFromRecordList.Request request = new CreateNewRecordsFromRecordList.Request();
        requests.add(request);

        List<CreateNewRecordsFromRecordList.Result> results = CreateNewRecordsFromRecordList.createNewRecords(requests);
        
        System.assertEquals(results[0].success, false);
    }
}