@isTest
private class AssignAccessQueueableTest {

    /*
    *********************************************************
    * @description : Utility method to create a test user
    *********************************************************
    */
    private static User createTestUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        Profile guestProfile = [SELECT Id FROM Profile WHERE Name='DFDFW Portal User Profile' LIMIT 1];
        User u = new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = guestProfile.Id,
            UserName = 'testuser' + System.currentTimeMillis() + '@example.com'
        );
        insert u;
        return u;
    }
    
    /*
    *********************************************************
    * @description : Utility method to create a test user
    *********************************************************
    */
   	private static User createTestUser(Contact c) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        Profile guestProfile = [SELECT Id FROM Profile WHERE Name='DFDFW Portal User Profile' LIMIT 1];
        User u = new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = guestProfile.Id,
            ContactId = c.Id,
            UserName = 'testuser' + System.currentTimeMillis() + '@example.com'
        );
        insert u;
        return u;
    }
    
    // Create Contact owned by guest user
    private static Contact makeContact(String email) {
        Contact c;
        User u = [SELECT Id from User where username like 'hamiltonw@stlouis-mo.gov%'];
        System.runAs(u) {
            Account acc = new Account(Name='TestAccount');
            insert acc;

            c = new Contact(
                FirstName='First',
                LastName='Last',
                Email=email,
                access_token__c='accesstoken',
                AccountId=acc.Id
            );
            insert c;            
        }
        
        return c;
    }

    /*
    *********************************************************
    * @description : Setup only real records we can create (Group).
    *                PermissionSets and PSLs are metadata → cannot be inserted in tests.
    *********************************************************
    */
    private static void setupMetadata() {
        if ([SELECT COUNT() FROM Group WHERE Name = 'DFDFW_Portal_Users' AND Type = 'Regular'] == 0) {
            insert new Group(Name = 'DFDFW_Portal_Users', Type = 'Regular');
        }
    }

    /*
    *********************************************************
    * @description : Main test method to cover success path
    *********************************************************
    */   
    @isTest
    static void testAssignAccessQueueable_Success() {
        setupMetadata();
        Contact c = makeContact('testuser@example.com');
        User u = createTestUser(c);
        
        u.ContactId = c.Id;
        update u;
        User u1 = [select id from User where Profile.Name='System Administrator' and isActive=true Limit 1];

        Test.startTest();
        System.runAs(u1) {
            System.enqueueJob(new AssignAccessQueueable(u.Id));
        }
		      
        Test.stopTest();
        List<PermissionSetAssignment> psAssigns  = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId=:u.id];
        List<PermissionSetLicenseAssign> pslAssigns  = [SELECT Id FROM PermissionSetLicenseAssign WHERE AssigneeId=:u.id];
        List<GroupMember> gmLst = [SELECT Id FROM GroupMember WHERE UserOrGroupId=:u.id];
		System.assert(psAssigns.size()>=2,'PermissionSetAssignment assigned successfully');
        System.assert(pslAssigns.size()>=2,'PermissionSetLicenseAssign assigned successfully');
        System.assert(psAssigns.size()>=1,'GroupMember assigned successfully');
    }
    
    /*
    *********************************************************
    * @description : Main test method to cover success path
    *********************************************************
    */   
    @isTest
    static void testAssignAccessQueueable_Failure() {
        setupMetadata();
       
        User u1 = [select id from User where Profile.Name='System Administrator' and isActive=true Limit 1];

        Test.startTest();
        System.runAs(u1) {
            System.enqueueJob(new AssignAccessQueueable(null));
        }
		      
        Test.stopTest();
        
    }
}