/*
*********************************************************
Apex Class Name    : DFDFW_INTPAYMENT_CalloutControllerTest
Created Date       : 11/8/2024
Author             : Cloud Synapps Inc.
Description        : Class used as test class for DFDFW_INTPAYMENT_CalloutController.
*********************************************************
*/
@isTest
public class DFDFW_INTPAYMENT_CalloutControllerTest {
    
    @testSetup
    static void setupTestData() {
        //Create User Detail record
        String userId = UserInfo.getUserId();
        DFD_User_Details__c ud = new DFD_User_Details__c();
        ud.SetupOwnerId = userId;
        ud.isRegistered__c = true;
        ud.Token_Part_1__c = 'daw3adaw3adaw';
        insert ud;

    }

    @isTest
    static void testPayFees() {
        // Set up mock callouts
        Test.setMock(HttpCalloutMock.class, new DFDFW_INTPAYMENT_CalloutControllerMock());

        Test.startTest();
        // Test the payFees method
        Map<String, Object> result = DFDFW_INTPAYMENT_CalloutController.payFees(
            12345, 
            'https://example.com/return', 
            'test@example.com', 
            'FEE123', 
            false
        );
        Test.stopTest();

        Assert.isNotNull(result, 'The result URL should not be null');
        
    }

    @isTest
    static void testErrorCallout() {
        // Set up mock callouts
        Test.setMock(HttpCalloutMock.class, new DFDFW_INTPAYMENT_CalloutControllerErrorMock());

        Test.startTest();
        // Test the payFees method
        try{
            Map<String, Object> result = DFDFW_INTPAYMENT_CalloutController.payFees(
                12345, 
                'https://example.com/return', 
                'test@example.com', 
                'FEE123', 
                false
            );
        }catch(Exception e){}
        Test.stopTest();
        
    }

    @isTest
    static void testUpdateTransactionId() {
        // Retrieve the test Service_Application_Detail__c record
        Service_Application_Detail__c sad = new Service_Application_Detail__c();
        insert sad;
        
        Test.startTest();
        DFDFW_INTPAYMENT_CalloutController.updateTransactionId(sad.Id, 'transaction123', true);
        Test.stopTest();
        
        // Query and check if the transaction ID was updated
        DFD_Payment_Transaction__c pt = [SELECT Id, Transaction_Id__c FROM DFD_Payment_Transaction__c LIMIT 1];
        Assert.areEqual('transaction123', pt.Transaction_Id__c, 'Transaction ID should be updated');
    }

    // Mock callout class
    public class DFDFW_INTPAYMENT_CalloutControllerMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();

            if (req.getEndpoint().containsIgnoreCase('permit')) {
                res.setStatusCode(200);
                res.setBody('{"Fees": [{"FeeCode": "FEE123", "CaFeeId": 1, "FeeDesc": "Description", "Amount": 100.0, "PaymentAmount": 50.0, "WaiveFee": "false"}]}');
            } else if (req.getEndpoint().containsIgnoreCase('checkout/create')) {
                res.setStatusCode(200);
                res.setBody('{"id": "payment123"}');
            } else if (req.getEndpoint().containsIgnoreCase('token')) {
                res.setStatusCode(200);
                res.setBody('{"token":"12345"}');
            }else {
                res.setStatusCode(404);
            }

            return res;
        }

    }

    public class DFDFW_INTPAYMENT_CalloutControllerErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();

            res.setStatusCode(500);
            res.setBody('{"Error": "Fatal Error"}');

            return res;
        }

    }


}