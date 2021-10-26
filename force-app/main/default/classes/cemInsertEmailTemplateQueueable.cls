public without sharing class cemInsertEmailTemplateQueueable implements Queueable{
    public String emailBody;
    public String subject;
    public id insertedTemplateID;
    public String userId;
    public String relatedTo;
    public String fromAddress;
    public String fromName;
    public String classification;
    public String deliveryOption;
    public List<string> toIds;
    public List<string> toAddress;
    public List<string> ccIds;
    public List<string> ccAddress;
    public List<id> attachmentID;
    
    public cemInsertEmailTemplateQueueable(string userId, string relatedTo, string fromAddress, string fromName, string subject, string emailBody, list<string> toIds, list<string> toAddress, list<string> ccIds, list<string> ccAddress, string classification, string deliveryOption, List<id> attachmentID){
        system.debug('attachmentID'+attachmentID);
        this.userId=userId;
        this.relatedTo=relatedTo;
        this.emailBody=emailBody;
        this.subject=subject;
        this.fromAddress=fromAddress;
        this.fromName=fromName;
        this.classification=classification;
        this.deliveryOption=deliveryOption;
        this.toIds=toIds;
        this.toAddress=toAddress;
        this.ccIds=ccIds;
        this.ccAddress=ccAddress;
        this.attachmentID=attachmentID;
    }
    
    public void execute(QueueableContext context) {
        List<Folder> folderName = [SELECT Id, Name, DeveloperName, Type FROM Folder where Type='Email' limit 1];
        Id folderId=folderName[0].id;
        String folName = folderName[0].Name;
        String Type = folderName[0].Type;
        system.debug('userId'+userId);
        
        EmailTemplate toInsertEmailTemplate = new EmailTemplate();
        List<EmailTemplate> emailTemplateList = [Select  Id, FolderId, HtmlValue, FolderName, isActive, body,Name,subject from EmailTemplate];
        if(emailTemplateList.size()>0){
            toInsertEmailTemplate=emailTemplateList[0];
            toInsertEmailTemplate.Body = emailBody;
            toInsertEmailTemplate.Subject = subject;                      
            update toInsertEmailTemplate;
        }
        else{
            toInsertEmailTemplate.Name = 'Test Email Template 1';
            toInsertEmailTemplate.Body = emailBody;
            toInsertEmailTemplate.Subject = subject;
            toInsertEmailTemplate.DeveloperName = 'a'+userId;
            toInsertEmailTemplate.FolderId=folderId;
            toInsertEmailTemplate.TemplateType = 'html';
            toInsertEmailTemplate.IsActive = true;
            system.debug('toInsertEmailTemplate'+toInsertEmailTemplate.Subject);
            insert toInsertEmailTemplate;
        }
        insertedTemplateID=toInsertEmailTemplate.Id;
        system.debug('insertedTemplateid'+toInsertEmailTemplate.id);
        if(!Test.isRunningTest()){
        System.enqueueJob(new cemSendEmailQueueable(userId, relatedTo, fromAddress, fromName, subject, emailBody, toIds, toAddress,  ccIds,  ccAddress,  classification,  deliveryOption, insertedTemplateID, attachmentID));
        }
    }    
}