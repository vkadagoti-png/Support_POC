/*
*********************************************************
Test Class Name    : Auth0CustomAuthProviderTest
Created Date       : 09/11/2025
Author             : Omniskope Inc.
Description        : This test class provides comprehensive test coverage for the Auth0CustomAuthProvider Apex class.
                     It uses HTTP mocking to simulate callouts to the Auth0 authentication provider and validates
                     the behavior of the authentication flow at each stage (initiate, handleCallback, and getUserInfo).
*********************************************************
*/
@isTest
private class Auth0CustomAuthProviderTest {

    // Test data and constants
    private static final String FAKE_CLIENT_ID = 'fakeClientId123';
    private static final String FAKE_CLIENT_SECRET = 'fakeClientSecret123';
    private static final String FAKE_AUTH_URL = 'https://fake-auth0-domain/authorize';
    private static final String FAKE_TOKEN_URL = 'https://fake-auth0-domain/oauth/token';
    private static final String FAKE_USERINFO_URL = 'https://fake-auth0-domain/userinfo';
    private static final String FAKE_REDIRECT_URL = 'https://Omni.my.salesforce.com/services/auth/test/callback';
    private static final String FAKE_SFDC_STATE = 'sfdcState123';
    private static final String FAKE_POST_LOGIN_URL = 'https://stl--qa.sandbox.my.site.com/permits/s/';

    /*
    *********************************************************
    @method Name    : getAuthProviderConfig
    @description    : Helper method to create a mock configuration map, simulating the custom
                      metadata type fields used by the authentication provider.
    @return         : Map<String, String> A map containing mock configuration values.
    ********************************************************
    */
    private static Map<String, String> getAuthProviderConfig() {
        Map<String, String> config = new Map<String, String>();
        config.put('App_ID__c', FAKE_CLIENT_ID);
        config.put('App_Secret__c', FAKE_CLIENT_SECRET);
        config.put('Authorization_Endpoint_URL__c', FAKE_AUTH_URL);
        config.put('Token_Endpoint_URL__c', FAKE_TOKEN_URL);
        config.put('Redirect_Url__c', FAKE_REDIRECT_URL);
        config.put('API_User_Url__c', FAKE_USERINFO_URL);
        return config;
    }

    /*
    *********************************************************
    @method Name    : testGetCustomMetadataType
    @description    : Tests the getCustomMetadataType method to ensure it returns the correct
                      API name for the custom metadata type.
    ********************************************************
    */
    @isTest
    static void testGetCustomMetadataType() {
        Auth0CustomAuthProvider provider = new Auth0CustomAuthProvider();
        String metadataType = provider.getCustomMetadataType();
        System.assertEquals('Auth0_Config__mdt', metadataType, 'The custom metadata type API name should be Auth0_Config__mdt.');
    }

    /*
    *********************************************************
    @method Name    : testInitiateWithoutPostLoginUrl
    @description    : Tests the initiate method's functionality, ensuring it constructs the
                      correct authorization URL with all required parameters.
    ********************************************************
    */
    @isTest
    static void testInitiateWithoutPostLoginUrl() {
        Auth0CustomAuthProvider provider = new Auth0CustomAuthProvider();
        Test.startTest();
        PageReference pr = provider.initiate(getAuthProviderConfig(), FAKE_SFDC_STATE);
        Test.stopTest();

        // Assert that the PageReference object is not null.
        System.assertNotEquals(null, pr, 'PageReference object should not be null.');

        // Use a more robust check by asserting for the presence of each parameter and its value.
        String actualUrl = pr.getUrl();

        // Assert the base URL is correct.
        System.assert(actualUrl.startsWith(FAKE_AUTH_URL), 'URL should start with the authorization endpoint URL.');

        // Assert that each parameter is present with the correct value.
        System.assert(actualUrl.contains('response_type=code'), 'URL should contain response_type parameter.');
        System.assert(actualUrl.contains('client_id=' + EncodingUtil.urlEncode(FAKE_CLIENT_ID, 'UTF-8')), 'URL should contain client_id parameter.');
        System.assert(actualUrl.contains('scope=' + EncodingUtil.urlEncode('openid profile email', 'UTF-8')), 'URL should contain scope parameter.');
        System.assert(actualUrl.contains('redirect_uri=' + EncodingUtil.urlEncode(FAKE_REDIRECT_URL, 'UTF-8')), 'URL should contain redirect_uri parameter.');
        System.assert(actualUrl.contains('state=' + EncodingUtil.urlEncode(FAKE_SFDC_STATE, 'UTF-8')), 'URL should contain state parameter.');
    }

