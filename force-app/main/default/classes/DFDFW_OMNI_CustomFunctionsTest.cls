@isTest
public class DFDFW_OMNI_CustomFunctionsTest {
    
    @testSetup
    static void setupData() {
        // Create a Service_Application_Detail__c record to use in tests
        Service_Application_Detail__c serviceApp = new Service_Application_Detail__c();
        insert serviceApp;
    }

    // Mock Http Callout
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            // Set mock response based on endpoint URI
            res.setStatusCode(200);
            res.setBody('{"Fields": {"Field1": "value1", "Field2": 75843}}');
            return res;
        }
    }

    @isTest
    static void testUpdateServiceApplicationOmniJson() {
        // Get the test Service_Application_Detail__c record
        Service_Application_Detail__c serviceApp = [SELECT Id FROM Service_Application_Detail__c LIMIT 1];

        // Set up input map
        Map<String, Object> input = new Map<String, Object>();
        input.put('applicationId', serviceApp.Id);
        String omniInputJson = '{"field1":"value1","UserTimeZoneName":"PST","timeStamp":"2023-09-21T12:34:56Z","EventDetails":{"EventType":"Run_Walk_Ride;Parade","BuildingDetails":{"EventActivites":"Pyrotechnics_Fireworks;Carnival_Rides"}}}';
        Map<String, Object> inputMap = (Map<String, Object>) JSON.deserializeUntyped(omniInputJson);
        input.put('omniInput', inputMap);
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output,
            'options' => new Map<String, Object>()
        };

        // Call the method
        DFDFW_OMNI_CustomFunctions customFunctions = new DFDFW_OMNI_CustomFunctions();
        customFunctions.call('UpdateServiceApplicationOmniJson', args);

        // Validate the update to Application_Form_Details__c field
        serviceApp = [SELECT Application_Form_Details__c FROM Service_Application_Detail__c WHERE Id = :serviceApp.Id];
        Assert.isTrue(serviceApp.Application_Form_Details__c.contains('field1'), 'The JSON should include field1');
        Assert.isTrue(!serviceApp.Application_Form_Details__c.contains('userTimeZoneName'), 'The JSON should not include userTimeZoneName');
    }

    @isTest
    static void testUpdatePayloadMappingJSON() {
        Service_Application_Detail__c serviceApp = [SELECT Id FROM Service_Application_Detail__c LIMIT 1];

        Map<String, Object> input = new Map<String, Object>();
        input.put('applicationId', serviceApp.Id);
        input.put('businessRuleName', 'TestBusinessRule');
        input.put('TransformOmniInputForAPIPayload', new Map<String, Object>{
            'TransformOmniInputForAPIPayload' => new Map<String, Object> {
                'key1' => 'value1'
            }
        });

        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output,
            'options' => new Map<String, Object>()
        };

        Test.startTest();
        DFDFW_OMNI_CustomFunctions customFunctions = new DFDFW_OMNI_CustomFunctions();
        customFunctions.call('updatePayloadMappingJSON', args);
        Test.stopTest();

        serviceApp = [SELECT Application_Detail_For_Payload__c, OIC_Payload__c FROM Service_Application_Detail__c WHERE Id = :serviceApp.Id];
        Assert.isTrue(serviceApp.Application_Detail_For_Payload__c.contains('key1'), 'Payload JSON should contain key1');
        Assert.isNotNull(serviceApp.OIC_Payload__c, 'OIC_Payload__c should be populated');
    }

    @isTest
    static void testCreatePayment() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Service_Application_Detail__c serviceApp = [SELECT Id FROM Service_Application_Detail__c LIMIT 1];

        Map<String, Object> input = new Map<String, Object>();
        input.put('applicationId', serviceApp.Id);

        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output,
            'options' => new Map<String, Object>()
        };

        Test.startTest();
        DFDFW_OMNI_CustomFunctions customFunctions = new DFDFW_OMNI_CustomFunctions();
        customFunctions.call('createPayment', args);
        Test.stopTest();

        //Assert.isNotNull(output.get('mappedPayload'), 'Output map should contain mappedPayload');
    }

    @isTest
    static void testCreateErrorLog() {
        Map<String, Object> input = new Map<String, Object>();
        input.put('OICCreatePermit', 'Permit creation failed');
        String inputMapJson = '{"statusCode":500, "status":"Internal Server Error"}';
        Map<String, Object> inputMap = (Map<String, Object>) JSON.deserializeUntyped(inputMapJson);
        input.put('OICCreatePermitInfo',inputMap);
        input.put('getServiceApplicationPayload', new Map<String, Object>{'requestToken'=>'testrequestToken'});
 
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output,
            'options' => new Map<String, Object>()
        };

        Test.startTest();
        DFDFW_OMNI_CustomFunctions customFunctions = new DFDFW_OMNI_CustomFunctions();
        customFunctions.call('createErrorLog', args);
        Test.stopTest();

        // Verify the logger record
        Exception_Logger__c logger = [SELECT Exception_Type__c, Exception_Message__c FROM Exception_Logger__c LIMIT 1];
        Assert.areEqual('API Callout Failure', logger.Exception_Type__c, 'Logger should record correct exception type');
        Assert.areEqual('Internal Server Error', logger.Exception_Message__c, 'Logger should record the correct error message');
    }
}