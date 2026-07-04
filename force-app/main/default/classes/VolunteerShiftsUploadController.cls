public  with sharing class VolunteerShiftsUploadController {

    
    @AuraEnabled
    public static ShiftUploadResult parseCSVFromContentVersion(String contentVersionId,string accountId,string campaignId,string userId,string contactId,string initials,string parnetcampaignId, string disasterEvent,Decimal totalHours,Decimal totalAttendees, Boolean isFileCSV) {
        system.debug('MB, contentVersionId:'+contentVersionId);
           ShiftUploadResult result = new ShiftUploadResult();
           Volunteer_Shift_Report__c vsr;
       try{
        ContentVersion cv = [
            SELECT Id, ContentDocumentId,VersionData
            FROM ContentVersion
            WHERE Id = :contentVersionId
            LIMIT 1
        ];
         List<String> lines = new list<String>();
       
        if(isFileCSV==true){
        String csvContent = cv.VersionData.toString();
      lines = csvContent.split('\n');

        if (lines.size() < 2) {
            throw new AuraHandledException('CSV has no data rows.');
           
        }
        system.debug('parnetcampaignId'+parnetcampaignId+' disasterEvent'+disasterEvent);
       }
         vsr= new Volunteer_Shift_Report__c(
            Account__c= accountId,
            Campaign__c=campaignId,
            Status__c='Submitted',
            Submitted_By__c=contactId,
            OwnerId=userId,
            Submission_Date__c=DateTime.now(),
            Submitter_Initials__c=initials,
            Parent_Campaign__c=parnetcampaignId,
            Disaster_Event__c=disasterEvent
          //  Total_Attendance__c=totalAttendees,
            //Total_Hours__c=totalHours

        );
        insert vsr;
         ContentDocumentLink cdl = new ContentDocumentLink();
    cdl.ContentDocumentId = cv.ContentDocumentId;
    cdl.LinkedEntityId = vsr.Id; // Link to Volunteer_Shift_Report__c record
    cdl.ShareType = 'V'; // Viewer permission
    cdl.Visibility = 'AllUsers'; // Or 'InternalUsers' / 'SharedUsers'

    insert cdl;

  if(isFileCSV==true){
        List<String> headers = lines[0].replaceAll('"', '').split(',');
        List<Volunteer_Shift_Attendance__c> recordsToInsert = new List<Volunteer_Shift_Attendance__c>();
        
        for (Integer i = 1; i < lines.size(); i++) {
            String line = lines[i].replaceAll('"', '');
            if (String.isBlank(line)) continue;

            String[] values = line.split(',');
            Volunteer_Shift_Attendance__c report = new Volunteer_Shift_Attendance__c();
            
            report.Volunteer_Name__c = values[0];
            
            report.Volunteer_Shift_Report__c=vsr.Id;
            
            report.Date_In__c = date.parse(values[1]);
            
            report.Account__c=accountId;
            
            report.Campaign__c=campaignId;
            
            String str = values[2];
            Boolean is12HrFormat = false;
            if(str.contains('AM')){
                str = str.subStringBefore(' ');
            }
            if(str.contains('PM')){
                is12HrFormat = true;
                str = str.subStringBefore(' ');
            }
            String[] strTimeSplit = str.split(':');
            Integer hour = Integer.valueOf(strTimeSplit[0]);
            Integer min = Integer.valueOf(strTimeSplit[1]);
            if(is12HrFormat && hour != 12){
                hour = hour + 12;
            }
            report.Time_In__c =  Time.newInstance(hour,min, 0, 0);
            
            report.Date_Out__c = date.parse(values[3]);

            str = values[4];
            if(str.contains('AM')){
                str = str.subStringBefore(' ');
            }
            if(str.contains('PM')){
                is12HrFormat = true;
                str = str.subStringBefore(' ');
            }
            strTimeSplit = str.split(':');
            hour = Integer.valueOf(strTimeSplit[0]);
            min = Integer.valueOf(strTimeSplit[1]);
            if(is12HrFormat && hour != 12){
                hour = hour + 12;
            }
            report.Time_Out__c =  Time.newInstance(hour, min, 0, 0);
            
            report.Actiivity__c = values[5];
            
            report.Category__c = values[6];
            
            report.Agency_Organization__c = values[7];

            recordsToInsert.add(report);
        }
        system.debug('MB, recordsToInsert:'+recordsToInsert);
        insert recordsToInsert;
        
  }else{
      Volunteer_Shift_Attendance__c attendance = new Volunteer_Shift_Attendance__c(
        Agency_Organization__c='Unsupported Import file',
        Category__c='Unsupported Import file',
        Actiivity__c='Unsupported Import file',
        Account__c=accountId,
            Campaign__c=campaignId,
            Volunteer_Name__c = 'Unsupported Import file',
            Volunteer_Shift_Report__c=vsr.Id,
           Hours__c=totalHours,
           Attendees__c=totalAttendees
      );
      insert attendance;
      
  }
  result.isSuccess = true;
        result.shiftReportId = vsr.Id;
    } catch (Exception ex) {
         if(vsr != null && vsr.Id != null) {
            try {
                delete vsr;
            } catch(Exception deleteEx) {
                System.debug('Error deleting VSR record after exception: ' + deleteEx.getMessage());
            }
        }
        result.isSuccess = false;
        result.errorMessage = ex.getMessage();
    }

    return result;
    }

    @AuraEnabled(cacheable=true)
    public static UserDetailsWrapper getUserDetails(string userId){
         UserDetailsWrapper details = new UserDetailsWrapper();

        User u =[select Id,Email,Name,contact.MobilePhone,contact.AccountID,contactId,contact.name from user where Id =:userId];
        Id accId=u.contact.AccountID;
        
        list<CampaignMember> Camp =[SELECT Id,Campaign.name,CampaignId,Campaign.ParentId FROM CampaignMember  where AccountId =: accId ];
        for(CampaignMember cm:Camp){
            System.debug('logLevel'+ cm);
            If (cm.Campaign.ParentId !=null){
                details.campaignId=cm.CampaignId ;
                details.disasterEvent=cm.Campaign.name;
            }else if (cm.Campaign.ParentId==null){
                details.parnetcampaignId=cm.CampaignId ;
            }
        }    
        details.submissionDate=System.today();
        details.submittedBy=u.contact.Name;
        details.phone=u.contact.MobilePhone;
        details.email=u.Email;
        details.accountId=accId;
        details.contactId=u.contactId;
        return details;
    }

    public class UserDetailsWrapper {
        @AuraEnabled public String disasterEvent;
        @AuraEnabled public Date submissionDate;
        @AuraEnabled public String submittedBy;
        @AuraEnabled public String phone;
        @AuraEnabled public String email;
        @AuraEnabled public String accountId;
        @AuraEnabled public String campaignId;
        @AuraEnabled public String contactId;
         @AuraEnabled public String parnetcampaignId;
    }

    public class ShiftUploadResult {
    @AuraEnabled public Boolean isSuccess ;
    @AuraEnabled public String errorMessage ;
    @AuraEnabled public String shiftReportId;
}
}