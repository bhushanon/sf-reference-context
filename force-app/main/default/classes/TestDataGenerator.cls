public class TestDataGenerator {
    public static void seedLocationData(){
        // Create Locations
        Schema.Location loc1 = new Schema.Location(
                                    Name = 'Loc-1',
                                    LocationType = 'Warehouse',
                                    ShouldSyncWithOci = true,
                                    ExternalReference = 'Loc-1'
                                );  
        Schema.Location loc2 = new Schema.Location(
                                    Name = 'Loc-2',
                                    LocationType = 'Warehouse',
                                    ShouldSyncWithOci = true,
                                    ExternalReference = 'Loc-2'
                                ); 
        Schema.Location loc3 = new Schema.Location(
                                    Name = 'Loc-3',
                                    LocationType = 'Warehouse',
                                    ShouldSyncWithOci = true,
                                    ExternalReference = 'Loc-3'
                                );
        Schema.Location loc4 = new Schema.Location(
                                    Name = 'Loc-4',
                                    LocationType = 'Warehouse',
                                    ShouldSyncWithOci = true,
                                    ExternalReference = 'Loc-4'
                                );
        
        List<Schema.Location> locations = new List<Schema.Location>();
        locations.add(loc1); 
        locations.add(loc2);
        locations.add(loc3);
        locations.add(loc4);
        insert locations;                  


        // Create LocationGroups
        List<LocationGroup> locationGroups = createLocationGroups();

        // Create Location Group Assignment
        List<LocationGroupAssignment> assignments = new List<LocationGroupAssignment> {
            new LocationGroupAssignment(
                LocationId = loc1.Id,
                LocationGroupId = locationGroups[0].Id
            ),
            new LocationGroupAssignment(
                LocationId = loc2.Id,
                LocationGroupId = locationGroups[0].Id
            ),
            new LocationGroupAssignment(
                LocationId = loc3.Id,
                LocationGroupId = locationGroups[0].Id
            ),
            new LocationGroupAssignment(
                LocationId = loc4.Id,
                LocationGroupId = locationGroups[1].Id
            )
        };
        insert assignments;

    }
    
    public static List<LocationGroup> createLocationGroups() {
        // Create LocationGroups - Default East and West Warehouse types
        LocationGroup group1 = new LocationGroup(
                                    LocationGroupName = 'East',
                                    ExternalReference = 'East',
                                    ShouldSyncWithOci = true
                                );
        LocationGroup group2 = new LocationGroup(
                                    LocationGroupName = 'West',
                                    ExternalReference = 'West',
                                    ShouldSyncWithOci = true
                                );
        
        List<LocationGroup> locationGroups = new List<LocationGroup>();
        locationGroups.add(group1);
        locationGroups.add(group2);
        insert locationGroups;
        
        return locationGroups;
    }
    
    public static List<String> getLocationGroupIDs() {
        // Query LocationGroups East and West for their IDs
        List<Schema.LocationGroup> locationGroups = [SELECT Id, ExternalReference 
                                                     FROM LocationGroup 
                                                     WHERE ExternalReference  = 'West' OR ExternalReference  = 'East'];
        
        List<String> locationGroupIDs = new List<String>();
        for(LocationGroup locationGroup : locationGroups) {
            locationGroupIDs.add(locationGroup.Id);
        }
        
        System.assertNotEquals(null, locationGroupIDs, 'Location Group IDs should not be null');
        
        return locationGroupIDs;
    }
    
    public static Account getAccount(String name) {
        List<Account> account = [SELECT Id, Name FROM Account WHERE Name =: name LIMIT 1];
        
        if (account.size() == 0) {
            return null;
        }
        
        return account[0];
    }
    
    public static Contact getContact(String accountId) {
        List<Contact> contact = [SELECT Id FROM Contact WHERE AccountId =: accountId LIMIT 1];
        
        if (contact.size() == 0) {
            return null;
        }
        
        return contact[0];
    }
    
    public static List<OrderItemSummary> getOrderItemSummaries(String orderSummaryId) {
        List<OrderItemSummary> orderItemSummaries = [SELECT Id, QuantityOrdered, StockKeepingUnit, 
                                                     Product2Id, OrderSummaryId, QuantityAvailableToFulfill, 
                                                     Type, ReservedAtLocationId, OrderDeliveryGroupSummaryId FROM OrderItemSummary WHERE OrderSummaryId =: orderSummaryId ];
        
        return orderItemSummaries;
    }
    
    public static List<OrderItemSummary> getOrderItemSummariesByIdList(List<String> orderSummaries) {
        List<OrderItemSummary> orderItemSummaries = [SELECT Id, QuantityOrdered, StockKeepingUnit, 
                                                     Product2Id, OrderSummaryId, QuantityAvailableToFulfill, 
                                                     Type, ReservedAtLocationId, OrderDeliveryGroupSummaryId FROM OrderItemSummary 
                                                     WHERE OrderSummaryId IN :orderSummaries ];
        
        return orderItemSummaries;
    }

    public static Account createAccount(String name, String email)
    {
      
        Account a = new Account(Name='SFDX Test');
        insert a;
            
        return a;
    }

    public static Contact createContact(String firstName, String lastName, String phoneNumber, String accID)
    {
        Contact con = new Contact(
            FirstName=firstName,
            LastName=lastName,
            Phone=phoneNumber,
            AccountId=accID);

        Database.DMLOptions dml = new Database.DMLOptions(); 
        dml.DuplicateRuleHeader.allowSave = true;
        Database.SaveResult sr = Database.insert(con, dml);
    
        if (sr.isSuccess()) {
            System.debug('Duplicate account has been inserted in Salesforce!');
        }

        System.debug('Contact Test: ' + con);
        
        return con;
    }

    public static SalesChannel createSalesChannel(String channelname)
    {
        SalesChannel sc = new SalesChannel();
        sc.SalesChannelName = channelname;
        
        return sc;
    }

    public static OrderItem createShippingOrderItem(Id orderId, Id product2Id, Id pricebookEntryId, Id orderDeliveryGroupId, Double amount)
    {
        OrderItem oi = new OrderItem();
        oi.OrderId = orderId;
        oi.Quantity = 1;
        oi.UnitPrice = 10;
        oi.Product2id = product2Id;
        oi.PricebookEntryId=pricebookEntryId;
        oi.OrderDeliveryGroupId = orderDeliveryGroupId;
        oi.Description = 'Shipping';
        oi.Type = 'Delivery Charge';
        oi.TotalLineAmount = amount; 
        
        return oi;
    }
    
    public static OrderDeliveryMethod createOrderDeliveryMethod(String name)
    {        
        OrderDeliveryMethod odm = new OrderDeliveryMethod(IsActive = true,
                                                          Name = name);
        
        return odm;
    }
    
    public static OrderDeliveryMethod createOrderDeliveryMethodWithProduct(String name, String externalReference, Product2 shippingProduct) {
        OrderDeliveryMethod odm = new OrderDeliveryMethod(IsActive = true,
                                                          Name = name,
                                                          ReferenceNumber = externalReference,
                                                          ProductId = shippingProduct.Id);
        
        return odm;
    }
    
    public static OrderDeliveryMethod getOrderDeliveryMethod(String externalReference) {
        List<OrderDeliveryMethod> orderDeliveryMethod = [SELECT Id, Name, ReferenceNumber FROM OrderDeliveryMethod WHERE ReferenceNumber =: externalReference LIMIT 1];
        
        if (orderDeliveryMethod.size() == 0) {
            return null;
        }
        
        return orderDeliveryMethod[0];
    }

    public static OrderDeliveryGroup createOrderDeliveryGroup(String orderId, Id orderDeliveryMethodId, 
                                                              String email, String name)
    {
        OrderDeliveryGroup odg = new OrderDeliveryGroup(DeliverToCity = 'Deerfield Beach', 
                                                       DeliverToStreet = '1166 W Newport Center Dr STE 210', 
                                                       DeliverToPostalCode = '33442',
                                                       DeliverToState = 'FL',
                                                       EmailAddress = email,
                                                       OrderId = orderId, 
                                                       DeliverToName = name, 
                                                       OrderDeliveryMethodId = orderDeliveryMethodId);        
        return odg;
    }

    
    public static Product2 createProduct2(String name, String sku) {
        Product2 p2 = new Product2();
        p2.Name = name;
        p2.StockKeepingUnit = sku;
        
        return p2;
    }
    
    public static Product2 getProduct2(String productId) {
        List<Product2> result = [SELECT Id, Name FROM Product2 WHERE Id =: productId LIMIT 1];
        System.debug('Product Search result for productId=' + productId + ': ' + result);
        if ( result == null || result.size() == 0) {
            return null;
        } else {
            return result[0];
        }
    }
    
    public static PricebookEntry getPricebookEntry(String product2Id) {
        List<PricebookEntry> result = [SELECT Id FROM PricebookEntry WHERE Product2Id =: product2Id LIMIT 1];
        
        if (result.size() == 0) {
            return null;
        }
        
        return result[0];
    }

    public static OrderItem createOrderItem(Id orderId, Id product2Id, Id pricebookEntryId, Id orderDeliveryGroupId, 
                                            Double amount, Double quantity, String reservedAtLocation)
    {
        OrderItem oi = new OrderItem();
        oi.OrderId = orderId;
        oi.Quantity = quantity;
        oi.UnitPrice = 240;
        oi.Product2id = product2Id;
        oi.PricebookEntryId=pricebookEntryId;
        oi.OrderDeliveryGroupId = orderDeliveryGroupId;
        oi.Description = 'Some Product';
        oi.TotalLineAmount = amount;
        oi.ReservedAtLocationId = reservedAtLocation;
        oi.Type = 'Order Product';
        
        return oi;
    }

    public static PriceBookEntry createPriceBookEntry(String productId, String priceBookId)
    {
       PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = priceBookId;
        pbe.Product2Id = productId;
        pbe.UnitPrice = 100;
        pbe.IsActive = true;

       return pbe ;
    }

    public static Order createOrder(Id accountId, Id pricebook2Id, Id salesChannelId, String email)
    {
        Order o = new Order(Name = 'Order123456', 
                            AccountId = accountId, 
                            EffectiveDate = system.today(), 
                            status = 'Draft',
                            Pricebook2Id = pricebook2Id, 
                            SalesChannelId= salesChannelId,
                            OrderReferenceNumber ='CCS-Standard3', 
                            BillingStreet = '1166 W Newport Center Dr STE 210', 
                            BillingState= 'FL', 
                            BillingCountry = 'US', 
                            BillingPostalCode = '33442', 
                            BillingCity ='Deerfield Beach', 
                            OrderedDate = system.today(),
                            BillingEmailAddress = email);
        
        return o;
    }

    public static String createOrderSummary(String orderId)
    {
        ConnectApi.OrderSummaryInputRepresentation inputRep  = new ConnectApi.OrderSummaryInputRepresentation();
        inputRep.orderId = orderId;
        inputRep.orderLifeCycleType = 'Managed';
        inputRep.name = 'OrderSummary' + orderId;
        
        ConnectApi.OrderSummaryOutputRepresentation outputRep = new ConnectApi.OrderSummaryOutputRepresentation();
        outputRep = connectapi.OrderSummaryCreation.createOrderSummary(inputRep);
        
        return outputRep.orderSummaryId;
    }

    
    public static String getOrderSummaryDeliveryGroup(String orderSummaryId){
        List<OrderDeliveryGroupSummary> odgs = [SELECT Id  FROM OrderDeliveryGroupSummary WHERE OrderSummaryId =: orderSummaryId LIMIT 1];
        return odgs[0].Id;
    }
    
    public static String getOrderSummaryItems(String orderSummaryId){
        List<OrderItemSummary> ois = [SELECT Id  FROM OrderItemSummary WHERE OrderSummaryId =: orderSummaryId LIMIT 1];
        return ois[0].Id;
    }
    
    public static List<OrderItem> createOrderAndOrderItems(String timestamp) {
        // Creating Availability Data       
        TestDataGenerator.createLocationGroups();
        List<ConnectApi.OCIInventoryRecordOutputRepresentation> inventoryRecords = new List<ConnectApi.OCIInventoryRecordOutputRepresentation>();
        ConnectApi.OCIInventoryRecordOutputRepresentation record1 = new ConnectApi.OCIInventoryRecordOutputRepresentation();
        String sku1 = 'sku1' + timestamp;
        record1.stockKeepingUnit = sku1;
        record1.availableToFulfill = 10;
        record1.availableToOrder = 10;
        record1.onHand = 5;

        ConnectApi.OCIInventoryRecordOutputRepresentation record1_1 = new ConnectApi.OCIInventoryRecordOutputRepresentation();
        String sku1_1 = 'sku1_1' + timestamp;
        record1_1.stockKeepingUnit = sku1_1;
        record1_1.availableToFulfill = 10;
        record1_1.availableToOrder = 10;
        record1_1.onHand = 5;

        ConnectApi.OCIInventoryRecordOutputRepresentation record1_2 = new ConnectApi.OCIInventoryRecordOutputRepresentation();
        String sku1_2 = 'sku1_2' + timestamp;
        record1_2.stockKeepingUnit = sku1_2;
        record1_2.availableToFulfill = 10;
        record1_2.availableToOrder = 10;
        record1_2.onHand = 5;

        ConnectApi.OCIInventoryRecordOutputRepresentation record2 = new ConnectApi.OCIInventoryRecordOutputRepresentation();
        String sku2 = 'sku2' + timestamp;
        record2.stockKeepingUnit = sku2;
        record2.availableToFulfill = 10;
        record2.availableToOrder = 5;
        record2.onHand = 6;
        
        ConnectApi.OCIInventoryRecordOutputRepresentation record3 = new ConnectApi.OCIInventoryRecordOutputRepresentation();
        String sku3 = 'sku3' + timestamp;
        record3.stockKeepingUnit = sku3;
        record3.availableToFulfill = 1;
        record3.availableToOrder = 1;
        
        inventoryRecords.add(record1);
        inventoryRecords.add(record1_1);
        inventoryRecords.add(record1_2);
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
        Product2 p1_1 = TestDataGenerator.createProduct2('P1_1', sku1_1);
        insert p1_1;
        Product2 p1_2 = TestDataGenerator.createProduct2('P1_2', sku1_2);
        insert p1_2;
        
        Product2 p2 = TestDataGenerator.createProduct2('P2', sku2);
        insert p2;        
        
        PriceBookEntry pbe1 = TestDataGenerator.createPriceBookEntry(p1.Id, System.Test.getStandardPricebookId());
        insert pbe1;
        PriceBookEntry pbe1_1 = TestDataGenerator.createPriceBookEntry(p1_1.Id, System.Test.getStandardPricebookId());
        insert pbe1_1;
        PriceBookEntry pbe1_2 = TestDataGenerator.createPriceBookEntry(p1_2.Id, System.Test.getStandardPricebookId());
        insert pbe1_2;
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
            
      System.debug(logginglevel.DEBUG, 'New Shipping Entry Created: ' + odm);
        } else {
            // Query for Product2 entry and pb entry
            p3 = TestDataGenerator.getProduct2(odm.ProductId);
            System.debug(logginglevel.DEBUG, 'Found p3 ' + p3);
            pbe3 = TestDataGenerator.getPricebookEntry(odm.ProductId);
            System.debug(logginglevel.DEBUG, 'Retrieved Shipping Charge Product Entry ' + p3.Id + ' and PricebookEntry '+ pbe3.Id);
        }
        
        OrderDeliveryGroup orderDeliveryGroup = TestDataGenerator.createOrderDeliveryGroup(order.Id, odm.Id, testEmail, fullName);
        insert orderDeliveryGroup;
        
        System.debug(logginglevel.DEBUG, 'Order Delivery Method Referenced: ' + odm);
        
        List<String> locationGroupIDs = TestDataGenerator.getLocationGroupIDs();
        String reservedAtLocation = locationGroupIDs[0];
        
        OrderItem oi1 =  TestDataGenerator.createOrderItem(order.Id, p1.Id, pbe1.Id, orderDeliveryGroup.Id, 200.0d, 2, reservedAtLocation);
        insert oi1;
        OrderItem oi1_1 =  TestDataGenerator.createOrderItem(order.Id, p1_1.Id, pbe1_1.Id, orderDeliveryGroup.Id, 200.0d, 2, reservedAtLocation);
        insert oi1_1;
        OrderItem oi1_2 =  TestDataGenerator.createOrderItem(order.Id, p1_2.Id, pbe1_2.Id, orderDeliveryGroup.Id, 200.0d, 2, reservedAtLocation);
        insert oi1_2;

        //children node like a regular items, purchased individually
        OrderItem oi1_2_i =  TestDataGenerator.createOrderItem(order.Id, p1_2.Id, pbe1_2.Id, orderDeliveryGroup.Id, 200.0d, 2, reservedAtLocation);
        insert oi1_2_i;

        OrderItem oi2 =  TestDataGenerator.createOrderItem(order.Id, p2.Id, pbe2.Id, orderDeliveryGroup.Id, 249.0d, 2, reservedAtLocation);
        insert oi2;
        OrderItem oi3 =  TestDataGenerator.createShippingOrderItem(order.Id, p3.Id, pbe3.Id, orderDeliveryGroup.Id, 20.0d);
        insert oi3;
            
        System.debug(logginglevel.DEBUG, 'Shipping Order Item: ' + oi3);
        System.debug(logginglevel.DEBUG, 'Shipping Order Item Id: ' + oi3.Id);

        List<OrderItem> orderItems = new List<OrderItem>();
        orderItems.add(oi1);
        orderItems.add(oi1_1);
        orderItems.add(oi1_2);
        orderItems.add(oi1_2_i);
        orderItems.add(oi2);
        orderItems.add(oi3);
        
        return orderItems;
    }
}