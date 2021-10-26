@isTest
public class EmailMessage_Trigger_Test {
    @isTest
    static void checkDLPKeywords() {

        test.startTest();

        EmailMessage em = new EmailMessage(Subject = 'Test email', HtmlBody = 'Trust // Internal \n sample email body for test class', FromAddress = UserInfo.getUserEmail(), ToAddress = 'test@email.com');
        try {
            insert em;
        }
        catch (Exception ex) {
            boolean validated = false;
            string msg = ex.getMessage();
            if (msg.containsIgnoreCase('Email has DLP restricted words and cannot be saved'))
                validated = true;

            //08:31:43:141 FATAL_ERROR System.DmlException: Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Email has DLP restricted words and cannot be saved.: []
            system.assertEquals(true, validated);

            test.stopTest();
        }
    }


    @isTest
    static void frsOnlyTest() {

        test.startTest();

        EmailMessage em = new EmailMessage(Subject = 'Test email', HtmlBody = 'Trust // ' + Label.Delivery_Option_FRSOnly + ' \n sample email body for test class', FromAddress = UserInfo.getUserEmail(), ToAddress = 'test@email.com', ccAddress = 'test@email.com');
        try {
            insert em;
        }
        catch (Exception ex) {
            boolean validated = false;
            string msg = ex.getMessage();
            if (msg.containsIgnoreCase(Label.FRSOnly_Error))
                validated = true;

            //08:31:43:141 FATAL_ERROR System.DmlException: Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Email has DLP restricted words and cannot be saved.: []
            system.assertEquals(true, validated);

            test.stopTest();
        }
    }
}