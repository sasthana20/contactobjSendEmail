@isTest
public with sharing class DLPFlagControllerTest {

    @isTest
    static void validateDLPFlag() {
        string emailBody = 'TRUST // INTERNAL \nSample email body for test class';
        string result = DLPFlagController.validateMessage(emailBody);

//        system.assertEquals('red', result);
    }
}