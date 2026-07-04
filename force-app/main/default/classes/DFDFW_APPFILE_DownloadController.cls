/*
*********************************************************
Apex Class Name    : DFDFW_APPFILE_DownloadController
Created Date       : 8/26/2024
Author             : Cloud Synapps Inc.
Description        : Class used as controller for retriveing files on flexcard.
Test Class Name    : DFDFW_APPFILE_DownloadControllerTest
*********************************************************
*/
public with sharing class DFDFW_APPFILE_DownloadController {
/*
  @AuraEnabled
  public static String getPreviewURL(String recordId) {
    
    ContentDistribution cdl = new ContentDistribution();
    cdl.ContentVersionId = recordId;
    cdl.Name = 'PublicShare';
    insert cdl;

    cdl = [SELECT DistributionPublicUrl FROM ContentDistribution WHERE Id = :cdl.Id LIMIT 1];
    return cdl.DistributionPublicUrl;
  }*/
  /*
  *********************************************************
  @method Name    : getFiles
  @description    : used to retrive files.
  @param          : recordId
  @return         : List<FileDataWrapper>
  ********************************************************
  */
  @AuraEnabled
  public static List<FileDataWrapper> getFiles(String recordId) {
    List<FileDataWrapper> fileDataList = new List<FileDataWrapper>();

    // Retrieve the value from the custom label 'Permit_File_Category'
       String issuedPermitCategory = Label.Permit_File_Category;

    // Retrieve the value from the custom label 'Application_File_Category'
       String ApplicationCategory = Label.Application_File_Category;

    // Query ContentDocumentLink and related ContentVersion records
    List<ContentDocumentLink> documentLinks = [
      SELECT Id, ContentDocumentId, ContentDocument.FileType, LinkedEntityId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :recordId
    ];

    // Iterate over ContentDocumentLinks to retrieve related ContentVersions
    Map<Id, ContentDocumentLink> cdIdsToLink = new Map<Id, ContentDocumentLink>();

    for (ContentDocumentLink link : documentLinks) {
      cdIdsToLink.put(link.ContentDocumentId, link);
    }
    List<ContentVersion> cvrs = [
      SELECT Id, Title, File_Category__c, CreatedDate, ContentDocumentId
      FROM ContentVersion
      WHERE ContentDocumentId IN :cdIdsToLink.keySet()
      AND File_Category__c !=: issuedPermitCategory
      ORDER BY CreatedDate DESC
    ];

    List<FileDataWrapper> applicationTypeFiles = new List<FileDataWrapper>();
    List<FileDataWrapper> otherFiles = new List<FileDataWrapper>();

    // Separate the files based on File_Category__c
    for (ContentVersion version : cvrs) {
      // Create a wrapper object to hold both ContentDocumentLink and ContentVersion data
      FileDataWrapper fileData = new FileDataWrapper();
      fileData.documentLink = cdIdsToLink.get(version.ContentDocumentId);
      fileData.fileId = version.Id;
      fileData.contentVersion = version;

      // Sort into Application type or other category
      (version.File_Category__c == ApplicationCategory ? applicationTypeFiles : otherFiles).add(fileData);
    }
    // Combine both lists, with Application type files first
    fileDataList.addAll(applicationTypeFiles);
    fileDataList.addAll(otherFiles);

    return fileDataList;
  }

    /*
    *********************************************************
    @method Name    : getIssuedPermitFiles
    @description    : Fetches files related to the child records (Sub_Application__c) and parent record (Service_Application_Detail__c), filtering by 'Issued Permit'
    @param          : recordId
    @return         : List<FileDataWrapper>
    ********************************************************
    */
    @AuraEnabled
    public static List<FileDataWrapper> getIssuedPermitFiles(String recordId) {
        List<FileDataWrapper> fileDataList = new List<FileDataWrapper>();

        // Retrieve the value from the custom label 'Permit_File_Category'
        String issuedPermitCategory = Label.Permit_File_Category;

        // Query ContentDocumentLink and related ContentVersion records for the parent object (Service_Application_Detail__c)
        List<ContentDocumentLink> parentDocumentLinks = [
        SELECT Id, ContentDocumentId, ContentDocument.FileType, LinkedEntityId
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :recordId
        ];

        // Query ContentDocumentLink for files related to the child records (Sub_Application__c)
        List<ContentDocumentLink> childDocumentLinks = [
        SELECT Id, ContentDocumentId, ContentDocument.FileType, LinkedEntityId
        FROM ContentDocumentLink
        WHERE LinkedEntityId IN (
            SELECT Id FROM Sub_Application__c WHERE Service_Application_Detail__c = :recordId
        )
        ];

        // Combine both the parent and child document links
        parentDocumentLinks.addAll(childDocumentLinks);

        // Iterate over ContentDocumentLinks to retrieve related ContentVersions
        Map<Id, ContentDocumentLink> cdIdsToLink = new Map<Id, ContentDocumentLink>();

        for (ContentDocumentLink link : parentDocumentLinks) {
        cdIdsToLink.put(link.ContentDocumentId, link);
        }

        // Query ContentVersion for the files linked to the ContentDocumentLinks, filter by 'Issued Permit' File_Category__c
        List<ContentVersion> cvrs = [
            SELECT Id, Title, File_Category__c, CreatedDate, ContentDocumentId
            FROM ContentVersion
            WHERE ContentDocumentId IN :cdIdsToLink.keySet()
            AND File_Category__c =: issuedPermitCategory
            ORDER BY CreatedDate DESC
        ];

        // Populate the wrapper list with the results
        for (ContentVersion version : cvrs) {
            FileDataWrapper fileData = new FileDataWrapper();
            fileData.documentLink = cdIdsToLink.get(version.ContentDocumentId);
            fileData.fileId = version.Id;
            fileData.contentVersion = version;
            fileDataList.add(fileData);
        }

        return fileDataList;
    }

  /*
  *********************************************************
  @method Name    : getFileId
  @description    : used to get file URL
  @param          : recordId
  @param          : fileTitle
  @return         : String
  ********************************************************
  */
  @AuraEnabled
  public static String getFileId(String recordId, String fileTitle) {
    String url = '';
    Service_Application_Detail__c sa = [SELECT Id, Name FROM Service_Application_Detail__c WHERE Id =:recordId];
    List<ContentDocumentLink> documentLinks = [
      SELECT Id, ContentDocumentId, ContentDocument.FileType, LinkedEntityId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :recordId
    ];
    String fileTitleWithName = sa.Name + '_' + fileTitle;
    List<Id> cdIds = new List<Id>();
    for (ContentDocumentLink link : documentLinks) {
      cdIds.add(link.ContentDocumentId);
    }

    List<ContentVersion> ver = [
      SELECT Id, Title, File_Category__c, CreatedDate, ContentDocumentId
      FROM ContentVersion
      WHERE ContentDocumentId IN :cdIds AND Title = :fileTitleWithName
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];

    if (!ver.isEmpty()) {
      String downloadUrl = getDownloadURL(ver[0].Id);
      if (downloadUrl != null) {
        url = downloadUrl;
      } else {
        ContentDistribution cd = new ContentDistribution();
        cd.ContentVersionId = ver[0].Id;
        cd.PreferencesAllowViewInBrowser = true;
        cd.Name = ver[0].Title;
        cd.PreferencesNotifyOnVisit = false;
        insert cd;

        url = getDownloadURL(ver[0].Id);
      }
      return url;
    } else {
      return null;
    }
  }

  /*
  *********************************************************
  @method Name    : getTableConfig
  @description    : used to get download URL
  @param          : cvId
  @return         : String
  ********************************************************
  */
  public static String getDownloadURL(Id cvId) {
    String url;
    List<ContentDistribution> contentDelivery = [
      SELECT Id, DistributionPublicUrl
      FROM ContentDistribution
      WHERE ContentVersionId = :cvId
      LIMIT 1
    ];
    url = (!contentDelivery.isEmpty() ? contentDelivery[0].DistributionPublicUrl : null);
    return url;
  }

  /*
    *********************************************************
    @method Name    : getErrorMessageFromMetadata
    @description    : used to get error message from custom metadata
    @param          : component
    @return         : String
    ********************************************************
    */
  @AuraEnabled
  public static String getErrorMessageFromMetadata(String component) {
    String errorString;
    try {
      DFD_Error_Messages__mdt mdt = DFD_Error_Messages__mdt.getInstance(
        component
      );
      errorString = mdt.Error_Message__c;
    } catch (Exception e) {
      new DFDFW_LOG_AllException().Module('My Application controller').Log(e);
    }
    return errorString;
  }
  // Wrapper class to hold both ContentDocumentLink and ContentVersion data
  public class FileDataWrapper {
    @AuraEnabled
    public ContentDocumentLink documentLink { get; set; }
    @AuraEnabled
    public ContentVersion contentVersion { get; set; }
    @AuraEnabled
    public string fileId { get; set; }
  }
}