public with sharing class OrderItemSummaryBundleActionInput {
    public OrderItemSummaryBundleActionInput() {

    }

    @AuraEnabled
    @InvocableVariable(label='Order Item Summaries' description='Order Item Summaries' required=false)
    public List<OrderItemSummary> orderItemSummaries;

    @AuraEnabled
    @InvocableVariable(label='Order Item Summary Relationships' description='Order Item Summary Relationships' required=false)
    public List<OrderItemSummaryRelationship> orderItemSummaryRelationships;
}