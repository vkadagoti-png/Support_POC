trigger ContentVersionTrigger on ContentVersion (after insert) {
    Set<Id> documentIds = new Set<Id>();

    for (ContentVersion cv : Trigger.new) {
        if (cv.ContentDocumentId != null) {
            documentIds.add(cv.ContentDocumentId);
        }
    }

    if (!documentIds.isEmpty()) {
        List<ContentDocumentLink> relatedLinks = [
            SELECT Id, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :documentIds
        ];

        List<Id> checklistItemLinkIds = new List<Id>();

        // Only enqueue links where the LinkedEntity is a DocumentChecklistItem
        Set<Id> entityIds = new Set<Id>();
        for (ContentDocumentLink cdl : relatedLinks) {
            entityIds.add(cdl.LinkedEntityId);
        }

        Map<Id, DocumentChecklistItem> dciMap = new Map<Id, DocumentChecklistItem>(
            [SELECT Id FROM DocumentChecklistItem WHERE Id IN :entityIds]
        );

        for (ContentDocumentLink cdl : relatedLinks) {
            if (dciMap.containsKey(cdl.LinkedEntityId)) {
                checklistItemLinkIds.add(cdl.Id);
            }
        }

        if (!checklistItemLinkIds.isEmpty()) {
            System.enqueueJob(new UpdateCDLVisibilityJob(checklistItemLinkIds));
        }
    }
}