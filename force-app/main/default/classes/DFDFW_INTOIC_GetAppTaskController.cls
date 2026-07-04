/*
*********************************************************
Apex Class Name    : DFDFW_INTOIC_GetAppTaskController
Created Date       : 11/19/2024
Author             : Cloud Synapps Inc.
Description        : Controller for retreiving and displaying information for the permit. Mainly the Task information.
Test Class Name    : DFDFW_INTOIC_GetAppTaskControllerTest
*********************************************************
*/
public without sharing class DFDFW_INTOIC_GetAppTaskController {
    /*
    *********************************************************
    @method Name    : getColumns
    @description    : Retreives the columns from metadata record that will be displayed for the tasks
    @param          : metadataName
    @return         : List<Map<String, String>>
    ********************************************************
    */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getColumns(String metadataName) {
        try {
            //Get the columns from the metadata
            Community_Dashboard_Endpoint__mdt mdt = Community_Dashboard_Endpoint__mdt.getInstance(
                metadataName
                );
            
            //Create the lists for the labels and the names
            List<String> fieldNames = mdt.Fields_To_Display__c.split(',');
            List<String> fieldLabels = mdt.Field_Labels__c.split(',');
            
            List<Map<String, String>> columns = new List<Map<String, String>>();
            
            //Loop through the lists to add them to the columns map
            for (Integer i = 0; i < fieldNames.size(); i++) {
                Map<String, String> col = new Map<String, String>();
                col.put('label', fieldLabels[i]);
                col.put('fieldName', fieldNames[i]);
                columns.add(col);
            }
            
            return columns;
        } catch (Exception e) {
            new DFDFW_LOG_AllException()
                .Module('DFDFW_INTOIC_GetAppTaskController')
                .Log(e);
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /*
    *********************************************************
    @method Name    : getTasks
    @description    : Makes a callout to retreive the tasks from cityworks along with the case status.
    @param          : recordId
    @return         : List<Object>
    ********************************************************
    */
    @AuraEnabled
    public static Map<String, Object> getTasks(String recordId) {
        try {
            //Query the Service Application record
            Service_Application_Detail__c sad = [
            SELECT Id, Case_Application_Id__c, Name, OIC_Status__c
            FROM Service_Application_Detail__c
            WHERE Id = :recordId
            LIMIT 1
            ];
            
            Map<String, Object> returnInfo = new Map<String, Object>();
            List<Object> tasks = new List<Object>();
            List<Integer> linkedPermitIds = new List<Integer>();

            HttpResponse res = getPermit((Integer)sad.Case_Application_Id__c);
            
            //Check for valid 200 response
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                //Get the task and case lists from the response map
                tasks = (List<Object>) responseMap.get('Tasks');
                List<Object> cases = (List<Object>) responseMap.get('Case');
                List<Object> fees = (List<Object>) responseMap.get('Fees'); //SV changes

                for (Object c : cases) {
                    Map<String, Object> caseMap = (Map<String, Object>) c;
                    Integer caId = (Integer) caseMap.get('CaObjectId');
                    //Check if the case application Id is correct
                    if (caId == sad.Case_Application_Id__c) {
                        //Get the Case Status and break the loop
                        sad.OIC_Status__c = (String) caseMap.get('CaseStatus');
                        break;
                    }
                }
                for (Object fee : fees) {           //SV changes
                    Map<String, Object> feeMap = (Map<String, Object>) fee;
                    Integer caId = (Integer) feeMap.get('CaObjectId');
                    if (caId == sad.Case_Application_Id__c) {
                        if(feeMap.get('Amount') != null){
                            sad.Fee__c = (Decimal) feeMap.get('Amount');
                            break;
                        }
                            
                    }
                }

                //Get the Linked Permits from the response
				List<Object> linkedPermits = (List<Object>) responseMap.get('LinkedPermits');
				
				List<Sub_Application__c> subAppsToUpsert = new List<Sub_Application__c>();

                if(linkedPermits != null){
                //Loop through the linked permits and set the sub application details for upserting
				    for(Object lp : linkedPermits){
				    	Map<String, Object> lpMap = (Map<String, Object>) lp;

				    	Sub_Application__c subApp = new Sub_Application__c();
				    	subApp.Case_Application_Id__c = ((Integer) lpMap.get('DestSid') != sad.Case_Application_Id__c) ? ((Integer) lpMap.get('DestSid')) : ((Integer) lpMap.get('SourceSid'));
				    	//Add the Id to the linked Permit Ids List
                        linkedPermitIds.add((Integer)subApp.Case_Application_Id__c);
                        subApp.Service_Application_Detail__c = recordId;
				    	subAppsToUpsert.add(subApp);
				    }
                }

                if (sad.OIC_Status__c == 'ISSUED' || sad.OIC_Status__c == 'DONE') {
                    getPDFDocument(sad.Id, (Integer)sad.Case_Application_Id__c);
                }

				upsert subAppsToUpsert Case_Application_Id__c;
                update sad;
                returnInfo.put('success', true);
            }
            else{
                returnInfo.put('error', res.getBody());
                returnInfo.put('success', false);
            }

            returnInfo.put('Tasks', tasks);
            returnInfo.put('LinkedPermits', linkedPermitIds);
            
            return returnInfo;
        } catch (Exception e) {
            new DFDFW_LOG_AllException().Module('DFDFW_INTOIC_GetAppTaskController').Log(e);
            return new Map<String, Object>{'success' => false, 'error' => e};
        }
    }
    
    /*
    *********************************************************
    @method Name    : getErrorMessage
    @description    : Retreives the Error message from metadata and returns it
    @return         : String
    ********************************************************
    */
    @AuraEnabled(cacheable=true)
    public static String getErrorMessage() {
        try {
            //Retreive the error message from metadata and return it
            DFD_Error_Messages__mdt errorMessage = DFD_Error_Messages__mdt.getInstance('DFD_Task_Controller_Get_Task_Error');
            return errorMessage.Error_Message__c;
        } catch (Exception e) {
            new DFDFW_LOG_AllException()
                .Module('DFDFW_INTOIC_GetAppTaskController')
                .Log(e);
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /*
    *********************************************************
    @method Name    : getPDFDocument
    @description    : Used to retreive the documents from OIC / City Works via APIs
    @param          : recordId
    @param          : permitId
    ********************************************************
    */
    public static void getPDFDocument(Id recordId, Integer permitId) {
        try {

            //Get Endpoint information from metadata
            DFD_CityWorks_Endpoint__mdt getPermitDownloads = DFD_CityWorks_Endpoint__mdt.getInstance('Get_Permit_Downloads');

            //Configure full endpoint
            String getPermitDownloadsEndpoint = 'callout:DFDFW_OIC_Endpoint' + getPermitDownloads.Endpoint_URI__c + '/' + permitId;

            //get user access token to add to request headers
            String accessToken = DFDFW_AUTH0_ManageUserTokenCtrl.getUserAccessToken(UserInfo.getUserId());

            UUID randomUUID = UUID.randomUUID();

            //Create header map to send to callout method
            Map<String, String> headerMap = new Map<String, String>{
                'X-Access-Token' => accessToken,
                'X-Request-Id' => String.valueOf(randomUUID)
            };

            String response = DFDFW_INTGEN_CallOutController.callout(
                getPermitDownloadsEndpoint,
                getPermitDownloads.Method__c,
                false,
                null,
                true,
                headerMap
            );

            if (response != null){
                
                //Get the existing Content Versions attached to the record
                List<ContentVersion> existingContentVersions = [SELECT Id, DFDFW_Case_Document_Id__c, FirstPublishLocationId FROM ContentVersion WHERE FirstPublishLocationId = :recordId];
                //Add all the document Ids of existing content versions to a Set
                Set<Integer> documentIds = new Set<Integer>();
                for(ContentVersion cv : existingContentVersions){
                    documentIds.add((Integer)cv.DFDFW_Case_Document_Id__c);
                }

                List<Object> responseList = (List<Object>) JSON.deserializeUntyped(response);
                
                List<ContentVersion> contentVersionsToInsert = new List<ContentVersion>();

                //Loop through returned documents attached to the case
                for(Object document : responseList){
                    Map<String, Object> documentMap = (Map<String, Object>) document;

                    //If blank response continue to next document
                    if(String.isBlank((String)documentMap.get('CA_REL_DOC_ID'))){
                        continue;
                    }

                    //Check if the document already exists in salesforce
                    if(!documentIds.contains(Integer.valueOf((String)documentMap.get('CA_REL_DOC_ID')))){
                        
                        //Call the download document method to download each document via API callout
                        ContentVersion returnedContentVersion = documentDownload(recordId, permitId, Integer.valueOf((String)documentMap.get('CA_REL_DOC_ID')), (String)documentMap.get('DOC_NAME'));
                        //If a content version was returned, add it to the list to insert
                        if(returnedContentVersion != null){
                            contentVersionsToInsert.add(returnedContentVersion);
                        }
                    }
                }
                insert contentVersionsToInsert;
            }

        } catch (Exception e) {
            new DFDFW_LOG_AllException().Module('DFDFW_INTOIC_GetAppTaskController').Log(e);
        }
    }


    /*
    *********************************************************
    @method Name    : documentDownload
    @description    : Used to download a specific document from OIC / City Works via API
    @param          : recordId
    @param          : permitId
    @param          : documentId
    @param          : fileName
    @return         : ContentVersion
    ********************************************************
    */
    public static ContentVersion documentDownload(Id recordId, Integer permitId, Integer documentId, String fileName){
        try{

            //Get the endpoint information via metadata
            DFD_CityWorks_Endpoint__mdt getPermitDownload = DFD_CityWorks_Endpoint__mdt.getInstance('Get_Permit_Download');
            //Configure the full endpoint
            String getPermitDownloadEndpoint = 'callout:DFDFW_OIC_Endpoint' + getPermitDownload.Endpoint_URI__c + '/' + permitId + '/' + documentId;
            //Get the user's access token
            String accessToken = DFDFW_AUTH0_ManageUserTokenCtrl.getUserAccessToken(UserInfo.getUserId());

            UUID randomUUID = UUID.randomUUID();

            //Form HTTP callout
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(getPermitDownloadEndpoint);
            req.setMethod('GET');
            req.setHeader('X-Access-Token', accessToken);
            req.setHeader('X-Request-Id', String.valueOf(randomUUID));

            HTTPResponse res = http.send(req);

            ContentVersion contentVersionToReturn = new ContentVersion();
            //If valid response, add the fields for the content version to be inserted
            if(res.getStatusCode() == 200){
                contentVersionToReturn.VersionData = res.getBodyAsBlob();
                contentVersionToReturn.PathOnClient = fileName;
                contentVersionToReturn.Title = fileName;
                contentVersionToReturn.FirstPublishLocationId = recordId;
                contentVersionToReturn.File_Category__c = 'Issued Permit';
                contentVersionToReturn.DFDFW_Case_Document_Id__c = documentId;
                contentVersionToReturn.DFDFW_Synced_With_City_Works__c = true;
            }
            else{
                Exception_Logger__c logger = new Exception_Logger__c();
                logger.Module_Name__c = 'Error in Callouts ==> ' + req.getEndpoint();
                logger.Class_Name__c = 'DFDFW_INTOIC_GetAppTaskController';
                logger.Method_Name__c = 'documentDownload';
                logger.Exception_Type__c = 'API Callout Failure';
                logger.Exception_Cause__c = 'Status Code==> ' + res.getStatusCode();
                logger.Exception_Message__c = res.getBody();
                logger.DFD_X_Request_Id__c = String.valueOf(randomUUID);
                insert logger;
            }

            return contentVersionToReturn;

        }catch(Exception e){
            new DFDFW_LOG_AllException().Module('DFDFW_INTOIC_GetAppTaskController').Log(e);
            return null;
        }
   
    }

    /*
    *********************************************************
    @method Name    : getSubApplication
    @description    : Makes callout to get the information for the Sub application record
    @param          : applicationId
    @param          : serviceAppId
    ********************************************************
    */
    @AuraEnabled
    public static Boolean getSubApplication(Integer applicationId, String serviceAppId){

        try{

            HttpResponse res = getPermit(applicationId);

            if (res.getStatusCode() == 200) {

                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> cases = (List<Object>) responseMap.get('Case');
                List<Object> fees = (List<Object>) responseMap.get('Fees'); //SV changes

                Sub_Application__c subApp = new Sub_Application__c();

                for (Object c : cases) {
                    Map<String, Object> caseMap = (Map<String, Object>) c;
                    Integer caId = (Integer) caseMap.get('CaObjectId');
                    //Check if the case application Id is correct
                    if (caId == applicationId) {

                        subApp.Permit_Type__c = ((String) caseMap.get('CaseType')).toLowerCase().capitalize();
                        subApp.Case_Number__c = (String) caseMap.get('CaseNumber');
                        subApp.Status__c = ((String) caseMap.get('CaseStatus')).toLowerCase().capitalize();
                        subApp.Case_Application_Id__c = applicationId;
		    		    subApp.Service_Application_Detail__c = serviceAppId;
                        break;
                    }
                }
                Map<Integer, Decimal> caIdToFeeMap = new Map<Integer, Decimal>();
                for (Object fee : fees) {               //SV changes
                    Map<String, Object> feeMap = (Map<String, Object>) fee;
                    Integer caId = (Integer) feeMap.get('CaObjectId');
                    if (caId == applicationId) {
                        if(feeMap.get('Amount') != null){
                            Decimal currentFee = (Decimal) feeMap.get('Amount');
                            if(caIdToFeeMap.containsKey(caId)){
                                caIdToFeeMap.put(caId, caIdToFeeMap.get(caId) + currentFee);
                            }else{
                                caIdToFeeMap.put(caId, currentFee);
                            }
                        }
                    }
                }

                if(caIdToFeeMap.containsKey(applicationId)){
                    subApp.Fee__c = caIdToFeeMap.get(applicationId);
                    subApp.Case_Application_Id__c = applicationId;
                }
                
                Sub_Application__c sub = [SELECT Id, Status__c FROM Sub_Application__c WHERE Case_Application_Id__c = :applicationId LIMIT 1];

                //Get Permit if status is Issued
                if ((subApp.Status__c == 'Issued' || subApp.Status__c == 'Issue' || subApp.Status__c == 'Done' || subApp.Permit_Type__c == 'Parks')){
                    getPDFDocument(sub.Id, applicationId);
                }

                upsert subApp Case_Application_Id__c;

                return true;
            }
            else{
                return false;
            }
        }
        catch(Exception e){
                new DFDFW_LOG_AllException().Module('DFDFW_INTOIC_GetAppTaskController').Log(e);
                return false;
        }

    }


    /*
    *********************************************************
    @method Name    : getPermit
    @description    : Makes the get permit callout and returns the response
    @param          : permitId
    @return         : HttpResponse
    ********************************************************
    */
    public static HttpResponse getPermit(Integer permitId){
        //Retreive the user access token for request
        String accessToken = DFDFW_AUTH0_ManageUserTokenCtrl.getUserAccessToken(
            UserInfo.getUserId()
            );
        
        //Retreive the appropraiet endpoint information
        DFD_CityWorks_Endpoint__mdt permitEndpoint = DFD_CityWorks_Endpoint__mdt.getInstance(
            'Get_Permit_By_Id'
            );
        
        UUID randomUUID = UUID.randomUUID();
        
        //Form HTTP callout
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(
            'callout:DFDFW_OIC_Endpoint' +
            permitEndpoint.Endpoint_URI__c +
            '/' +
            permitId
            );
        req.setMethod(permitEndpoint.Method__c);
        req.setHeader('X-Access-Token', accessToken);
        req.setHeader('X-Request-Id', String.valueOf(randomUUID));
        req.setTimeout(100000);
        
        //Make HTTP callout
        HTTPResponse res = http.send(req);

        //Check for valid 200 response
        if (res.getStatusCode() != 200) {
            //Create exception log record if response status code was not 200
            Exception_Logger__c logger = new Exception_Logger__c();
            logger.Module_Name__c = 'Error in getting Permit Callout ==> ' + req.getEndpoint();
            logger.Stack_Trace__c = res.getBody();
            logger.Class_Name__c = 'DFDFW_INTOIC_GetAppTaskController';
            logger.Method_Name__c = 'getPermit';
            logger.Exception_Type__c = 'API Callout Failure';
            logger.Exception_Cause__c = 'Status Code== ' + res.getStatusCode();
            logger.Exception_Message__c = res.getStatus();
            logger.DFD_X_Request_Id__c = String.valueOf(randomUUID);
            insert logger;
        }

        return res;
    }



}