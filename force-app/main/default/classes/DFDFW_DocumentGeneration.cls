/*
*********************************************************
Apex Class Name    : DFDFW_DocumentGeneration
Created Date       : 01/20/2025
Author             : Cloud Synapps Inc.
Description        : Class used to generate the documents for the users.
Test Class Name    : DFDFW_DocumentGenerationTest
*********************************************************
*/
global without sharing class DFDFW_DocumentGeneration implements Callable {
    // Entry point for the Callable interface
    global Object call(String action, Map<String, Object> args) {
        try {
            if (action == 'generateDocument') {
                // Parse input arguments
                Map<String, Object> input = (Map<String, Object>) args.get('input');
                String documentName = (String) input.get('documentName');
                Id mainId = (Id) input.get('mainId');
                
                // Extract payload mappings
                Map<String, Object> specialEventPayload = extractPayload(input, 'SpecialEventTransformOmniInputForPayload');
                Map<String, Object> parkPayload = extractPayload(input, 'ParkTransformOmniInputForPayload');
                Map<String, Object> streetPayload = extractPayload(input, 'StreetTransformOmniInputForPayload');
                Map<String, Object> specialEventWithoutPayload = extractPayload(input, 'SpecialEventWithoutParkTransformOmniInputForPayload');
                // Combine payloads
                Map<String, Object> combinedPayload = new Map<String, Object>();
                combinedPayload.putAll(specialEventPayload);
                combinedPayload.putAll(parkPayload);
                combinedPayload.putAll(streetPayload);
                combinedPayload.putAll(specialEventWithoutPayload);
                // Generate the document
                generateDocument(documentName, mainId, combinedPayload);
                return 'Document generation initiated successfully.';
            } else {
                throw new AuraHandledException('Unsupported action: ' + action);
            }
        } catch (Exception e) {
            new DFDFW_LOG_AllException().Module('Document Generation').Log(e);
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
* Extracts a payload from the input Map.
* 
* @param input The input Map containing transformation data.
* @param key   The key for the transformation payload.
* @return The extracted payload as a Map<String, Object>.
*/
    private static Map<String, Object> extractPayload(Map<String, Object> input, String key) {
        if (input.containsKey(key)) {
            Map<String, Object> transformedJson = (Map<String, Object>) input.get(key);
            return (Map<String, Object>) transformedJson.get(key);
        }
        return new Map<String, Object>();
    }
    
    /**
* Generates a document using the provided template and main object ID.
*
* @param documentName The name of the document template to use.
* @param mainId       The ID of the main object to reference.
* @param payload      The combined payload data for the document generation request.
*/
    private static void generateDocument(String documentName, Id mainId, Map<String, Object> payload) {
        try {
            // Retrieve the Service_Application_Detail__c record (optional)
            Service_Application_Detail__c serviceApplication = [
                SELECT Id, Name 
                FROM Service_Application_Detail__c 
                WHERE Id = :mainId 
                LIMIT 1
            ];
            
            // Query for the active document template
            DocumentTemplate docTemplate = [
                SELECT Id, Name, Type, MapperOmniDataTransformName
                FROM DocumentTemplate
                WHERE IsActive = true 
                AND Name = :documentName
                LIMIT 1
            ];
            
            // Query for the latest content version of the template
            DocumentTemplateContentDoc templateContent = [
                SELECT Id, LatestContentVersionId 
                FROM DocumentTemplateContentDoc 
                WHERE DocumentTemplate.Name = :documentName
                LIMIT 1
            ];
            
            // Serialize the payload to JSON
            String tokenData = JSON.serialize(payload);
            if(documentName == System.Label.DFDFW_Special_Event_Without_Park_Acknowledgements){
                // Create and insert the document generation request
                DocumentGenerationProcess request = new DocumentGenerationProcess(); 
                request.Type = 'GenerateAndConvert';
                request.RequestText = JSON.serialize(new Map<String, Object>{
                    'keepIntermediate' => false,
                        'title' => serviceApplication.Name + '_' + System.Label.DFDFW_Special_Event_Application,
                        'templateContentVersionId' => templateContent.LatestContentVersionId
                        });
                request.ReferenceObject = mainId;
                request.TokenData = tokenData;
                request.DocGenApiVersionType = 'Advanced';
                request.DocumentTemplateId = docTemplate.Id;
                
                insert request;
            } else {
                // Create and insert the document generation request
                DocumentGenerationProcess request = new DocumentGenerationProcess(); 
                request.Type = 'GenerateAndConvert';
                request.RequestText = JSON.serialize(new Map<String, Object>{
                    'keepIntermediate' => false,
                        'title' => serviceApplication.Name + '_' + documentName,
                        'templateContentVersionId' => templateContent.LatestContentVersionId
                        });
                request.ReferenceObject = mainId;
                request.TokenData = tokenData;
                request.DocGenApiVersionType = 'Advanced';
                request.DocumentTemplateId = docTemplate.Id;
                
                insert request;
                
            }
        }catch (Exception e) {
            new DFDFW_LOG_AllException().Module('Document Generation').Log(e);
            throw new AuraHandledException(e.getMessage());
        }
    }
}