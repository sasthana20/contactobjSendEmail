({
    handleMessageBodyChange : function(component, event, helper) {
console.log('***** controller method invoked');

        component.set("v.cueColor", "green");

        var messageBody = component.get("v.messageBody");
        console.log('***** message body: ' + JSON.stringify(messageBody));

        var action = component.get("c.validateMessage");
        action.setParam("messageBody", messageBody);
        action.setCallback(this, function(response) {
            var state = response.getState();
console.log('***** state: ' + state);
console.log('***** response: ' + JSON.stringify(response));
            if (state === "SUCCESS") {
console.log('***** return value: ' + response.getReturnValue());
                component.set("v.cueColor", response.getReturnValue());
            }
            else {
                component.set("v.cueColor", "");
            }
        });
        $A.enqueueAction(action);
    },
})