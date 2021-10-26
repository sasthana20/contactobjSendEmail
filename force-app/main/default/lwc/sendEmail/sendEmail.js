import { LightningElement, track, api, wire } from 'lwc';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import FRSOnly_Error from '@salesforce/label/c.FRSOnly_Error';

import getClassification from '@salesforce/apex/cemSendEmailController.getClassification';
import getDeliveryOptions from '@salesforce/apex/cemSendEmailController.getDeliveryOptions';

/** Apex methods from SendEmailController */
import getInitialSelection from '@salesforce/apex/cemSendEmailController.getInitialSelection';
import getCCSelection from '@salesforce/apex/cemSendEmailController.getCCSelection';
import getEmail from '@salesforce/apex/cemSendEmailController.getEmail';
import search from '@salesforce/apex/cemSendEmailController.search';
//import getRecentlyViewed from '@salesforce/apex/SendEmailController.getRecentlyViewed';
import UserPermissionsOfflineUser from '@salesforce/schema/User.UserPermissionsOfflineUser';
import sendEmail from '@salesforce/apex/cemSendEmailController.sendEmail';

import getUserDetails from '@salesforce/apex/cemSendEmailController.getUserDetails';
import GetEmailTemplates from '@salesforce/apex/cemSendEmailController.getEmailTemplates';
import GetRelatedAccounts from '@salesforce/apex/cemSendEmailController.getRelatedAccounts';
import USER_ID from '@salesforce/user/Id';
import IsDeleted from '@salesforce/schema/Account.IsDeleted';
import NamespacePrefix from '@salesforce/schema/RecordType.NamespacePrefix';

export default class SendEmail extends LightningElement {
    @api recordId;
    @api objectAPIName;
    @api responseType;

    label = {
        FRSOnly_Error
    }

    userId = USER_ID;

    // Use alerts instead of toasts (LEX only) to notify user
    @api notifyViaAlerts = false;

    isMultiEntry = true;
    maxSelectionSize = 10;
    initialSelection = [];
    ccSelection = [];

    selectedIds = [];

    errors = [];
    recentlyViewed = [];
    newRecordOptions = [];
//        { value: 'Contact', label: 'Contact' },
//        { value: 'Opportunity', label: 'New Opportunity' }
//    ];

    @track error;
    @track sender;
    @track userEmail;
    @track userName;

    toIds = [];
    toAddresses = [];
    ccIds = [];
    ccAddresses = [];

    @track cvalue = '';
    @track dvalue = '';
    @track subject = '';
    @track emailBody = '';

    @track showInsertTemplateComp = false;
    @track showInsertAttachmentComp = false;
    @track showPreviewEmail = false;
    @track showAttachedItem = false;
    columns = [
        { label: 'Name', fieldName: 'Name',sortable: true,cellAttributes: { alignment: 'left' }, },
        { label: 'Description', fieldName: 'Description' },
        { label: 'Template Folders', fieldName: 'FolderName' },
    ];
    @api attachedFileRecID;
    get acceptedFileItem() {
        return ['.pdf', '.png', '.pdf'];
    }    
    get emailTemplateoptions() {
        return [
                 { label: 'My Lightning Templates', value: 'myLightTemplates' },
                 { label: 'All Lightning Templates', value: 'allLightTemplates' },
                 { label: 'My Classic Templates', value: 'myClassicTemplates' },
               ];
    }
    @track dropDownValue='allLightTemplates';
    selectedEmailTemplate;
    chooseAccId = '';
    attachedFileName;
    attachedFileID;
    @track relatedtoid ='';

    coptions;
    doptions;

    handleClassificationChange(event) {
        this.cvalue = event.detail.value;
    }

    handleDOChange(event) {
        this.dvalue = event.detail.value;
    }


    @wire(getUserDetails, { recId: '$userId'})
    wiredUser({error, data}) {
        if (error) {
            this.error = error ; 
        }
        else if (data) {
console.log('***** get User record: ' + JSON.stringify(data));
            this.sender = data.Name + ' <' + data.Email + '>';
            this.userEmail = data.Email;
            this.userName = data.Name;
        }
    }

