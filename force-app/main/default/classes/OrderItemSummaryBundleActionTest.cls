@IsTest(SeeAllData=true)
private class OrderItemSummaryBundleActionTest {
    @isTest
    static void testBundleAndInventoryAtParent() {
        String timestamp = String.valueOf(DateTime.now());

        List<OrderItemSummaryBundleActionInput> bundleActionInputs = new List<OrderItemSummaryBundleActionInput>();
        OrderItemSummaryBundleActionInput bundleActionInput = new OrderItemSummaryBundleActionInput();
        bundleActionInput.orderItemSummaries = CreateOrderWithBundleAndInventoryAtParent(timestamp, false);
        bundleActionInput.orderItemSummaryRelationships = OrderItemSummaryBundleActionTest.getRelationshipItems(bundleActionInput.orderItemSummaries[0].OrderSummaryId);

        bundleActionInputs.add(bundleActionInput);
        
        List<OrderItemSummaryBundleActionOutput> output = OrderItemSummaryBundleAction.getOrderItemSummaryRecordsWithInventory(bundleActionInputs);

        System.debug(logginglevel.DEBUG, 'testBundleAndInventoryAtParent' + output);
        
        System.assert(output != null, 'bundleActionOutput should not be null');
        System.assert(output[0].orderItemSummariesWithInventory != null, 'bundleActionOutput.orderItemSummariesWithInventory should not be null');
        System.assert(output[0].orderItemSummariesWithInventory.size() == 4, 'bundleActionOutput.orderItemSummariesWithInventory should have 3 items');
        
        Set<String> skusWithInventory = new Set<String>();
        skusWithInventory.add('sku1' + timestamp);
        skusWithInventory.add('sku1_2' + timestamp); //Product that belongs to a bundle but was also purchased individually
        skusWithInventory.add('sku2' + timestamp);
        skusWithInventory.add('sku3' + timestamp);

        for(OrderItemSummary ois: output[0].orderItemSummariesWithInventory){
            System.assert(skusWithInventory.contains(ois.StockKeepingUnit), 'item with inventory should be only the expected sku');
        }
    }

    @isTest
    static void testBundleAndInventoryAtParentWithNullStockCheckMethod() {
        String timestamp = String.valueOf(DateTime.now());

        List<OrderItemSummaryBundleActionInput> bundleActionInputs = new List<OrderItemSummaryBundleActionInput>();
        OrderItemSummaryBundleActionInput bundleActionInput = new OrderItemSummaryBundleActionInput();
        bundleActionInput.orderItemSummaries = CreateOrderWithBundleAndInventoryAtParent(timestamp, true);
        bundleActionInput.orderItemSummaryRelationships = OrderItemSummaryBundleActionTest.getRelationshipItems(bundleActionInput.orderItemSummaries[0].OrderSummaryId);

        bundleActionInputs.add(bundleActionInput);
        
        List<OrderItemSummaryBundleActionOutput> output = OrderItemSummaryBundleAction.getOrderItemSummaryRecordsWithInventory(bundleActionInputs);

        System.debug(logginglevel.DEBUG, 'testBundleAndInventoryAtParent' + output);
        
        System.assert(output != null, 'bundleActionOutput should not be null');
        System.assert(output[0].orderItemSummariesWithInventory != null, 'bundleActionOutput.orderItemSummariesWithInventory should not be null');
        System.assert(output[0].orderItemSummariesWithInventory.size() == 4, 'bundleActionOutput.orderItemSummariesWithInventory should have 3 items');
        
        Set<String> skusWithInventory = new Set<String>();
        skusWithInventory.add('sku1' + timestamp);
        skusWithInventory.add('sku1_2' + timestamp); //Product that belongs to a bundle but was also purchased individually
        skusWithInventory.add('sku2' + timestamp);
        skusWithInventory.add('sku3' + timestamp);

        for(OrderItemSummary ois: output[0].orderItemSummariesWithInventory){
            System.assert(skusWithInventory.contains(ois.StockKeepingUnit), 'item with inventory should be only the expected sku');
        }
    }

    @isTest
    static void testBundleAndInventoryAtChildren() {
        String timestamp = String.valueOf(DateTime.now());
        List<OrderItemSummaryBundleActionInput> bundleActionInputs = new List<OrderItemSummaryBundleActionInput>();
        OrderItemSummaryBundleActionInput bundleActionInput = new OrderItemSummaryBundleActionInput();
        bundleActionInput.orderItemSummaries = CreateOrderWithBundleAndInventoryAtChildren(timestamp);
        bundleActionInput.orderItemSummaryRelationships = OrderItemSummaryBundleActionTest.getRelationshipItems(bundleActionInput.orderItemSummaries[0].OrderSummaryId);
        
        bundleActionInputs.add(bundleActionInput);
        
        List<OrderItemSummaryBundleActionOutput> output = OrderItemSummaryBundleAction.getOrderItemSummaryRecordsWithInventory(bundleActionInputs);

        System.debug(logginglevel.DEBUG, 'testBundleAndInventoryAtChildren' + output);

        System.assert(output != null, 'bundleActionOutput should not be null');
        System.assert(output[0].orderItemSummariesWithInventory != null, 'bundleActionOutput.orderItemSummariesWithInventory should not be null');
        System.assert(output[0].orderItemSummariesWithInventory.size() == 5, 'bundleActionOutput.orderItemSummariesWithInventory should have 4 items');

        Set<String> skusWithInventory = new Set<String>();
        skusWithInventory.add('sku1_1' + timestamp);
        skusWithInventory.add('sku1_2' + timestamp);
        skusWithInventory.add('sku2' + timestamp);
        skusWithInventory.add('sku3' + timestamp);

        for(OrderItemSummary ois: output[0].orderItemSummariesWithInventory){
            System.assert(skusWithInventory.contains(ois.StockKeepingUnit), 'item with inventory should be only the expected sku');
        }

    }

