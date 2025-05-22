public  with sharing  class RoutingItem {
    public RoutingItem() {

    }

    @InvocableVariable(label='orderItemSummaryId' description='orderItemSummaryId' required=true)
    @AuraEnabled
    public ID orderItemSummaryId;

    @InvocableVariable(label='quantity' description='quantity' required=true)
    @AuraEnabled
    public Decimal quantity;


    @InvocableVariable(label='Reserved At Location Id' description='Reserved At Location Id' required=true)
    @AuraEnabled
    public ID reservedAtLocationId;

    @InvocableVariable(label='Associated Item Inventory' description='Associated Item Inventory' required=false)
    @AuraEnabled
    public String associatedItemInventory;

    @InvocableVariable(label='Main Order Item Summary' description='Main Order Item Summary' required=false)
    @AuraEnabled
    public ID mainOrderItemSummary;

}