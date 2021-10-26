public with sharing class DLPFlagController {

    @AuraEnabled(cacheable=true)
    public static string validateMessage(string messageBody){

        list<string> keywords = new list<string>();
        for (DLP_Restricted_list__mdt dlp: [SELECT MasterLabel FROM DLP_Restricted_List__mdt]) {
            keywords.add(dlp.MasterLabel);
        }

//        list<string> keywords = new list<string>{'TYPE I - CONTROLLED DEPT', 'TYPE II - DEPT', 'TYPE III - INTERNAL DEPT', 'OPEN/GENERAL RELEASE', 'CONTROLLED DEPT', 'CAUTION BUT GENERAL', 'Support and Control', 'Trust', 'Trust TBD', 'TRUST MEMO'};
system.debug('***** Apex controller method invoked: ' + messageBody);

        boolean foundKey = false;
        boolean foundKey2 = false;
		for (string keyword:keywords) {
 
            String regex2 = keyword + '+ // [A-Za-z]+ [A-Za-z]+';
            String regex = keyword + '+ // [A-Za-z]+';
            Matcher matcher2 = Pattern.compile(regex2).matcher(messageBody);
            Matcher matcher = Pattern.compile(regex).matcher(messageBody);
            foundKey2 = matcher2.find();
            foundKey = matcher.find();
system.debug('***** matcher result 2: ' + foundKey2);
system.debug('***** matcher result 1: ' + foundKey);

            if(foundKey2) {
               System.debug('Matching group 0 string'+matcher2.group(0));
            }
            if(foundKey) {
               System.debug('Matching group 0 string'+matcher.group(0));
            }

            foundKey = (foundKey || foundKey2);

            if (foundKey) {
                break;
            }
        }

        if (foundKey) {
            system.debug('***** returning RED');
            return 'red';
        }

system.debug('***** found Key: ' + foundKey);

system.debug('***** returning GREEN');
        return 'green';
	}

}