    @wire(getClassification)
    wiredClassification({error, data}) {
        if (error) {
console.log('***** error: ' + error);
            this.error = error;
        }
        if (data) {
console.log('***** classification options: ' + JSON.stringify(data));
            this.coptions = data;
        }
    }

    @wire(getDeliveryOptions)
    wiredDO({error, data}) {
        if (error) {
            this.error = error;
        }
        if (data) {
console.log('***** DO data: ' + JSON.stringify(data));
            this.doptions = data;
        }
    }

    /**
     * Loads recently viewed records and set them as default lookpup search results (optional)
     */
//    @wire(getRecentlyViewed)
//    getRecentlyViewed({ data }) {
//        if (data) {
//            this.recentlyViewed = data;
//            this.initLookupDefaultResults();
//        }
//    }


    @wire(getEmail, { recordId: '$recordId'})
    wiredEmail({error, data}) {
        if (error) {
            this.error = error ; 
        }
        else if (data) {
console.log('***** get Email record: ' + JSON.stringify(data));
//***** get Email record: {"htmlBody":"<div dir=\"ltr\"><div dir=\"ltr\">Response from gmail to Salesforce email service<br></div><br><div class=\"gmail_quote\"><blockquote class=\"gmail_quote\" style=\"margin:0px 0px 0px 0.8ex;border-left:1px solid rgb(204,204,204);padding-left:1ex\"><div dir=\"ltr\"><div class=\"gmail_quote\"><blockquote class=\"gmail_quote\" style=\"margin:0px 0px 0px 0.8ex;border-left:1px solid rgb(204,204,204);padding-left:1ex\"><div class=\"gmail_quote\"><div dir=\"ltr\" class=\"gmail_attr\">On Wed, May 19, 2021 at 1:21 AM User User &lt;<a href=\"mailto:basavaiahr21@gmail.com\" target=\"_blank\">basavaiahr21@gmail.com</a>&gt; wrote:<br></div><blockquote class=\"gmail_quote\" style=\"margin:0px 0px 0px 0.8ex;border-left:1px solid rgb(204,204,204);padding-left:1ex\">NONCONFIDENTIAL // EXTERNAL\n\n<p>Outbound from Custom Component</p></blockquote></div>\n</blockquote></div></div>\n</blockquote></div></div>","subject":"Re: 0BZo0000000KyjG Sandbox: Outbound from Custom Component"}
            this.subject = data.subject;
//              	cleanText = str.replace(/<\/?[^>]+(>|$)/g, "");
            this.emailBody = '<br /><br /><br />' + data.htmlBody;
        }
    }

    connectedCallback() {
        this.loadInitialSelection();
        console.log('this.cvalue',this.cvalue);
        console.log('this.dvalue',this.dvalue);
    }

    loadInitialSelection() {
console.log('***** Action Type: ' + this.responseType);
//sendEmail.js:4 Lookup error {"status":500,"body":{"message":"Insert failed. First exception on row 0; first error: CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY, EmailMessage_Trigger: execution of BeforeInsert\n\ncaused by: System.NullPointerException: Attempt to de-reference a null object\n\nTrigger.EmailMessage_Trigger: line 18, column 1: []"},"headers":{}}
        getInitialSelection({recordId: this.recordId})
        .then((results) => {
console.log('***** initial selection result: ' + JSON.stringify(results));
            this.initialSelection = results;

            this.toIds = [];
            this.toAddresses = [];
            this.initialSelection.forEach(element => {
                this.toIds.push(element.id);
                this.toAddresses.push(element.subtitle);
            });
        })
        .catch((error) => {
            console.error('Lookup error', JSON.stringify(error));
        });
console.log('***** initial selection result: ' + JSON.stringify(this.toAddresses));

        if (this.responseType === 'Forward') {

            this.initialSelection = [];
            this.toIds = [];
            this.toAddresses = [];
        }

        if (this.responseType === 'Reply All') {
            getCCSelection({recordId: this.recordId})
            .then((results) => {
                this.ccSelection = results;

                this.ccIds = [];
                this.ccAddresses = [];
                this.ccSelection.forEach(element => {
                    this.ccIds.push(element.id);
                    this.ccAddresses.push(element.subtitle);
                });
            })
            .catch((error) => {
                console.error('Lookup error', JSON.stringify(error));
            });
        }

    }

