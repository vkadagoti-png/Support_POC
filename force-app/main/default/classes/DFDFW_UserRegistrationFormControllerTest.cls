/*
*********************************************************
Apex Class Name    : DFDFW_UserRegistrationFormControllerTest
Created Date       : 9/4/2024
updated Date       : 9/12/2025, updated by Omniskope INC
Author             : Cloud Synapps Inc.
Description        : Class used as test class for DFDFW_UserRegistrationFormController.
*********************************************************
*/
@isTest
private class DFDFW_UserRegistrationFormControllerTest {

    // Mock class for the external callout
    private class Auth0HttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            if (req.getEndpoint().contains('userinfo')) {
                res.setBody('{"sub": "auth0|testfedid123", "email": "testuser@example.com", "given_name": "Test", "family_name": "User"}');
            } else if (req.getEndpoint().contains('oauth/token')) {
                res.setBody('{"access_token": "mock_access_token", "token_type": "Bearer", "expires_in": 3600}');
            }
            return res;
        }
    }

    private class MockManageUserTokenCtrl {
        public void saveAccessToken(String accessToken, String userId) {
        }
    }

    @testSetup
    static void setupTestData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            ProfileId = p.Id,
            LastName = 'Test',
            FirstName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser@example.com' + System.currentTimeMillis(),
            Alias = 'testuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            FederationIdentifier = 'testfedid123',
            IsActive = true
        );
        insert testUser;

        DFD_Redirect_URLs__c urls = new DFD_Redirect_URLs__c();
        urls.Name = 'Default';
        urls.Redirect_URL__c = 'https://test.salesforce.com/s/';
        urls.DFD_Auth0_Get_User_Info_URL__c = 'https://test.auth0.com/userinfo';
        insert urls;
    }

    // Test for the saveAccessToken method
    @isTest
    static void testSaveAccessToken() {
        User testUser = [SELECT Id FROM User WHERE FederationIdentifier = 'testfedid123' LIMIT 1];
        Test.startTest();
        try {
            DFDFW_UserRegistrationFormController.saveAccessToken('testToken', testUser.Id);
            System.assert(true, 'Method should complete without exceptions.');
        } catch (Exception e) {
            System.assert(false, 'Unexpected exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    // Test for the checkExistingUser method when user exists
    @isTest
    static void testCheckExistingUser_Exists() {
        User testUser = [SELECT Id FROM User WHERE FederationIdentifier = 'testfedid123' LIMIT 1];
        Test.startTest();
        String userId = DFDFW_UserRegistrationFormController.checkExistingUser('testfedid123');
        System.assertEquals(testUser.Id, userId, 'Should return the existing user ID.');
        Test.stopTest();
    }
    
    // Test for the checkExistingUser method when user does not exist
    @isTest
    static void testCheckExistingUser_NotExists() {
        Test.startTest();
        String userId = DFDFW_UserRegistrationFormController.checkExistingUser('nonexistentfedid');
        System.assert(userId == null, 'Should return null for a non-existent user.');
        Test.stopTest();
    }

    // Test for the createPortalUser and createAccountAndContact methods
    @isTest
    static void testCreatePortalUser_NewUser_Business() {
        DFDFW_UserRegistrationFormController.InputData parms = new DFDFW_UserRegistrationFormController.InputData();
        parms.firstName = 'New';
        parms.lastName = 'BusinessUser';
        parms.email = 'newbusinessuser@example.com';
        parms.company = 'New Company Inc.';
        parms.radioValue = 'business';
        parms.fedralId = 'newfedid123';
        parms.cellPhone = '1234567890';
        parms.street = '123 Main St';
        parms.city = 'Anytown';
        parms.state = 'CA';
        parms.zipCode = '12345';
        String inputParams = JSON.serialize(parms);

        Test.startTest();
        Map<String, String> result = DFDFW_UserRegistrationFormController.createPortalUser(inputParams, 'https://test.salesforce.com');
        Test.stopTest();

        Account createdAccount = [SELECT Id, Name FROM Account WHERE Name = 'New Company Inc.' LIMIT 1];
        Contact createdContact = [SELECT Id, FirstName FROM Contact WHERE FirstName = 'New' LIMIT 1];
        System.assertNotEquals(null, createdAccount, 'A new business account should be created.');
        System.assertNotEquals(null, createdContact, 'A new contact should be created.');
        System.assertEquals('success', result.get('status'), 'Status should be success.');
    }

    @isTest
    static void testCreatePortalUser_NewUser_Individual() {
        DFDFW_UserRegistrationFormController.InputData parms = new DFDFW_UserRegistrationFormController.InputData();
        parms.firstName = 'New';
        parms.lastName = 'IndividualUser';
        parms.email = 'newindividualuser@example.com';
        parms.radioValue = 'individual';
        parms.fedralId = 'newfedid456';
        parms.cellPhone = '0987654321';
        parms.street = '456 Elm St';
        parms.city = 'Sometown';
        parms.state = 'NY';
        parms.zipCode = '54321';
        String inputParams = JSON.serialize(parms);

        Test.startTest();
        Map<String, String> result = DFDFW_UserRegistrationFormController.createPortalUser(inputParams, 'https://test.salesforce.com');
        Test.stopTest();
        
        Account createdAccount = [SELECT Id, LastName FROM Account WHERE LastName = 'IndividualUser' LIMIT 1];
        System.assertNotEquals(null, createdAccount, 'A new person account should be created.');
        System.assertEquals('success', result.get('status'), 'Status should be success.');
    }
    
    @isTest
    static void testGetUserInfoFromAuth0() {
        Test.setMock(HttpCalloutMock.class, new Auth0HttpMock());
        Test.startTest();
        Map<String, String> userInfo = DFDFW_UserRegistrationFormController.getuserInfoFromAuth0('mock_access_token');
        Test.stopTest();
        System.assertNotEquals(null, userInfo, 'User info should not be null.');
        System.assertEquals('auth0|testfedid123', userInfo.get('fedrationId'), 'Federation ID should match the mock response.');
        System.assertEquals('testuser@example.com', userInfo.get('email'), 'Email should match the mock response.');
    }

    @isTest
    static void testGetRedirectUrl() {
        Test.startTest();
        Map<String, String> urls = DFDFW_UserRegistrationFormController.getRedirectUrl();
        Test.stopTest();
        System.assertNotEquals(null, urls, 'URL map should not be null.');
        System.assertEquals('https://test.salesforce.com/s/', urls.get('home'), 'Home URL should match the custom setting.');
    }
    
    @isTest
    static void testGetErrorMessageFromMetadata() {
        Test.startTest();
        String component = 'registerUserFormCreateUser';
        String errorMessage = DFDFW_UserRegistrationFormController.getErrorMessageFromMetadata(component);
        Test.stopTest();
        System.assertEquals('Error in creating user. Please try again later.', errorMessage, 'The returned error message should match the expected value');
    }
}