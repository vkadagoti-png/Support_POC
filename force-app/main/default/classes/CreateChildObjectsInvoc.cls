public with sharing class CreateChildObjectsInvoc {
    
    @InvocableMethod(label='Create Child Object(s)' description='Creates 1 or more child object record with a lookup pointing to the parent record, defined by a JSON object string.')
    public static List<Result> createChildBojects(List<Request> request){
        List<Result> results = new List<Result>();
        Result result = new Result();
        result.success = false;

        try {
            String recordId = request[0].recordId;
            String jsonString = request[0].jsonObjectString;
            String parentObjectApiName = request[0].parentObjectApiName;

            List<ChildObjectConfig> childConfigs = (List<ChildObjectConfig>)JSON.deserialize(jsonString, List<ChildObjectConfig>.class);

            List<sObject> childRecords = new List<sObject>();
            List<String> parentFieldToChildList = new List<String>();
        
            for (ChildObjectConfig childConfig : childConfigs) {
                Schema.SObjectType childObjectType = Schema.getGlobalDescribe().get(childConfig.childObjectApiName);
                
                if (childObjectType != null) {
                    sObject childObj = childObjectType.newSObject();
                    childObj.put(childConfig.childFieldForRecordId, recordId);
                    childRecords.add(childObj);
                }
                
                if (!String.isBlank(childConfig.parentFieldForChildId)) {
                    parentFieldToChildList.add(childConfig.parentFieldForChildId); 
                }
            }

            if(childRecords.size() > 0) {
                insert childRecords;

                if (parentFieldToChildList.size() > 0) {
                    Schema.SObjectType parentObjectType = Schema.getGlobalDescribe().get(parentObjectApiName);
                    sObject parentRecord = parentObjectType.newSObject();
                    parentRecord.Id = recordId;

                    for(Integer i = 0; i < childRecords.size(); i++) {
                        String parentField = childConfigs[i].parentFieldForChildId;
                        if(!String.isBlank(parentField)) {
                            parentRecord.put(parentField, childRecords[i].Id);
                        }
                    }

                    update parentRecord;
                }

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
        @InvocableVariable(label='JSON Object String' required=true description='[{"childObjectApiName":"Child_Object_Api_Name__c","childFieldForRecordId":"Child_Field_For_RecordId__c","parentFieldForChildId":"Parent_Field_API_Name__c"},{"childObjectApiName":"Child_Object_Api_Name2__c","childFieldForRecordId":"Child_Field_For_RecordId2__c","parentFieldForChildId":""},...] ... NOTE: Leave parentFieldForChildId blank if you do not want to populate the Id of the new child record to a field on the parent.')
        public String jsonObjectString;
        @InvocableVariable(label='Parent Object API Name' required=true description='The API Name of your parent object (such as Application__c)')
        public String parentObjectApiName;
        @InvocableVariable(label='RecordId' required=true description='Parent object Record Id')
        public String recordId;
    }

    public class Result {
        @InvocableVariable(label='Success (boolean)')
        public Boolean success;
        @InvocableVariable(label='Error Message')
        public String error;
    }
    
    private class ChildObjectConfig {
        public String childObjectApiName;
        public String childFieldForRecordId;
        public String parentFieldForChildId;
    }
}