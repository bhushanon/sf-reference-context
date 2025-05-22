public with sharing class OCIInteractionOISBundleActionOutput {
    public OCIInteractionOISBundleActionOutput() {
        OCIInteractionItemSummariesWithInventory = new List<OCIInteractionOrderItemSummary__c>();
    }

    @AuraEnabled
    @InvocableVariable(label='OCI Interaction Order Item Summaries With Inventory' description='OCI Interaction Order Item Summaries With Inventory' required=true)
    public List<OCIInteractionOrderItemSummary__c> OCIInteractionItemSummariesWithInventory;
}