public with sharing class cemSendEmailController {
    private final static Integer MAX_RESULTS = 5;
    public static ID loggedInUserID = UserInfo.getUserID();
    public static id insertedTemplateID;
    public static String emailBodyUI;
    public static String emailSubjectUI;

    @AuraEnabled(cacheable=true)
    public static list<PicklistOptions> getClassification(){
        list<PicklistOptions> options = new list<PicklistOptions>();

        try { 
            Schema.DescribeFieldResult F = EmailMessage.Classification__c.getDescribe();
            Schema.sObjectField T = F.getSObjectField();
            List<PicklistEntry> entries = T.getDescribe().getPicklistValues();

            for (PicklistEntry pe : entries) {
                options.add(new PicklistOptions(pe.getLabel(), pe.getValue()));
            }

        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return options;
    }


    @AuraEnabled(cacheable=true)
    public static list<PicklistOptions> getDeliveryOptions() {
        list<PicklistOptions> options = new list<PicklistOptions>();

        try {
            Schema.DescribeFieldResult F = EmailMessage.Delivery_Option__c.getDescribe();
            Schema.sObjectField T = F.getSObjectField();
            List<PicklistEntry> entries = T.getDescribe().getPicklistValues();

            for (PicklistEntry pe : entries) {
                options.add(new PicklistOptions(pe.getLabel(), pe.getValue()));
            }
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return options;
    }


    @AuraEnabled(cacheable=true)
    public static list<LookupSearchResult> getInitialSelection(string recordId) {
        List<LookupSearchResult> results = new List<LookupSearchResult>();
        system.debug('***** initial selection record Id: ' + recordId);

        //Contact object
        if (recordId.startsWith('003')) {
            // Extract Contact & convert them into LookupSearchResult
            String conIcon = 'standard:contact';
            for (Contact con : [SELECT Id, Name, Email FROM Contact WHERE Id = :recordId AND Email != null]) {
                results.add(new LookupSearchResult(con.Id, 'Contact', conIcon, con.Name, con.Email));
            }
        }

        //EmailMessage object
        if (recordId.startsWith('02s')) {
            // Extract Contacts using EmailMessage FromAddress & CCAddress and convert them into LookupSearchResult
            String conIcon = 'standard:contact';
            EmailMessage em = [SELECT Id, FromAddress, CCAddress FROM EmailMessage WHERE Id = :recordId];
            string toEmail = '';
            list<string> ccEmails = new list<string>();
            if (em != null) {
                toEmail = em.FromAddress;
            }

            for (Contact con : [SELECT Id, Name, Email FROM Contact WHERE Email = :toEmail]) {
                results.add(new LookupSearchResult(con.Id, 'Contact', conIcon, con.Name, con.Email));
            }

            boolean found = false;
            for (LookupSearchResult l:results) {
                if (toEmail == l.subtitle) {
                    found = true;
                }
            }
            if (!found) {
                results.add(new LookupSearchResult(null, 'Contact', conIcon, toEmail, toEmail));
            }

        }
        system.debug('***** initial selection results: ' + results);

        return results;
    }


    @AuraEnabled(cacheable=true)
    public static list<LookupSearchResult> getCCSelection(string recordId) {
        List<LookupSearchResult> results = new List<LookupSearchResult>();
system.debug('***** initial selection record Id: ' + recordId);

        //EmailMessage object
        if (recordId.startsWith('02s')) {
            // Extract Contacts using EmailMessage FromAddress & CCAddress and convert them into LookupSearchResult
            String conIcon = 'standard:contact';
            EmailMessage em = [SELECT Id, FromAddress, CCAddress FROM EmailMessage WHERE Id = :recordId];
            list<string> ccEmails = new list<string>();
            if (em != null) {
                if (em.CCAddress != null)
                    ccEmails = em.CCAddress.split(',');
            }

            list<Contact> cc = [SELECT Id, Name, Email FROM Contact WHERE Email = :ccEmails];
            for (Contact con : cc) {
                results.add(new LookupSearchResult(con.Id, 'Contact', conIcon, con.Name, con.Email));
            }

            for (string email:ccEmails) {
                boolean found = false;
                for (LookupSearchResult l:results) {
                    if (email == l.subtitle) {
                        found = true;
                    }
                }
                if (!found) {
                    results.add(new LookupSearchResult(null, 'Contact', conIcon, email, email));
                }
            }
        }
system.debug('***** initial selection CC results: ' + results);

        return results;
    }


    @AuraEnabled(cacheable=true)
    public static LoadEmail getEmail(string recordId) {
        LoadEmail result = null;

system.debug('***** getEmail record Id: ' + recordId);

        //EmailMessage object
        if (recordId.startsWith('02s')) {
            // Extract Contacts using EmailMessage FromAddress & CCAddress and convert them into LookupSearchResult
            EmailMessage em = [SELECT Id, Subject, HtmlBody, Classification__c, Delivery_Option__c FROM EmailMessage WHERE Id = :recordId];

            result = new LoadEmail(em.Subject, em.HtmlBody);
        }
system.debug('***** Email record: ' + result);

        return result;
    }


    @AuraEnabled(Cacheable=true)
    public static List<LookupSearchResult> search(String searchTerm, List<String> selectedIds) {
        // Prepare query paramters
        searchTerm += '*';
system.debug('***** search Term: ' + searchTerm + ' ==== selectedIds: ' + selectedIds);

        // Execute search query
        List<List<SObject>> searchResults = [
            FIND :searchTerm
            IN ALL FIELDS
            RETURNING
                Contact(Id, Name, Email WHERE id NOT IN :selectedIds),
                User(Id, Name, Email WHERE id NOT IN :selectedIds)
            LIMIT :MAX_RESULTS
        ];

        // Prepare results
        List<LookupSearchResult> results = new List<LookupSearchResult>();

        // Extract Contact & convert them into LookupSearchResult
        String conIcon = 'standard:contact';
        Contact[] contacts = (List<Contact>) searchResults[0];
        for (Contact con : contacts) {
            results.add(new LookupSearchResult(con.Id, 'Contact', conIcon, con.Name, con.Email));
        }

        // Extract User & convert them into LookupSearchResult
        String userIcon = 'standard:user';
        User[] users = (List<User>) searchResults[1];
        for (User u : users) {
            results.add(
                new LookupSearchResult(
                    u.Id,
                    'User',
                    userIcon,
                    u.Name,
                    u.Email
                )
            );
        }

        // Optionnaly sort all results on title
        results.sort();

        return results;
    }


    @AuraEnabled(cacheable=true)
    public static User getUserDetails(String recId) {
        return [SELECT Id, Name, Email FROM User WHERE Id = :recId];
    }

/*
    @AuraEnabled(Cacheable=true)
    public static List<LookupSearchResult> getRecentlyViewed() {
        List<LookupSearchResult> results = new List<LookupSearchResult>();
        // Get recently viewed records of type Contact or User
        List<RecentlyViewed> recentRecords = [
            SELECT Id, Name, Email, Type 
            FROM RecentlyViewed
             WHERE Type = 'Contact' OR Type = 'User'
            ORDER BY LastViewedDate DESC
            LIMIT 5
        ];
        // Convert recent records into LookupSearchResult
        for (RecentlyViewed recentRecord : recentRecords) {
            if (recentRecord.Type == 'Contact') {
                results.add(
                    new LookupSearchResult(
                        recentRecord.Id,
                        'Contact',
                        'standard:contact',
                        recentRecord.Name,
                        recentRecord.Email
                    )
                );
            }
            else {
                results.add(
                    new LookupSearchResult(
                        recentRecord.Id,
                        'User',
                        'standard:user',
                        recentRecord.Name,
                        recentRecord.Email
                    )
                );
            }
        }
        return results;
    }
*/

    @AuraEnabled
    public static void sendEmail(string userId, string relatedTo, string fromAddress, string fromName, string subject, string emailBody, list<string> toIds, list<string> toAddress, list<string> ccIds, list<string> ccAddress, string classification, string deliveryOption,List<Id> attachmentID) {
        system.debug('attachmentID'+attachmentID);
        system.debug('@@EmailBody'+emailBody);
        emailBody = classification + ' // ' + deliveryOption + '\n\n' + emailBody;
        //emailBody = classification + '\n' + emailBody ;
        //emailBody = deliveryOption + '\n' + emailBody;
        emailBody.replace('<p>', '');
        emailBody.replace('</p>', '');
        List<Id> lstAttachment = new List<Id>();
        //lstAttachment.add(attachmentID);


        // Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        // email.setToAddresses(new List<String>{'abhijeet.salesforce1@gmail.com'});                 
        // email.settargetObjectId('0035f0000042novAAA');
        // email.setSubject('Testing');
        // email.setHtmlBody(emailBody);      
        // String emailhtmlBody=email.getSubject();
        // system.debug('emailSubject'+emailhtmlBody);

        // Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {email};
        // Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

           System.enqueueJob(new cemInsertEmailTemplateQueueable(userId, relatedTo, fromAddress, fromName, subject, emailBody, toIds, toAddress,  ccIds,  ccAddress,  classification,  deliveryOption,attachmentID));
        
        /*try {
            
			
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
            emailMessage.toAddress = 'a_young@yopmail.com'; //Set toAddress Only if the email address are not associated with Contact, Lead or User
            system.debug('Inserting emailMessage'+emailMessage);
            //insert emailMessage; // insert

			//Please refer this thread for EmailMessage and Relation record creation process
			//https://trailblazers.salesforce.com/answers?id=9063A000000pIAKQA2

            // Add Email Message Relation for id of the sender
            if (relatedTo != null) {
                EmailMessageRelation emr = new EmailMessageRelation();
                emr.emailMessageId = emailMessage.id;
                emr.relationId = relatedTo;
                emr.relationType = 'ToAddress';
                //insert emr;
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
            email.settargetObjectId('0035f0000042novAAA');
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
            throw new AuraHandledException(e.getMessage());
        }*/
    }
    
    public class PicklistOptions {
        @AuraEnabled
        public string label {get; set;}
        @AuraEnabled
        public string value {get; set;}

        public PicklistOptions(string label, string value) {
            this.label = label;
            this.value = value;
        }
    }

    public class LoadEmail {
        @AuraEnabled
        public string subject {get; set;}
        @AuraEnabled
        public string htmlBody {get; set;}

        public LoadEmail(string sub, string body) {
            this.subject = sub;
            this.htmlBody = body;
        }
    }
    
    

    @AuraEnabled
    public static List<EmailTemplate> getEmailTemplates(String filterValue){
        system.debug('filterValue'+filterValue);
        List<EmailTemplate> emailTemplateList = new List<EmailTemplate>();
        if(filterValue=='myLightTemplates'){
            emailTemplateList=[Select Id,Body,Subject,HtmlValue,Name,FolderName,Description,UiType from EmailTemplate where UiType='SFX' AND OwnerId=:loggedInUserID];
        }
        if(filterValue=='allLightTemplates'){
            emailTemplateList=[Select Id,Body,Subject,HtmlValue,Name,FolderName,Description,UiType from EmailTemplate where UiType='SFX'];
        }
        if(filterValue=='myClassicTemplates'){
            emailTemplateList=[Select Id,Body,Subject,HtmlValue,Name,FolderName,Description,UiType from EmailTemplate where UiType='Aloha' AND OwnerId=:loggedInUserID];
        }
        System.debug('emailTemplateList '+emailTemplateList[0].HtmlValue);
        return emailTemplateList;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Account> getRelatedAccounts(){
        return [Select id,Name from Account limit 100];
    }  
    
    @AuraEnabled
    public static void deleteAttachment(id attachmentID){
        ContentDocument deletDocument = new ContentDocument(id=attachmentID);
        delete deletDocument;
    } 
    
    @AuraEnabled(cacheable=true)
    public static List<sObject> search1(String searchTerm, string myObject, String filter) {
        String myQuery = null;
        if(filter != null && filter != ''){
            myQuery = 'Select Id, Name from '+myObject+' Where Name Like  \'%' + searchTerm + '%\' AND '+filter+' LIMIT  5';
        }
        else {
            if(searchTerm == null || searchTerm == ''){
                myQuery = 'Select Id, Name from '+myObject+' Where LastViewedDate != NULL ORDER BY LastViewedDate DESC LIMIT  5';
            }
            else {
                myQuery = 'Select Id, Name from '+myObject+' Where Name Like  \'%' + searchTerm + '%\' LIMIT  5';
            }
        }
        List<sObject> lookUpList = database.query(myQuery);
        return lookUpList;
    }
    
    @AuraEnabled
    public static List<String> getEmailMessage(Id TempId,Id recordId){
        EmailTemplate et = [select Body,HTMLValue,Subject from EmailTemplate where Id =: TempId];
        List<String> finalresult = new List<String>();
        List<Messaging.RenderEmailTemplateBodyResult> resList = Messaging.renderEmailTemplate(UserInfo.getUserId() ,recordId , new List<String>{et.Subject,et.Body,et.HTMLValue});
        for(Integer i=0; i<resList.size();i++){
        if(resList[i].getSuccess()){
            if(i == 1){
                finalresult.add(resList[i].getMergedBody());
            }else{
               finalresult.add(resList[i].getMergedBody()); 
            }

        }
            }
        return finalresult;
    }

/* -------------------------- Start : merge method ------------------------------ */
    @AuraEnabled(cacheable=true)
    public static map<string,string> fetchContactField(){
        SObjectType accountType = Schema.getGlobalDescribe().get('Contact');
        System.debug('SObjectType ::: '+accountType);
        Map<String,Schema.SObjectField> mfields = accountType.getDescribe().fields.getMap();
        System.debug('mfields ::: '+mfields.keySet());
        Map<String,String> reqFields = new   Map<String,String>();

        for(String fieldName : mfields.keySet()) {         
            //if(mfields.get(fieldName).getDescribe().isUpdateable()){
                reqFields.put(fieldName, mfields.get(fieldName).getDescribe().getLabel());
            //}
            
            system.debug('fieldName'+fieldName);
        }
        return reqFields;
    }

    @AuraEnabled(cacheable=true)
    public static list<ObjectFieldList> fetchFieldsWrapper(){
        list<ObjectFieldList> returnData = new list<ObjectFieldList>();

        SObjectType org = Schema.getGlobalDescribe().get('Organization');
        Map<String,Schema.SObjectField> mfields = org.getDescribe().fields.getMap();
        Map<String,String> reqFields = new   Map<String,String>();

        list<FieldLabels> fieldsList = new list<FieldLabels>();
        for(String fieldName : mfields.keySet()) {         
            if(mfields.get(fieldName).getDescribe().isUpdateable()){
                // reqFields.put(fieldName, mfields.get(fieldName).getDescribe().getLabel());
                fieldsList.add(new FieldLabels(fieldName, mfields.get(fieldName).getDescribe().getLabel()));
            }
          
        }
        returnData.add(new ObjectFieldList('Organization', 'Organization', fieldsList));
      

        SObjectType accountType = Schema.getGlobalDescribe().get('Contact');
        mfields = accountType.getDescribe().fields.getMap();
        reqFields = new   Map<String,String>();       
        fieldsList = new list<FieldLabels>();
        for(String fieldName : mfields.keySet()) {         
            if(mfields.get(fieldName).getDescribe().isUpdateable()){
                // reqFields.put(fieldName, mfields.get(fieldName).getDescribe().getLabel());
               
                FieldLabels fl = new FieldLabels(fieldName, mfields.get(fieldName).getDescribe().getLabel());   
                system.debug('In'+fl);            
                fieldsList.add(fl);
            }           
        }
        system.debug('fieldsList'+fieldsList);
        returnData.add(new ObjectFieldList('Contact', 'Contact', fieldsList));
        system.debug('returnData2'+returnData);
        
          SObjectType usr = Schema.getGlobalDescribe().get('User');
        Map<String,Schema.SObjectField> ufields = usr.getDescribe().fields.getMap();
       // Map<String,String> reqFields = new   Map<String,String>();

        list<FieldLabels> fieldsList1 = new list<FieldLabels>();
        for(String fieldName : ufields.keySet()) {  
            if(ufields.get(fieldName).getDescribe().isUpdateable()){
                // reqFields.put(fieldName, mfields.get(fieldName).getDescribe().getLabel());
                if(ufields.get(fieldName).getDescribe().getCompoundFieldName() ==null){
                   fieldsList1.add(new FieldLabels(fieldName, ufields.get(fieldName).getDescribe().getLabel())); 
                }
            }
        }
        returnData.add(new ObjectFieldList('User', 'User', fieldsList1));
        return returnData;
    }
/*
    SObjectType accountType = Schema.getGlobalDescribe().get('User');
        mfields = accountType.getDescribe().fields.getMap();
        reqFields = new   Map<String,String>();       
        fieldsList = new list<FieldLabels>();
        for(String fieldName : mfields.keySet()) {         
            if(mfields.get(fieldName).getDescribe().isUpdateable()){
                // reqFields.put(fieldName, mfields.get(fieldName).getDescribe().getLabel());
               
                FieldLabels fl = new FieldLabels(fieldName, mfields.get(fieldName).getDescribe().getLabel());   
                system.debug('In'+fl);            
                fieldsList.add(fl);
            }           
        }
        system.debug('fieldsList'+fieldsList);
        returnData.add(new ObjectFieldList('User', 'User', fieldsList));
        system.debug('returnData2'+returnData);
        return returnData;
    }
*/
    public class ObjectFieldList{
        @AuraEnabled
        public String objectName{get;set;}
        @AuraEnabled
        public String objectAPIName{get;set;}
        @AuraEnabled
        public list<FieldLabels> fieldLabels{get;set;}
        public ObjectFieldList(String objName, String objAPIName, list<FieldLabels> fLabels){
            objectAPIName = objName;
            objectName = objAPIName;
            fieldLabels = fLabels;
        }
    }

    public class FieldLabels{
        @AuraEnabled
        public String fieldLabel{get;set;}
        @AuraEnabled
        public String fieldAPI{get;set;}
        public FieldLabels(String label, String api){
            fieldLabel = label;
            fieldAPI = api;
        }
    }
/* -------------------------- Close : merge method ------------------------------ */
}