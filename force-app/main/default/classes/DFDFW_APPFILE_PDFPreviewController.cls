/*
*********************************************************
Apex Class Name    : DFDFW_APPFILE_PDFPreviewController
Created Date       : 01/23/2025
Author             : Cloud Synapps Inc.
Description        : Class used as controller for retrieving files on Omniscript.
Test Class Name    : DFDFW_APPFILE_DownloadControllerTest
*********************************************************
*/
public class DFDFW_APPFILE_PDFPreviewController {
    /*
    *********************************************************
    @method Name    : getfileDetails
    @description    : used to get file URL
    @param          : recordId
    @param          : fileNames
    @return         : List<Object>
    ********************************************************
    */
    @AuraEnabled
     public static List<Object> getfileDetails(String recordId, List<String> fileNames) {
        try {
            List<Object> returnList = new List<Object>();
            Service_Application_Detail__c sa = [SELECT Id, Name FROM Service_Application_Detail__c WHERE Id = :recordId];
            List<ContentDocumentLink> documentLinks = [
                SELECT Id, ContentDocumentId, ContentDocument.FileType, LinkedEntityId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :recordId
            ];

            List<String> fileNameTitles = new List<String>();
            for (String str : fileNames) {
                String fileTitleWithName = sa.Name + '_' + str;
                fileNameTitles.add(fileTitleWithName);
            }

            List<Id> cdIds = new List<Id>();
            for (ContentDocumentLink link : documentLinks) {
                cdIds.add(link.ContentDocumentId);
            }

            List<ContentVersion> ver = [
                SELECT Id, Title, ContentDocumentId, ContentDocument.FileType
                FROM ContentVersion
                WHERE ContentDocumentId IN :cdIds AND Title IN :fileNameTitles
                ORDER BY CreatedDate DESC
            ];

            if (!ver.isEmpty()) {
                for (ContentVersion cv : ver) {
                    Map<String, Object> fileDetails = new Map<String, Object>();
                    fileDetails.put('Name', cv.Title);  // File name (no extension handling)
                    fileDetails.put('FileUrl', '/sfc/servlet.shepherd/document/download/' + cv.ContentDocumentId);  // Direct download URL
                    fileDetails.put('FileType', cv.ContentDocument.FileType);  // Add the file type (PDF, DOCX, etc.)
                    returnList.add(fileDetails);
                }
            }
            return returnList;
        } catch (Exception e) {
            throw new AuraHandledException('An error occurred: ' + e.getMessage());
        }
    }
    
    /*
    *********************************************************
    @method Name    : createObjectList
    @description    : used to create list of object for download URLs to be used in LWC
    @param          : downloadUrlMap
    @param          : ver
    @return         : List<Object>
    ********************************************************
    */
    public static List<Object> createObjectList(Map<String, String> downloadUrlMap, List<ContentVersion> ver) {
        try {
            Map<Id, String> cvIdToNameMap = new Map<Id, String>();
            for (ContentVersion cv : ver) {
                cvIdToNameMap.put(cv.Id, cv.Title);
            }
            List<Object> returnList = new List<Object>();
            for (String key : downloadUrlMap.keySet()) {
                Map<String, String> detailMap = new Map<String, String>();
                detailMap.put('Name', cvIdToNameMap.get(key));
                detailMap.put('FileUrl', downloadUrlMap.get(key));
                returnList.add(detailMap);
            }
            if(!returnList.isEmpty() && returnList.size() > 0){
                return returnList;     
            }else{
                return null;
            }
           
        } catch (Exception e) {
            DFDFW_LOG_AllException logger = new DFDFW_LOG_AllException();
            logger.Module('createObjectList').Log(e);
            throw new AuraHandledException('An unexpected error occurred: ' + e.getMessage());
            
        }
        
    }
    
    /*
    *********************************************************
    @method Name    : getDownloadURL
    @description    : used to get download URLs
    @param          : cvIds
    @return         : Map<String, String>
    ********************************************************
    */
    public static Map<String, String> getDownloadURL(List<Id> cvIds) {
        try {
            Map<String, String> urlMap = new Map<String, String>();
            List<ContentDistribution> contentDelivery = [
                SELECT Id, Name, DistributionPublicUrl, ContentVersionId
                FROM ContentDistribution
                WHERE ContentVersionId IN :cvIds
            ];
            if (!contentDelivery.isEmpty()) {
                for (ContentDistribution cd : contentDelivery) {
                    urlMap.put(cd.ContentVersionId, cd.DistributionPublicUrl);
                }
            }
            return urlMap;
        } catch (Exception e) {
            DFDFW_LOG_AllException logger = new DFDFW_LOG_AllException();
            logger.Module('getDownloadURL').Log(e);
            throw new AuraHandledException('An unexpected error occurred: ' + e.getMessage());
        }
    }
}