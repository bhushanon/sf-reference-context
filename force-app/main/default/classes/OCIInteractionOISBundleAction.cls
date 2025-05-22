public with sharing class OCIInteractionOISBundleAction {

    public OCIInteractionOISBundleAction() {

    }

    @InvocableMethod(label='Get OCI Interaction Order Item Summaries with inventory' description='Extracts OCI Interaction Order Item Summaries with inventory' category='Order Management')
    public static List<OCIInteractionOISBundleActionOutput> getOCIInteractionOrderItemSummaryRecordsWithInventory(List<OCIInteractionOISBundleActionInput> inputs){

        List<OCIInteractionOISBundleActionOutput> results = new List<OCIInteractionOISBundleActionOutput>();

        for (OCIInteractionOISBundleActionInput input : inputs) {
        
            OCIInteractionOISBundleActionOutput output = new OCIInteractionOISBundleActionOutput();
            
            Set<String> parentsWithoutInventory = new Set<String>();
            
            List<OCIInteractionOrderItemSummary__c> remainingItemsToProcess = new List<OCIInteractionOrderItemSummary__c>();
            
            for (OCIInteractionOrderItemSummary__c item: input.ociInteractionOrderItemSummaries) {
                // all children
                if (item.Main_Order_Item_Summary__c != null) {
                    // children with inventory
                    if (item.Associated_Item_Inventory__c == 'NotIncludedInMainInventory') {
                        output.OCIInteractionItemSummariesWithInventory.add(item);
                        // parents without inventory
                        if (!parentsWithoutInventory.contains(item.Main_Order_Item_Summary__c)) {
                            parentsWithoutInventory.add(item.Main_Order_Item_Summary__c);
                        }
                    }
                // all parents + non bundles 
                } else {
                    remainingItemsToProcess.add(item);
                }
            }
        
            if (parentsWithoutInventory.size() == 0) {
                output.OCIInteractionItemSummariesWithInventory.addAll(remainingItemsToProcess);
            } else {
                for (OCIInteractionOrderItemSummary__c item: remainingItemsToProcess) {
                    if (!parentsWithoutInventory.contains(item.OrderItemSummary__c)) {
                        output.OCIInteractionItemSummariesWithInventory.add(item);
                    }
                }
            }
            results.add(output);
        }
        return results;
    }
}