    /*
    *********************************************************
    @method Name    : testInitiateWithPostLoginUrl
    @description    : Tests the initiate method with an embedded post-login URL in the state
                      parameter, as found in the commented-out code block.
    ********************************************************
    */
    @isTest
    static void testInitiateWithPostLoginUrl() {
        Auth0CustomAuthProvider provider = new Auth0CustomAuthProvider();
        String combinedState = FAKE_SFDC_STATE + '||' + EncodingUtil.urlEncode(FAKE_POST_LOGIN_URL, 'UTF-8');
        
        Test.startTest();
        PageReference pr = provider.initiate(getAuthProviderConfig(), combinedState);
        Test.stopTest();
        
        System.assertNotEquals(null, pr, 'PageReference object should not be null.');
        String actualUrl = pr.getUrl();
        
        System.assert(actualUrl.startsWith(FAKE_AUTH_URL), 'URL should start with the authorization endpoint URL.');
        System.assert(actualUrl.contains('response_type=code'), 'URL should contain response_type parameter.');
        System.assert(actualUrl.contains('client_id=' + EncodingUtil.urlEncode(FAKE_CLIENT_ID, 'UTF-8')), 'URL should contain client_id parameter.');
        System.assert(actualUrl.contains('scope=' + EncodingUtil.urlEncode('openid profile email', 'UTF-8')), 'URL should contain scope parameter.');
        System.assert(actualUrl.contains('redirect_uri=' + EncodingUtil.urlEncode(FAKE_REDIRECT_URL, 'UTF-8')), 'URL should contain redirect_uri parameter.');
        System.assert(actualUrl.contains('state=' + EncodingUtil.urlEncode(combinedState, 'UTF-8')), 'URL should contain the combined state parameter.');
    }

    /*
    *********************************************************
    @method Name    : testHandleCallback
    @description    : Tests the handleCallback method. It mocks the HTTP callout for the
                      token exchange and asserts that the access token and state are correctly
                      parsed from the response.
    ********************************************************
    */
    @isTest
    static void testHandleCallback() {
        Auth0CustomAuthProvider provider = new Auth0CustomAuthProvider();
        // Mock the HTTP response for the token exchange
        HttpMockFactory tokenMock = new HttpMockFactory(200, 'OK', '{"access_token": "fakeAccessToken", "id_token": "fakeIdToken"}');
        Test.setMock(HttpCalloutMock.class, tokenMock);

        // Workaround to create an instance of Auth.AuthProviderCallbackState
        Auth.AuthProviderCallbackState state = (Auth.AuthProviderCallbackState) JSON.deserialize(
            '{"queryParameters": {"code": "fakeAuthCode", "state": "' + FAKE_SFDC_STATE + '"}}',
            Auth.AuthProviderCallbackState.class
        );

        Test.startTest();
        Auth.AuthProviderTokenResponse response = provider.handleCallback(getAuthProviderConfig(), state);
        Test.stopTest();

        System.assertNotEquals(null, response, 'Response object should not be null.');
        System.assertEquals('fakeAccessToken', response.oauthToken, 'The access token should be extracted correctly.');
        System.assertEquals(FAKE_SFDC_STATE, response.state, 'The state parameter should be passed through correctly.');
    }

    /*
    *********************************************************
    @method Name    : testGetUserInfo
    @description    : Tests the getUserInfo method. It mocks the HTTP callout to the user info
                      endpoint and verifies that the returned user data is correct.
    ********************************************************
    */
    @isTest
    static void testGetUserInfo() {
        Auth0CustomAuthProvider provider = new Auth0CustomAuthProvider();
        // Mock the HTTP response for the user info call
        String userinfoJson = '{"sub": "auth0|user123", "email": "test@example.com", "given_name": "Test", "family_name": "User", "locale": "en"}';
        HttpMockFactory userinfoMock = new HttpMockFactory(200, 'OK', userinfoJson);
        Test.setMock(HttpCalloutMock.class, userinfoMock);

        Auth.AuthProviderTokenResponse tokenResponse = new Auth.AuthProviderTokenResponse('Auth0', 'fakeAccessToken', null, FAKE_SFDC_STATE);

        Test.startTest();
        Auth.UserData userData = provider.getUserInfo(getAuthProviderConfig(), tokenResponse);
        Test.stopTest();

        System.assertNotEquals(null, userData, 'User data object should not be null.');
        //System.assertEquals('auth0|user123', userData.id, 'User ID should match the mocked JSON.');
        System.assertEquals('Test User', userData.fullName, 'Full name should be correctly concatenated.');
        System.assertEquals('test@example.com', userData.email, 'Email should match the mocked JSON.');
        //System.assertEquals(FAKE_SFDC_STATE, userData.attributeMap.get('https://stl--qa.sandbox.my.site.com/state'), 'The original state should be in the attribute map.');
    }

    /*
    *********************************************************
    @class Name     : HttpMockFactory
    @description    : Private helper class that implements the HttpCalloutMock interface to
                      simulate HTTP responses during testing.
    ********************************************************
    */
    private class HttpMockFactory implements HttpCalloutMock {
        private Integer statusCode;
        private String status;
        private String body;

        public HttpMockFactory(Integer statusCode, String status, String body) {
            this.statusCode = statusCode;
            this.status = status;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            response.setStatus(status);
            response.setBody(body);
            return response;
        }
    }
}