    /**
     * Initializes the lookup default results with a list of recently viewed records (optional)
     */
//    initLookupDefaultResults() {
        // Make sure that the lookup is present and if so, set its default results
//        const lookup = this.template.querySelector('c-lookup');
//        if (lookup) {
//            lookup.setDefaultResults(this.recentlyViewed);
//        }
//    }

    /**
     * Handles the lookup search event.
     * Calls the server to perform the search and returns the resuls to the lookup.
     * @param {event} event `search` event emmitted by the lookup
     */
    handleLookupSearch(event) {
        const lookupElement = event.target;
        // Call Apex endpoint to search for records and pass results to the lookup
console.log('***** search event: ' + JSON.stringify(event));
//***** search event: {"isTrusted":false,"composed":false,
//"detail":{"searchTerm":"user","lookupFor":"To","rawSearchTerm":"user",
//"selectedIds":["0033R0000020PaKQAU","0033R0000020Kj7QAE"]},
//"type":"search","target":{},"currentTarget":{},"eventPhase":2,"bubbles":false,"cancelable":false,"defaultPrevented":false,"timeStamp":198565.9700000033,"srcElement":{},"returnValue":true,"cancelBubble":false,"path":[{},{},{},{}],"NONE":0,"CAPTURING_PHASE":1,"AT_TARGET":2,"BUBBLING_PHASE":3}

        this.selectedIds = [];
        (this.template.querySelectorAll('.lookup')).forEach(element => {
            console.log('Lookup type: ' + element.dataset.lookup);
            const tempIds = element.getSelection().map((sel) => sel.id);
            tempIds.forEach(itemId => {
                this.selectedIds.push(itemId);
            })
        });
        console.log('Selection: ' + this.selectedIds);

        search({"searchTerm": event.detail.searchTerm, "selectedIds": this.selectedIds})
            .then((results) => {
                (this.template.querySelectorAll('.lookup')).forEach(element => {
                    if (element.dataset.lookup == event.detail.lookupFor) {
                        element.setSearchResults(results);
                    }
                });
//                lookupElement.setSearchResults(results);
            })
            .catch((error) => {
                this.notifyUser('Lookup Error', 'An error occured while searching with the lookup field.', 'error');
                // eslint-disable-next-line no-console
                console.error('Lookup error', JSON.stringify(error));
                this.errors = [error];
            });
    }

    /**
     * Handles the lookup selection change
     * @param {event} event `selectionchange` event emmitted by the lookup.
     * The event contains the list of selected ids.
     */
    // eslint-disable-next-line no-unused-vars
    handleLookupSelectionChange(event) {
        this.checkForErrors();
//        const selection = this.template.querySelector('c-lookup').getSelection();
//console.log('***** Selection: ' + JSON.stringify(selection));

//[{"icon":"standard:contact","id":"0033R0000020HtXQAU","sObjectType":"Contact","subtitle":"joesmith@sforce.com","title":"Joe Smith","titleFormatted":"<strong>Jo</strong>e Smith","subtitleFormatted":"<strong>jo</strong>esmith@sforce.com"},{"icon":"standard:contact","id":"0033R0000020HtSQAU","sObjectType":"Contact","subtitle":"jondoe@sforce.com","title":"Jon Doe","titleFormatted":"<strong>Jo</strong>n Doe","subtitleFormatted":"<strong>jo</strong>ndoe@sforce.com"},{"icon":"standard:user","id":"0053R000000KNoFQAW","sObjectType":"User","subtitle":"basavaiahr21@gmail.com","title":"User User","titleFormatted":"<strong>User</strong> <strong>User</strong>","subtitleFormatted":"basavaiahr21@gmail.com"}]

        if (event.detail.lookupFor === 'To') {

            if (selection.length > 0) {
                this.toIds = [];
                this.toAddresses = [];
                selection.forEach(element => {
                    this.toIds.push(element.id);
                    this.toAddresses.push(element.subtitle);
                });
console.log(JSON.stringify(this.toIds) + ' === ' + JSON.stringify(this.toAddresses));
            }
        }

        if (event.detail.lookupFor === 'CC') {

            if (selection.length > 0) {
                this.ccIds = [];
                this.ccAddresses = [];
                selection.forEach(element => {
                    this.ccIds.push(element.id);
                    this.ccAddresses.push(element.subtitle);
                });
console.log(JSON.stringify(this.ccIds) + ' === ' + JSON.stringify(this.ccAddresses));
            }
        }
    }


