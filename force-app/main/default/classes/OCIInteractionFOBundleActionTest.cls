@isTest
private class OCIInteractionFOBundleActionTest {

    @isTest
    static void testFilteringBundleInventoryAllRegularProducts() {
        // Create Records
        FulfillmentOrder fo = seedFulfillOrder();
        FulfillmentOrderLineItem foli1 = seedFulfillOrderLineItem(fo);
        FulfillmentOrderLineItem foli2 = seedFulfillOrderLineItem(fo);
        FulfillmentOrderLineItem foli3 = seedFulfillOrderLineItem(fo);
        FulfillmentOrderLineItem foli4 = seedFulfillOrderLineItem(fo);
        
        OCIInteractionFulfillOrder__c ociFulfill = seedOCIFullfillOrder(fo);
        
        OCIInteractionFulfillOrderItem__c ociFulfillItem1 = seedOCIFullfillOrderItem(ociFulfill, foli1, null, null);
        OCIInteractionFulfillOrderItem__c ociFulfillItem2 = seedOCIFullfillOrderItem(ociFulfill, foli2, null, null);
        OCIInteractionFulfillOrderItem__c ociFulfillItem3 = seedOCIFullfillOrderItem(ociFulfill, foli3, null, null);
        OCIInteractionFulfillOrderItem__c ociFulfillItem4 = seedOCIFullfillOrderItem(ociFulfill, foli4, null, null);
        
        List<OCIInteractionFOBundleActionInput> inputs = new List<OCIInteractionFOBundleActionInput>();
        OCIInteractionFOBundleActionInput input1 = new OCIInteractionFOBundleActionInput();
        input1.OCIInteractionFulfillOrderItems.add(ociFulfillItem1);
        input1.OCIInteractionFulfillOrderItems.add(ociFulfillItem2);
        input1.OCIInteractionFulfillOrderItems.add(ociFulfillItem3);
        input1.OCIInteractionFulfillOrderItems.add(ociFulfillItem4);

        inputs.add(input1);
        List<OCIInteractionFOBundleActionOutput> outputs = OCIInteractionFOBundleAction.getRecordWithInventory(inputs);

        System.assertEquals(1, outputs.size());
        System.assertEquals(4, outputs.get(0).OCIInteractionFulfillOrderItems.size());
    }

    @isTest
    static void testFilteringBundleInventoryAtChildren() {
        // Create Records
        FulfillmentOrder fo = seedFulfillOrder();
        FulfillmentOrderLineItem foli1 = seedFulfillOrderLineItem(fo);
        FulfillmentOrderLineItem foli2 = seedFulfillOrderLineItem(fo);
        FulfillmentOrderLineItem foli3 = seedFulfillOrderLineItem(fo);
        FulfillmentOrderLineItem foli4 = seedFulfillOrderLineItem(fo);
        
        OCIInteractionFulfillOrder__c ociFulfill = seedOCIFullfillOrder(fo);
        
        OCIInteractionFulfillOrderItem__c ociFulfillItem1 = seedOCIFullfillOrderItem(ociFulfill, foli1, null, null);
        OCIInteractionFulfillOrderItem__c ociFulfillItem2 = seedOCIFullfillOrderItem(ociFulfill, foli2, null, null);
        //children
        OCIInteractionFulfillOrderItem__c ociFulfillItem3 = seedOCIFullfillOrderItem(ociFulfill, foli3, foli1.Id, 'NotIncludedInMainInventory');
        OCIInteractionFulfillOrderItem__c ociFulfillItem4 = seedOCIFullfillOrderItem(ociFulfill, foli4, foli1.Id, 'NotIncludedInMainInventory');
        
        List<OCIInteractionFOBundleActionInput> inputs = new List<OCIInteractionFOBundleActionInput>();
        OCIInteractionFOBundleActionInput input1 = new OCIInteractionFOBundleActionInput();
        input1.OCIInteractionFulfillOrderItems.add(ociFulfillItem1);
        input1.OCIInteractionFulfillOrderItems.add(ociFulfillItem2);
        input1.OCIInteractionFulfillOrderItems.add(ociFulfillItem3);
        input1.OCIInteractionFulfillOrderItems.add(ociFulfillItem4);

        inputs.add(input1);
        List<OCIInteractionFOBundleActionOutput> outputs = OCIInteractionFOBundleAction.getRecordWithInventory(inputs);

        System.assertEquals(3, outputs.get(0).OCIInteractionFulfillOrderItems.size());

        for(OCIInteractionFulfillOrderItem__c item: outputs.get(0).OCIInteractionFulfillOrderItems){
            //make sure parent is not in the output since it doesn't have iventory
            System.assertNotEquals(ociFulfillItem1.Id, item.Id);
        }
    }

