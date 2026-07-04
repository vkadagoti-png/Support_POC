@isTest
public class UpdateCDLVisibilityJobTest {

    // Helper to create a ContentDocument and return the Id
    private static Id createContentDocument() {
        ContentVersion cv = new ContentVersion(
            Title = 'TestDoc',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Test content')
        );
        insert cv;

        // Fetch ContentDocument Id
        ContentVersion insertedVersion = [
            SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id
        ];
        return insertedVersion.ContentDocumentId;
    }

    @isTest
    static void testExecute_updatesVisibility() {
        // Create parent record for DocumentChecklistItem
        Case parentCase = new Case(Subject = 'Checklist Case', Status = 'New', Origin = 'Phone');
        insert parentCase;

        DocumentChecklistItem dci = new DocumentChecklistItem(
            Name = 'Checklist 1',
            ParentRecordId = parentCase.Id
        );
        insert dci;

        // Create ContentDocument and link it to DCI with wrong visibility
        Id contentDocId = createContentDocument();

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocId,
            LinkedEntityId = dci.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;

        Test.startTest();
        System.enqueueJob(new UpdateCDLVisibilityJob(new List<Id>{cdl.Id}));
        Test.stopTest();

        ContentDocumentLink updated = [
            SELECT Id, Visibility FROM ContentDocumentLink WHERE Id = :cdl.Id
        ];
        System.assertEquals('InternalUsers', updated.Visibility, 'CDL visibility should be updated');
    }

    @isTest
    static void testExecute_noUpdateWhenAlreadyInternalUsers() {
        Case parentCase = new Case(Subject = 'Checklist Case', Status = 'New', Origin = 'Phone');
        insert parentCase;

        DocumentChecklistItem dci = new DocumentChecklistItem(
            Name = 'Checklist 2',
            ParentRecordId = parentCase.Id
        );
        insert dci;

        Id contentDocId = createContentDocument();

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocId,
            LinkedEntityId = dci.Id,
            ShareType = 'V',
            Visibility = 'InternalUsers'
        );
        insert cdl;

        Test.startTest();
        System.enqueueJob(new UpdateCDLVisibilityJob(new List<Id>{cdl.Id}));
        Test.stopTest();

        ContentDocumentLink result = [
            SELECT Id, Visibility FROM ContentDocumentLink WHERE Id = :cdl.Id
        ];
        System.assertEquals('InternalUsers', result.Visibility, 'Visibility should remain InternalUsers');
    }

    @isTest
    static void testExecute_nonChecklistLinkedEntity() {
        // Linked to an Account, not DocumentChecklistItem
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Id contentDocId = createContentDocument();

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocId,
            LinkedEntityId = acc.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;

        Test.startTest();
        System.enqueueJob(new UpdateCDLVisibilityJob(new List<Id>{cdl.Id}));
        Test.stopTest();

        ContentDocumentLink result = [
            SELECT Id, Visibility FROM ContentDocumentLink WHERE Id = :cdl.Id
        ];
        System.assertEquals('AllUsers', result.Visibility, 'Visibility should remain AllUsers for non-checklist items');
    }
}