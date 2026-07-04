public class DFDExecuteDocGenIP {
    //Use this to execute anonymously: DFDExecuteDocGenIP.callIP('DFDFW_GenerateDocument', 'a1fcn0000002twTAAQ');
    //Query:: select id, CreatedDate, CreatedBy.Name, ContentUrl, DFDFW_Case_Document_Id__c, Description  from ContentVersion order by createdDate desc
    
    public static Map<String, Object> callIP(String ipName, String applicationId) {
        /* Initialize variables */
        Map<String, Object> ipInput = new Map<String, Object> ();
        Map<String, Object> ipOutput = new Map<String, Object> ();
        Map<String, Object> ipOptions = new Map<String, Object> ();
        
        /* Populating input map for an Integration Procedure. 
        Follow whatever structure your VIP expects */
        ipInput.put('ContextId', String.valueOf(applicationId));
        ipOptions.put('useFuture', false);
		ipOptions.put('ignoreCache', true);
        /* Call the IP via runIntegrationService, 
        and save the output to ipOutput */
        ipOutput = (Map<String, Object>) omnistudio.IntegrationProcedureService.runIntegrationService(ipName, ipInput, ipOptions);
        
        System.debug('IP Output: ' + ipOutput);
        return ipOutput;
    }

}