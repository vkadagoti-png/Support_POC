/*
*********************************************************
Apex Class Name    : DFDFW_INTPAYMENT_CalloutController
Created Date       : 11/08/2024
Author             : Cloud Synapps Inc.
Description        : Controls the payment integration logic including callouts.
Test Class Name    : DFDFW_INTPAYMENT_CalloutControllerTest
*********************************************************
*/
public class DFDFW_INTPAYMENT_CalloutController{
    /*
    *********************************************************
    @method Name    : payFees
    @description    : Called from the payment checkout lwc - gets the fees and sends to payit.
    @param          : permitId
    @param          : returnUrl
    @param          : email
    @param          : searchFeeCode
    @param          : getAllFees
    @return         : String
    ********************************************************
    */
    @AuraEnabled
    public static Map<String, Object> payFees(Integer permitId, String returnUrl, String email, String searchFeeCode, Boolean getAllFees){
        try {

            //Get the fee information by making the get permit callout
            HttpResponse res = getPermit(permitId);
            if(res.getStatusCode() != 200){
                return new Map<String, Object>{'success' => false, 'error' => DFD_Error_Messages__mdt.getInstance('DFD_Payment_Controller_Generic').Error_Message__c};
            }

            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            //Get the Fees list
            List<Object> fees = (List<Object>) responseMap.get('Fees');

            List<Map<String, Object>> feeList = new List<Map<String, Object>>();
            //Loop through fees list and take the necessary fields for processing
            for(Object fee : fees){
                Map<String, Object> feeMap = (Map<String, Object>) fee;
                String feeCode = (String) feeMap.get('FeeCode');
                //Check for the feeCode if getAllFees is false
                if(getAllFees || (!getAllFees && feeCode == searchFeeCode)){
                    Map<String, Object> feeLineItem = new Map<String, Object>();
                    feeLineItem.put('FeeCode', (String) feeMap.get('FeeCode'));
                    feeLineItem.put('CaFeeId', String.valueOf((Integer) feeMap.get('CaFeeId')));
                    feeLineItem.put('FeeDesc', (String) feeMap.get('FeeDesc'));
                    feeLineItem.put('Amount', (Decimal) feeMap.get('Amount'));
                    feeLineItem.put('PaymentAmount', (Decimal) feeMap.get('PaymentAmount'));
                    feeLineItem.put('WaiveFee', (String) feeMap.get('WaiveFee'));
                    feeList.add(feeLineItem);
                }
            }

            //Call the createPaymentCart method to make the payIt create Cart callout with the line items
            String paymentId = createPaymentCart(feeList, email, permitId);

            //Call the getPayItUrl method to return the url to redirect to for payment
            return new Map<String, Object>{'success' => true, 'url' => getPayItURL(paymentId, returnUrl)};

        } 
        catch (Exception e) {
            new DFDFW_LOG_AllException().Module('DFD Payment Callout Controller').Log(e);
            String errorMessage = DFD_Error_Messages__mdt.getInstance('DFD_Payment_Controller_Generic').Error_Message__c;
            return new Map<String, Object>{'success' => false, 'error' => errorMessage};
        }
    }

    public static Map<Integer, String> getPermitTypeBasedOnCaseId(Decimal caseApplicationId){ //SV changes
        Map<Integer, String> caseApplicationIdToPermityTypeMap = new Map<Integer, String>();
        List<Service_Application_Detail__c> serviceList = [select id, Case_Application_Id__c, Permit_Type__c  from Service_Application_Detail__c where Case_Application_Id__c = :caseApplicationId];

        if(serviceList.size() > 0){
            for(Service_Application_Detail__c service: serviceList){
                caseApplicationIdToPermityTypeMap.put((Integer) service.Case_Application_Id__c, service.Permit_Type__c);
            }
        }else{
            List<Sub_Application__c> subList = [select id, Case_Application_Id__c, Permit_Type__c  from Sub_Application__c  where Case_Application_Id__c = :caseApplicationId];
            
            if(subList.size() > 0){
                for(Sub_Application__c sub: subList){
                    caseApplicationIdToPermityTypeMap.put((Integer) sub.Case_Application_Id__c, sub.Permit_Type__c);
                }
            }
        }

        return caseApplicationIdToPermityTypeMap;
    }

