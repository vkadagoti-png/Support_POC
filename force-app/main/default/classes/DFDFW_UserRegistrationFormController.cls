/*
*********************************************************
Apex Class Name    : DFDFW_UserRegistrationFormController
Created Date       : 8/1/2024
Author             : Cloud Synapps Inc.
Description        : Class containing methods related to register or login user from community.
Test Class Name    : DFDFW_UserRegistrationFormControllerTest
*********************************************************
*/
global without sharing class DFDFW_UserRegistrationFormController {
    /*
*********************************************************
@method Name    : saveAccessToken
@description    : used to save auth0 access token of current user.
@param          : accessToken - The Auth0 access token to be saved.
@param          : userId
@return         : void
********************************************************
*/
    @AuraEnabled
    global static void saveAccessToken(String accessToken, String userId) {
        try {
            DFDFW_AUTH0_ManageUserTokenCtrl.saveAccessToken(
                accessToken,
                userId
            );
        } catch (Exception e) {new DFDFW_LOG_AllException().Module('Registered User Form Controller').Log(e);throw new AuraHandledException(e.getMessage() + '===>' + e.getLineNumber());}
    }
    
/*
*********************************************************
@method Name    : logInUser
@description    : used to create session for existing user
@param          : emai]l
@param          : password
@param          : baseUrl
@return         : List<Map<String, String>>
********************************************************
*/
   /* @AuraEnabled
    global static string loginUser(
        String email,
        String password,
        String baseUrl
    ) {
        try {
            String url;
            if (password != null && password.length() > 1) {
                ApexPages.PageReference pageRef = Site.login(email, password, baseUrl);
                if (pageRef != null)
                    url = pageRef.getUrl();
            }
            return url;
        } catch (Exception e) {new DFDFW_LOG_AllException().Module('Registered User Form Controller').Log(e);throw new AuraHandledException(e.getMessage());}
    } */
    
/*
*********************************************************
@method Name    : checkExistingUser
@description    : used to check if a user with a specific Federation Identifier already exists in Salesforce.
@param          : fedId - The Federation Identifier to check against.
@return         : String - The Salesforce User ID if the user exists, otherwise null.
********************************************************
*/
    @AuraEnabled
    global static String checkExistingUser(String fedId) {
        try {
            String userId;
            List<User> userList = [
                SELECT ID, FederationIdentifier
                FROM User
                WHERE FederationIdentifier = :fedId
            ];
            if (!userList.isEmpty()) {
                userId = userList[0].Id;
            }
            return userId;
        } catch (Exception e) {new DFDFW_LOG_AllException().Module('Registered User Form Controller').Log(e);throw new AuraHandledException(e.getMessage());}
    }
    
    /*
*********************************************************
@method Name    : getuserInfoFromAuth0
@description    : used to get user information (like Federation ID and email) from Auth0's user info endpoint.
@param          : accessToken - The access token required for authentication with Auth0.
@return         : Map<String, String> - A map containing the user's 'fedrationId' and 'email'.
********************************************************
*/
    @AuraEnabled
    global static Map<String, String> getuserInfoFromAuth0(String accessToken) {
        Map<String, String> returnMap = new Map<String, String>();
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res;
        DFD_Redirect_URLs__c ge = DFD_Redirect_URLs__c.getInstance();
        
        String endpoint = ge.DFD_Auth0_Get_User_Info_URL__c;
        String token = 'Bearer ' + accessToken;
        
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', token);
        req.setHeader('Content-Type', 'application/json');
        try {
            res = http.send(req);
            if (res.getStatusCode() == 200) {
                AuthUserResponse authResponse = (AuthUserResponse) JSON.deserialize(
                    res.getBody(),
                    AuthUserResponse.class
                );
                returnMap.put('fedrationId', authResponse.sub);
                returnMap.put('email', authResponse.email);
            } else {
                // Handle HTTP error status code
                returnMap.put(
                    'Error',
                    'The Status id ==> ' + res.getStatusCode() + ' ' + res.getStatus()
                );
            }
            return returnMap;
        } catch (Exception e) {new DFDFW_LOG_AllException().Module('Registered User Form Controller').Log(e);throw new AuraHandledException(e.getMessage());}
    }
    
    /*
*********************************************************
@method Name    : getRedirectUrl
@description    : used to retrieve a redirect URL from a custom setting in Salesforce.
@param          : void
@return         : Map<String, String> - A map containing the 'home' redirect URL.
********************************************************
*/
    @AuraEnabled
    global static Map<String, String> getRedirectUrl() {
        try {
            Map<String, String> returnMap = new Map<String, String>();
            DFD_Redirect_URLs__c urls = DFD_Redirect_URLs__c.getInstance();
            returnMap.put('home', urls.Redirect_URL__c);
            return returnMap;
        } catch (Exception e) {new DFDFW_LOG_AllException().Module('Registered User Form Controller').Log(e);throw new AuraHandledException(e.getMessage());}
    }
    
/*
*********************************************************
@method Name    : getRedirectURL2
@description    : used to get a specific error message from a custom metadata record based on the component name.
@param          : component - The name of the component for which to retrieve the error message.
@return         : String - URL of Auth Provider.
********************************************************
*/
    @AuraEnabled
    public  static Map<String, String> getRedirectURL2() {
        Map<String, String> returnMap;
        try {
            returnMap = new Map<String, String>();
            // Get Auth0 Login URL from Custom Metadata
            Auth0_Config__mdt auth0Config = [
                SELECT DFD_Auth0_Login_URL__c
                FROM Auth0_Config__mdt
                WHERE DeveloperName = 'Auth0'
                LIMIT 1
            ];
            
            String auth0LoginUrl = auth0Config.DFD_Auth0_Login_URL__c;

            // Redirect the user to Auth0 without passing any data in the state parameter.
            // The RegistrationHandler will now look up the records by email.
             returnMap.put('home', auth0LoginUrl);
             return returnMap;
            
        } catch (Exception e) { new DFDFW_LOG_AllException().Module('Registered User Form Controller').Log(e); }
        return returnMap;
    }
    
/*
*********************************************************
@method Name    : getErrorMessageFromMetadata
@description    : used to get a specific error message from a custom metadata record based on the component name.
@param          : component - The name of the component for which to retrieve the error message.
@return         : String - The error message string from the custom metadata, or null if not found.
********************************************************
*/
    @AuraEnabled
    public static String getErrorMessageFromMetadata(String component) {
        String errorString;
        try {
            DFD_Error_Messages__mdt mdt = DFD_Error_Messages__mdt.getInstance(component);
            errorString = mdt.Error_Message__c;
        } catch (Exception e) { new DFDFW_LOG_AllException().Module('Registered User Form Controller').Log(e); }
        return errorString;
    }
/*    
*********************************************************
@method Name    : createPortalUser
@description    : used to create a new portal user. It first creates an Account and Contact, then redirects the user to the Auth0 login page to complete the registration.
@param          : inputParams - A JSON string containing the user's registration data.
@param          : baseUrl - The base URL of the community site.
@return         : Map<String, String> - A map containing the registration status and the redirect URL.
********************************************************
*/
    @AuraEnabled
    global static Map<String, String> createPortalUser(String inputParams, String baseUrl) {
        Map<String, String> resultMap = new Map<String, String>();
        try {
            InputData parms = (InputData) JSON.deserialize(inputParams, InputData.class);
            
            // Check if the user exists based on email and profile
            String profileName = System.label.DFDFW_Community_Profile_Name;
            Id profileId = [
                SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1
            ].Id;
            
            // Prevent duplicate user creation
            List<User> existingUsers = [
            SELECT Id, Username, Email, FederationIdentifier,IsActive
            FROM User
            WHERE Email = :parms.email 
            AND ProfileId = :profileId
            AND IsActive = TRUE
            LIMIT 1               
            ];

          /*if (!existingUsers.isEmpty()) {
            System.debug('User already exists. Returning existing user: ' + existingUsers[0].Id);
            resultMap.put('status', 'success');
            resultMap.put('userId', existingUsers[0].Id);
            return resultMap;
          }*/ 
            
           if (!existingUsers.isEmpty()) {
            if (existingUsers[0].IsActive == false) {
        		resultMap.put('status', 'error');
        		resultMap.put('message', 'Your user account is deactivated. Please contact your system administrator.');
        		return resultMap;
            } else {
                resultMap.put('status', 'success');
                resultMap.put('userId', existingUsers[0].Id);
                return resultMap;
              }
           }

            // Create Account & Contact
            Map<String, Id> accConMap = createAccountAndContact(inputParams);
            Id accountId = accConMap.get('accountId');
            Id contactId = accConMap.get('contactId');

            // Get Auth0 Login URL from Custom Metadata
            Auth0_Config__mdt auth0Config = [
                SELECT DFD_Auth0_Login_URL__c
                FROM Auth0_Config__mdt
                WHERE DeveloperName = 'Auth0'
                LIMIT 1
            ];
            
            String auth0LoginUrl = auth0Config.DFD_Auth0_Login_URL__c;

            // Redirect the user to Auth0 without passing any data in the state parameter.
            // The RegistrationHandler will now look up the records by email.
            String redirectUrl = auth0LoginUrl;

            resultMap.put('status', 'success');
            resultMap.put('redirectUrl', redirectUrl);

        } catch (Exception e) {
            new DFDFW_LOG_AllException().Module('Registered User Form Controller').Log(e);
            throw new AuraHandledException('User registration failed: ' + e.getMessage());
        }
        return resultMap;
    }
    
/*
*********************************************************
@method Name    : createAccountAndContact
@description    : used to create a new Account and Contact record based on the user's input. It handles both Person Accounts and Business Accounts.
@param          : dataObject - A JSON string containing the user's registration data.
@return         : Map<String, Id> - A map containing the IDs of the created 'accountId' and 'contactId'.
********************************************************
*/
    @AuraEnabled
    global static Map<String, Id> createAccountAndContact(String dataObject) {
        Map<String, Id> mapIds = new Map<String, Id>();
        try {
            InputData parms = (InputData) JSON.deserialize(dataObject, InputData.class);
            System.debug('Radio Value from form: ' + parms.radioValue);
            
            // Check if the user exists based on email and profile
            String profileName = System.label.DFDFW_Community_Profile_Name;
            Id profileId = [
                SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1
            ].Id;
            
            List<User> existingUsers = [ 
                SELECT Id, Email, AccountId, IsActive
                FROM User 
                WHERE Email = :parms.email 
                AND ProfileId = :profileId
                AND IsActive = TRUE
                LIMIT 1
            ]; 
            
            // If user does not exist, create the account and contact
            if (existingUsers.isEmpty() || existingUsers[0].AccountId == null) {
                Id recordTypeId;
                if (parms.radioValue == 'business') {
                    recordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Accounts').getRecordTypeId();
                } else {
                    recordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
                }
                
                Account acc = new Account();
                acc.RecordTypeId = recordTypeId;
                acc.DFD_Street_Address_Line_1__c = parms.streetLine1;
                acc.DFD_Street_Address_Line_2__c = parms.streetLine2;
                
                if (parms.radioValue == 'business') {
                    acc.Name = parms.company;
                    acc.BillingStreet = parms.street;
                    acc.BillingCity = parms.city;
                    acc.BillingPostalCode = parms.zipCode;
                    acc.BillingStateCode = parms.state;
                    acc.BillingCountryCode = 'US';
                } else { // It's a Person Account
                    acc.LastName = parms.lastName;
                    acc.FirstName = parms.firstName;
                    acc.PersonEmail = parms.email;
                    acc.PersonMobilePhone = parms.cellPhone;
                    acc.PersonMailingStreet = parms.street;
                    acc.PersonMailingCity = parms.city;
                    acc.PersonMailingPostalCode = parms.zipCode;
                    acc.PersonMailingStateCode = parms.state;
                    acc.PersonMailingCountryCode = 'US';
                    acc.access_token__pc = parms.accessToken;
                }
                insert acc;
                
                if (parms.radioValue == 'business') {
                    Contact con = new Contact();
                    con.AccountId = acc.Id;
                    con.FirstName = parms.firstName;
                    con.LastName = parms.lastName;
                    con.Email = parms.email;
                    con.MobilePhone = parms.cellPhone;
                    con.MailingStreet = parms.street;
                    con.MailingCity = parms.city;
                    con.MailingPostalCode = parms.zipCode;
                    con.MailingStateCode = parms.state;
                    con.MailingCountryCode = 'US';
                    con.access_token__c = parms.accessToken;
                    insert con;
                    mapIds.put('contactId', con.Id);
                }
                mapIds.put('accountId', acc.Id);
                return mapIds;
            } else {
                Contact existingContact = [SELECT Id,email FROM Contact WHERE AccountId = :existingUsers[0].AccountId and email =:existingUsers[0].email LIMIT 1];
                mapIds.put('accountId', existingUsers[0].AccountId);
                mapIds.put('contactId', existingContact.Id);
                return mapIds;
            }
        } catch (Exception e) {
            new DFDFW_LOG_AllException().Module('Registered User Form Controller').Log(e);
            return null;
        }
    } 
       
    global class AuthUserResponse {
        public String sub;
        public String email;
    }
    
    global class UserData {
        public String firstName;
        public String lastName;
        public String radiovalue;
        public String businessName;
    }
    
    global class InputData {
        public String firstName;
        public String lastName;
        public String email;
        public String company;
        public String radioValue;
        public string fedralId;
        public String password;
        public String cellPhone;
        public String street;
        public String city;
        public String state;
        public String zipCode;
        public String streetLine1;
        public String streetLine2;
        public String accessToken;
    }  
    
}