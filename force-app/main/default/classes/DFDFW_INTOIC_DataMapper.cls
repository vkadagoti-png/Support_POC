/*
*********************************************************
Apex Class Name    : DFDFW_INTOIC_DataMapper
Created Date       : 9/18/2024
Author             : Cloud Synapps Inc.
Description        : Class used to create mapping for payload to be sent on OIC for permit creation
Test Class Name    : DFDFW_INTOIC_DataMapperTest
*********************************************************
*/
public class DFDFW_INTOIC_DataMapper {
  /*
  *********************************************************
  @method Name    : parseJson
  @description    : used to get table configurations
  @param          : applicationJsonString
  @param          : businessRuleName
  @return         : String
  ********************************************************
  */
  public static String parseJson(
    String applicationJsonString,
    String businessRuleName
  ) {
    try {
      Map<String, Object> applicationJSON = (Map<String, Object>) JSON.deserializeuntyped(
        applicationJsonString
      );
      List<DFD_Service_Rule__c> brList = [
        SELECT Id, Name, Payload_Details_Mapping__c
        FROM DFD_Service_Rule__c
        WHERE
          Service_Rule_Configuration__r.Name = :businessRuleName
          AND Service_Rule_Configuration__r.Active__c = TRUE
          AND Active__c = TRUE
      ];
      Map<String, DFD_Service_Rule__c> brNameTosObj = new Map<String, DFD_Service_Rule__c>();
      Map<String, Object> payloadMap = new Map<String, Object>();
      if (!brList.isEmpty()) {
        for (DFD_Service_Rule__c br : brList) {
          brNameTosObj.put(br.Name, br);
        }
        if (brNameTosObj != null) {
          if (brNameTosObj.containsKey('JSON Map')) {
            Map<String, Object> payloadJsonMapping = (Map<String, Object>) JSON.deserializeuntyped(
              brNameTosObj.get('JSON Map').Payload_Details_Mapping__c
            );
            List<Object> mappedData = new List<Object>();
            if (payloadJsonMapping != null) {
              for (String key : applicationJSON.keySet()) {
                Map<String, Object> objmap = new Map<String, Object>();
                Map<String, Object> brKey = (Map<String, Object>) payloadJsonMapping.get(
                  key
                );
                if (brKey != null) {
                  objMap.put('DetailCode', brKey.get('DetailCode'));
                    if(brKey.containsKey('DefaultValue')) {
                        objMap.put((String)brKey.get('DetailValueType'), (String) brKey.get('DefaultValue'));
                    } else {
                        objMap.put((String) brKey.get('DetailValueType'),applicationJSON.get(key));
                    }
                 
                  mappedData.add(objMap);
                }
              }
            }
            payloadMap.put('Details', mappedData);
          }
          if (brNameTosObj.containsKey('Address Coordinate')) {
            Map<String, Object> payloadJsonMapping = (Map<String, Object>) JSON.deserializeuntyped(
              brNameTosObj.get('Address Coordinate').Payload_Details_Mapping__c
            );
            if (payloadJsonMapping != null) {
              for (String key : payloadJsonMapping.keySet()) {
                String keyVal = (String) payloadJsonMapping.get(key);
                payloadMap.put(key, applicationJson.get(keyVal));
              }
            }
          }
          if (brNameTosObj.containsKey('OIC Keys')) {
            Map<String, Object> metadataMapping = (Map<String, Object>) JSON.deserializeUntyped(
              brNameTosObj.get('OIC Keys').Payload_Details_Mapping__c
            );
            Map<String, Object> payloadJsonMapping_metadata = (Map<String, Object>) metadataMapping.get(
              'mapping_metadata'
            );
            Map<String, Object> payloadJsonMapping_application = (Map<String, Object>) metadataMapping.get(
              'mapping_application'
            );
            List<DFD_OIC_Template_Id__mdt> templateIdMdt = new List<DFD_OIC_Template_Id__mdt>();
            if (metadataMapping != null) {
              String mdtLabel = (String) metadataMapping.get('label');
              templateIdMdt = [
                SELECT Id, Permit_Id__c, Template_Id__c, MasterLabel
                FROM DFD_OIC_Template_Id__mdt
                WHERE MasterLabel = :mdtLabel
                LIMIT 1
              ];
            }
              
              if(payloadJsonMapping_application != null) {
                  for(String key : payloadJsonMapping_application.keySet()) {
                      String keyVal = (String) payloadJsonMapping_application.get(key);
                      payloadMap.put(key, applicationJSON.get(keyVal));
                  }
              }
            if (payloadJsonMapping_metadata != null) {
              for (String key : payloadJsonMapping_metadata.keySet()) {
                String keyVal = (String) payloadJsonMapping_metadata.get(key);
                if (templateIdMdt[0].get(keyVal) != null) {
                  payloadMap.put(key, templateIdMdt[0].get(keyVal));
                } else {
                  payloadMap.put(key, '');
                }
              }
            }
          }
        }
      }

      String payloadJson = JSON.serialize(payloadMap);
      return payloadJson;
    } catch (Exception ex) {
      new DFDFW_LOG_AllException().Module('OIC Payload Mapping').Log(ex);
      return null;
    }
  }
}