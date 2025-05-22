@IsTest(SeeAllData=true)
public class RoutingActionTest {
    
    
    // Expected Input: RoutingActionInput containing location group Ids, summaries, etc
    // Expected Output: RoutingActionResult containing a RoutingActionOutput object embedded
    @IsTest static void test_RoutingAction_success() {
        // Arrange
        TestDataGenerator.seedLocationData();
        System.Test.startTest();
        List<RoutingActionInput> routingActionInputs = createRoutingActionInputs();
        
        System.assertNotEquals(null, routingActionInputs, 'Routing Action Inputs list should not be null');
        
        // Act
        List<RoutingActionResult> routingActionResults = RoutingAction.generateRoutingData(routingActionInputs);
        System.Test.stopTest();
        System.assertNotEquals(null, routingActionResults, 'Routing Action Results list should not be null');
        
        // Assert
        for(RoutingActionResult routingActionResult : routingActionResults) {
            RoutingActionOutput routingActionOutput = routingActionResult.output;
            
            
            System.assertNotEquals(null, routingActionOutput, 'Routing Action Output object should not be null');
            System.assertNotEquals(null, routingActionOutput.orderSummaryId, 'Order Summary ID should not be null');
        }
        
    }
    
    private static List<RoutingActionInput> createRoutingActionInputs() {
        List<RoutingActionInput> inputs = new List<RoutingActionInput>();
        String timestamp = String.valueOf(DateTime.now());
        
        // Creating Availability Data
        List<ConnectApi.OCIInventoryRecordOutputRepresentation> inventoryRecords = new List<ConnectApi.OCIInventoryRecordOutputRepresentation>();
        ConnectApi.OCIInventoryRecordOutputRepresentation record1 = new ConnectApi.OCIInventoryRecordOutputRepresentation();
        String sku1 = 'sku1' + timestamp;
        record1.stockKeepingUnit = sku1;
        record1.availableToFulfill = 10;
        record1.availableToOrder = 10;
        record1.onHand = 5;
        
        
        ConnectApi.OCIInventoryRecordOutputRepresentation record2 = new ConnectApi.OCIInventoryRecordOutputRepresentation();
        String sku2 = 'sku2' + timestamp;
        record2.stockKeepingUnit = sku2;
        record2.availableToFulfill = 10;
        record2.availableToOrder = 5;
        record2.onHand = 6;
        
        ConnectApi.OCIInventoryRecordOutputRepresentation record3 = new ConnectApi.OCIInventoryRecordOutputRepresentation();
        String sku3 = 'sku3'+timestamp;
        record3.stockKeepingUnit = sku3;
        record3.availableToFulfill = 1;
        record3.availableToOrder = 1;
        inventoryRecords.add(record1);
        inventoryRecords.add(record2);
        inventoryRecords.add(record3);
        
        ConnectApi.OCILocationAvailabilityOutputRepresentation locationAvailability1 = new ConnectApi.OCILocationAvailabilityOutputRepresentation();
        locationAvailability1.locationIdentifier = 'Loc-1';
        locationAvailability1.inventoryRecords = inventoryRecords;
        
        ConnectApi.OCILocationAvailabilityOutputRepresentation locationAvailability2 = new ConnectApi.OCILocationAvailabilityOutputRepresentation();
        locationAvailability2.locationIdentifier = 'Loc-2';
        locationAvailability2.inventoryRecords = inventoryRecords;
        
        List<ConnectApi.OCILocationAvailabilityOutputRepresentation> locations = new List<ConnectApi.OCILocationAvailabilityOutputRepresentation>();
        locations.add(locationAvailability1);
        locations.add(locationAvailability2);
        
        ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation availability1 = new ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation();
        availability1.locations = locations;
        
        List<ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation> inventoryAvailabilityList = new List<ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation>();
        inventoryAvailabilityList.add(availability1);
        
        
        // Create Product Data
        
        Product2 p1 = TestDataGenerator.createProduct2('P1', sku1);
        insert p1;
        
        Product2 p2 = TestDataGenerator.createProduct2('P2', sku2);
        insert p2;
        
        PriceBookEntry pbe1 = TestDataGenerator.createPriceBookEntry(p1.Id, System.Test.getStandardPricebookId());
        insert pbe1;
        PriceBookEntry pbe2 = TestDataGenerator.createPriceBookEntry(p2.Id, System.Test.getStandardPricebookId());
        insert pbe2;
        
        
        // Test Purchaser Data for Order
        String firstName = 'Codey';
        String lastName = 'Bear';
        String fullName = firstName + lastName;
        String testEmail = 'test1@salesforce.com';
        String testPhone = '555-555-5777';
        
        Account acc = TestDataGenerator.getAccount(fullName);
        Contact contact = null;
        if (acc == null) {
            acc = TestDataGenerator.createAccount(fullName, testEmail);
            contact = TestDataGenerator.createContact(firstName, lastName, testPhone, acc.Id);
        } else {
            contact = TestDataGenerator.getContact(acc.Id);
        }
        
        Saleschannel sc = TestDataGenerator.createSaleschannel('RoutingTest');
        
        
        // Create Order, Order Summary, and retrieve Order Delivery Group Summary
        Order order = TestDataGenerator.createOrder(acc.Id, System.Test.getStandardPricebookId(), sc.Id, testEmail);
        insert order;
        
        OrderDeliveryMethod odm  = TestDataGenerator.getOrderDeliveryMethod('002');
        Product2 p3 = null;
        PriceBookEntry pbe3 = null;
        if (odm == null) {
            // Only Create the product if needed for the Order Delivery Method
            p3 = TestDataGenerator.createProduct2('Shipping', sku3);
            insert p3;
            
            pbe3 = TestDataGenerator.createPriceBookEntry(p3.Id, System.Test.getStandardPricebookId());
            insert pbe3;
            
            odm = TestDataGenerator.createOrderDeliveryMethodWithProduct('Overnight Shipping', '002', p3);
            insert odm;
            
            System.debug('New Shipping Entry Created: ' + odm);
        } else {
            // Query for Product2 entry and pb entry
            p3 = TestDataGenerator.getProduct2(odm.ProductId);
            System.debug('Found p3 ' + p3);
            pbe3 = TestDataGenerator.getPricebookEntry(odm.ProductId);
            System.debug('Retrieved Shipping Charge Product Entry ' + p3.Id + ' and PricebookEntry '+ pbe3.Id);
        }
        
        OrderDeliveryGroup orderDeliveryGroup = TestDataGenerator.createOrderDeliveryGroup(order.Id, odm.Id, testEmail, fullName);
        insert orderDeliveryGroup;
        
        System.debug('Order Delivery Method Referenced: ' + odm);
        
        List<String> locationGroupIDs = TestDataGenerator.getLocationGroupIDs();
        String reservedAtLocation = locationGroupIDs[0];
        
        OrderItem oi1 =  TestDataGenerator.createOrderItem(order.Id, p1.Id, pbe1.Id, orderDeliveryGroup.Id, 200.0d, 2, reservedAtLocation);
        insert oi1;
        OrderItem oi2 =  TestDataGenerator.createOrderItem(order.Id, p2.Id, pbe2.Id, orderDeliveryGroup.Id, 249.0d, 2, reservedAtLocation);
        insert oi2;
        OrderItem oi3 =  TestDataGenerator.createShippingOrderItem(order.Id, p3.Id, pbe3.Id, orderDeliveryGroup.Id, 20.0d);
        insert oi3;
        
        System.debug('Shipping Order Item: ' + oi3);
        System.debug('Shipping Order Item Id: ' + oi3.Id);
        
        order.Status='Activated';
        update order;
        
        String orderSummaryId = TestDataGenerator.createOrderSummary(order.Id);
        
        List<OrderItemSummary> orderItemSummaries = TestDataGenerator.getOrderItemSummaries(orderSummaryId);
        for(OrderItemSummary orderItemSummary: orderItemSummaries) {
            if (orderItemSummary.Product2Id == p3.Id) {
                System.debug('Fulfillment QTY for shipping item ' + orderItemSummary.QuantityAvailableToFulfill);
            }
        }
        
        
        List<String> rankedAvailableLocations = new List<String>();
        rankedAvailableLocations.add(locationAvailability1.locationIdentifier);
        rankedAvailableLocations.add(locationAvailability2.locationIdentifier);
        
        // Build out the RoutingActionInput
        RoutingActionInput routingActionInput = new RoutingActionInput();
        routingActionInput.orderItemSummaries = orderItemSummaries;
        routingActionInput.orderSummaryId = orderSummaryId;
        routingActionInput.locationGroupIds = locationGroupIDs;
        routingActionInput.inventoryAvailabilityList = inventoryAvailabilityList;
        routingActionInput.rankAvailableLocationsToFulfill = rankedAvailableLocations;
        
        inputs.add(routingActionInput);
        
        System.debug('Routing Action Input: ' + inputs);
        
        return inputs;
    }
    
    
    // New test methods for bundle scenarios and splitments
    @IsTest
    static void testBundleWithParentInventoryWithNullStockCheckMethod() {
        // Arrange
        TestDataGenerator.seedLocationData();
        List<RoutingActionInput> inputs = createBundleWithParentInventoryInputs(2, 2, 4, true);

        // no splitment for this test
        inputs.get(0).inventoryAvailabilityList = createInventoryAvailabilityList(new Map<String, Decimal>{'BUNDLE001' => 20, 'REGULAR001' => 100});
        inputs.get(0).rankAvailableLocationsToFulfill = new List<String>{'Loc-1'};

        // Act
        System.Test.startTest();
        List<RoutingActionResult> results = RoutingAction.generateRoutingData(inputs);
        System.Test.stopTest();

        // Assert
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should have one result');

        RoutingActionOutput output = results[0].output;
        System.assertNotEquals(null, output, 'Output should not be null');
        System.assertNotEquals(null, output.orderSummaryId, 'Order Summary ID should not be null');
    }

