global without sharing class DFDFW_OMNI_CustomFunctions implements Callable {
  public object call(String action, Map<String, object> args) {
    Map<String, Object> input = (Map<String, Object>) args.get('input');
    Map<String, Object> output = (Map<String, Object>) args.get('output');
    Map<String, Object> options = (Map<String, Object>) args.get('options');

    return invokeMethod(action, input, output, options);
  }

  global boolean invokemethod(
    String methodname,
    Map<String, Object> input,
    Map<String, Object> output,
    Map<String, Object> options
  ) {
    try {
      if (methodName.equalsIgnoreCase('UpdateServiceApplicationOmniJson')) {
        String applicationId = (String) input.get('applicationId');
        Map<String, object> omniJSON = (Map<String, object>) input.get(
          'omniInput'
        );
        omniJSON.remove('userTimeZoneName');
        omniJSON.remove('userAccountId');
        omniJSON.remove('SaveApplicationStatus');
        omniJSON.remove('timeStamp');
        omniJSON.remove('userTimeZone');
        omniJSON.remove('userId');
        omniJSON.remove('userName');
        omniJSON.remove('addressCheckbox');
        omniJSON.remove('uploadCheckbox');
        omniJSON.remove('localTimeZoneName');
        omniJSON.remove('omniProcessId');
        omniJSON.remove('options');
        Service_Application_Detail__c serviceApp = [SELECT ID, Name, Application_Form_Details__c FROM Service_Application_Detail__c WHERE Id =:applicationId];
          
        Map<String, Object> eventDetailStepMap = (Map<String, Object>) omniJSON.get('EventDetails');
        Map<String, Object> buildingDetailsMap = (Map<String, Object>) eventDetailStepMap.get('BuildingDetails');
        String eventTypeValue = (String) eventDetailStepMap.get('EventType');
        String eventActivitiesValue = (String) buildingDetailsMap.get('EventActivites');
        List<String> eventActivitiesList = eventActivitiesValue.split(';');
        List<String> eventTypeList = eventTypeValue.split(';');
          
          for(String eventType: eventTypeList) {
              omniJSON.put(eventType, 'Y');
          }
          for(String eventActivities: eventActivitiesList) {
              omniJSON.put(eventActivities, 'Y');
          }
        omniJSON.put('SF_Case_Number', serviceApp.Name);
		
        
        serviceApp.Application_Form_Details__c = JSON.serialize(omniJSON);
        update serviceApp;
      }
      if (methodName.equalsIgnoreCase('updatePayloadMappingJSON')) {
        String applicationId = (String) input.get('applicationId');
        Map<String, object> transformedJson = (Map<String, object>) input.get(
          'TransformOmniInputForAPIPayload'
        );
        String businessRuleName = (String) input.get('businessRuleName');
        Map<String, Object> payloadJsonMapping = (Map<String, Object>) transformedJson.get(
          'TransformOmniInputForAPIPayload'
        );
        UUID randomUUID = UUID.randomUUID();        
        Service_Application_Detail__c serviceApp = new Service_Application_Detail__c(
          Id = applicationId,
          Application_Detail_For_Payload__c = JSON.serialize(payloadJsonMapping)
        );
          serviceApp.Request_token__c = String.valueOf(randomUUID);

        String mappedPayload = DFDFW_INTOIC_DataMapper.parseJson(
          JSON.serialize(payloadJsonMapping),
          businessRuleName
        );
        serviceApp.OIC_Payload__c = mappedPayload;
        update serviceApp;

        Service_Application_Detail__c sad = [SELECT Id, Name FROM Service_Application_Detail__c WHERE Id = :applicationId LIMIT 1];

        output.put('appName', sad.Name);
      }
      if (methodName.equalsIgnoreCase('createErrorLog')) {
        Map<String, Object> getServiceApplicationPayload = (Map<String, Object>) input.get('getServiceApplicationPayload');
        Exception_Logger__c logger = new Exception_Logger__c();
        logger.Module_Name__c = 'Error in creating permit on OIC.';
        logger.Stack_Trace__c = String.valueOf(input.get('OICCreatePermit'));
        logger.Class_Name__c = 'DFDFW_OMNI_CustomFunctions';
        logger.Method_Name__c = 'DFDServiceApplicationFormDetailsCallout IP';
        logger.Exception_Type__c = 'API Callout Failure';
        logger.DFD_X_Request_Id__c = String.valueOf(getServiceApplicationPayload.get('requestToken'));
        Map<String, Object> expCauseMap = (Map<String, Object>) input.get(
          'OICCreatePermitInfo'
        );
        logger.Exception_Cause__c =
          'Status Code==> ' + Integer.valueOf(expCauseMap.get('statusCode'));
        logger.Exception_Message__c = String.valueOf(expCauseMap.get('status'));

        insert logger;
      }
      return true;
    } catch (Exception e) {
      return false;
    }
  }
}