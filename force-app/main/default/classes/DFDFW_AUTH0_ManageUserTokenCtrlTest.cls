/*
*********************************************************
Apex Class Name    : DFD_CustomSettingControllerTest
Created Date       : 10/1/2024
Author             : Cloud Synapps Inc.
Description        : Class used as test class for DFDFW_AUTH0_ManageUserTokenCtrl.
*********************************************************
*/
@isTest
public class DFDFW_AUTH0_ManageUserTokenCtrlTest {

    @isTest
    static void testGetUserAccessToken() {
        // Insert a mock custom setting record with a valid SetupOwnerId (organization-wide default)
        DFD_User_Details__c userDetails = new DFD_User_Details__c(
            SetupOwnerId = UserInfo.getOrganizationId(),  // Use organization-wide default
            Name = 'TestUserId',
            Token_Part_1__c = 'Part1',
            Token_Part_2__c = 'Part2',
            Token_Part_3__c = 'Part3',
            Token_Part_4__c = 'Part4'
        );
        insert userDetails;

        // Call the method
        Test.startTest();
        String accessToken = DFDFW_AUTH0_ManageUserTokenCtrl.getUserAccessToken(userDetails.SetupOwnerId);
        Test.stopTest();

        // Assert that the access token is correctly assembled
        System.assertEquals('Part1Part2Part3Part4', accessToken, 'Access token should match the concatenated parts.');
    }

    @isTest
    static void testGetUserAccessToken_NullParts() {
        // Insert a mock custom setting record with some null parts
        DFD_User_Details__c userDetails = new DFD_User_Details__c(
            SetupOwnerId = UserInfo.getOrganizationId(),  // Use organization-wide default
            Name = 'TestUserId',
            Token_Part_1__c = 'Part1'
        );
        insert userDetails;

        // Call the method
        Test.startTest();
        String accessToken = DFDFW_AUTH0_ManageUserTokenCtrl.getUserAccessToken(userDetails.SetupOwnerId);
        Test.stopTest();

        // Assert that the access token is only the non-null part
        System.assertEquals('Part1', accessToken, 'Access token should only contain the non-null parts.');
    }

    @isTest
    static void testSaveAccessToken() {
        String accessToken = 'a'.repeat(800);  // Long token to test splitting

        // Call the method to save the access token
        Test.startTest();
        DFDFW_AUTH0_ManageUserTokenCtrl.saveAccessToken(accessToken, UserInfo.getUserId());
        Test.stopTest();

        // Retrieve the saved custom setting record
        DFD_User_Details__c savedUserDetails = DFD_User_Details__c.getInstance(UserInfo.getUserId());

        // Assert that the token parts were saved correctly
        System.assertEquals('a'.repeat(255), savedUserDetails.Token_Part_1__c, 'Token Part 1 should be saved correctly.');
        System.assertEquals('a'.repeat(255), savedUserDetails.Token_Part_2__c, 'Token Part 2 should be saved correctly.');
        System.assertEquals('a'.repeat(255), savedUserDetails.Token_Part_3__c, 'Token Part 3 should be saved correctly.');
        System.assertEquals('a'.repeat(35), savedUserDetails.Token_Part_4__c, 'Token Part 4 should be saved correctly.');
    }

    @isTest
    static void testSaveAccessToken_ShortToken() {
        // Mock a short access token
        String accessToken = 'a'.repeat(150); // Token shorter than 255 characters

        // Call the method to save the short access token
        Test.startTest();
        DFDFW_AUTH0_ManageUserTokenCtrl.saveAccessToken(accessToken, UserInfo.getUserId());
        Test.stopTest();

        // Retrieve the saved custom setting record
        DFD_User_Details__c savedUserDetails = DFD_User_Details__c.getInstance(UserInfo.getUserId());

        // Assert that the short token is saved entirely in Token_Part_1__c
        System.assertEquals('a'.repeat(150), savedUserDetails.Token_Part_1__c, 'Token Part 1 should contain the full short token.');
        System.assertEquals(null, savedUserDetails.Token_Part_2__c, 'Token Part 2 should be null for a short token.');
        System.assertEquals(null, savedUserDetails.Token_Part_3__c, 'Token Part 3 should be null for a short token.');
        System.assertEquals(null, savedUserDetails.Token_Part_4__c, 'Token Part 4 should be null for a short token.');
    }
    
    @isTest
    static void testSaveAccessToken_MediumSToken() {
        // Mock a short access token
        String accessToken = 'a'.repeat(300); // Token shorter than 255 characters

        // Call the method to save the short access token
        Test.startTest();
        DFDFW_AUTH0_ManageUserTokenCtrl.saveAccessToken(accessToken, UserInfo.getUserId());
        Test.stopTest();

        // Retrieve the saved custom setting record
        DFD_User_Details__c savedUserDetails = DFD_User_Details__c.getInstance(UserInfo.getUserId());

        // Assert that the short token is saved entirely in Token_Part_1__c
        System.assertEquals('a'.repeat(255), savedUserDetails.Token_Part_1__c, 'Token Part 1 should be saved correctly.');
        System.assertEquals('a'.repeat(45), savedUserDetails.Token_Part_2__c, 'Token Part 2 should be saved correctly.');
        System.assertEquals(null, savedUserDetails.Token_Part_3__c, 'Token Part 3 should be null for a short token.');
        System.assertEquals(null, savedUserDetails.Token_Part_4__c, 'Token Part 4 should be null for a short token.');
    }
@isTest
    static void testSaveAccessToken_MediumLToken() {
        // Mock a short access token
        String accessToken = 'a'.repeat(600); // Token shorter than 255 characters

        // Call the method to save the short access token
        Test.startTest();
        DFDFW_AUTH0_ManageUserTokenCtrl.saveAccessToken(accessToken, UserInfo.getUserId());
        Test.stopTest();

        // Retrieve the saved custom setting record
        DFD_User_Details__c savedUserDetails = DFD_User_Details__c.getInstance(UserInfo.getUserId());

        // Assert that the short token is saved entirely in Token_Part_1__c
        System.assertEquals('a'.repeat(255), savedUserDetails.Token_Part_1__c, 'Token Part 1 should be saved correctly.');
        System.assertEquals('a'.repeat(255), savedUserDetails.Token_Part_2__c, 'Token Part 2 should be saved correctly.');
        System.assertEquals('a'.repeat(90), savedUserDetails.Token_Part_3__c, 'Token Part 3 should be saved correctly.');
        System.assertEquals(null, savedUserDetails.Token_Part_4__c, 'Token Part 4 should be null for a short token.');
    }
    
}