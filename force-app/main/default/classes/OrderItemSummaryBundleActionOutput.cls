public with sharing class OrderItemSummaryBundleActionOutput {
    public OrderItemSummaryBundleActionOutput() {
        orderItemSummariesWithInventory = new List<OrderItemSummary>();
    }

    public OrderItemSummaryBundleActionOutput(List<OrderItemSummary> items) {
        orderItemSummariesWithInventory = items;
    }

    @InvocableVariable(label='orderItemSummariesWithInventory' description='orderItemSummariesWithInventory' required=true)
    @AuraEnabled
    public List<OrderItemSummary> orderItemSummariesWithInventory;
}