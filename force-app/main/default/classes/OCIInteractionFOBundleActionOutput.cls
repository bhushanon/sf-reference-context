public with sharing class OCIInteractionFOBundleActionOutput {
    public OCIInteractionFOBundleActionOutput() {
        OCIInteractionFulfillOrderItems = new List<OCIInteractionFulfillOrderItem__c>();
    }
    @AuraEnabled
    @InvocableVariable(label='OCI Interaction Fulfill Order Items' description='OCI Interaction Fulfill Order Items' required=true)
    public List<OCIInteractionFulfillOrderItem__c> OCIInteractionFulfillOrderItems;
    
}