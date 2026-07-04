@istest
public with sharing class OperatingBudgetTablesControllerTest {

    @istest
    private static void test() {
        List<String> categories = new List<String>();
        string template = '';
        for( Budget_Table_Field__mdt fieldMetadata : [
            SELECT 
                Category__c,
                Template__c,
                Field_API__c,
                Rollup_Total__c,
                Required__c,
                Label,
                Column_Style__c,
                Order__c
            FROM Budget_Table_Field__mdt
            WHERE Active__c = true
            ORDER BY Category__c, Order__c
        ]) {
            categories.add( fieldMetadata.Category__c );
            template = fieldMetadata.Template__c;
        }
        Test.startTest();
        OperatingBudgetTablesController.GetData( template, categories); 
        Test.stopTest();
    }
}