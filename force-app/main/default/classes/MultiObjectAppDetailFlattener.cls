public with sharing class MultiObjectAppDetailFlattener {

    @InvocableMethod(
        label='Multi-oject Application Detail Flattener'
        description='Takes Application Details and writes the inputted value to fields on a one or more records'
    )  
    public static void SetFields(List<Request> input) {

        if (input == null || input.isEmpty() || input[0].application == null) {
            System.debug('❌ Input is null or Application__c is missing.');
            return;
        }

        Application__c app = input[0].application;

        Map<String, String> recordTypeInputFieldMap = new Map<String, String>{
            'Input_Checkbox' => 'Input_Checkbox__c',
            'Input_Checkbox_Group' => 'Input_Text__c',
            'Input_Currency' => 'Input_Currency__c',
            'Input_Date' => 'Input_Date__c',
            'Input_Date_Time' => 'Input_Datetime__c',
            'Input_Number' => 'Input_Number__c',
            'Input_Picklist' => 'Input_Text__c',
            'Input_Radio_Group' => 'Input_Text__c',
            'Input_Text' => 'Input_Text__c',
            'Input_Email' => 'Input_Text__c',
            'Input_Lookup' => 'Input_Text__c',
            'Input_Text_Area_Long' => 'Input_Text_Long__c',
            'Input_Address' => 'Input_Address'
        };

        List<Application_Detail__c> appDetails = [
            SELECT Id,
                Application_Section__r.Application__c,
                Target_Field_API_Name__c,
                RecordType.DeveloperName,
                Input_Checkbox__c,
                Input_Currency__c,
                Input_Date__c,
                Input_Datetime__c,
                Input_Number__c,
                Input_Text__c,
                Input_Text_Long__c,
                Input_Street__c,
                Input_City__c,
                Input_State_Province__c,
                Input_Postal_Code__c,
                Input_Country__c,
                Street_Target_Field_API_Name__c,
                City_Target_Field_API_Name__c,
                Province_Target_Field_API_Name__c,
                Postal_Code_Target_Field_API_Name__c,
                Country_Target_Field_API_Name__c,
                App_Field_API_Name_with_Target_Record_Id__c
            FROM Application_Detail__c
            WHERE Application_Section__r.Application__c = :app.Id
                AND App_Field_API_Name_with_Target_Record_Id__c != null
                AND (
                    Target_Field_API_Name__c != null OR
                    Street_Target_Field_API_Name__c != null OR
                    City_Target_Field_API_Name__c != null OR
                    Province_Target_Field_API_Name__c != null OR
                    Postal_Code_Target_Field_API_Name__c != null OR
                    Country_Target_Field_API_Name__c != null
                )
        ];

        System.debug('✅ Loaded ' + appDetails.size() + ' Application_Detail__c records.');

        Map<Id, sObject> sObjectMap = new Map<Id, sObject>();

        for (Application_Detail__c appDetail : appDetails) {

            if (appDetail.RecordType == null || appDetail.RecordType.DeveloperName == null) {
                System.debug('⚠️ Skipping record due to missing RecordType.');
                continue;
            }

            String appFieldApiName = appDetail.App_Field_API_Name_with_Target_Record_Id__c;
            if (appFieldApiName == null) {
                System.debug('⚠️ Skipping record due to null App_Field_API_Name_with_Target_Record_Id__c.');
                continue;
            }

            Object targetRecordIdObj = app.get(appFieldApiName);
            if (targetRecordIdObj == null) {
                System.debug('⚠️ Application record has no value for field: ' + appFieldApiName);
                continue;
            }

            Id targetRecordId;
            try {
                targetRecordId = (Id)targetRecordIdObj;
            } catch (Exception e) {
                System.debug('❌ Could not cast field value to Id for: ' + appFieldApiName);
                continue;
            }

            if (!sObjectMap.containsKey(targetRecordId)) {
                String targetObjectAPIName;
                try {
                    targetObjectAPIName = targetRecordId.getSObjectType().getDescribe().getName();
                } catch (Exception e) {
                    System.debug('❌ Could not determine SObject type for Id: ' + targetRecordId);
                    continue;
                }

                Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(targetObjectAPIName);
                if (sObjectType == null) {
                    System.debug('❌ Could not find Schema.SObjectType for: ' + targetObjectAPIName);
                    continue;
                }

                SObject sob = sObjectType.newSObject();
                sob.Id = targetRecordId;
                sObjectMap.put(targetRecordId, sob);
            }

            SObject sob = sObjectMap.get(targetRecordId);

            String sourceFieldApiName = recordTypeInputFieldMap.get(appDetail.RecordType.DeveloperName);
            if (String.isBlank(sourceFieldApiName)) {
                System.debug('⚠️ No source field mapping for RecordType: ' + appDetail.RecordType.DeveloperName);
                continue;
            }

            if (sourceFieldApiName == 'Input_Address') {
                if (appDetail.Street_Target_Field_API_Name__c != null)
                    sob.put(appDetail.Street_Target_Field_API_Name__c, appDetail.Input_Street__c);
                if (appDetail.City_Target_Field_API_Name__c != null)
                    sob.put(appDetail.City_Target_Field_API_Name__c, appDetail.Input_City__c);
                if (appDetail.Province_Target_Field_API_Name__c != null)
                    sob.put(appDetail.Province_Target_Field_API_Name__c, appDetail.Input_State_Province__c);
                if (appDetail.Postal_Code_Target_Field_API_Name__c != null)
                    sob.put(appDetail.Postal_Code_Target_Field_API_Name__c, appDetail.Input_Postal_Code__c);
                if (appDetail.Country_Target_Field_API_Name__c != null)
                    sob.put(appDetail.Country_Target_Field_API_Name__c, appDetail.Input_Country__c);
            } else {
                String targetFieldApiName = appDetail.Target_Field_API_Name__c;
                Object sourceFieldValue = appDetail.get(sourceFieldApiName);
                if (targetFieldApiName != null && sourceFieldValue != null) {
                    sob.put(targetFieldApiName, sourceFieldValue);
                }
            }

            System.debug('✅ Updated sObject: ' + sob);
        }

        if (!sObjectMap.isEmpty()) {
            update sObjectMap.values();
            System.debug('✅ Updated ' + sObjectMap.size() + ' target records.');
        } else {
            System.debug('ℹ️ No records to update.');
        }
    }

    public class Request {
        @InvocableVariable(label='Application Record' required=true)
        public Application__c application;
    }
}