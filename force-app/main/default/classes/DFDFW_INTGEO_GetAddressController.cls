/*
*********************************************************
Apex Class Name    : DFDFW_INTGEO_GetAddressController
Created Date       : 7/2/2024
Author             : Cloud Synapps Inc.
Description        : Class used to fetch address from geocode APIs.
Test Class Name    : DFDFW_INTGEO_GetAddressControllerTest
*********************************************************
*/
public class DFDFW_INTGEO_GetAddressController {
  /*
  *********************************************************
  @method Name    : getAddressCandidate
  @description    : used to get address from geocode
  @param          : street
  @return         : List<Object>
  ********************************************************
  */
  @AuraEnabled
  public static List<Object> getAddressCandidate(
    String street,
    String metadataName
  ) {
    try {
      Geocoder_Endpoint__mdt ge = Geocoder_Endpoint__mdt.getInstance(
        metadataName
      );
      Map<String, String> headerMap = new Map<String, String>();
      String endpoint = ge.Endpoint__c;
      endpoint += '?Street=' + street.replaceAll(' ', '+') + '&f=json';
      String jsonBody = DFDFW_INTGEN_CallOutController.callout(
        endpoint,
        'GET',
        false,
        null,
        false,
        headerMap
      );
      DFDFW_INTGEO_AddressWrapper addressCandidates = (DFDFW_INTGEO_AddressWrapper) JSON.deserialize(
        jsonBody,
        DFDFW_INTGEO_AddressWrapper.class
      );
      List<Object> addressList = new List<Object>();
      for (
        DFDFW_INTGEO_AddressWrapper.candidates ca : addressCandidates.candidates
      ) {
        Map<String, Object> addressToValueMap = new Map<String, Object>();
        if (ca.score == 100) {
          addressToValueMap.put('address', ca.address);
          addressToValueMap.put('x', ca.location.x);
          addressToValueMap.put('y', ca.location.y);
          addressToValueMap.put('score', ca.score);
          addressList.add(addressToValueMap);
          break;
        } else if (ca.score >= 80) {
          addressToValueMap.put('address', ca.address);
          addressToValueMap.put('x', ca.location.x);
          addressToValueMap.put('y', ca.location.y);
          addressToValueMap.put('score', ca.score);
          addressList.add(addressToValueMap);
        } else if (ca.score < 80) {
          addressList = null;
        }
      }

      return addressList;
    } catch (Exception e) {
      new DFDFW_LOG_AllException().Module('Geocode Address Candidate').Log(e);
      throw new AuraHandledException(e.getMessage());
    }
  }
}