    handleLookupTypeChange(event) {
        this.initialSelection = [];
        this.errors = [];
        this.isMultiEntry = event.target.checked;
    }

    handleMaxSelectionSizeChange(event) {
        this.maxSelectionSize = event.target.value;
    }

    handleSubjectChange(event) {
console.log('***** subject: ' + event);
        this.subject = event.detail.value;
    }

    handleBodyChange(event) {
console.log('***** email Body: ' + event);
        this.emailBody = event.target.value;
    }

    handleAddTemplate(event) {
        console.log('***** handleAddTemplateClicked: ' + event);        
        this.showInsertTemplateComp = true;
        this.getEmailTemplates();
    }

    handleShowPreview(event) {
        console.log('***** handleAddTemplateClicked: ' + event);        
        this.showPreviewEmail = true;
    }

    handleAddAttachment(event) {
        console.log('***** handleAddTemplateClicked: ' + event);        
        this.showInsertAttachmentComp = true;
    }

    handleDeleteAttachment(event) {
        console.log('***** handleDeleteAttachment: ' + event);        
        this.showAttachedItem = false;
    }

    handleRelatedTo(event) {
        console.log('***** handleRelatedTo: ' + event);
        this.chooseAccId = event.detail.value;
        console.log('this.chooseAccId: ' + this.chooseAccId);
    }

    handlelookupselect(event){
        this.relatedtoid = event.detail;
    }

    handleClearError(event){
        this.errors = '';
    }

    customHideModalPopup() {           
        this.showInsertTemplateComp = false;
        this.showInsertAttachmentComp = false;
        this.showPreviewEmail = false;
    }

    templateData = [];
    getEmailTemplates(){
        console.log('In getEmailTemplates');
        GetEmailTemplates({filterValue: this.dropDownValue})
            .then(data =>{
                console.log('data in getEmailTemplates',data);
                this.templateData = data.map(i => ({
                    Id: i.Id,
                    Name: i.Name,
                    FolderName: i.FolderName,
                    Description: i.Description,
                    Subject: i.Subject,
                    Body: i.Body,
                }));
            })
            
            .catch(error =>{
                console.log('error getting Existing Email Templates Data:', JSON.stringify(error, null, 2));
            });
    }

    uploadFiledAction(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files[0];
        console.log('uploadedFiles',uploadedFiles.documentId)
        this.attachedFileName=uploadedFiles.name;
        this.attachedFileID=uploadedFiles.documentId;
        console.log('this.attachedFileID',this.attachedFileID);
       // alert("No. of files uploaded : " + uploadedFiles.length);
        const toastEvent = new ShowToastEvent({
            title:'Files uploaded successfully',
            message:'No. of files uploaded ' + uploadedFiles.length,
            variant:'success',
        })
        this.dispatchEvent(toastEvent);
        this.showInsertAttachmentComp = false;
        this.showAttachedItem = true;
    }

    handleChangeTemplateDropdown(event) {
        this.dropDownValue = event.detail.value;
        console.log('Email Template DD Value',this.dropDownValue);
        this.getEmailTemplates();
    }

    handleEmailTemplateSelect(event) {
        this.selectedEmailTemplate = event.currentTarget.dataset.recid;
        console.log('Selected Email Template',this.selectedEmailTemplate);
        let Subject = event.currentTarget.dataset.subject;
        this.subject=Subject;
        console.log('Selected Email Subject',Subject);
        let Body = event.currentTarget.dataset.body;
        this.emailBody=Body;
        console.log('Selected Email Body',Body);
        this.showInsertTemplateComp = false;

    }

