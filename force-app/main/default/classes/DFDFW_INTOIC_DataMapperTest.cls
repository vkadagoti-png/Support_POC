@isTest
private class DFDFW_INTOIC_DataMapperTest {

    @isTest
    static void testParseJson() {
        // Step 1: Set up test data
        String businessRuleName = 'Test Business Rule';
        DFD_Service_Configuration__c config = new DFD_Service_Configuration__c();
        config.Active__c = true;
        config.Name = 'Test Business Rule';
        insert config;
        
        // Create and insert DFD_Service_Rule__c records
        DFD_Service_Rule__c serviceRule = new DFD_Service_Rule__c(
            Name = 'JSON Map',
            Payload_Details_Mapping__c = '{"EventType":{"DetailCode":"EVENT-TYPE","DetailValueType":"ListValue"},"EventTypeGuest":{"DetailCode":"EVENT-TYPE","DetailValueType":"ListValue"},"EventDescription":{"DetailCode":"DESC","DetailValueType":"CommentValue"},"EventDescriptionGuest":{"DetailCode":"DESC","DetailValueType":"CommentValue"}}',
            Active__c = true,
            Service_Rule_Configuration__c = config.Id
        );
        
        DFD_Service_Rule__c addressRule = new DFD_Service_Rule__c(
            Name = 'Address Coordinate',
            Payload_Details_Mapping__c = '{"Location":"address","X":"x","Y":"y"}',
            Active__c = true,
            Service_Rule_Configuration__c = config.Id
        );

        DFD_Service_Rule__c keysRule = new DFD_Service_Rule__c(
            Name = 'OIC Keys',
            Payload_Details_Mapping__c = '{"label":"Special Event","mapping_metadata":{"TemplateId":"Template_Id__c","PermitID":"Permit_Id__c"},"mapping_application":{"Name":"EventName"}}',
            Active__c = true,
            Service_Rule_Configuration__c = config.Id
        );

        // Insert the test rules
        insert new List<DFD_Service_Rule__c> { serviceRule, addressRule, keysRule };

        // Create the JSON input string
        String applicationJsonString = '{"EventType": "Festival with public park usage", "EventDescription": "asdasd", "y": "1019162.4250790704", "x": "896599.79852054222","address": "300 S GRAND AVE, 63103","EventName": "special Event" }';

        // Step 2: Call the method to test
        Test.startTest();
        String result = DFDFW_INTOIC_DataMapper.parseJson(applicationJsonString, businessRuleName);
        Test.stopTest();

        // Step 3: Validate the result
        System.assertNotEquals(null, result, 'The result should not be null.');
        
        // Step 4: Parse and validate the resulting JSON string
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assert(resultMap.containsKey('Details'), 'Result should contain Details key.');
        List<Object> details = (List<Object>) resultMap.get('Details');
        System.assertEquals(2, details.size(), 'Details should contain one mapped object.');
        Map<String, Object> detailMap = (Map<String, Object>) details[0];
        System.assertEquals('EVENT-TYPE', detailMap.get('DetailCode'), 'DetailCode should match.');
        System.assertEquals('Festival with public park usage', detailMap.get('ListValue'), 'DetailValueType should match.');
    }

    @isTest
    static void testParseJsonWithException() {
        // Step 5: Test exception handling
        String invalidJson = 'invalid json string';
        Test.startTest();
        String result = DFDFW_INTOIC_DataMapper.parseJson(invalidJson, null);
        Test.stopTest();

        // Step 6: Validate that result is null due to exception
        System.assertEquals(null, result, 'The result should be null when an exception occurs.');
    }
}