    /*
    *********************************************************
    @method Name    : getPermit
    @description    : Make the get permit callout and returns the response
    @param          : permitId
    @return         : HttpResponse
    ********************************************************
    */
    public static HttpResponse getPermit(Integer permitId){
        //Retrieve the user access token for request
        String accessToken = DFDFW_AUTH0_ManageUserTokenCtrl.getUserAccessToken(UserInfo.getUserId());
        
        //Retreive the appropriate endpoint information
        DFD_CityWorks_Endpoint__mdt permitEndpoint = DFD_CityWorks_Endpoint__mdt.getInstance('Get_Permit_By_Id');
        
        UUID randomUUID = UUID.randomUUID();
        
        //Form HTTP callout
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:DFDFW_OIC_Endpoint' + permitEndpoint.Endpoint_URI__c + '/' + permitId);
        req.setMethod(permitEndpoint.Method__c);
        req.setHeader('X-Access-Token', accessToken);
        req.setHeader('X-Request-Id', String.valueOf(randomUUID));
        req.setTimeout(60000);
        
        //Make HTTP callout
        HTTPResponse res = http.send(req);

        //Check for valid 200 response
        if (res.getStatusCode() != 200) {
            //Create exception log record if response status code was not 200
            Exception_Logger__c logger = new Exception_Logger__c();
            logger.Module_Name__c = 'Error in getting Permit Callout ==> ' + req.getEndpoint();
            logger.Stack_Trace__c = res.getBody();
            logger.Class_Name__c = 'DFDFW_INTPAYMENT_CalloutController';
            logger.Method_Name__c = 'getPermit';
            logger.Exception_Type__c = 'API Callout Failure';
            logger.Exception_Cause__c = 'Status Code== ' + res.getStatusCode();
            logger.Exception_Message__c = res.getStatus();
            logger.DFD_X_Request_Id__c = String.valueOf(randomUUID);
            insert logger;
            //throw newAuraException('Could not retrieve case information');
        }
        return res;

    }

    /*
    *********************************************************
    @method Name    : createPaymentCheckout
    @description    : Makes a callout to the PayIt endpoint to create a Cart that will later be accessed to pay.
    @param          : feeList
    @param          : email
    @return         : String
    ********************************************************
    */
    public static String createPaymentCart(List<Map<String, Object>> feeList, String email, Integer permitId) {

        //Get the accessToken
        String accessToken = getAccessToken();

        //If accessToken is null, pass empty string
        accessToken = accessToken != null ? accessToken : '';

        //Retreive the two metadata records that are needed for the configuration
        //Has information about endpoint and method
        DFDFW_Payment_Provider_Endpoint__mdt endpointInfo = DFDFW_Payment_Provider_Endpoint__mdt.getInstance('Create_Cart');
        //Has general information including base url, app name, etc. 
        DFDFW_Payment_Provider__mdt config = null;
        Map<Integer, String> caseApplicationIdToPermitTypeMap = getPermitTypeBasedOnCaseId(permitId);
        
        if(caseApplicationIdToPermitTypeMap.containsKey(permitId) && caseApplicationIdToPermitTypeMap.get(permitId) == 'Parks'){
            config = DFDFW_Payment_Provider__mdt.getInstance('St_Louis_Payments_Parks');
        }else if(caseApplicationIdToPermitTypeMap.containsKey(permitId) && caseApplicationIdToPermitTypeMap.get(permitId) == 'Streets'){
            config = DFDFW_Payment_Provider__mdt.getInstance('St_Louis_Payments_Streets');
        }else{
            config = DFDFW_Payment_Provider__mdt.getInstance('St_Louis_Payments');
        }
        

        //Construct the endpoint
        String endpoint = config.Base_URL__c + endpointInfo.Endpoint_URI__c.replace(':appName', config.App_Name__c);

        //Construct the start of the request body
        Map<String, Object> requestBodyMap = new Map<String, Object>{
            'appName' => config.App_Name__c,
            'authToken' => accessToken,
            'brandColor' => '',
            'requirePayItAuthentication' => true,
            'emailAddress' => email,
            'environment' => config.Environment__c,
            'lineItems' => new List<Map<String, Object>>{}
        };

        //Loop through fees list and add them to the request body map
        for(Map<String, Object> fee : feeList){
            //Get the required amount to pay
            Decimal feeAmount = ((Decimal) fee.get('Amount')) - ((Decimal) fee.get('PaymentAmount'));
            
            //Check if this fee requires payment, if not continue
            if(feeAmount <= 0 || (String) fee.get('WaiveFee') == 'true'){
                continue;
            }

            //Multiply by 100 for PayIt 
            feeAmount *= 100;
            system.debug('SV, serviceOfferingId:' + config.Service_Offering_Id__c);
            //populate a line item
            Map<String, Object> lineItem = new Map<String, Object>{
                'label' => (String) fee.get('FeeDesc'),
                'description' => '',
                'value' => feeAmount,
                'serviceOfferingId' => config.Service_Offering_Id__c,
                'uniqueExternalId' => (String) fee.get('CaFeeId')
            };
            ((List<Map<String, Object>>)requestBodyMap.get('lineItems')).add(lineItem);
        }

        //If no line items are present, throw an error
        if(((List<Map<String, Object>>)requestBodyMap.get('lineItems')).isEmpty()){
            String errorMessage = DFD_Error_Messages__mdt.getInstance('DFD_Payment_Controller_No_Fees').Error_Message__c;
            throw newAuraException(errorMessage);
        }

        // Serialize the request body map into JSON
        String requestBody = JSON.serialize(requestBodyMap);
            
        //Create the HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(endpointInfo.Method__c);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(requestBody);
        system.debug('SV, req:' + req);
        //Send the HTTP request
        Http http = new Http();
        HttpResponse res = http.send(req);
            
        //Check for success response 200 and return the response
        if (res.getStatusCode() == 200) {
            Map<String, String> responseMap = (Map<String, String>) JSON.deserialize(res.getBody(), Map<String, String>.class);
        
            //Return the id from the deserialized map
            return responseMap.get('id');
        } else {
            String errorMessage = 'Error in API callout: ' + res.getStatusCode() + ' - ' + res.getBody();
            throw newAuraException(errorMessage);
        }
            
    }
    
