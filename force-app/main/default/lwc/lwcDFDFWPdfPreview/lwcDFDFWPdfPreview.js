import { api, LightningElement, track } from 'lwc';
import getfileDetails from '@salesforce/apex/DFDFW_APPFILE_PDFPreviewController.getfileDetails';

export default class LwcDFDFWPdfPreview extends LightningElement {
    @api recordId;
    @api specialFileName;
    @api streetFileName;
    @api parkFileName;
    @track dataList = [];
    rowOffset = 0;

    @track columnsList = [
        {
            label: 'File Name',
            fieldName: 'Name', // Display 'Name' as the file name
        },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'Download', name: 'download', iconName: 'utility:download' }
                ]
            }
        }
    ];

    connectedCallback() {
        console.log(this.recordId);
        this.getFiles();
    }

    getFiles() {
        const fileNames = [this.specialFileName, this.streetFileName, this.parkFileName];
        console.log(fileNames);

        getfileDetails({ recordId: this.recordId, fileNames: fileNames })
            .then(result => {
                this.dataList = result;
                console.log(this.dataList);
            })
            .catch(error => {
                console.error(error);
            });
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'download') {
            // Pass both FileUrl, FileName and FileType to the downloadFile method
            console.log('row:'+JSON.stringify(row));

            this.downloadFile(row.FileUrl, row.Name, row.FileType, row.fileId);
        }
    }

    // Enhanced downloadFile method to append file type to the file name
    downloadFile(fileUrl, fileName, fileType, fileId) {
        // Append the file type (extension) to the file name (if it exists)
/*        const fileNameWithExtension = `${fileName}.${fileType.toLowerCase()}`;

        // Build the URL dynamically
        const downloadUrl = `/permits/sfc/servlet.shepherd/document/download/${fileId}`;

        const link = document.createElement('a');
        link.href = downloadUrl;  // Using the dynamic URL here
        
        // Set the file name for the download (with the file extension)
        link.download = fileNameWithExtension || 'file';  // Use file name with extension or default to 'file'

        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link); // Clean up*/
        console.log('fileUrl::'+fileUrl);
        const url = `/permits${fileUrl}`;
        window.open(url, "_blank");
    }

}