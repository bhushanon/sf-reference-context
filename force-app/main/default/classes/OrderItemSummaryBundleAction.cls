public with sharing class OrderItemSummaryBundleAction {

    public OrderItemSummaryBundleAction() {

    }

    @InvocableMethod(label='Get Order Item Summaries with inventory' description='Extracts Order Item Summary records with inventory by looking into the provided Order Item Summary Relationship records' category='Order Management')
    public static List<OrderItemSummaryBundleActionOutput> getOrderItemSummaryRecordsWithInventory(List<OrderItemSummaryBundleActionInput> inputs){

        System.debug(logginglevel.DEBUG, ' --- Bundle Action Input ---' + inputs);

        List<OrderItemSummaryBundleActionOutput> results = new List<OrderItemSummaryBundleActionOutput>();

        for (OrderItemSummaryBundleActionInput input : inputs) {

            if(
                //if there is no relationship nodes, all items should have inventory since those are not bundles
                input.orderItemSummaryRelationships == null || 
                input.orderItemSummaryRelationships.size() == 0 || 
                //if OrerItemSummaries are not provided then nothing to do
                input.orderItemSummaries == null || 
                input.orderItemSummaries.size() == 0
            ){
                results.add(new OrderItemSummaryBundleActionOutput(input.orderItemSummaries));
                continue;
            }

            Map<String, OrderItemSummaryRelationship> children = new Map<String, OrderItemSummaryRelationship>();
            Map<String, OrderItemSummaryRelationship> parents = new Map<String, OrderItemSummaryRelationship>();
            for(OrderItemSummaryRelationship oisr: input.orderItemSummaryRelationships){
                children.put(oisr.AssociatedOrderItemSummaryId, oisr);
                parents.put(oisr.MainOrderItemSummaryId, oisr);
            }

            System.debug(logginglevel.DEBUG, ' --- Children ---' + children);
            System.debug(logginglevel.DEBUG, ' --- Parents ---' + parents);

            OrderItemSummaryBundleActionOutput output = new OrderItemSummaryBundleActionOutput();
            
            Map<String,OrderItemSummary> orderItemSummariesWithInventory = new Map<String,OrderItemSummary>();
            for(OrderItemSummary ois: input.orderItemSummaries){
                System.debug(logginglevel.DEBUG, ' --- Checking Item Relationship ---');
                //if parent item of a bundle
                if(parents.containsKey(ois.Id)){
                    System.debug(logginglevel.DEBUG, ' --- Found Parent Record ---' + ois);
                    //and associated item of the parent IS included in the main inventory then parent has the inventory
                    if(parents.get(ois.Id).AssociatedOrderItemInventory == null || parents.get(ois.Id).AssociatedOrderItemInventory == 'IncludedInMainInventory'){
                        System.debug(logginglevel.DEBUG, ' --- Parent Record Has Inventory ---' + parents.get(ois.Id));
                        output.orderItemSummariesWithInventory.add(ois);
                    }
                //if child item of a bundle
                }else if(children.containsKey(ois.Id)){
                    System.debug(logginglevel.DEBUG, ' --- Child Parent Record ---' + ois);
                    //and associated item of the bundle IS NOT included in the main inventory, then associated items has inventory
                    if(children.get(ois.Id).AssociatedOrderItemInventory == 'NotIncludedInMainInventory'){
                        System.debug(logginglevel.DEBUG, ' --- Child Record Has Inventory ---' + children.get(ois.Id));
                        output.orderItemSummariesWithInventory.add(ois);
                    }
                }else{
                    //its an item that is not part of a bundle, so it should have inventory
                    System.debug(logginglevel.DEBUG, ' --- Non-Bundled Record Has Inventory ---' + ois);
                    output.orderItemSummariesWithInventory.add(ois);
                }
            }

            results.add(output);
        }
        
        return results;
    }
    
}