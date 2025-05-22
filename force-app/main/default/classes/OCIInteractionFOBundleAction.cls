public with sharing class OCIInteractionFOBundleAction {
    public OCIInteractionFOBundleAction() {

    }

    @InvocableMethod(label='Get OCI Interaction Fulfill Order Item with inventory' description='Filters and returns OCI Interaction Fulfill Order Item with inventory' category='Order Management')
    public static List<OCIInteractionFOBundleActionOutput> getRecordWithInventory(List<OCIInteractionFOBundleActionInput> inputs){
        List<OCIInteractionFOBundleActionOutput> result = new List<OCIInteractionFOBundleActionOutput>();

        for (OCIInteractionFOBundleActionInput input : inputs) {

            OCIInteractionFOBundleActionOutput output = new OCIInteractionFOBundleActionOutput();

            Set<String> parentsWithoutInventory = new Set<String>();
            
            List<OCIInteractionFulfillOrderItem__c> remainingItemsToProcess = new List<OCIInteractionFulfillOrderItem__c>();
            
            //detect children with inventory
            for(OCIInteractionFulfillOrderItem__c item: input.OCIInteractionFulfillOrderItems){
                if(item.Main_Fulfillment_Order_Item__c != null){
                    if(item.Associated_Item_Inventory__c == 'NotIncludedInMainInventory'){
                        //add to response since this child has inventory
                        output.OCIInteractionFulfillOrderItems.add(item);
                        
                        //we want to exlude the parent later on, because it doesnt have inventory
                        if(!parentsWithoutInventory.contains(item.Main_Fulfillment_Order_Item__c)){
                            parentsWithoutInventory.add(item.Main_Fulfillment_Order_Item__c);
                        }
                    }
                }else{
                    //other items we process in another loop, because we need to know all the parents withut inventory first
                    remainingItemsToProcess.add(item);
                }
            }

            if(parentsWithoutInventory.size() == 0){
                output.OCIInteractionFulfillOrderItems.addAll(remainingItemsToProcess);
            }else{
                //loop suspset of records that have regular products (non bundles) and parents
                for(OCIInteractionFulfillOrderItem__c item: remainingItemsToProcess){
                    if(!parentsWithoutInventory.contains(item.FulfillmentOrderItem__c)){
                        output.OCIInteractionFulfillOrderItems.add(item);
                    }
                }
            }
            
            result.add(output);

        }

        return result;
    }
}