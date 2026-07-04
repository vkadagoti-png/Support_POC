/*
*********************************************************
Apex Class Name    : DFDFW_APP_GetDocTypeControllerTest
Created Date       : 10/29/2024
Author             : Cloud Synapps Inc.
Description        : Class used as test class for DFDFW_APP_GetDocTypeController.
*********************************************************
*/
@IsTest
private class DFDFW_APP_GetDocTypeControllerTest {
    
    // Utility method to create a sample input map
    private static Map<String, Object> createInputMap(List<Object> docTypes, List<Object> submittedDocTypes) {
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('DocumentTypes', docTypes);
        inputMap.put('SubmittedDocumentTypes', submittedDocTypes);
        return inputMap;
    }

    // Test method to ensure compareDocumentTypes works as expected
    @IsTest
    static void testCompareDocumentTypes() {
        // Arrange: Create input and expected outputs
        List<Object> allDocTypes = new List<Object>{'Certificate of Insurance', 'Approval Letter', 'Site Map'};
        List<Object> submittedDocTypes = new List<Object>{'Certificate of Insurance'};
        Map<String, Object> inputMap = createInputMap(allDocTypes, submittedDocTypes);
        Map<String, Object> outputMap = new Map<String, Object>();
        
        // Act: Call the method using the Apex class
        DFDFW_APP_GetDocTypeController obj = new DFDFW_APP_GetDocTypeController();
        obj.compareDocumentTypes(inputMap, outputMap);

        // Assert: Check if the correct documents are marked as missing
        Assert.areEqual(true, outputMap.get('Approval Letter'));
        Assert.areEqual(true, outputMap.get('Site Map'));
        Assert.isNull(outputMap.get('Certificate of Insurance'), 'Certificate of Insurance should not be marked as needed');

        // Assert: Verify the generated HTML description
        String expectedHtml = '<ul><li>Approval Letter</li><li>Site Map</li><ul>';
        Assert.areEqual(expectedHtml, outputMap.get('filesNeeded'));
    }

    // Test method for the invokeMethod functionality
    @IsTest
    static void testInvokeMethod() {
        // Arrange: Create input and output maps
        Map<String, Object> inputMap = createInputMap(
            new List<Object>{'Approval Letter', 'Vendors List'}, 
            new List<Object>{'Approval Letter'}
        );
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>{
            'input' => inputMap,
            'output' => outputMap,
            'options' => new Map<String, Object>()
        };
        
        // Act: Call invokeMethod using the appropriate method name
        DFDFW_APP_GetDocTypeController obj = new DFDFW_APP_GetDocTypeController();
        Boolean result = (Boolean) obj.call('compareDocumentTypes', args);

        // Assert: Verify that the invokeMethod executed correctly
        Assert.isTrue(result, 'Method should return true');
        Assert.areEqual(true, outputMap.get('Vendors List'), 'Vendors List should be marked as needed');
        Assert.isNull(outputMap.get('Approval Letter'), 'Approval Letter should not be marked as needed');
    }
}