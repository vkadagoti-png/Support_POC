trigger FileVisibilityControlTrigger on ContentDocumentLink (after insert) {
    List<Id> checklistItemLinkIds = new List<Id>();

    // Only process files linked to Document Checklist Item
    Set<Id> recordIds = new Set<Id>();
    for (ContentDocumentLink cdl : Trigger.new) {
        if (cdl.LinkedEntityId != null) {
            recordIds.add(cdl.LinkedEntityId);
        }
    }

    // Identify checklist item links
    Map<Id, DocumentChecklistItem> dciMap = new Map<Id, DocumentChecklistItem>(
        [SELECT Id FROM DocumentChecklistItem WHERE Id IN :recordIds]
    );

    for (ContentDocumentLink cdl : Trigger.new) {
        if (dciMap.containsKey(cdl.LinkedEntityId)) {
            checklistItemLinkIds.add(cdl.Id);
        }
    }

    if (!checklistItemLinkIds.isEmpty()) {
        System.enqueueJob(new UpdateCDLVisibilityJob(checklistItemLinkIds));
    }
}