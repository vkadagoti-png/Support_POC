/*
*********************************************************
@description    : A Queueable class responsible for assigning Permission Set Licenses,
                  Permission Sets, and adding a user to a Public Group after user creation.
                  This class ensures access rights are granted asynchronously to avoid governor limits during the user creation transaction.
@author         : Omniskope INC.
@date           : 8/19/2024
*********************************************************
*/
public class AssignAccessQueueable implements Queueable {
    public Id userId;

/*
*********************************************************
* @description   : Constructor for the AssignAccessQueueable class.
* @param         : usrId The ID of the User record to which access will be assigned.
*********************************************************
*/
    public AssignAccessQueueable(Id usrId) {
        this.userId = usrId;
    }

/*
*********************************************************
* @description   : The main execution method of the Queueable class. It dynamically
                   retrieves the IDs for the required access components and assigns them to the user.
                   Hardcoded IDs have been replaced with dynamic queries.
* @param         : context The QueueableContext provided by the platform.
*********************************************************
*/
    public void execute(QueueableContext context) {
        try {
            // Step 1: Dynamically retrieve IDs for Permission Set Licenses (PSLs) by their DeveloperName
            Set<String> pslNames = new Set<String>{'DocGenRuntimeCCPsl', 'OmniStudioRuntimeCC'};
            Map<String, Id> pslIdMap = new Map<String, Id>();
            for (PermissionSetLicense psl : [SELECT Id, DeveloperName FROM PermissionSetLicense WHERE DeveloperName IN :pslNames]) {
                pslIdMap.put(psl.DeveloperName, psl.Id);
            }
            
            // Create a list to hold the PSL assignments
            List<PermissionSetLicenseAssign> pslAssigns = new List<PermissionSetLicenseAssign>();
            if (pslIdMap.containsKey('DocGenRuntimeCCPsl')) {
                pslAssigns.add(new PermissionSetLicenseAssign(PermissionSetLicenseId = pslIdMap.get('DocGenRuntimeCCPsl'), AssigneeId = userId));
            }
            if (pslIdMap.containsKey('OmniStudioRuntimeCC')) {
                pslAssigns.add(new PermissionSetLicenseAssign(PermissionSetLicenseId = pslIdMap.get('OmniStudioRuntimeCC'), AssigneeId = userId));
            }
            if (!pslAssigns.isEmpty()) {
                insert pslAssigns;
            }

            // Step 2: Dynamically retrieve IDs for Permission Sets by their DeveloperName
            Set<String> psNames = new Set<String>{'DocGenRuntimeCC', 'DFDFW_OmniStudio_Community_User', 'DFDFW_Portal_User', 'Password_Never_Expires'};
            Map<String, Id> psIdMap = new Map<String, Id>();
            for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE Name IN :psNames]) {
                psIdMap.put(ps.Name, ps.Id);
            }
            
            // Create a list to hold the Permission Set assignments
            List<PermissionSetAssignment> psAssigns = new List<PermissionSetAssignment>();
            for (String psName : psNames) {
                if (psIdMap.containsKey(psName)) {
                    psAssigns.add(new PermissionSetAssignment(PermissionSetId = psIdMap.get(psName), AssigneeId = userId));
                }
            }
            if (!psAssigns.isEmpty()) {
                insert psAssigns;
            }

            // Step 3: Dynamically retrieve the Public Group ID by its Name
            String groupName = 'DFDFW_Portal_Users';
            Group publicGroup = [SELECT Id,DeveloperName,Type FROM Group WHERE DeveloperName = :groupName AND Type = 'Regular' LIMIT 1];

            // Add the user to the public group
            GroupMember gm = new GroupMember(
                GroupId = publicGroup.Id,
                UserOrGroupId = userId
            );
            insert gm;
            System.debug('✅ Successfully assigned PSL, Permission Sets, and Group to: ' + userId);

        } catch (Exception e) {
            System.debug('❌ Access assignment failed for ' + userId + ': ' + e.getMessage());
        }
    }
}