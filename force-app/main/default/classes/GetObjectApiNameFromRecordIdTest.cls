@isTest
public with sharing class GetObjectApiNameFromRecordIdTest {

    @TestSetup
    static void makeData() {
        Account acct = new Account();
        acct.Name = 'Test Account';
        acct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Organizations').getRecordTypeId();
        insert acct;
    }

    @isTest
    private static void getObjectApiName() {
        Account acct = [SELECT Id FROM Account LIMIT 1];

        List<GetObjectApiNameFromRecordId.Request> requests = new List<GetObjectApiNameFromRecordId.Request>();
        GetObjectApiNameFromRecordId.Request request = new GetObjectApiNameFromRecordId.Request();
        request.recordId = acct.Id;
        requests.add(request);

        List<GetObjectApiNameFromRecordId.Result> results = GetObjectApiNameFromRecordId.getObjectApiName(requests);

        System.assertEquals(results[0].success, true);
        System.assertEquals(results[0].objectApiName, 'Account');
        System.assertEquals(results[0].error, null);
    }

    @isTest
    private static void failGetObjectApiName() {
        List<GetObjectApiNameFromRecordId.Request> requests = new List<GetObjectApiNameFromRecordId.Request>();
        GetObjectApiNameFromRecordId.Request request = new GetObjectApiNameFromRecordId.Request();
        requests.add(request);

        List<GetObjectApiNameFromRecordId.Result> results = GetObjectApiNameFromRecordId.getObjectApiName(requests);

        System.assertEquals(results[0].success, false);
        System.assertEquals(results[0].objectApiName, null);
        System.assertNotEquals(results[0].error, null);
    }
}