    handleClearEmail(event){
        console.log('clear Email Clicked',event.detail.value);
        this.subject='';
        this.emailBody='';
        this.toIds='', 
        this.toAddresses='';
        this.ccIds='';
        this.ccAddresses='', 
        this.cvalue=''
        this.dvalue=''; 
        this.showInsertAttachmentComp = false;       
    }

    accountOptions = [];
     @wire(GetRelatedAccounts)
     wiredGetRelatedAccounts({data, error}) {
         if (error) {
             console.log('wiredGetRelatedAccounts error:', JSON.stringify(error, null, 2));
         } else if (data) {
             console.log('Accounts data',data)
             this.accountOptions = data.map(i => ({
                     label: i.Name,
                     value: i.Id,
                 })
                 ).sort((a,b)=>{ return (a.label.toLowerCase()<b.label.toLowerCase()) ? -1 : (a.label.toLowerCase()>b.label.toLowerCase()) ? 1 : 0 });
         }
     }  

    handleSubmit() {
        this.checkForErrors();
        if (this.errors.length === 0) {
/*
console.log('***** To ids: ' + this.toIds);
console.log('***** To addresses: ' + this.toAddresses);
console.log('***** Subject: ' + this.subject);
console.log('***** Classification: ' + this.cvalue);
console.log('***** Delivery Option: ' + this.dvalue);
console.log('***** Body: ' + this.emailBody);
*/

        //sendEmail(string userId,      string relatedTo,           string fromAddress,         string fromName,        string subject,         string emailBody,       list<string> toIds, list<string> toAddress,         string classification,      string deliveryOption) {
        console.log('this.attachedFileID before sendEmail',this.attachedFileID);
        sendEmail({userId: this.userId, relatedTo: this.recordId, fromAddress: this.userEmail, fromName: this.userName, subject: this.subject, emailBody: this.emailBody, toIds: this.toIds, toAddress: this.toAddresses, ccIds: this.ccIds, ccAddress: this.ccAddresses, classification: this.cvalue, deliveryOption: this.dvalue, attachmentID:this.attachedFileID})
            .then((result) => {
                this.notifyUser('Success', 'Email sent successfully', 'success');
                this.handleClear();
            })
            .catch((error) => {
//Lookup error {"status":500,"body":{"message":"Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Email includes outside addresses and defined as FRSOnly: []"},"headers":{}}
console.log('***** error: ' + JSON.stringify(error.body.message));

                const errMsg = error.body.message;
                if (errMsg.indexOf(this.label.FRSOnly_Error) > 0)
                    this.notifyUser('Send Email Error', this.label.FRSOnly_Error, 'error');
                else
                    this.notifyUser('Send Email Error', 'An error occured while sending email.', 'error');

                // eslint-disable-next-line no-console
                this.errors = [error];
            })
            .finally(() =>{ 
                const closeQA = new CustomEvent('close');
                this.dispatchEvent(closeQA);
            });
        }
        else{

        }
    }

    handleClear() {
//        this.initialSelection = [];
        this.loadInitialSelection();
        this.subject = '';
        this.emailBody = '';
        this.cvalue = '';
        this.dvalue = '';
        this.errors = [];
        this.showAttachedItem = false; 
    }

    checkForErrors() {
        this.errors = '';
        const selection = this.template.querySelector('c-lookup').getSelection();
        // Custom validation rule
        if (this.isMultiEntry && selection.length > this.maxSelectionSize) {
            this.errors = `You may only select up to ${this.maxSelectionSize} items.`;
        }
        // Enforcing required field
        if (selection.length === 0) {
            this.errors = 'Please make a selection.';
        }

        if (this.cvalue == null || this.cvalue == '') {
            this.errors = 'Please select Classification.';
        }

        if (this.dvalue == null || this.dvalue == '') {
            this.errors = 'Please select Delivery Option.';
        }
    }

    notifyUser(title, message, variant) {
        if (this.notifyViaAlerts) {
            // Notify via alert
            // eslint-disable-next-line no-alert
            alert(`${title}\n${message}`);
        } else {
            // Notify via toast (only works in LEX)
            const toastEvent = new ShowToastEvent({ title, message, variant });
            this.dispatchEvent(toastEvent);
        }
    }
}