/***************************************************************************
 * Class:           DFDFW_APP_GetDocTypeController
 * Description:     Used for more document upload after permit submission. Will return the list of documents still required for the permit type.
 * Author:          Cloud SynApps
 * Date Created:    11-04-2024 (mm-dd-yyyy)
 * Last Modified:   11-04-2024 (mm-dd-yyyy)
 * Change History:  
 * 
 ***************************************************************************/
global with sharing class DFDFW_APP_GetDocTypeController implements Callable {
    public Object call(String action, Map<String, object> args) {
        Map<String, Object> input = (Map<String, Object>) args.get('input');
        Map<String, Object> output = (Map<String, Object>) args.get('output');
        Map<String, Object> options = (Map<String, Object>) args.get('options');
        
        return invokeMethod(action, input, output, options);
    }

    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        try {
            if(methodName.equals('compareDocumentTypes')) {                                                               
                compareDocumentTypes(inputMap, outputMap); 
            } 
            return true;           
        } 
        catch(Exception e) {
            new DFDFW_LOG_AllException().Module('DFD Document Types Needed').Log(e);
            return false; 
        }
    }
/**********************************************************
 * Method:          compareDocumentTypes
 * Description:     Removed the submitted document types from the required document types list and adds those document types to the output for the omniscript to reference.
 *********************************************************/
    global void compareDocumentTypes(Map <String, Object> inputMap, Map <String, Object> outputMap){

        //List of require document types and list of already submitted document types, retreived from the input map from the omniscript.
        List<Object> documentTypes = (List<Object>)inputMap.get('DocumentTypes');
        List<Object> submittedDocumentTypes = (List<Object>)inputMap.get('SubmittedDocumentTypes');

        List<String> notSubmittedDocuments = new List<String>();

        //Loop through the document types that are required
        for(Object dt : documentTypes){
            //Check if this value is NOT in the submitted document types
            if (!submittedDocumentTypes.contains(dt)){
                //Add the document type to the list and output map
                notSubmittedDocuments.add((String) dt);
                outputMap.put((String)dt, true);
            }
        }

        notSubmittedDocuments.sort();

        //Create a String output listing the document types still needed in html list format. In case it needs to be displayed on the omniscript
        String description = '<ul>';
        for(String dt: notSubmittedDocuments){
            description += '<li>' + dt + '</li>';
        }
        description += '<ul>';

        outputMap.put('filesNeeded', description);

        
    }

}