    /*
    *********************************************************
    @method Name    : getPaymentCallout
    @description    : Gets the appropriate payIt url and returns it
    @param          : paymentId
    @param          : returnUrl
    @return         : String
    ********************************************************
    */
    public static String getPayItURL(String paymentId, String returnUrl) {
            
        //Retreive the two metadata records that are needed for the configuration
        //Has information about endpoint and method
        DFDFW_Payment_Provider_Endpoint__mdt endpointInfo = DFDFW_Payment_Provider_Endpoint__mdt.getInstance('Get_Cart_UI');
        //Has general information including base url, app name, etc. 
        DFDFW_Payment_Provider__mdt config = DFDFW_Payment_Provider__mdt.getInstance('St_Louis_Payments');

        //Construct the base url
        String endpoint = config.Base_URL__c + endpointInfo.Endpoint_URI__c.replace(':appName', config.App_Name__c);
        
        //Construct the final endpoint URL with the extracted paymentId and passed redirect url
        String paymentDetailsEndpoint = endpoint + paymentId + '?redirectUrl=' + returnUrl;
        
        return paymentDetailsEndpoint;
            
    }

    /*
    *********************************************************
    @method Name    : getAccessToken
    @description    : Make a callout to retreive an accesstoken to add to the request
    @return         : String
    ********************************************************
    */
    private static String getAccessToken(){

        String accessToken;

        //Retreive the two metadata records that are needed for the configuration
        //Has information about endpoint and method
        DFDFW_Payment_Provider_Endpoint__mdt endpointInfo = DFDFW_Payment_Provider_Endpoint__mdt.getInstance('Obtain_a_token');
        //Has general information including base url, app name, etc. 
        DFDFW_Payment_Provider__mdt config = DFDFW_Payment_Provider__mdt.getInstance('St_Louis_Payments');
        
        //Construct the endpoint
        String endpoint = config.Base_URL__c + endpointInfo.Endpoint_URI__c.replace(':appName', config.App_Name__c);

        //Set the Request Body
        String requestBody = '{"clientId": "' + config.Client_Id__c + '", "clientSecret": "' + config.Client_Secret__c + '"}';

        //Create the HTTP Request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(endpointInfo.Method__c);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(requestBody);
        
        //Send the HTTP request
        Http http = new Http();
        HttpResponse res = http.send(req);

        //Check for success response 200 and retreive the accessToken
        if(res.getStatusCode() == 200){
            accessToken = (String) ((Map<String, Object>) JSON.deserializeUntyped(res.getBody())).get('token');
        }

        return accessToken;

    }

    /*
    *********************************************************
    @method Name    : updateTransactionId
    @description    : Creates the payment transaction record
    @param          : recordId
    @param         : transactionId
    ********************************************************
    */
    @AuraEnabled
    public static Boolean updateTransactionId(String recordId, String transactionId, Boolean serviceApp){
        try{
            Boolean success = false;
            List<DFD_Payment_Transaction__c> pts = [SELECT Id, Service_Application_Detail__c, Transaction_Id__c, Sub_Application__c 
                                                    FROM DFD_Payment_Transaction__c 
                                                    WHERE Transaction_Id__c = :transactionId 
                                                    AND (Service_Application_Detail__c = :recordId
                                                    OR Sub_Application__c = :recordId
                                                    )];

            if (pts.isEmpty()){
                DFD_Payment_Transaction__c pt = new DFD_Payment_Transaction__c();
                pt.Transaction_Id__c = transactionId;
                if(serviceApp){
                    pt.Service_Application_Detail__c = recordId;
                    Service_Application_Detail__c sad = [SELECT Id, Status__c FROM Service_Application_Detail__c WHERE Id = :recordId LIMIT 1];
                    if(sad.Status__c == 'Pending Payment'){
                        sad.Status__c = 'Submitted';
                        update sad;
                    }
                }
                else{
                    pt.Sub_Application__c = recordId;
                }
                insert pt;
                success = true;
                
            }
            return success;

        }
        catch(Exception e){
            //Log the Exception and rethrow it
            new DFDFW_LOG_AllException().Module('DFD Payment Callout Controller').Log(e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*
    *********************************************************
    @method Name    : newAuraException
    @description    : Used for properly sending Error Messages back to LWC
    @param          : message
    @return         : AuraHandledException
    ********************************************************
    */
    private static AuraHandledException newAuraException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }
     
}