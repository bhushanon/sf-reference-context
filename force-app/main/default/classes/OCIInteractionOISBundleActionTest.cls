@IsTest(SeeAllData=true)
private class OCIInteractionOISBundleActionTest {

    @isTest
    static void testRegularProducts() {
        // Assign
        List<OCIInteractionOISBundleActionInput> inputs = new List<OCIInteractionOISBundleActionInput>();
        OCIInteractionOISBundleActionInput input = new OCIInteractionOISBundleActionInput();

        input.ociInteractionOrderItemSummaries = CreateOCIInteractionItemSummariesWithRegularProducts();
        inputs.add(input);

        // Action
        List<OCIInteractionOISBundleActionOutput> outputs = OCIInteractionOISBundleAction.getOCIInteractionOrderItemSummaryRecordsWithInventory(inputs);

        // Assert
        System.assert(outputs != null, 'bundleActionOutput should not be null');
        System.assert(outputs[0].OCIInteractionItemSummariesWithInventory != null, 'bundleActionOutput.ociInteractionItemSummariesWithInventory should not be null');
        System.assert(outputs[0].OCIInteractionItemSummariesWithInventory.size() == 3);
        System.assert(inputs[0].OCIInteractionOrderItemSummaries.size() == 3);
    }
    
    @isTest
    static void testBundleAndInventoryAtParent() {
        // Assign
        List<OCIInteractionOISBundleActionInput> inputs = new List<OCIInteractionOISBundleActionInput>();
        OCIInteractionOISBundleActionInput input = new OCIInteractionOISBundleActionInput();

        input.ociInteractionOrderItemSummaries = CreateOCIInteractionItemSummariesAndInventoryAtParent(false);
        inputs.add(input);
        
        // Action
        List<OCIInteractionOISBundleActionOutput> outputs = OCIInteractionOISBundleAction.getOCIInteractionOrderItemSummaryRecordsWithInventory(inputs);

        // Assert
        System.assert(outputs != null, 'bundleActionOutput should not be null');
        System.assert(outputs[0].OCIInteractionItemSummariesWithInventory != null, 'bundleActionOutput.ociInteractionItemSummariesWithInventory should not be null');
        System.assert(outputs[0].OCIInteractionItemSummariesWithInventory.size() == 1);
        System.assert(inputs[0].OCIInteractionOrderItemSummaries.size() == 3);
        
        List<String> childrenIds = new List<String>();
        childrenIds.add(input.ociInteractionOrderItemSummaries[1].Id);
        childrenIds.add(input.ociInteractionOrderItemSummaries[2].Id);
        
        // Check there is no child items from output
        for(OCIInteractionOrderItemSummary__c oiois: outputs[0].ociInteractionItemSummariesWithInventory){
            System.assert(!childrenIds.contains(oiois.Id));
        }
    }

    @isTest
    static void testBundleAndInventoryAtParentAndNullStockCheckMethod() {
        // Assign
        List<OCIInteractionOISBundleActionInput> inputs = new List<OCIInteractionOISBundleActionInput>();
        OCIInteractionOISBundleActionInput input = new OCIInteractionOISBundleActionInput();

        input.ociInteractionOrderItemSummaries = CreateOCIInteractionItemSummariesAndInventoryAtParent(true);
        inputs.add(input);
        
        // Action
        List<OCIInteractionOISBundleActionOutput> outputs = OCIInteractionOISBundleAction.getOCIInteractionOrderItemSummaryRecordsWithInventory(inputs);

        // Assert
        System.assert(outputs != null, 'bundleActionOutput should not be null');
        System.assert(outputs[0].OCIInteractionItemSummariesWithInventory != null, 'bundleActionOutput.ociInteractionItemSummariesWithInventory should not be null');
        System.assert(outputs[0].OCIInteractionItemSummariesWithInventory.size() == 1);
        System.assert(inputs[0].OCIInteractionOrderItemSummaries.size() == 3);
        
        List<String> childrenIds = new List<String>();
        childrenIds.add(input.ociInteractionOrderItemSummaries[1].Id);
        childrenIds.add(input.ociInteractionOrderItemSummaries[2].Id);
        
        // Check there is no child items from output
        for(OCIInteractionOrderItemSummary__c oiois: outputs[0].ociInteractionItemSummariesWithInventory){
            System.assert(!childrenIds.contains(oiois.Id));
        }
    }
    
