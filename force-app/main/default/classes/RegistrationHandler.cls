/*
*********************************************************
Apex Class Name    : RegistrationHandler
Created Date       : 8/19/2024
Author             : Omniskope Inc.
description        : This class implements the Auth.RegistrationHandler interface to manage the user registration and login process
                     for a Salesforce community using an external authentication provider like Auth0.
					 It is responsible for creating a new user record upon the first login and can be extended to handle subsequent logins.
     				 This handler is designed to link a new user to an existing Contact record based on the user's email.
*********************************************************
*/
global without sharing class RegistrationHandler implements Auth.RegistrationHandler {
    global boolean canCreateUser(Auth.UserData data) {
        return true;
    }

/*
*********************************************************
@method Name    : createUser
@description    : This method is called to create a new user record in Salesforce. It first attempts to find an existing
                  user with the same Federation Identifier. If one exists, it returns the existing user. Otherwise, it queries
                  for a related Contact record by email and creates a new user, linking it to the Contact.
@param          : portalId The ID of the community the user is logging into.
@param          : data The Auth.UserData object containing user details from the authentication provider.
@return         : User The newly created or existing user record.
********************************************************
*/
    global User createUser(Id portalId, Auth.UserData data) {
        try {
            // Get the unique identifier from Auth0.
            String fedId = data.identifier;
            
            // Look up the guest user's ID to filter our query.
            Id guestUserId = [SELECT Id FROM User WHERE Profile.Name = 'DFDFW Service Guest User Profile' AND IsActive = true LIMIT 1].Id;

            // Look up the most recently created Contact by the guest user and the email provided by Auth0.
            Contact mostRecentContact = [
                SELECT Id, AccountId, CreatedDate, FirstName, LastName,
                    access_token__c,Account.RecordType.Name 
                FROM Contact 
                WHERE Email = :data.email 
                AND CreatedById = :guestUserId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            
            Id contactId = null;
            String userFirstName = null;
            String userLastName = null;
            String accessToken = null;
            
            if (mostRecentContact != null) {
                contactId = mostRecentContact.Id;
                userFirstName = mostRecentContact.FirstName;
                userLastName = mostRecentContact.LastName;
                accessToken = mostRecentContact.access_token__c;
                if(mostRecentContact.Account.RecordType.Name=='Person Account'){
                    Account acct = new Account(id=mostRecentContact.AccountId);
                    acct.access_token__pc=null;
                    update acct;
                } else {
                    mostRecentContact.access_token__c=null;
                    update mostRecentContact;
                }
                
            } else {
                throw new DmlException('No recent Contact found for user registration.');
            }

            // Prevent duplicate user creation.
            List<User> existingUsers = [
                SELECT Id,
                Email,
                FederationIdentifier,
                IsActive
                FROM User 
                WHERE FederationIdentifier = :fedId 
                LIMIT 1
            ];
            /*if (!existingUsers.isEmpty()) {
                return existingUsers[0];
            }*/
            if (!existingUsers.isEmpty()) {
                if (existingUsers[0].IsActive == false) {
                    throw new Auth.AuthProviderPluginException('Your user account is deactivated. Please contact your system administrator.');
                }
                return existingUsers[0];
            }
            
            // Get the Community Profile.
            Id profileId = [
                SELECT Id 
                FROM Profile 
                WHERE Name = :System.Label.DFDFW_Community_Profile_Name 
                LIMIT 1
            ].Id;
            
            // Create the new User record using data from the Contact record.
            User newUser = new User(
                Username = data.email,
                Email = data.email,
                // Use the variables from the Contact record.
                FirstName = userFirstName,
                LastName = userLastName,
                CommunityNickname = (String.isNotBlank(userLastName) ? userLastName.substring(0, 1) : 'G') + (String.isNotBlank(userFirstName) ? userFirstName.substring(0, 1) : 'G') + System.now().getTime(),
                Alias = (String.isNotBlank(userFirstName) && userFirstName.length()>=2 ? userFirstName.substring(0,2) : 'XX'),
                ProfileId = profileId,
                FederationIdentifier = fedId,
                ContactId = contactId,
                TimeZoneSidKey = 'America/Chicago',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
            );
            
            insert newUser;           
            DFDFW_UserRegistrationFormController.saveAccessToken(accessToken, newUser.Id);
            // Assign permission sets / groups
            System.enqueueJob(new AssignAccessQueueable(newUser.Id));            
            return newUser;
            
        }catch (Exception ex) {
            System.debug('❌ RegistrationHandler.createUser FAILED: ' + ex.getMessage());
            throw new DmlException('User creation failed: ' + ex.getMessage());
        }
    }

/*
*********************************************************
@method Name    : updateUser
@description    : This method is called when an existing user logs in. In this implementation, it is left empty
                  as there are no updates to be made.
@param 			: userId The ID of the existing user record.
@param 			: portalId The ID of the community.
@param			: data The Auth.UserData object from the authentication provider.
********************************************************
*/
    global void updateUser(Id userId, Id portalId, Auth.UserData data) {
         User existingUser = [SELECT Id, IsActive FROM User WHERE Id = :userId LIMIT 1];
        if (existingUser != null && existingUser.IsActive == false) {
            throw new Auth.AuthProviderPluginException('Your user account is deactivated. Please contact your system administrator.');
        }
    }
}