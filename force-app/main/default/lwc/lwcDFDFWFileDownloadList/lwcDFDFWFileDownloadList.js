import { LightningElement, api, track, wire } from 'lwc';
import getFiles from "@salesforce/apex/DFDFW_APPFILE_DownloadController.getFiles";
import getIssuedPermitFiles from "@salesforce/apex/DFDFW_APPFILE_DownloadController.getIssuedPermitFiles";
import { NavigationMixin } from "lightning/navigation";

export default class LwcDFDFWFileDownloadList extends NavigationMixin(LightningElement) {
  @api recordId; // This will be passed from the community page
  @track files = [];
  @track data = [];
  //@track columns = [];
  @track issuedPermitFiles = [];
  showData = false;
  isIssuedPermitFilesOpen = true;  // Control if Issued Permit Files are open
  isApplicationFilesOpen = true;   // Control if Application Files are open
  @api fileCategory;
  @api title;
  @api fileType;
  //@track previewFileUrl = null;  // Store the preview URL for the file
  //@track isPreviewOpen = false;  // Control whether the preview is open


  // Icon states for toggling
  issuedPermitFilesIcon = 'utility:chevrondown'; // Initially open
  applicationFilesIcon = 'utility:chevrondown'; // Initially open

  // Column definition with row actions
  columns = [
    { label: "File Name", fieldName: "name", hideDefaultActions: true },
    { label: "File Category", fieldName: "fileCategory", hideDefaultActions: true },
    { label: "Document Date", fieldName: "documentDate", hideDefaultActions: true },
    {
      type: "action",
      typeAttributes: { rowActions: this.getRowActions }
    }
  ];
  // Column definition with row actions
  columns2 = [
    { label: "File Name", fieldName: "name", hideDefaultActions: true },
    { label: "", fieldName: "fileCategory", hideDefaultActions: true },
    { label: "Document Date", fieldName: "documentDate", hideDefaultActions: true },
    {
      type: "action",
      typeAttributes: { rowActions: this.getRowActions }
    }
  ];

  connectedCallback() {
    this.getFiles();
    this.getIssuedPermitFiles();
  }

  getFiles() {
    getFiles({ recordId: this.recordId })
      .then((data) => {
        if (data) {
          this.data = data.map(fileRecord => {
            // Get the CreatedDate and format it to MM/DD/YYYY with zero padding
            const createdDate = new Date(fileRecord.contentVersion.CreatedDate);
            const month = String(createdDate.getMonth() + 1).padStart(2, '0');
            const day = String(createdDate.getDate()).padStart(2, '0');
            const year = createdDate.getFullYear(); 
            const formattedDate = `${month}/${day}/${year}`; 
            return {
              fileId: fileRecord.contentVersion.ContentDocumentId,
              CONTENTVERSIONID: fileRecord.contentVersion.Id,
              name: fileRecord.contentVersion.Title,
              fileType: fileRecord.contentVersion.File_Type__c,
              fileCategory: fileRecord.contentVersion.File_Category__c,
              documentDate: formattedDate
            };
          });
          this.showData = true;
        }
      })
      .catch((err) => {
        console.error(err);
      });
  }

  // Fetching files with 'Issued Permit' category
  getIssuedPermitFiles() {
    getIssuedPermitFiles({ recordId: this.recordId })
      .then((data) => {
        if (data) {
          this.issuedPermitFiles = data.map(fileRecord => {
          // Get the CreatedDate and format it to MM/DD/YYYY with zero padding
          const createdDate = new Date(fileRecord.contentVersion.CreatedDate);
          const month = String(createdDate.getMonth() + 1).padStart(2, '0'); 
          const day = String(createdDate.getDate()).padStart(2, '0');
          const year = createdDate.getFullYear();
          const formattedDate = `${month}/${day}/${year}`;
          
          return {
            fileId: fileRecord.contentVersion.ContentDocumentId,
            CONTENTVERSIONID: fileRecord.contentVersion.Id,
            name: fileRecord.contentVersion.Title,
            fileType: fileRecord.contentVersion.File_Type__c,
            //fileCategory: fileRecord.contentVersion.File_Category__c,
            documentDate: formattedDate
          };
        });
      }
    })
    .catch((err) => {
      console.error(err);
    });
  }

  // Row action method to provide action options for each row
  getRowActions(row, doneCallback) {
    const actions = [
      { label: "Download", name: "download", iconName: "action:download" },
      //{ label: "View", name: "showPreview", iconName: "action:preview" }
    ];
    doneCallback(actions);
  }

  // Handle row actions
  handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;

    switch (actionName) {
      case "download":
        this.downloadFile(row);
        break;
      case "showPreview":
        this.showFilePreview(row);
        break;
      default:
        break;
    }
  }

  // Method to download the files
  downloadFile(row) {
    const url = `/permits/sfc/servlet.shepherd/document/download/${row.fileId}`;
    window.open(url, "_blank");
  }

  //Method to Preview the Files
  /*showFilePreview(row) {
    const contentVersionId = row.CONTENTVERSIONID;
   // let baseUrl = `${window.location.origin}/permits/s/contentdocument/${row.fileId}`;
   // window.open(baseUrl, "_blank");
    //SV
    let baseUrl=`${window.location.origin}/permits/s/contentdocument/${row.fileId}`;
    this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: baseUrl
                }
            }, false );


  }*/

  // Toggle for Issued Permit Files Section
  toggleIssuedPermitFiles() {
    this.isIssuedPermitFilesOpen = !this.isIssuedPermitFilesOpen;
    this.issuedPermitFilesIcon = this.isIssuedPermitFilesOpen ? 'utility:chevrondown' : 'utility:chevronright';
  }

  // Toggle for Application Files Section
  toggleApplicationFiles() {
    this.isApplicationFilesOpen = !this.isApplicationFilesOpen;
    this.applicationFilesIcon = this.isApplicationFilesOpen ? 'utility:chevrondown' : 'utility:chevronright';
  }
}