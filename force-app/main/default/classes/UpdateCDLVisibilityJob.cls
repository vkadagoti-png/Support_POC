public class UpdateCDLVisibilityJob implements Queueable {
    private List<Id> linkIds;

    public UpdateCDLVisibilityJob(List<Id> linkIds) {
        this.linkIds = linkIds;
    }

    public void execute(QueueableContext context) {
        List<ContentDocumentLink> links = [
            SELECT Id, Visibility, LinkedEntityId
            FROM ContentDocumentLink
            WHERE Id IN :linkIds
        ];

        Set<Id> checklistItemIds = new Set<Id>();
        for (ContentDocumentLink cdl : links) {
            checklistItemIds.add(cdl.LinkedEntityId);
        }

        Map<Id, DocumentChecklistItem> checklistItems = new Map<Id, DocumentChecklistItem>(
            [SELECT Id FROM DocumentChecklistItem WHERE Id IN :checklistItemIds]
        );

        List<ContentDocumentLink> toUpdate = new List<ContentDocumentLink>();

        for (ContentDocumentLink cdl : links) {
            if (checklistItems.containsKey(cdl.LinkedEntityId) && cdl.Visibility != 'InternalUsers') {
                cdl.Visibility = 'InternalUsers';
                toUpdate.add(cdl);
            }
        }

        if (!toUpdate.isEmpty()) {
            try {
                update toUpdate;
            } catch (Exception e) {
                System.debug('❌ Failed to update CDL visibility: ' + e.getMessage());
            }
        }
    }
}