    @isTest
    static void testFilteringBundleInventoryAtParent() {
        // Create Records
        FulfillmentOrder fo = seedFulfillOrder();
        FulfillmentOrderLineItem foli1 = seedFulfillOrderLineItem(fo);
        FulfillmentOrderLineItem foli2 = seedFulfillOrderLineItem(fo);
        FulfillmentOrderLineItem foli3 = seedFulfillOrderLineItem(fo);
        FulfillmentOrderLineItem foli4 = seedFulfillOrderLineItem(fo);
        
        OCIInteractionFulfillOrder__c ociFulfill = seedOCIFullfillOrder(fo);
        
        OCIInteractionFulfillOrderItem__c ociFulfillItem1 = seedOCIFullfillOrderItem(ociFulfill, foli1, null, null);
        OCIInteractionFulfillOrderItem__c ociFulfillItem2 = seedOCIFullfillOrderItem(ociFulfill, foli2, null, null);
        //children
        OCIInteractionFulfillOrderItem__c ociFulfillItem3 = seedOCIFullfillOrderItem(ociFulfill, foli3, foli1.Id, 'IncludedInMainInventory');
        OCIInteractionFulfillOrderItem__c ociFulfillItem4 = seedOCIFullfillOrderItem(ociFulfill, foli4, foli1.Id, 'IncludedInMainInventory');
        
        List<OCIInteractionFOBundleActionInput> inputs = new List<OCIInteractionFOBundleActionInput>();
        OCIInteractionFOBundleActionInput input1 = new OCIInteractionFOBundleActionInput();
        input1.OCIInteractionFulfillOrderItems.add(ociFulfillItem1);
        input1.OCIInteractionFulfillOrderItems.add(ociFulfillItem2);
        input1.OCIInteractionFulfillOrderItems.add(ociFulfillItem3);
        input1.OCIInteractionFulfillOrderItems.add(ociFulfillItem4);

        inputs.add(input1);
        List<OCIInteractionFOBundleActionOutput> outputs = OCIInteractionFOBundleAction.getRecordWithInventory(inputs);

        System.assertEquals(2, outputs.get(0).OCIInteractionFulfillOrderItems.size());

        for(OCIInteractionFulfillOrderItem__c item: outputs.get(0).OCIInteractionFulfillOrderItems){
            //make sure children are not in the output since those do not track iventory
            System.assertNotEquals(ociFulfillItem3.Id, item.Id);
            System.assertNotEquals(ociFulfillItem4.Id, item.Id);
        }
    }