    @isTest
    static void testBundleAndInventoryAtChildren() {
        // Assign
        List<OCIInteractionOISBundleActionInput> inputs = new List<OCIInteractionOISBundleActionInput>();
        OCIInteractionOISBundleActionInput input = new OCIInteractionOISBundleActionInput();

        input.ociInteractionOrderItemSummaries = CreateOCIInteractionItemSummariesAndInventoryAtChildren();
        inputs.add(input);
        
        // Action
        List<OCIInteractionOISBundleActionOutput> outputs = OCIInteractionOISBundleAction.getOCIInteractionOrderItemSummaryRecordsWithInventory(inputs);

        // Assert        
        System.assert(outputs != null, 'bundleActionOutput should not be null');
        System.assert(outputs[0].OCIInteractionItemSummariesWithInventory != null, 'bundleActionOutput.ociInteractionItemSummariesWithInventory should not be null');
        System.assert(outputs[0].OCIInteractionItemSummariesWithInventory.size() == 2);
        System.assert(inputs[0].OCIInteractionOrderItemSummaries.size() == 3);
        
        List<String> parentIds = new List<String>();
        parentIds.add(input.ociInteractionOrderItemSummaries[0].Id);
        
        // Check there is no parent items from output
        for(OCIInteractionOrderItemSummary__c oiois: outputs[0].ociInteractionItemSummariesWithInventory){
            System.assert(!parentIds.contains(oiois.Id));
        }
    }
    
    private static List<OCIInteractionOrderItemSummary__c> CreateOCIInteractionItemSummariesWithRegularProducts(){
        String orderSummaryId = CreateOrderSummary();
        List<OrderItemSummary> orderItemSummaries = TestDataGenerator.getOrderItemSummaries(orderSummaryId);
  
        OCIInteractionOrderSummary__c ociInteractionOrderSummary = CreateOCIInteractionOrderSummary(orderSummaryId, orderItemSummaries[0].OrderDeliveryGroupSummaryId);
       
        List<OCIInteractionOrderItemSummary__c> ociInteractionOrderItemSummaries = new List<OCIInteractionOrderItemSummary__c>();
        
        OCIInteractionOrderItemSummary__c item1 = CreateOCIInteractionOrderItemSummary(ociInteractionOrderSummary.Id, orderItemSummaries[0].Id, null, null);
        OCIInteractionOrderItemSummary__c item2 = CreateOCIInteractionOrderItemSummary(ociInteractionOrderSummary.Id, orderItemSummaries[1].Id, null, null);
        OCIInteractionOrderItemSummary__c item3 = CreateOCIInteractionOrderItemSummary(ociInteractionOrderSummary.Id, orderItemSummaries[2].Id, null, null);
        
        ociInteractionOrderItemSummaries.add(item1);
        ociInteractionOrderItemSummaries.add(item2);
        ociInteractionOrderItemSummaries.add(item3);
        
        return ociInteractionOrderItemSummaries;
    }
    
    private static List<OCIInteractionOrderItemSummary__c> CreateOCIInteractionItemSummariesAndInventoryAtChildren(){
        String orderSummaryId = CreateOrderSummary();
        List<OrderItemSummary> orderItemSummaries = TestDataGenerator.getOrderItemSummaries(orderSummaryId);
  
        OCIInteractionOrderSummary__c ociInteractionOrderSummary = CreateOCIInteractionOrderSummary(orderSummaryId, orderItemSummaries[0].OrderDeliveryGroupSummaryId);
       
        List<OCIInteractionOrderItemSummary__c> ociInteractionOrderItemSummaries = new List<OCIInteractionOrderItemSummary__c>();
        
        OCIInteractionOrderItemSummary__c item1 = CreateOCIInteractionOrderItemSummary(ociInteractionOrderSummary.Id, orderItemSummaries[0].Id, null, null);
        OCIInteractionOrderItemSummary__c item1_1 = CreateOCIInteractionOrderItemSummary(ociInteractionOrderSummary.Id, orderItemSummaries[1].Id, 'NotIncludedInMainInventory', orderItemSummaries[0].Id);
        OCIInteractionOrderItemSummary__c item1_2 = CreateOCIInteractionOrderItemSummary(ociInteractionOrderSummary.Id, orderItemSummaries[2].Id, 'NotIncludedInMainInventory', orderItemSummaries[0].Id);
        
        ociInteractionOrderItemSummaries.add(item1);
        ociInteractionOrderItemSummaries.add(item1_1);
        ociInteractionOrderItemSummaries.add(item1_2);
        
        return ociInteractionOrderItemSummaries;
    }
    