    @IsTest
    static void testBundleWithParentInventory() {
        // Arrange
        TestDataGenerator.seedLocationData();
        List<RoutingActionInput> inputs = createBundleWithParentInventoryInputs(2,2,4,false);

        // no splitment for this test
        inputs.get(0).inventoryAvailabilityList = createInventoryAvailabilityList(new Map<String, Decimal>{'BUNDLE001' => 20, 'REGULAR001' => 100});
        inputs.get(0).rankAvailableLocationsToFulfill = new List<String>{'Loc-1'};
        
        // Act
        System.Test.startTest();
        List<RoutingActionResult> results = RoutingAction.generateRoutingData(inputs);
        System.Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should have one result');
        
        RoutingActionOutput output = results[0].output;
        System.assertNotEquals(null, output, 'Output should not be null');
        System.assertNotEquals(null, output.orderSummaryId, 'Order Summary ID should not be null');
        
        System.debug(' ----- RoutingActionOutput ----- :' + output);

        // Verify that we have one routing group for the bundle, no splitments
        System.assertEquals(1, output.routingGroupList.size(), 'Should have one routing group for the bundle');
        
        RoutingGroup bundleGroup = output.routingGroupList[0];
        System.assertEquals(5, bundleGroup.routingItems.size(), 'Should have 5 routing items (1 parent + 2 children + 1 regular + 1 shipping)');
        
        Map<String, OrderItemSummary> skusMap = RoutingActionTest.getSKUMap(inputs[0].orderItemSummaries);
        
        // Verify that the parent and children are in the same routing group, and the total quantity is there
        Set<Id> routingItemIds = new Set<Id>();
        Decimal totalQuantity = 0;
        for (RoutingItem item : bundleGroup.routingItems) {
            routingItemIds.add(item.orderItemSummaryId);
            if(item.orderItemSummaryId != skusMap.get('Shipping001').Id){
                totalQuantity += item.quantity;
            }

            if(skusMap.get('CHILD001').Id == item.orderItemSummaryId || skusMap.get('CHILD002').Id == item.orderItemSummaryId){
                System.assertEquals('IncludedInMainInventory', item.associatedItemInventory);
                System.assertEquals(skusMap.get('BUNDLE001').Id, item.mainOrderItemSummary);
            }else if(skusMap.get('BUNDLE001').Id == item.orderItemSummaryId || skusMap.get('REGULAR001').Id == item.orderItemSummaryId){
                System.assertEquals(null, item.associatedItemInventory);
                System.assertEquals(null, item.mainOrderItemSummary);
            }
        }
        System.assertEquals(5, routingItemIds.size(), 'Should have 5 unique order item summary IDs');

        System.assertEquals(skusMap.get('REGULAR001').QuantityAvailableToFulfill + skusMap.get('BUNDLE001').QuantityAvailableToFulfill + skusMap.get('CHILD001').QuantityAvailableToFulfill + skusMap.get('CHILD002').QuantityAvailableToFulfill, totalQuantity, 'Total quantity should match original order item quantity');

        
    }
    
