trigger EmailMessage_Trigger on EmailMessage (before insert) {

    for (EmailMessage em : trigger.new) {
        if (em.ParentId != null) {
            em.htmlBody = em.Classification__c + ' // ' + em.Delivery_Option__c + '\n\n' + em.htmlBody;
        }

        string emailBody = em.TextBody;
        if (emailBody == null || emailBody == '')
            emailBody = em.HtmlBody;
        string result = DLPFlagController.validateMessage(emailBody);

        if (result == 'red') {
            em.addError(Label.DLP_Trigger_Error);
        }
        else {
system.debug('***** to Addresses: ' + em.toAddress);
 system.debug('***** Delivery Option: ' + em.Delivery_Option__c);
  system.debug('***** Emailbody: ' + emailBody.containsIgnoreCase(' // ' + Label.Delivery_Option_FRSOnly));
            if (em.Delivery_Option__c == Label.Delivery_Option_FRSOnly || emailBody.containsIgnoreCase(' // ' + Label.Delivery_Option_FRSOnly)) {
             system.debug('***** to Addressescontains: ' + em.toAddress.contains(';'));
                if(em.toAddress.contains(';')){
                    for (string tos : em.toAddress.split(';')) {
                    if (!tos.containsIgnoreCase(Label.Delivery_Option_FRSOnly_Email_Domain)) {
                        em.addError(Label.FRSOnly_Error);
                    }
                }
                }
                if (em.ccAddress != null) {
                    for (string ccs : em.ccAddress.split(';')) {
                        if (!ccs.containsIgnoreCase(Label.Delivery_Option_FRSOnly_Email_Domain)) {
                            em.addError(Label.FRSOnly_Error);
                        }
                    }
                }
            }
        }
    }
}