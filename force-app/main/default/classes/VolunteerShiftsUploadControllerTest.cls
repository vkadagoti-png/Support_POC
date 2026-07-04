@isTest
public class VolunteerShiftsUploadControllerTest {
    
    @isTest
    static void testVolunteer() {
        // Create Account, Contact, User, Campaign, and CampaignMember
        Account acc = new Account(Name = 'Tester Account');
        insert acc;

        Contact con = new Contact(LastName = 'Tester Contact', AccountId = acc.Id);
        insert con;

        User u = new User(
            Username = 'testuser+' + String.valueOf(Math.random()).replace('.', '') + '@test.com.test',            LastName='atest',
            Alias = 'tuser',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            IsActive=true
           // ContactId = con.Id
        );
        insert u;
        system.debug('u'+u);

        Campaign parentCamp = new Campaign(Name = 'Parent Campaign');
        insert parentCamp;

        Campaign childCamp = new Campaign(Name = 'Child Campaign', ParentId = parentCamp.Id);
        insert childCamp;

        CampaignMember cm = new CampaignMember(CampaignId = childCamp.Id, ContactId = con.Id, AccountId = acc.Id);
        insert cm;
         String csvContent = 'Name,Date In,Time In,Date Out,Time Out,Activity,Category,Org\n' +
                            'Test1,10/10/2025,10:00,11/10/2025,5:00,Activity1,Cat1,Org1\n';
        Blob csvBlob = Blob.valueOf(csvContent);

        ContentVersion cv = new ContentVersion(
            Title = 'TestCSV',
            PathOnClient = 'TestCSV.csv',
            VersionData = csvBlob
        );
        insert cv;

        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        Test.startTest();
        VolunteerShiftsUploadController.ShiftUploadResult result =
            VolunteerShiftsUploadController.parseCSVFromContentVersion(
                cv.Id,
                acc.Id,
                childCamp.Id,
                u.Id,
                con.Id,
                'JD',
                childCamp.ParentId,
                'Disaster A',
                4,
                1,
                true
            );
         VolunteerShiftsUploadController.parseCSVFromContentVersion(
                cv.Id,
                acc.Id,
                childCamp.Id,
                u.Id,
                con.Id,
                'JD',
                childCamp.ParentId,
                'Disaster A',
                4,
                1,
                false
            );
        VolunteerShiftsUploadController.getUserDetails(u.Id);
        Test.stopTest();
    }


}