    @IsTest
    static void testBundleWithParentInventoryAndSplitment() {
        // Arrange
        TestDataGenerator.seedLocationData();
        List<RoutingActionInput> inputs = createBundleWithParentInventoryInputs(10,10,20,false);

        // splitment for this test
        inputs.get(0).inventoryAvailabilityList = createInventoryAvailabilityList(new Map<String, Decimal>{'BUNDLE001' => 5, 'REGULAR001' => 100});
        inputs.get(0).rankAvailableLocationsToFulfill = new List<String>{'Loc-1', 'Loc-2'};
        
        // Act
        System.Test.startTest();
        List<RoutingActionResult> results = RoutingAction.generateRoutingData(inputs);
        System.Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should have two result');
        
        RoutingActionOutput output = results[0].output;
        System.assertNotEquals(null, output, 'Output should not be null');
        System.assertNotEquals(null, output.orderSummaryId, 'Order Summary ID should not be null');
        
        System.debug(' ----- RoutingActionOutput ----- :' + output);
        Map<String, OrderItemSummary> skusMap = RoutingActionTest.getSKUMap(inputs[0].orderItemSummaries);

        // Verify that we have two routing group for the bundle, no splitments
        System.assertEquals(2, output.routingGroupList.size(), 'Should have 2 routing group for the bundle');
        
        RoutingGroup bundleGroup = output.routingGroupList[0];
        System.assertEquals(5, bundleGroup.routingItems.size(), 'Should have 5 routing items (1 parent + 2 children + 1 shipping + 1 regular)');
        RoutingGroup bundleGroup2 = output.routingGroupList[1];
        System.assertEquals(3, bundleGroup2.routingItems.size(), 'Should have 3 routing items (1 parent + 2 children)');
        
        // Verify that the parent and children are in the same routing group, and the total quantity is there
        Set<Id> routingItemIds = new Set<Id>();
        Decimal totalQuantity = 0;
        for(RoutingGroup rg : output.routingGroupList){
            for (RoutingItem item : rg.routingItems) {
                routingItemIds.add(item.orderItemSummaryId);
                if(item.orderItemSummaryId != skusMap.get('Shipping001').Id){
                    totalQuantity += item.quantity;
                }
    
                if(skusMap.get('CHILD001').Id == item.orderItemSummaryId || skusMap.get('CHILD002').Id == item.orderItemSummaryId){
                    System.assertEquals('IncludedInMainInventory', item.associatedItemInventory);
                    System.assertEquals(skusMap.get('BUNDLE001').Id, item.mainOrderItemSummary);
                }else if(skusMap.get('BUNDLE001').Id == item.orderItemSummaryId || skusMap.get('REGULAR001').Id == item.orderItemSummaryId){
                    System.assertEquals(null, item.associatedItemInventory);
                    System.assertEquals(null, item.mainOrderItemSummary);
                }
            }
        }
        
        System.assertEquals(5, routingItemIds.size(), 'Should have 5 unique order item summary IDs');

        System.assertEquals(skusMap.get('REGULAR001').QuantityAvailableToFulfill + skusMap.get('BUNDLE001').QuantityAvailableToFulfill + skusMap.get('CHILD001').QuantityAvailableToFulfill + skusMap.get('CHILD002').QuantityAvailableToFulfill, totalQuantity, 'Total quantity should match original order item quantity');

        
    }
    
    
    @IsTest
    static void testBundleWithChildInventory() {
        // Arrange
        TestDataGenerator.seedLocationData();
        List<RoutingActionInput> inputs = createBundleWithChildInventoryInputs(20,20,40);
        
        // Act
        System.Test.startTest();
        List<RoutingActionResult> results = RoutingAction.generateRoutingData(inputs);
        System.Test.stopTest();

        System.debug(logginglevel.DEBUG, 'testBundleWithChildInventory: ' + results);
        
        // Assert
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should have one result');
        
        RoutingActionOutput output = results[0].output;
        System.assertNotEquals(null, output, 'Output should not be null');
        System.assertNotEquals(null, output.orderSummaryId, 'Order Summary ID should not be null');
        
        System.debug(' ----- RoutingActionOutput ----- :' + output);

        // Verify that we have two routing group for the bundle
        System.assertEquals(2, output.routingGroupList.size(), 'Should have 2 routing group for the bundle, beecause splitment');

        Map<String, OrderItemSummary> skusMap = RoutingActionTest.getSKUMap(inputs[0].orderItemSummaries);

        Decimal totalChildren = 0;
        Decimal totalParent = 0;
        Decimal totalShipping = 0;
        Decimal totalQuantity = 0;
        Set<Id> routingItemIds = new Set<Id>();
        // Verify that the parent item is included in each routing group
        for (RoutingGroup rgroup : output.routingGroupList) {
            Boolean hasParent = false;
            
            //check shipping?
            for (RoutingItem item : rgroup.routingItems) {
                routingItemIds.add(item.orderItemSummaryId);
                if (item.orderItemSummaryId == skusMap.get('BUNDLE002').Id) {
                    hasParent = true;
                    totalParent++;
                    totalQuantity += item.quantity;
                    
                    System.assertEquals(null, item.associatedItemInventory);
                    System.assertEquals(null, item.mainOrderItemSummary);

                } else {
                    if(item.orderItemSummaryId == skusMap.get('Shipping002').Id){
                        totalShipping++;
                    }else{
                        totalChildren++;
                        totalQuantity += item.quantity;
                        if(skusMap.get('CHILD003').Id == item.orderItemSummaryId || skusMap.get('CHILD004').Id == item.orderItemSummaryId){
                            System.assertEquals('NotIncludedInMainInventory', item.associatedItemInventory);
                            System.assertEquals(skusMap.get('BUNDLE002').Id, item.mainOrderItemSummary);
                        }
                    }
                }
            }
            System.assert(hasParent, 'Each routing group should include the parent item');
        }
        System.assertEquals(4, routingItemIds.size(), 'Should have 4 unique order item summary IDs');
        System.assertEquals(3, totalChildren, '3 children in total, 2 in first group and 1 in second group');
        System.assertEquals(2, totalParent, '2 aprent in total');
        System.assertEquals(1, totalShipping, '1 shipping in total');
        System.assertEquals(80, totalQuantity, 'total quantity should be X');
    }

