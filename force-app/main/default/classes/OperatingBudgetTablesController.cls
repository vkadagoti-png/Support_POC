public with sharing class OperatingBudgetTablesController {
    public class FieldInfo {
        @AuraEnabled public string label{get;set;}
        @AuraEnabled public string api {get;set;}
        // @AuraEnabled public string objectName {get;set;}
        @AuraEnabled public string type {get;set;}
        @AuraEnabled public Integer maxLength {get;set;}
        @AuraEnabled public Integer scale {get;set;}
        @AuraEnabled public Integer precision {get;set;}
        @AuraEnabled public List<String> picklists{get;set;}
    }

    public class BudgetField {
        @AuraEnabled public String category{get;set;}
        @AuraEnabled public Decimal order{get;set;}
        @AuraEnabled public Boolean rollupTotal{get;set;} 
        @AuraEnabled public Boolean required{get;set;}
        @AuraEnabled public String fieldLabel{get;set;}
        @AuraEnabled public String fieldAPI{get;set;} 
        @AuraEnabled public String columnStyle{get;set;} 
    }

    public class GetDataResponse {
        @AuraEnabled public List<FieldInfo> fields{get;set;}
        @AuraEnabled public List<BudgetField> budgetFields{get;set;}
    }

    @AuraEnabled(cacheable=true)
    public static GetDataResponse GetData( String template, List<String> categories ) {
        if( categories == null ) return null;

        List<BudgetField> budgetFields = new List<BudgetField>();
        List<String> fieldAPIs = new List<String>();
        {
            List<Budget_Table_Field__mdt> fieldMetadata = [
                SELECT 
                    Category__c,
                    Field_API__c,
                    Rollup_Total__c,
                    Required__c,
                    Label,
                    Column_Style__c,
                    Order__c
                FROM Budget_Table_Field__mdt
                WHERE Active__c = true
                AND Category__c IN: categories
                AND Template__c =: template
                ORDER BY Category__c, Order__c
            ];
            for( Budget_Table_Field__mdt fieldData : fieldMetadata ) {
                fieldAPIs.add( fieldData.Field_API__c );
                BudgetField budgetField = new BudgetField();
                budgetField.fieldLabel = fieldData.Label;
                budgetField.columnStyle = fieldData.Column_Style__c;
                budgetField.required = fieldData.Required__c;
                budgetField.category = fieldData.Category__c;
                budgetField.fieldAPI = fieldData.Field_API__c;
                budgetField.order = fieldData.Order__c;
                budgetField.rollupTotal = fieldData.Rollup_Total__c;
                budgetFields.add( budgetField ); 
            }
        }
        final string objectName = 'BudgetCategoryValue';

        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        List<FieldInfo> fieldInfos = new List<FieldInfo>();
        {//Field Metadata
            for( string field : fieldAPIs ) {
                Schema.SObjectField objectField = fieldMap.get( field );
                if( objectField != null ) {
                    FieldInfo newFieldInfo = new FieldInfo();
                    newFieldInfo.api = field;
                    Schema.DescribeFieldResult describeResult = objectField.getDescribe();
                    newFieldInfo.label = describeResult.getLabel();

                    //https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_enum_Schema_DisplayType.htm?q=Schema.DisplayType
                    Schema.DisplayType fieldType = describeResult.getType();
                    newFieldInfo.type = String.valueOf( fieldType );
                    if( fieldType == Schema.DisplayType.Picklist || fieldType == Schema.DisplayType.MultiPicklist ) {
                        newFieldInfo.picklists = new List<String>();
                        for (Schema.PicklistEntry pv : describeResult.getPickListValues()) {
                            newFieldInfo.picklists.add( pv.getValue().toUpperCase() );
                        }
                    } else if( fieldType == Schema.DisplayType.String || fieldType == Schema.DisplayType.TextArea ) {
                        newFieldInfo.maxLength = describeResult.getLength();
                    } else if( fieldType == Schema.DisplayType.Double || fieldType == Schema.DisplayType.CURRENCY || fieldType == Schema.DisplayType.PERCENT ) {
                        newFieldInfo.scale = describeResult.getScale();
                        newFieldInfo.precision = describeResult.getPrecision();
                    }
                    fieldInfos.add( newFieldInfo );
                }
            }
        }

        GetDataResponse response = new GetDataResponse();
        response.budgetFields = budgetFields;
        response.fields = fieldInfos;
        return response;
    }
}