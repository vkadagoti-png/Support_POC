public without sharing class GetObjectApiNameFromRecordId {
    @InvocableMethod(label='Get Object API Name from Record Id (GetObjectApiNameFromRecordId)' description='Returns the API Name of an Object based on a Record Id input.')
    public static List<Result> getObjectApiName(List<Request> request){
        List<Result> results = new List<Result>();
        Result result = new Result();
        result.success = false;

        try {
            Id targetObjectRecordId = request[0].recordId;
            String targetObjectAPIName  = (Id.valueOf(targetObjectRecordId)).getSObjectType().getDescribe().getName();
            result.objectApiName = targetObjectAPIName;
            result.success = true;
        }
        catch (Exception e) {
            result.error = e.getMessage();
            results.add(result);
            return results;
        }

        results.add(result);
        return results;
    }

    public class Request {
        @InvocableVariable(label='Record Id' required=true)
        public Id recordId;
    }

    public class Result {
        @InvocableVariable(label='Object API Name')
        public String objectApiName;
        @InvocableVariable(label='Success (boolean)')
        public Boolean success;
        @InvocableVariable(label='Error')
        public String error;
    }

}