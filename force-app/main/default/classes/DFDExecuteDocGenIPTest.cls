@isTest
public class DFDExecuteDocGenIPTest {

    @testSetup
    static void setupTestData() {
        // Create a dummy Application record (or any object that ContextId refers to)
        Case testCase = new Case(
            Subject = 'Test Case'
        );
        insert testCase;
    }

    @isTest
    static void testCallIP() {
        // Arrange
        String ipName = 'DFDFW_GenerateDocument';
        String applicationId = [SELECT Id FROM Case LIMIT 1].Id;

        // Simulate the expected output from the Integration Procedure
        Map<String, Object> mockIpOutput = new Map<String, Object>();
        mockIpOutput.put('Success', true);
        mockIpOutput.put('Message', 'Document generated successfully');

        // Start the test context
        Test.startTest();

        // Call the Integration Procedure service (this is where the actual logic will happen)
        Map<String, Object> actualOutput = DFDExecuteDocGenIP.callIP(ipName, applicationId);

        // Stop the test context
        Test.stopTest();

        // Assert
        // Check that actualOutput is not null
        System.assertNotEquals(actualOutput, null, 'IP output should not be null');
        
        // Assert other values
        // Check if 'Success' exists and then assert
        if (actualOutput != null && actualOutput.containsKey('Success')) {
            System.assertEquals(mockIpOutput.get('Success'), actualOutput.get('Success'), 'Expected Success = true');
            System.assertEquals(mockIpOutput.get('Message'), actualOutput.get('Message'), 'Expected message mismatch');
        } else {
            System.debug('Expected key "Success" not found in actualOutput');
        }
    }
}