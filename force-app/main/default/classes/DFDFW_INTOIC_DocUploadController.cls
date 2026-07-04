/*
*********************************************************
Apex Class Name    : DFDFW_INTOIC_DocUploadController
Created Date       : 11/04/2024
Author             : Cloud Synapps Inc.
Description        : Handles the uploading of files to OIC / City Works
Test Class Name    : DFDFW_INTOIC_DocUploadControllerTest
*********************************************************
*/
global with sharing class DFDFW_INTOIC_DocUploadController implements Callable {
    public Object call(String action, Map<String, object> args) {
        Map<String, Object> input = (Map<String, Object>) args.get('input');
        Map<String, Object> output = (Map<String, Object>) args.get('output');
        Map<String, Object> options = (Map<String, Object>) args.get('options');
        
        return invokeMethod(action, input, output, options);
    }

    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        try {
            if(methodName.equals('uploadFilesToCityWorks')) {                                                               
                uploadFilesToCityWorks(inputMap, outputMap); 
            } 
            return true;           
        } 
        catch(Exception e) {
            new DFDFW_LOG_AllException().Module('DFDFW_INTOIC_DocUploadController').Log(e);
            return false; 
        }
    }

    /*
    *********************************************************
    @method Name    : uploadFilesToCityWorks
    @description    : Syncs all the files with city works that need to be synced. 
    @param          : inputMap
    @param          : outputMap
    ********************************************************
    */
    private static void uploadFilesToCityWorks(Map<String,Object> inputMap, Map<String,Object> outputMap){

        //Retreive the record Id
        String recordId = (String) inputMap.get('ContextId');
        
        Set<id> contentVersionIds = new Set<id>();
        //Loop throught content document links attached to the record and add the Content Version Ids to Set
        for(ContentDocumentLink cdl : [SELECT Id, ContentDocument.LatestPublishedVersionId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId]){
            contentVersionIds.add(cdl.ContentDocument.LatestPublishedVersionId);
        }
        //Trim the ContentVersions that have not been synced with City Works
        List <ContentVersion> contentVersionsAttached = [SELECT Id FROM ContentVersion WHERE Id IN :contentVersionIds AND DFDFW_Synced_With_City_Works__c = false];
        
        //Retreive the Service Application record to get the permit Id
        Service_Application_Detail__c serviceApplication = [SELECT Id, Case_Application_Id__c FROM Service_Application_Detail__c WHERE Id = :recordId LIMIT 1];

        //Loop through the content Versions and call the future method for each one
        for(ContentVersion cv : contentVersionsAttached){
            uploadFile(cv.Id, (Integer)serviceApplication.Case_Application_Id__c);
        }

    }

    /*
    *********************************************************
    @method Name    : uploadFile
    @description    : future method to upload a file that has not yet been synced with City Works
    @param          : fileId
    @param          : permitId
    ********************************************************
    */
    @future(callout=true)
    public static void uploadFile(String fileId, Integer permitId){

        try{
            
            //Get the endpoint information via metadata
            DFD_CityWorks_Endpoint__mdt documentUpload = DFD_CityWorks_Endpoint__mdt.getInstance('Document_Upload');
            //Configure the full endpoint
            String documentUploadEndpoint = 'callout:DFDFW_OIC_Endpoint' + documentUpload.Endpoint_URI__c + '/' + permitId;
            
            UUID randomUUID = UUID.randomUUID();
            
            //Form HTTP callout
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(documentUploadEndpoint);
            req.setMethod(documentUpload.Method__c);
            req.setHeader('Accept', '*/*');
            req.setHeader('Accept-Encoding', 'gzip, deflate, br');
		    req.setHeader('Content-Type', 'application/json');
            req.setHeader('X-Access-Token', DFDFW_AUTH0_ManageUserTokenCtrl.getUserAccessToken(UserInfo.getUserId()));
            req.setHeader('X-Request-Id', String.valueOf(randomUUID));
            
            //Form the Request Body, SOQL for loop to save heap size
            Map<String, Object> requestBodyMap = new Map<String, Object>();
            for(ContentVersion file : [SELECT FileType, VersionData, PathOnClient FROM ContentVersion WHERE Id = :fileId]){
                requestBodyMap.put('mimeType', DFDFW_Document_Mimetype_Mapping__mdt.getInstance(file.FileType).Mimetype__c);
                requestBodyMap.put('base64', EncodingUtil.base64Encode(file.VersionData));
                requestBodyMap.put('FileName', file.PathOnClient);
                break;
            }

		    req.setBody(JSON.serialize(requestBodyMap));

            //Make HTTP callout
            HTTPResponse res = http.send(req);

            //If a valid response, update the ContentVersion to be synced with City Works
            if(res.getStatusCode() == 200){
                ContentVersion cv = new ContentVersion();
                cv.DFDFW_Synced_With_City_Works__c = true;
                cv.Id = fileId;
                update cv;
            }
            else{
                //Create exception log record if response status code was not 200
                Exception_Logger__c logger = new Exception_Logger__c();
                logger.Module_Name__c = 'Error in Document Upload ==> ' + req.getEndpoint();
                logger.Stack_Trace__c = res.getBody();
                logger.Class_Name__c = 'DFDFW_INTOIC_DocUploadController';
                logger.Method_Name__c = 'uploadFile';
                logger.Exception_Type__c = 'API Callout Failure';
                logger.Exception_Cause__c = 'Status Code== ' + res.getStatusCode();
                logger.Exception_Message__c = res.getStatus();
                logger.DFD_X_Request_Id__c = String.valueOf(randomUUID);
                insert logger;
            }

        }catch(Exception e){
            new DFDFW_LOG_AllException().Module('DFDFW_INTOIC_DocUploadController').Log(e);
        }

    }

}