    @IsTest
    static void testBundleWithChildInventoryAndSplitment() {
        // Arrange
        TestDataGenerator.seedLocationData();
        List<RoutingActionInput> inputs = createBundleWithChildInventoryInputs(20,20,40);

        //simulate a splitment for an order of
        //20 parent
        //20 child1
        //40 child2
        inputs.get(0).inventoryAvailabilityList = createInventoryAvailabilityList(new Map<String, Decimal>{'CHILD003' => 7, 'CHILD004' => 15});
        inputs.get(0).rankAvailableLocationsToFulfill = new List<String>{'Loc-1', 'Loc-2', 'Loc-3'};
        
        // Act
        System.Test.startTest();
        List<RoutingActionResult> results = RoutingAction.generateRoutingData(inputs);
        System.Test.stopTest();

        System.debug(logginglevel.DEBUG, 'testBundleWithChildInventory: ' + results);
        
        // Assert
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should have one result');
        
        RoutingActionOutput output = results[0].output;
        System.assertNotEquals(null, output, 'Output should not be null');
        System.assertNotEquals(null, output.orderSummaryId, 'Order Summary ID should not be null');
        
        System.debug(' ----- RoutingActionOutput ----- :' + output);
        Map<String, OrderItemSummary> skusMap = RoutingActionTest.getSKUMap(inputs[0].orderItemSummaries);

        // Verify that we have two routing group for the bundle
        System.assertEquals(3, output.routingGroupList.size(), 'Should have 3 routing group for the bundle, because splitment');
        
        Decimal totalChildren = 0;
        Decimal totalParent = 0;
        Decimal totalShipping = 0;
        Decimal totalQuantity = 0;
        Set<Id> routingItemIds = new Set<Id>();
        // Verify that the parent item is included in each routing group
        for (RoutingGroup rgroup : output.routingGroupList) {
            Boolean hasParent = false;
            
            for (RoutingItem item : rgroup.routingItems) {
                routingItemIds.add(item.orderItemSummaryId);
                if (item.orderItemSummaryId == skusMap.get('BUNDLE002').Id) {
                    hasParent = true;
                    totalParent++;
                    totalQuantity += item.quantity;
                    
                    System.assertEquals(null, item.associatedItemInventory);
                    System.assertEquals(null, item.mainOrderItemSummary);

                } else {
                    if(item.orderItemSummaryId == skusMap.get('Shipping002').Id){
                        totalShipping++;
                    }else{
                        totalChildren++;
                        totalQuantity += item.quantity;
                        if(skusMap.get('CHILD003').Id == item.orderItemSummaryId || skusMap.get('CHILD004').Id == item.orderItemSummaryId){
                            System.assertEquals('NotIncludedInMainInventory', item.associatedItemInventory);
                            System.assertEquals(skusMap.get('BUNDLE002').Id, item.mainOrderItemSummary);
                        }
                    }
                }
            }
            System.assert(hasParent, 'Each routing group should include the parent item');
        }
        System.assertEquals(4, routingItemIds.size(), 'Should have 4 unique order item summary IDs');
        System.assertEquals(6, totalChildren, '6 children in total');
        System.assertEquals(3, totalParent, '3 parents in total');
        System.assertEquals(1, totalShipping, '1 shipping in total');
        System.assertEquals(80, totalQuantity, 'total quantity should be 80');
    }

