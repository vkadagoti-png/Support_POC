public without sharing class CreateNewRecordsFromRecordList {
    @InvocableMethod(label='Create New Records From Record List (CreateNewRecordsFromRecordList)' description='Creates 1 or more child object records based on a list .')
    public static List<Result> createNewRecords(List<Request> request){
        List<Result> results = new List<Result>();
        Result result = new Result();
        result.success = false;

        try {
            String sourceObjectApiName = request[0]?.sourceObjectApiName;
            String sourceObjectFilterString = request[0]?.sourceObjectFilterString;
            String sourceDupMatchFieldApiName = request[0]?.sourceDupMatchFieldApiName;
            String targetDupMatchFieldApiName = request[0]?.targetDupMatchFieldApiName;
            String targetObjectApiName = request[0]?.targetObjectApiName;
            String jsonFieldMappings = request[0]?.jsonFieldMappings;
            Id parentRecordId = request[0]?.parentRecordId;
            String parentLookupFieldApiName = request[0]?.parentLookupFieldApiName;
            String sourceQueryString = 'SELECT Id';

            List<String> dupFilterStrings = new List<String>();

            if(sourceDupMatchFieldApiName != null && targetDupMatchFieldApiName != null) {

                String targetDupQuery = 'SELECT ' + targetDupMatchFieldApiName + ' FROM ' + targetObjectApiName + ' WHERE ' + parentLookupFieldApiName + ' = :parentRecordId';
                List<SObject> targetPotentialDups = Database.query(targetDupQuery);

                if(targetPotentialDups.size() > 0) {

                    for(SObject potentialDup : targetPotentialDups) {
                        String fieldValue = (String) potentialDup.get(targetDupMatchFieldApiName);
                        dupFilterStrings.add(fieldValue);
                    }

                }
            }

            Map<String, String> fieldMap =  new Map<String, String>();
            if(jsonFieldMappings != null & jsonFieldMappings != '') {
                fieldMap = (Map<String, String>) JSON.deserialize(jsonFieldMappings, Map<String, String>.class);

                for (String key : fieldMap.keySet()) {
                    System.debug(key);
                    sourceQueryString += ', ' + key;
                }
            }

            sourceQueryString += ' FROM ' + sourceObjectApiName + ' WHERE ' + sourceObjectFilterString;

            if(dupFilterStrings.size() > 0) {
                sourceQueryString += ' AND ' + sourceDupMatchFieldApiName + ' NOT IN :dupFilterStrings';
            }

            List<SObject> sourceRecords = Database.query(sourceQueryString);

            if(sourceRecords.size() > 0) {
                Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(targetObjectAPIName);
                
                List<sObject> newRecords = new List<sObject>();
                
                for(sObject rec : sourceRecords) {
                    SObject sob = sObjectType.newSObject();

                    if(parentRecordId != null && parentLookupFieldApiName != null && parentLookupFieldApiName != '') {
                        sob.put(parentLookupFieldApiName, parentRecordId);
                    }

                    for (String key : fieldMap.keySet()) {
                        String sourceApiName = key;
                        String targetApiName = fieldMap.get(key);
                        Object sourceFieldValue = rec.get(sourceApiName);
                            
                        if (sourceFieldValue != null && sourceFieldValue != '') {
                            sob.put(targetApiName, sourceFieldValue);
                        }
                    }

                    newRecords.add(sob);
                }

                insert newRecords;
                result.success = true;
            }

        } catch (Exception e) {
            result.error = e.getMessage();
            results.add(result);
            return results;
        }

        results.add(result);
        return results;
    }

    public class Request {
        @InvocableVariable(label='Source Object API Name' required=true description='The API Name of the object to query to get source/reference records (such as Reference_Checks__c)')
        public String sourceObjectApiName;
        @InvocableVariable(label='Source Object Filter String' required=true description='A string of any filter criteria that would go after the WHERE clause in a SOWL query. Eample: "Reference_Checks__c = \'"&{!input_RefCheckId}&"\'" ')
        public String sourceObjectFilterString;
        @InvocableVariable(label='Source Duplicate Match Field API Name' required=false description='API Name of Field on SOURCE Object that should be used to filter out duplicates when it matches the Target Duplicate Match Field API Name')
        public String sourceDupMatchFieldApiName;
        @InvocableVariable(label='Target Duplicate Match Field API Name' required=false description='API Name of Field on TARGET Object that should be used to filter out duplicates when it matches the Source Duplicate Match Field API Name')
        public String targetDupMatchFieldApiName;
        @InvocableVariable(label='Target Object API Name' required=true description='The API Name of the object to create new records for (such as Project__c)')
        public String targetObjectApiName;
        @InvocableVariable(label='JSON Field Mapping' required=false description='Source and Target field API name pairs (optional). Example:  {"Display_Name_on_Source__c":"Display_Name_on_Target__c","Description__c":"Description_Text__c",...}')
        public String jsonFieldMappings;
        @InvocableVariable(label='Parent RecordId' required=false description='Parent object Record Id (optional, but also requires Parent Lookup Field API Name to be specified)')
        public String parentRecordId;
        @InvocableVariable(label='Lookup to Parent Field API Name' required=false description='API Name of the lookup on the new record that should point to the parent (optional, but also requires Parent RecordId to be specified)')
        public String parentLookupFieldApiName;
    }

    public class Result {
        @InvocableVariable(label='Success (boolean)')
        public Boolean success;
        @InvocableVariable(label='Error Message')
        public String error;
    }

}