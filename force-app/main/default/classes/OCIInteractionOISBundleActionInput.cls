public with sharing class OCIInteractionOISBundleActionInput {
    public OCIInteractionOISBundleActionInput() {

    }

    @AuraEnabled
    @InvocableVariable(label='OCI Interaction Order Item Summaries' description='OCI Interaction Order Item Summaries' required=false)
    public List<OCIInteractionOrderItemSummary__c> OCIInteractionOrderItemSummaries;
}