    @isTest
    static void testFilteringBundleInventoryAtParentAndNullStockCheckMethod() {
        // Create Records
        FulfillmentOrder fo = seedFulfillOrder();
        FulfillmentOrderLineItem foli1 = seedFulfillOrderLineItem(fo);
        FulfillmentOrderLineItem foli2 = seedFulfillOrderLineItem(fo);
        FulfillmentOrderLineItem foli3 = seedFulfillOrderLineItem(fo);
        FulfillmentOrderLineItem foli4 = seedFulfillOrderLineItem(fo);
        
        OCIInteractionFulfillOrder__c ociFulfill = seedOCIFullfillOrder(fo);
        
        OCIInteractionFulfillOrderItem__c ociFulfillItem1 = seedOCIFullfillOrderItem(ociFulfill, foli1, null, null);
        OCIInteractionFulfillOrderItem__c ociFulfillItem2 = seedOCIFullfillOrderItem(ociFulfill, foli2, null, null);
        //children
        OCIInteractionFulfillOrderItem__c ociFulfillItem3 = seedOCIFullfillOrderItem(ociFulfill, foli3, foli1.Id, null);
        OCIInteractionFulfillOrderItem__c ociFulfillItem4 = seedOCIFullfillOrderItem(ociFulfill, foli4, foli1.Id, null);
        
        List<OCIInteractionFOBundleActionInput> inputs = new List<OCIInteractionFOBundleActionInput>();
        OCIInteractionFOBundleActionInput input1 = new OCIInteractionFOBundleActionInput();
        input1.OCIInteractionFulfillOrderItems.add(ociFulfillItem1);
        input1.OCIInteractionFulfillOrderItems.add(ociFulfillItem2);
        input1.OCIInteractionFulfillOrderItems.add(ociFulfillItem3);
        input1.OCIInteractionFulfillOrderItems.add(ociFulfillItem4);

        inputs.add(input1);
        List<OCIInteractionFOBundleActionOutput> outputs = OCIInteractionFOBundleAction.getRecordWithInventory(inputs);

        System.assertEquals(2, outputs.get(0).OCIInteractionFulfillOrderItems.size());

        for(OCIInteractionFulfillOrderItem__c item: outputs.get(0).OCIInteractionFulfillOrderItems){
            //make sure children are not in the output since those do not track iventory
            System.assertNotEquals(ociFulfillItem3.Id, item.Id);
            System.assertNotEquals(ociFulfillItem4.Id, item.Id);
        }
    }

    // Create Fulfillment Order
    private static FulfillmentOrder seedFulfillOrder(){
        OrderDeliveryMethod odm = new OrderDeliveryMethod(
                                        IsActive = false,
                                        Name = 'test'
                                    );
        insert odm;
        FulfillmentOrder fo = new FulfillmentOrder(
                                    status = 'Draft',
                                    FulfilledToName = 'test',
                                    DeliveryMethodId = odm.Id
                                );
        insert fo;
        return fo;
    }

    // Create Fulfillment Order Line Item
    private static FulfillmentOrderLineItem seedFulfillOrderLineItem(FulfillmentOrder fo){
        FulfillmentOrderLineItem foli = new FulfillmentOrderLineItem(
                                            FulfillmentOrderId = fo.Id,
                                            Quantity = 1.0,
                                            OriginalQuantity = 1.0,
                                            Type = 'Order Product',
                                            TypeCode = 'Product'
                                        );
        insert foli;
        return foli;
    }

    // Create OCI Interaction Fulfillment Order
    private static OCIInteractionFulfillOrder__c seedOCIFullfillOrder(FulfillmentOrder fo){
        OCIInteractionFulfillOrder__c ociFulfill = new OCIInteractionFulfillOrder__c(
                                                        FulfillmentOrder__c = fo.Id,
                                                        Status__c = 'REQUESTED',
                                                        Type__c = 'TRANSFER_MOVE',
                                                        ConnectionFailedAttempts__c = 0,
                                                        Schedule__c = DateTime.now()
                                                    );
        insert ociFulfill;
        return ociFulfill;    
    }
    
    // Create OCI Interaction Fulfillment Order Item
    private static OCIInteractionFulfillOrderItem__c seedOCIFullfillOrderItem(OCIInteractionFulfillOrder__c ociFulfill, FulfillmentOrderLineItem foli, String mainFulfillmentOrderItem, String associatedItemInventory){
        OCIInteractionFulfillOrderItem__c ociFulfillItem = new OCIInteractionFulfillOrderItem__c(
                                                                OCIInteractionFulfillOrder__c = ociFulfill.Id,
                                                                FulfillmentOrderItem__c = foli.Id,
                                                                Quantity__c = 1,
                                                                Status__c = 'REQUESTED',
                                                                Type__c = 'TRANSFER_MOVE',
                                                                Main_Fulfillment_Order_Item__c = mainFulfillmentOrderItem,
                                                                Associated_Item_Inventory__c = associatedItemInventory
                                                            );
        insert ociFulfillItem;
        return ociFulfillItem;
    }
}