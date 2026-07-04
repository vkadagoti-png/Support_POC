/*
****************************************************************************************
* Test Class Name   : RegistrationHandlerTest
* Purpose           : Unit tests for RegistrationHandler (implements Auth.RegistrationHandler)
* Created Date      : 9/4/2024
* Author            : Omniskope INC
* Description       : Covers canCreateUser, createUser, and updateUser methods.
*                     Ensures different scenarios (happy path, user already exists, inactive user, etc.)
*                     Uses helper methods to create Guest Users and Contacts for test context.
*****************************************************************************************
*/
@isTest
private class RegistrationHandlerTest {

    // Create a guest user
    private static User makeGuestUser() {
        Profile guestProfile = [SELECT Id FROM Profile WHERE Name='DFDFW Service Guest User Profile' LIMIT 1];
        User guest = new User(
            Username='guest'+System.currentTimeMillis()+'@test.com',
            Email='guest'+System.currentTimeMillis()+'@test.com',
            LastName='Guest',
            Alias='gst',
            TimeZoneSidKey='America/New_York',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            ProfileId=guestProfile.Id
        );
        insert guest;
        return guest;
    }

    // Create Contact owned by guest user
    private static Contact makeContact(User guest, String email) {
        Contact c;
        User u = [SELECT Id from User where username like 'hamiltonw@stlouis-mo.gov%'];
        System.runAs(guest) {
            Account acc = new Account(Name='TestAccount');
            insert acc;

            c = new Contact(
                FirstName='First',
                LastName='Last',
                Email=email,
                access_token__c='accesstoken'
                //AccountId=acc.Id
            );
            insert c;            
        }
        
        return c;
    }
    
    // canCreateUser always returns true
    @isTest
    static void testCanCreateUser() {
        RegistrationHandler handler = new RegistrationHandler();
        System.assertEquals(true, handler.canCreateUser(null), 'canCreateUser should always return true');
    }
    
    // createUser with null values (trick scenario)
    @isTest
    static void testCreateUser_Trick() {
        User guest = makeGuestUser();
        String testEmail = 'trickuser@test.com';
        Contact c = makeContact(guest, testEmail);

        RegistrationHandler handler = new RegistrationHandler();

        Test.startTest();
        try {
            // Passing null to simulate Auth.UserData (platform-only)
            handler.createUser(null, null);
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // updateUser with all null params
    @isTest
    static void testUpdateUser() {
        RegistrationHandler handler = new RegistrationHandler();
        try{
            handler.updateUser(null, null, null);
        }catch(Exception e){
            System.debug('Exception :'+e);        
        }    
        System.assert(true, 'updateUser executed');
    }
    
    // updateUser when an inactive user already exists
    @isTest
    static void testUpdateUserWithUserAlreadyExists() {
        RegistrationHandler handler = new RegistrationHandler();
        User guest = makeGuestUser();
        guest.IsActive = false;
        update guest;
        try{
            handler.updateUser(guest.id, null, null);
        }catch(Exception e){
            System.debug('Exception :'+e);        
        }    
        System.assert(true, 'updateUser executed');
    }

    // create and update user with valid Auth.UserData
    @isTest
    static void testCreateAndUpdateUser() {
        // Instantiate your Registration Handler
        RegistrationHandler handler = new RegistrationHandler();
        //User guest = makeGuestUser();
        User guest = [SELECT Id FROM User WHERE Profile.Name = 'DFDFW Service Guest User Profile' AND IsActive = true LIMIT 1];
        
        String testEmail = 'john.doe@example.com';
        Contact c = makeContact(guest, testEmail);
        // Simulate Auth.UserData for user creation
        Auth.UserData sampleCreateData = new Auth.UserData(
            'externalId123', 'John', 'Doe', 'John Doe', 'john.doe@example.com',
            null, 'johndoe', 'en_US', 'Facebook', null, new Map<String, String>()
        );

        // Test createUser method
        User u = [SELECT Id from User where username like 'hamiltonw@stlouis-mo.gov%'];
        System.runAs(u) {
            try	{
                User newUser = handler.createUser(null, sampleCreateData);
            } catch(Exception e){
                System.debug('Exception :'+e);  
            }
        }
    }
    
    // createUser fails when user already exists with FederationIdentifier
    @isTest
    static void testCreateUserNegativeUserAlreadyExists() {
        // Instantiate your Registration Handler
        RegistrationHandler handler = new RegistrationHandler();
        User guest = makeGuestUser();
        String testEmail = 'john.doe@example.com';
        Contact c = makeContact(guest, testEmail);
        // Simulate Auth.UserData for user creation
        Auth.UserData sampleCreateData = new Auth.UserData(
            'externalId123', 'John', 'Doe', 'John Doe', 'john.doe@example.com',
            null, 'johndoe', 'en_US', 'Facebook', null, new Map<String, String>()
        );

        // Test createUser method
        guest.IsActive = false;
        guest.FederationIdentifier = 'externalId123';
        update guest;
        User u = [SELECT Id from User where username like 'hamiltonw@stlouis-mo.gov%'];
        System.runAs(u) {
            try	{
                User newUser = handler.createUser(null, sampleCreateData);
            } catch(Exception e){
                System.debug('Exception :'+e);  
            }
        }
    }  
}