    private static List<OrderItemSummaryRelationship> getRelationshipItems(String OrderSummaryId){
        return [
            SELECT 
            Id,
            MainOrderSummaryId,
            
            MainOrderItemSummaryId,
            MainOrderItemSummaryRole,
            
            AssociatedOrderItemSummaryId,
            AssociatedOrderItemSummaryRole,
            AssociatedOrderItemInventory,
            AssociatedOrderItemSumPricing,
            AssociatedQuanScaleMethod,

            OrderItemRelationshipId,
            ProductRelatedComponentId,
            ProductRelationshipTypeId
            FROM 
                OrderItemSummaryRelationship 
            WHERE 
                MainOrderSummaryId =: OrderSummaryId
        ];
    }

    private static List<OrderItemSummary> CreateOrderWithBundleAndInventoryAtParent(String timestamp, Boolean nullStockCheckMethod){
        List<OrderItem> orderItems = TestDataGenerator.createOrderAndOrderItems(timestamp);

        Order order = [SELECT Id, Status FROM Order WHERE Id =: orderItems[0].OrderId];

        OrderItemRelationship oir = OrderItemSummaryBundleActionTest.createOrderItemRelationship(timestamp, order.Id, orderItems[0].Id, 'Bundle', orderItems[1].Id, 'BundleComponent', nullStockCheckMethod ? null : 'IncludedInMainInventory');
        insert oir;
        OrderItemRelationship oir2 = OrderItemSummaryBundleActionTest.createOrderItemRelationship(timestamp, order.Id, orderItems[0].Id, 'Bundle', orderItems[2].Id, 'BundleComponent', nullStockCheckMethod ? null : 'IncludedInMainInventory');
        insert oir2;

        order.Status='Activated';
        update order;
        
        String orderSummaryId = TestDataGenerator.createOrderSummary(order.Id);

        List<OrderItemSummary> orderItemSummaries = TestDataGenerator.getOrderItemSummaries(orderSummaryId);
        
        return orderItemSummaries;
    }

    private static List<OrderItemSummary> CreateOrderWithBundleAndInventoryAtChildren(String timestamp){
        List<OrderItem> orderItems = TestDataGenerator.createOrderAndOrderItems(timestamp);

        Order order = [SELECT Id, Status FROM Order WHERE Id =: orderItems[0].OrderId];

        OrderItemRelationship oir = OrderItemSummaryBundleActionTest.createOrderItemRelationship(timestamp, order.Id, orderItems[0].Id, 'Bundle', orderItems[1].Id, 'BundleComponent', 'NotIncludedInMainInventory');
        insert oir;
        OrderItemRelationship oir2 = OrderItemSummaryBundleActionTest.createOrderItemRelationship(timestamp,order.Id, orderItems[0].Id, 'Bundle', orderItems[2].Id, 'BundleComponent', 'NotIncludedInMainInventory');
        insert oir2;
        
        order.Status='Activated';
        update order;
        
        String orderSummaryId = TestDataGenerator.createOrderSummary(order.Id);

        List<OrderItemSummary> orderItemSummaries = TestDataGenerator.getOrderItemSummaries(orderSummaryId);
        
        return orderItemSummaries;
    }

    private static OrderItemRelationship createOrderItemRelationship(String timestamp, String orderId, String mainItem, String mainItemRole, String associatedItem, String associatedItemRole, String associatedOrderItemInventory) {
        List<ProductRelationshipType> prtList = [SELECT Id FROM ProductRelationshipType WHERE AssociatedProductRoleCat = 'BundleComponent' AND MainProductRoleCat = 'Bundle'  ];
        
        ProductRelationshipType prt = null;
        if(prtList.size() == 0){
            prt = new ProductRelationshipType();
            prt.Name = 'Bundle to Bundle Component Relationship';
            prt.MainProductRoleCat = 'Bundle';
            prt.AssociatedProductRoleCat = 'BundleComponent';
            insert prt;
        } else {
            prt = prtList[0];
        }
        
        OrderItemRelationship oir = new OrderItemRelationship();
        oir.ProductRelationshipTypeId = prt.Id;
        oir.MainOrderItemId = mainItem;
        oir.AssociatedOrderItemId = associatedItem;
        oir.AssociatedOrderItemInventory = associatedOrderItemInventory;

        return oir;
    }
}