    private static List<OCIInteractionOrderItemSummary__c> CreateOCIInteractionItemSummariesAndInventoryAtParent(Boolean nullStockCheckMethod){
        String orderSummaryId = CreateOrderSummary();
        List<OrderItemSummary> orderItemSummaries = TestDataGenerator.getOrderItemSummaries(orderSummaryId);

        OCIInteractionOrderSummary__c ociInteractionOrderSummary = CreateOCIInteractionOrderSummary(orderSummaryId, orderItemSummaries[0].OrderDeliveryGroupSummaryId);
       
        List<OCIInteractionOrderItemSummary__c> ociInteractionOrderItemSummaries = new List<OCIInteractionOrderItemSummary__c>();
        
        OCIInteractionOrderItemSummary__c item1 = CreateOCIInteractionOrderItemSummary(ociInteractionOrderSummary.Id, orderItemSummaries[0].Id, null, null);
        OCIInteractionOrderItemSummary__c item1_1 = CreateOCIInteractionOrderItemSummary(ociInteractionOrderSummary.Id, orderItemSummaries[1].Id, nullStockCheckMethod ? null : 'IncludedInMainInventory', orderItemSummaries[0].Id);
        OCIInteractionOrderItemSummary__c item1_2 = CreateOCIInteractionOrderItemSummary(ociInteractionOrderSummary.Id, orderItemSummaries[2].Id, nullStockCheckMethod ? null : 'IncludedInMainInventory', orderItemSummaries[0].Id);
        
        ociInteractionOrderItemSummaries.add(item1);
        ociInteractionOrderItemSummaries.add(item1_1);
        ociInteractionOrderItemSummaries.add(item1_2);
        
        return ociInteractionOrderItemSummaries;
    }
    
    private static OCIInteractionOrderSummary__c CreateOCIInteractionOrderSummary(String orderSummaryId, String orderDeliveryGroupSummaryId){
        OCIInteractionOrderSummary__c oios = new OCIInteractionOrderSummary__c();
        
        oios.OrderSummary__c = orderSummaryId;
        oios.Status__c = 'REQUESTED';
        oios.Type__c = 'TRANSFER_ROUTING';
        oios.ConnectionFailAttempts__c = 0;
        oios.OrderDeliveryGroupSummary__c = orderDeliveryGroupSummaryId;
        oios.Schedule__c = DateTime.now();
        insert oios;
        return oios;
    }

    private static OCIInteractionOrderItemSummary__c CreateOCIInteractionOrderItemSummary(Id OCIInteractionOrderSummaryId, 
    Id OrderItemSummaryId, String associatedItemInventory, Id mainOrderItemSummary){
        OCIInteractionOrderItemSummary__c oiois = new OCIInteractionOrderItemSummary__c();
        
        oiois.OCIInteractionOrderSummary__c = OCIInteractionOrderSummaryId;
        oiois.OrderItemSummary__c = OrderItemSummaryId;
        oiois.Status__c = 'REQUESTED';
        oiois.Type__c = 'TRANSFER_ROUTING';
        oiois.Quantity__c = 1;
        oiois.Associated_Item_Inventory__c = associatedItemInventory;
        oiois.Main_Order_Item_Summary__c = mainOrderItemSummary;
        
        insert oiois;
        return oiois;
    }
    
    private static String CreateOrderSummary() {
        String timestamp = String.valueOf(DateTime.now());
        List<OrderItem> orderItems = TestDataGenerator.createOrderAndOrderItems(timestamp);
        Order order = [SELECT Id, Status FROM Order WHERE Id =: orderItems[0].OrderId];
        order.Status='Activated';
        update order;
        return TestDataGenerator.createOrderSummary(order.Id);
    }
    
}