    @IsTest
    static void testBundleWithChildInventoryAndSplitmentWithParent0() {
        // Arrange
        TestDataGenerator.seedLocationData();
        List<RoutingActionInput> inputs = createBundleWithChildInventoryInputs(2,2,4);

        //simulate a splitment for an order of
        //20 parent
        //20 child1
        //40 child2
        inputs.get(0).inventoryAvailabilityList = createInventoryAvailabilityList(new Map<String, Decimal>{'CHILD003' => 1, 'CHILD004' => 1});
        inputs.get(0).rankAvailableLocationsToFulfill = new List<String>{'Loc-1', 'Loc-2', 'Loc-3', 'Loc-4'};
        
        // Act
        System.Test.startTest();
        List<RoutingActionResult> results = RoutingAction.generateRoutingData(inputs);
        System.Test.stopTest();

        System.debug(logginglevel.DEBUG, 'testBundleWithChildInventory: ' + results);
        
        // Assert
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should have one result');
        
        RoutingActionOutput output = results[0].output;
        System.assertNotEquals(null, output, 'Output should not be null');
        System.assertNotEquals(null, output.orderSummaryId, 'Order Summary ID should not be null');
        
        System.debug(' ----- RoutingActionOutput ----- :' + output);
        Map<String, OrderItemSummary> skusMap = RoutingActionTest.getSKUMap(inputs[0].orderItemSummaries);

        // Verify that we have two routing group for the bundle
        System.assertEquals(4, output.routingGroupList.size(), 'Should have 4 routing group for the bundle, because splitment');
        
        Decimal totalChildren = 0;
        Decimal totalParent = 0;
        Integer parentWith0Quantity = 0;
        Decimal totalShipping = 0;
        Decimal totalQuantity = 0;
        Set<Id> routingItemIds = new Set<Id>();
        // Verify that the parent item is included in each routing group
        for (RoutingGroup rgroup : output.routingGroupList) {
            Boolean hasParent = false;
            
            for (RoutingItem item : rgroup.routingItems) {
                routingItemIds.add(item.orderItemSummaryId);
                if (item.orderItemSummaryId == skusMap.get('BUNDLE002').Id) {
                    hasParent = true;
                    totalParent++;
                    totalQuantity += item.quantity;
                    if(item.quantity == 0){
                        parentWith0Quantity++;
                    }
                    
                    System.assertEquals(null, item.associatedItemInventory);
                    System.assertEquals(null, item.mainOrderItemSummary);

                } else {
                    if(item.orderItemSummaryId == skusMap.get('Shipping002').Id){
                        totalShipping++;
                    }else{
                        totalChildren++;
                        totalQuantity += item.quantity;
                        if(skusMap.get('CHILD003').Id == item.orderItemSummaryId || skusMap.get('CHILD004').Id == item.orderItemSummaryId){
                            System.assertEquals('NotIncludedInMainInventory', item.associatedItemInventory);
                            System.assertEquals(skusMap.get('BUNDLE002').Id, item.mainOrderItemSummary);
                        }
                    }
                }
            }
            System.assert(hasParent, 'Each routing group should include the parent item');
        }
        System.assertEquals(4, routingItemIds.size(), 'Should have 4 unique order item summary IDs');
        System.assertEquals(6, totalChildren, '6 children in total');
        System.assertEquals(4, totalParent, '4 parents in total');
        System.assertEquals(1, totalShipping, '1 shipping in total');
        System.assertEquals(8, totalQuantity, 'total quantity should be 8');
        System.assertEquals(2, parentWith0Quantity, 'parent with 0 quantity should be 2');
    }
    
    
    @IsTest
    static void testSplitment() {
        // Arrange
        TestDataGenerator.seedLocationData();
        List<RoutingActionInput> inputs = createSplitmentInputs();
        
        // Act
        System.Test.startTest();
        List<RoutingActionResult> results = RoutingAction.generateRoutingData(inputs);
        System.Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should have one result');
        
        RoutingActionOutput output = results[0].output;
        System.assertNotEquals(null, output, 'Output should not be null');
        System.assertNotEquals(null, output.orderSummaryId, 'Order Summary ID should not be null');
        
        // Verify that we have multiple routing groups for the split item
        System.assert(output.routingGroupList.size() > 1, 'Should have multiple routing groups for split item');
        
        // Verify that the total quantity across all routing groups matches the original quantity
        Decimal totalQuantity = 0;
        for (RoutingGroup rgroup : output.routingGroupList) {
            for (RoutingItem item : rgroup.routingItems) {
                totalQuantity += item.quantity;
            }
        }
        System.assertEquals(inputs[0].orderItemSummaries[0].QuantityAvailableToFulfill, totalQuantity, 'Total quantity should match original order item quantity');
    }
    
    
    // Helper methods for creating test inputs
    
    
    private static List<RoutingActionInput> createBundleWithParentInventoryInputs(Integer parent, Integer child1, Integer child2, Boolean nullStockCheckMethod) {
        List<RoutingActionInput> inputs = new List<RoutingActionInput>();
        RoutingActionInput input = new RoutingActionInput();
        
        // Create bundle parent and child products
        Product2 parentProduct = TestDataGenerator.createProduct2('Bundle Parent', 'BUNDLE001');
        Product2 childProduct1 = TestDataGenerator.createProduct2('Child 1', 'CHILD001');
        Product2 childProduct2 = TestDataGenerator.createProduct2('Child 2', 'CHILD002');
        Product2 regularProduct1 = TestDataGenerator.createProduct2('Regular 1', 'REGULAR001');
        insert new List<Product2>{parentProduct, childProduct1, childProduct2, regularProduct1};

        PriceBookEntry pb1 = TestDataGenerator.createPriceBookEntry(parentProduct.Id, System.Test.getStandardPricebookId());
        insert pb1;
        PriceBookEntry pb2 = TestDataGenerator.createPriceBookEntry(childProduct1.Id, System.Test.getStandardPricebookId());
        insert pb2;
        PriceBookEntry pb3 = TestDataGenerator.createPriceBookEntry(childProduct2.Id, System.Test.getStandardPricebookId());
        insert pb3;
        PriceBookEntry pb4 = TestDataGenerator.createPriceBookEntry(regularProduct1.Id, System.Test.getStandardPricebookId());
        insert pb4;
        
        // Create order with bundle
        Order order = TestDataGenerator.createOrder(TestDataGenerator.createAccount('Test Account', 'test@example.com').Id, System.Test.getStandardPricebookId(), TestDataGenerator.createSaleschannel('Web').Id, 'test@example.com');
        insert order;

        OrderDeliveryMethod odm  = TestDataGenerator.getOrderDeliveryMethod('002');
        Product2 p3 = null;
        PriceBookEntry pbe3 = null;
        if (odm == null) {
            // Only Create the product if needed for the Order Delivery Method
            p3 = TestDataGenerator.createProduct2('Shipping', 'Shipping001');
            insert p3;
            
            pbe3 = TestDataGenerator.createPriceBookEntry(p3.Id, System.Test.getStandardPricebookId());
            insert pbe3;
            
            odm = TestDataGenerator.createOrderDeliveryMethodWithProduct('Overnight Shipping', '002', p3);
            insert odm;
            
            System.debug('New Shipping Entry Created: ' + odm);
        } else {
            // Query for Product2 entry and pb entry
            p3 = TestDataGenerator.getProduct2(odm.ProductId);
            System.debug('Found p3 ' + p3);
            pbe3 = TestDataGenerator.getPricebookEntry(odm.ProductId);
            System.debug('Retrieved Shipping Charge Product Entry ' + p3.Id + ' and PricebookEntry '+ pbe3.Id);
        }
        
        OrderDeliveryGroup odg = TestDataGenerator.createOrderDeliveryGroup(order.Id, odm.Id, 'test@example.com', 'Test User');
        insert odg;
        
        // Create order items for bundle
        OrderItem parentOI = TestDataGenerator.createOrderItem(order.Id, parentProduct.Id, pb1.Id, odg.Id, 500, parent, null);
        OrderItem childOI1 = TestDataGenerator.createOrderItem(order.Id, childProduct1.Id, pb2.Id, odg.Id, 200, child1, null);
        OrderItem childOI2 = TestDataGenerator.createOrderItem(order.Id, childProduct2.Id, pb3.Id, odg.Id, 300, child2, null);
        OrderItem regular1 = TestDataGenerator.createOrderItem(order.Id, regularProduct1.Id, pb4.Id, odg.Id, 300, 5, null);
        OrderItem shipping = TestDataGenerator.createShippingOrderItem(order.Id, p3.Id, pbe3.Id, odg.Id, 20.0d);
        insert parentOI;
        insert childOI1;
        insert childOI2;
        insert regular1;
        insert shipping;
        
        insert createOrderItemRelationship(order.Id, parentOI.Id, 'Bundle', childOI1.Id, 'BundleComponent', nullStockCheckMethod ? null : 'IncludedInMainInventory');
        insert createOrderItemRelationship(order.Id, parentOI.Id, 'Bundle', childOI2.Id, 'BundleComponent', nullStockCheckMethod ? null : 'IncludedInMainInventory');

        order.Status = 'Activated';
        update order;
        
        // Create OrderSummary and OrderItemSummaries
        String orderSummaryId = TestDataGenerator.createOrderSummary(order.Id);
        List<OrderItemSummary> orderItemSummaries = TestDataGenerator.getOrderItemSummaries(orderSummaryId);
        
        // Set up input
        input.orderItemSummaries = orderItemSummaries;
        input.orderSummaryId = orderSummaryId;
        input.locationGroupIds = TestDataGenerator.getLocationGroupIDs();
        input.inventoryAvailabilityList = createInventoryAvailabilityList(new Map<String, Decimal>{'BUNDLE001' => 30, 'REGULAR001' => 100});
        input.rankAvailableLocationsToFulfill = new List<String>{'Loc-1', 'Loc-2'};
        input.orderItemSummaryRelationships = RoutingActionTest.getRelationshipItems(orderSummaryId);
        
        inputs.add(input);
        return inputs;
    }
    
    
    private static List<RoutingActionInput> createBundleWithChildInventoryInputs(Integer parent, Integer child1, Integer child2) {
        List<RoutingActionInput> inputs = new List<RoutingActionInput>();
        RoutingActionInput input = new RoutingActionInput();
        
        // Create bundle parent and child products
        Product2 parentProduct = TestDataGenerator.createProduct2('Bundle Parent', 'BUNDLE002');
        Product2 childProduct1 = TestDataGenerator.createProduct2('Child 1', 'CHILD003');
        Product2 childProduct2 = TestDataGenerator.createProduct2('Child 2', 'CHILD004');
        insert new List<Product2>{parentProduct, childProduct1, childProduct2};

        PriceBookEntry pb1 = TestDataGenerator.createPriceBookEntry(parentProduct.Id, System.Test.getStandardPricebookId());
        insert pb1;
        PriceBookEntry pb2 = TestDataGenerator.createPriceBookEntry(childProduct1.Id, System.Test.getStandardPricebookId());
        insert pb2;
        PriceBookEntry pb3 = TestDataGenerator.createPriceBookEntry(childProduct2.Id, System.Test.getStandardPricebookId());
        insert pb3;
        
        // Create order with bundle
        Order order = TestDataGenerator.createOrder(TestDataGenerator.createAccount('Test Account', 'test@example.com').Id, System.Test.getStandardPricebookId(), TestDataGenerator.createSaleschannel('Web').Id, 'test@example.com');
        insert order;

        OrderDeliveryMethod odm  = TestDataGenerator.getOrderDeliveryMethod('002');
        Product2 p3 = null;
        PriceBookEntry pbe3 = null;
        if (odm == null) {
            // Only Create the product if needed for the Order Delivery Method
            p3 = TestDataGenerator.createProduct2('Shipping', 'Shipping002');
            insert p3;
            
            pbe3 = TestDataGenerator.createPriceBookEntry(p3.Id, System.Test.getStandardPricebookId());
            insert pbe3;
            
            odm = TestDataGenerator.createOrderDeliveryMethodWithProduct('Overnight Shipping', '002', p3);
            insert odm;
            
            System.debug('New Shipping Entry Created: ' + odm);
        } else {
            // Query for Product2 entry and pb entry
            p3 = TestDataGenerator.getProduct2(odm.ProductId);
            System.debug('Found p3 ' + p3);
            pbe3 = TestDataGenerator.getPricebookEntry(odm.ProductId);
            System.debug('Retrieved Shipping Charge Product Entry ' + p3.Id + ' and PricebookEntry '+ pbe3.Id);
        }
        
        OrderDeliveryGroup odg = TestDataGenerator.createOrderDeliveryGroup(order.Id, odm.Id, 'test@example.com', 'Test User');
        insert odg;
        
        // Create order items for bundle
        OrderItem parentOI = TestDataGenerator.createOrderItem(order.Id, parentProduct.Id, pb1.Id, odg.Id, 500, parent, null);
        OrderItem childOI1 = TestDataGenerator.createOrderItem(order.Id, childProduct1.Id, pb2.Id, odg.Id, 200, child1, null);
        OrderItem childOI2 = TestDataGenerator.createOrderItem(order.Id, childProduct2.Id, pb3.Id, odg.Id, 300, child2, null);
        OrderItem shipping = TestDataGenerator.createShippingOrderItem(order.Id, p3.Id, pbe3.Id, odg.Id, 20.0d);
        insert parentOI;
        insert childOI1;
        insert childOI2;
        insert shipping;
        
        insert createOrderItemRelationship(order.Id, parentOI.Id, 'Bundle', childOI1.Id, 'BundleComponent', 'NotIncludedInMainInventory');
        insert createOrderItemRelationship(order.Id, parentOI.Id, 'Bundle', childOI2.Id, 'BundleComponent', 'NotIncludedInMainInventory');

        order.Status = 'Activated';
        update order;
        
        // Create OrderSummary and OrderItemSummaries
        String orderSummaryId = TestDataGenerator.createOrderSummary(order.Id);
        List<OrderItemSummary> orderItemSummaries = TestDataGenerator.getOrderItemSummaries(orderSummaryId);
        
        // Set up input
        input.orderItemSummaries = orderItemSummaries;
        input.orderSummaryId = orderSummaryId;
        input.locationGroupIds = TestDataGenerator.getLocationGroupIDs();
        input.inventoryAvailabilityList = createInventoryAvailabilityList(new Map<String, Decimal>{'CHILD003' => 30, 'CHILD004' => 30});
        input.rankAvailableLocationsToFulfill = new List<String>{'Loc-1', 'Loc-2'};
        input.orderItemSummaryRelationships = RoutingActionTest.getRelationshipItems(orderSummaryId);
        
        inputs.add(input);
        return inputs;
    }
    
    
    private static List<RoutingActionInput> createSplitmentInputs() {
        List<RoutingActionInput> inputs = new List<RoutingActionInput>();
        RoutingActionInput input = new RoutingActionInput();
        
        // Create product for splitment
        Product2 product = TestDataGenerator.createProduct2('Splitment Product', 'SPLIT001');
        insert product;
        
        PriceBookEntry pbe1 = TestDataGenerator.createPriceBookEntry(product.Id, System.Test.getStandardPricebookId());
        insert pbe1;
        
        // Create order with large quantity
        Order order = TestDataGenerator.createOrder(TestDataGenerator.createAccount('Test Account', 'test@example.com').Id, System.Test.getStandardPricebookId(), TestDataGenerator.createSaleschannel('Web').Id, 'test@example.com');
        insert order;

        OrderDeliveryMethod odm  = TestDataGenerator.getOrderDeliveryMethod('002');
        Product2 p3 = null;
        PriceBookEntry pbe3 = null;
        if (odm == null) {
            // Only Create the product if needed for the Order Delivery Method
            p3 = TestDataGenerator.createProduct2('Shipping', 'Shipping003');
            insert p3;
            
            pbe3 = TestDataGenerator.createPriceBookEntry(p3.Id, System.Test.getStandardPricebookId());
            insert pbe3;
            
            odm = TestDataGenerator.createOrderDeliveryMethodWithProduct('Overnight Shipping', '002', p3);
            insert odm;
            
            System.debug('New Shipping Entry Created: ' + odm);
        } else {
            // Query for Product2 entry and pb entry
            p3 = TestDataGenerator.getProduct2(odm.ProductId);
            System.debug('Found p3 ' + p3);
            pbe3 = TestDataGenerator.getPricebookEntry(odm.ProductId);
            System.debug('Retrieved Shipping Charge Product Entry ' + p3.Id + ' and PricebookEntry '+ pbe3.Id);
        }
        
        OrderDeliveryGroup odg = TestDataGenerator.createOrderDeliveryGroup(order.Id, odm.Id, 'test@example.com', 'Test User');
        insert odg;
        
        
        // Create order item with large quantity
        OrderItem oi = TestDataGenerator.createOrderItem(order.Id, product.Id, pbe1.Id, odg.Id, 1000, 2, null);
        oi.Quantity = 100; // Large quantity to force splitment
        insert oi;
        
        order.Status = 'Activated';
        update order;
        
        // Create OrderSummary and OrderItemSummaries
        String orderSummaryId = TestDataGenerator.createOrderSummary(order.Id);
        List<OrderItemSummary> orderItemSummaries = TestDataGenerator.getOrderItemSummaries(orderSummaryId);
        
        // Set up input
        input.orderItemSummaries = orderItemSummaries;
        input.orderSummaryId = orderSummaryId;
        input.locationGroupIds = TestDataGenerator.getLocationGroupIDs();
        input.inventoryAvailabilityList = createInventoryAvailabilityList(new Map<String, Decimal>{'SPLIT001' => 30});
        input.rankAvailableLocationsToFulfill = new List<String>{'Loc-1', 'Loc-2', 'Loc-3', 'Loc-4'};
        
        inputs.add(input);
        return inputs;
    }
    
    
    private static List<ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation> createInventoryAvailabilityList(Map<String, Decimal> skus) {
        List<ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation> inventoryList = new List<ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation>();
        ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation inventoryOutput = new ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation();
        
        List<ConnectApi.OCILocationAvailabilityOutputRepresentation> locations = new List<ConnectApi.OCILocationAvailabilityOutputRepresentation>();
        
        for (String locationIdentifier : new List<String>{'Loc-1', 'Loc-2', 'Loc-3', 'Loc-4'}) {
            ConnectApi.OCILocationAvailabilityOutputRepresentation location = new ConnectApi.OCILocationAvailabilityOutputRepresentation();
            location.locationIdentifier = locationIdentifier;
            
            List<ConnectApi.OCIInventoryRecordOutputRepresentation> inventoryRecords = new List<ConnectApi.OCIInventoryRecordOutputRepresentation>();
            
            for (String sku : skus.keySet()) {
                ConnectApi.OCIInventoryRecordOutputRepresentation record = new ConnectApi.OCIInventoryRecordOutputRepresentation();
                record.stockKeepingUnit = sku;
                record.availableToFulfill = skus.get(sku);
                record.availableToOrder = skus.get(sku);
                record.onHand = skus.get(sku);
                inventoryRecords.add(record);
            }
            
            location.inventoryRecords = inventoryRecords;
            locations.add(location);
        }
        
        inventoryOutput.locations = locations;
        inventoryList.add(inventoryOutput);
        
        return inventoryList;
    }

    private static OrderItemRelationship createOrderItemRelationship(String orderId, String mainItem, String mainItemRole, String associatedItem, String associatedItemRole, String associatedOrderItemInventory) {
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

    private static List<OrderItemSummaryRelationship> getRelationshipItems(String OrderSummaryId){
        List<OrderItemSummaryRelationship> orderItemSummaryRelationship = [
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

        System.debug('getRelationshipItems: ' + orderItemSummaryRelationship);

        return orderItemSummaryRelationship;
    }

    private static Map<String, OrderItemSummary> getSKUMap(List<OrderItemSummary> oiss){
        Map<String, OrderItemSummary> result = new Map<String, OrderItemSummary>();
        for (OrderItemSummary ois : oiss) {
            result.put(ois.StockKeepingUnit, ois);
        }
        return result;
    }
}