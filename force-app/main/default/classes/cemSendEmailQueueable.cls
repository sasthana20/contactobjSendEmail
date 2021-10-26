public without sharing class cemSendEmailQueueable implements Queueable{
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
    
    public cemSendEmailQueueable(string userId, string relatedTo, string fromAddress, string fromName, string subject, string emailBody, list<string> toIds, list<string> toAddress, list<string> ccIds, list<string> ccAddress, string classification, string deliveryOption, Id insertedTemplateID,List<ID> attachmentID){
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
        this.insertedTemplateID=insertedTemplateID;
        this.attachmentID=attachmentID;
    }
    
    public void execute(QueueableContext context) {
        try {  
            system.debug('attach Debugs attachmentID'+attachmentID);
            List<Messaging.Emailfileattachment> efaList = new List<Messaging.Emailfileattachment>();
            if(attachmentID != NULL){   
                Map<String,Blob> blobMap = new Map<String,Blob>();
                List<Blob> blobList = new List<Blob>();
                for(contentversion cvList : ([SELECT title,PathOnClient, FileType,versiondata 
                                             FROM contentversion 
                                             WHERE ContentDocumentId = :attachmentID])){
                                                 system.debug('attach Debugs cvList'+cvList);
                                                 Messaging.Emailfileattachment singleEFA = new Messaging.Emailfileattachment();
                                                 Blob data = cvList.VersionData;
                                                 singleEFA.setBody(Data);
                                                 singleEFA.setFileName(cvList.Title);
                                                 efaList.add(singleEFA);
                                             }
                
                              
                system.debug('attach Debugs efaList'+efaList);
                
            }
            
            
            emailBody = classification + ' // ' + deliveryOption + '\n\n' + emailBody;

            if (!relatedTo.startsWith(('003'))) {
                relatedTo = null;
                list<Contact> tempContacts = [SELECT Id FROM Contact WHERE Id = :toIds limit 1];
                if (!tempContacts.isEmpty())
                    relatedTo = tempContacts[0].Id;
            }

            list<Contact> contacts = [SELECT Id, AccountId FROM Contact WHERE Id = :relatedTo limit 1];
            
            // if EnhancedEmail Perm is enabled, create an EmailMessage object
            EmailMessage emailMessage = new EmailMessage();
            if (!contacts.isEmpty())
                emailMessage.relatedToId = contacts[0].AccountId; //Account Id from contact
            emailMessage.status = '3'; // 0 - New, 3 - email was sent
            emailMessage.fromAddress = fromAddress;
            emailMessage.fromName = fromName;
            emailMessage.subject = subject;
            emailMessage.Classification__c = classification;
            emailMessage.Delivery_Option__c = deliveryOption;
            emailMessage.htmlBody = emailBody;
            emailmessage.incoming = false;
            // Contact, Lead or User Ids of recipients
            if (ccIds != null)
                toIds.addAll(ccIds);

            //emailMessage.toIds = toIds;
            // additional recipients who don’t have a corresponding contact, lead or user id in the Salesforce org (optional)
            string toemails = toAddress.toString().replace('(', '').replace(')', '');
            system.debug('***** to address: ' + toemails);
            Set<String> toSetAddress = new Set<String>();
            toSetAddress.add('toAddress');
            emailMessage.toAddress = toemails; //Set toAddress Only if the email address are not associated with Contact, Lead or User
            system.debug('Inserting emailMessage'+emailMessage);
            insert emailMessage; // insert

            //Please refer this thread for EmailMessage and Relation record creation process
            //https://trailblazers.salesforce.com/answers?id=9063A000000pIAKQA2

            // Add Email Message Relation for id of the sender
            if (relatedTo != null) {
                EmailMessageRelation emr = new EmailMessageRelation();
                emr.emailMessageId = emailMessage.id;
                emr.relationId = relatedTo;
                emr.relationType = 'ToAddress';
                insert emr;
            }

            //Email not going out after inserting EmailMessage and Relation object. Sending email using SingleEmailMessage.

            //setTargetObjectId will send email. If the same contact's email is also included in ToAddresses, the contact will get two emails
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(toAddress);
            if (ccAddress != null)
                email.setCcAddresses(ccAddress);
            email.setSenderDisplayName(fromName);
            email.setReplyTo(fromAddress);
            email.setTemplateid(insertedTemplateID);
            email.settargetObjectId(relatedTo);
            if(attachmentID != NULL)
                email.setFileAttachments(efaList);
            //email.setSubject(emailTemplate[0].Subject);
            //email.setHtmlBody(templateBody);
            system.debug('email at 312'+email);
            String emailhtmlBody=email.getSubject();
            system.debug('emailSubject'+emailhtmlBody);

            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {email};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
            if (results[0].success) {
                System.debug('Email sent successfully.');
            }
            else {
                System.debug('Email failed: ' + results[0].errors[0].message + ' \nPlease contact your administrator.');
                throw new AuraHandledException(results[0].errors[0].message);
            }

        }
        catch (Exception e) {
            system.debug('exception in SendEmail'+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }    
}