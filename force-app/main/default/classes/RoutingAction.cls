public with sharing class RoutingAction {
    public RoutingAction() {
    }
    
    
    @InvocableMethod(label='Generate Interaction Order Summary Data' description='Generate Interaction Order Summary Data' category='Order Management')
    public static List<RoutingActionResult> generateRoutingData(List<RoutingActionInput> inputs){
        // This method is the entry point for the routing logic. It processes a list of inputs and returns routing results.
        
        List<RoutingActionResult> results = new List<RoutingActionResult>();
        Set<ID> locationGroupSet = new Set<ID>();
        
        
        // Collect all location group IDs from the inputs
        for (RoutingActionInput input : inputs) {
            locationGroupSet.addAll(input.locationGroupIds);
        }
        
        
        // Query LocationGroupAssignments for the given location groups
        // This retrieves the mapping between locations and their external references
        List<Schema.LocationGroupAssignment> locationGroupAssignments = [SELECT LocationId, LocationExternalReference  
            FROM LocationGroupAssignment 
            WHERE LocationGroupId  IN: locationGroupSet];
        
        
        // Create a map of LocationExternalReference to LocationGroupAssignment for quick lookup
        Map<String,Schema.LocationGroupAssignment> mapLocation = new Map<String,Schema.LocationGroupAssignment>();
        for (Schema.LocationGroupAssignment locationGroupAssignment : locationGroupAssignments) {
            if (!mapLocation.containsKey(locationGroupAssignment.LocationExternalReference)) {
                mapLocation.put(locationGroupAssignment.LocationExternalReference,locationGroupAssignment);
            }
        }
        
        
        // Process each input
        for (RoutingActionInput input : inputs) {
            
            RoutingActionResult result = new RoutingActionResult();
            RoutingActionOutput output = new RoutingActionOutput();
            
            
            // Create a map of location identifiers to their inventory availability
            // This map will be used to quickly look up inventory information for each location
            Map<String,List<ConnectApi.OCILocationAvailabilityOutputRepresentation>> locationInvtMap =
                new  Map<String,List<ConnectApi.OCILocationAvailabilityOutputRepresentation>>();
            
            // Populate the locationInvtMap
            // This loop organizes inventory data by location for efficient access later
            for (ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation inventory : input.inventoryAvailabilityList) {
                for (ConnectApi.OCILocationAvailabilityOutputRepresentation location : inventory.locations) {
                    // Only consider locations that are in the ranked list of available locations to fulfill
                    if (input.rankAvailableLocationsToFulfill.contains(location.locationIdentifier)) {
                        // Add the location to the map, creating a new list if it doesn't exist
                        if (locationInvtMap.containsKey(location.locationIdentifier)) {
                            locationInvtMap.get(location.locationIdentifier).add(location);
                        } else {
                            List<ConnectApi.OCILocationAvailabilityOutputRepresentation> listInv =
                                new List<ConnectApi.OCILocationAvailabilityOutputRepresentation>();
                            listInv.add(location);
                            locationInvtMap.put(location.locationIdentifier,listInv);
                        }
                    }
                }
            }
            
            
            // Initialize data structures for processing
            Map<String, RoutingGroup> mapRoutingGroup = new Map<String, RoutingGroup>();
            List<OrderItemSummary> deliveryChargeItems = new List<OrderItemSummary>();
            Map<Id, OrderItemSummary> orderItemSummaryMap = new Map<Id, OrderItemSummary>();
            Map<Id, List<OrderItemSummaryRelationship>> bundleParentRelationshipMap = new Map<Id, List<OrderItemSummaryRelationship>>();
            Map<Id, OrderItemSummaryRelationship> bundleChildrenRelationshipMap = new Map<Id, OrderItemSummaryRelationship>();
            
            
            // Create a map of OrderItemSummary Id to OrderItemSummary for quick lookup
            for (OrderItemSummary ois : input.orderItemSummaries) {
                orderItemSummaryMap.put(ois.Id, ois);
            }
            
            
            // Create a map of parent OrderItemSummary Id to list of child OrderItemSummaryRelationships, and children with null
            if(input.orderItemSummaryRelationships != null && !input.orderItemSummaryRelationships.isEmpty()){
                for (OrderItemSummaryRelationship oisr : input.orderItemSummaryRelationships) {
                    //parents
                    if (!bundleParentRelationshipMap.containsKey(oisr.MainOrderItemSummaryId)) {
                        bundleParentRelationshipMap.put(oisr.MainOrderItemSummaryId, new List<OrderItemSummaryRelationship>());
                    }
                    bundleParentRelationshipMap.get(oisr.MainOrderItemSummaryId).add(oisr);

                    //children
                    bundleChildrenRelationshipMap.put(oisr.AssociatedOrderItemSummaryId, oisr);
                }
            }
            
            // Process each order item
            // This loop determines whether each item is a delivery charge, a bundle, or a regular product
            // and processes it accordingly
            for (OrderItemSummary orderItemSummary : input.orderItemSummaries) {
                if (orderItemSummary.Type == 'Delivery Charge') {
                    deliveryChargeItems.add(orderItemSummary);
                } else {
                    processOrderItem(orderItemSummary, input, mapRoutingGroup, locationInvtMap, mapLocation, bundleParentRelationshipMap, bundleChildrenRelationshipMap, orderItemSummaryMap);
                }
            }
            
            
            // Handle delivery charge items
            // Delivery charges are added to the first routing group (if any exist)
            if (deliveryChargeItems.size() > 0 && !mapRoutingGroup.isEmpty()) {
                // Add delivery charges to the first routing group
                for (OrderItemSummary deliveryChargeItem : deliveryChargeItems) {
                    RoutingItem routingItem = new RoutingItem();
                    routingItem.orderItemSummaryId = deliveryChargeItem.Id;
                    routingItem.quantity = deliveryChargeItem.QuantityAvailableToFulfill;
                    mapRoutingGroup.values().get(0).routingItems.add(routingItem);
                }
            }
            
            
            // Prepare the output
            output.orderDeliveryGroupSummaryId = input.orderDeliveryGroupSummaryId;
            output.orderSummaryId = input.orderSummaryId;
            output.routingGroupList = mapRoutingGroup.values();
            result.output = output;
            
            
            results.add(result);
            
        }
        
        
        return results;
        
        
    }
    
    
    private static void processOrderItem(OrderItemSummary orderItemSummary, RoutingActionInput input,
    Map<String, RoutingGroup> mapRoutingGroup,
    Map<String, List<ConnectApi.OCILocationAvailabilityOutputRepresentation>> locationInvtMap,
    Map<String, Schema.LocationGroupAssignment> mapLocation,
    Map<Id, List<OrderItemSummaryRelationship>> bundleParentRelationshipMap,
    Map<Id, OrderItemSummaryRelationship> bundleChildrenRelationshipMap,
    Map<Id, OrderItemSummary> orderItemSummaryMap) {
        
        // Check if the order item is part of a bundle
        if (bundleParentRelationshipMap.containsKey(orderItemSummary.Id) || bundleChildrenRelationshipMap.containsKey(orderItemSummary.Id)) {
             System.debug(logginglevel.DEBUG, ' ----- starting processBundleProduct for ' + orderItemSummary);
            processBundleProduct(orderItemSummary, input, mapRoutingGroup, locationInvtMap, mapLocation, bundleParentRelationshipMap, bundleChildrenRelationshipMap, orderItemSummaryMap);
        } else {
             System.debug(logginglevel.DEBUG, ' ----- starting processOrderItem for ' + orderItemSummary);
            processOrderItem(orderItemSummary, input, mapRoutingGroup, locationInvtMap, mapLocation, bundleChildrenRelationshipMap);
        }
    }
    
    
    /**
     * Processes a bundle product, handling inventory at parent or child level.
     *
     * Example:
     * Parent: "Gaming Console Bundle" (Quantity: 2)
     * Children:
     *   - "PlayStation 5" (Quantity: 2)
     *   - "PlayStation Controller" (Quantity: 4)
     *
     * If inventory at parent:
     *   - Process parent, then add children proportionally
     * If inventory at children:
     *   - Process each child, then add parent based on fulfillment ratio
     */
    private static void processBundleProduct(OrderItemSummary item, RoutingActionInput input,
        Map<String, RoutingGroup> mapRoutingGroup,
        Map<String, List<ConnectApi.OCILocationAvailabilityOutputRepresentation>> locationInvtMap,
        Map<String, Schema.LocationGroupAssignment> mapLocation,
        Map<Id, List<OrderItemSummaryRelationship>> bundleParentRelationshipMap,
        Map<Id, OrderItemSummaryRelationship> bundleChildrenRelationshipMap,
        Map<Id, OrderItemSummary> orderItemSummaryMap) {
        
        //skip children since those are handled as part of parent processing
        if(bundleChildrenRelationshipMap.containsKey(item.Id)){
            return;
        }
        
        List<OrderItemSummaryRelationship> childRelationships = bundleParentRelationshipMap.get(item.Id);

        // Check if inventory is managed at the parent level or child level
        Boolean inventoryAtParent = childRelationships[0].AssociatedOrderItemInventory == null || childRelationships[0].AssociatedOrderItemInventory == 'IncludedInMainInventory';
        
        
        if (inventoryAtParent) {
             System.debug(logginglevel.DEBUG, ' ----- starting processBundleProduct.processOrderItem and addChildrenToRoutingGroups');
            // If inventory is managed at parent level, process the parent as a regular product
            processOrderItem(item, input, mapRoutingGroup, locationInvtMap, mapLocation, bundleChildrenRelationshipMap);
            // Then add children to the same routing groups as the parent
            addChildrenToRoutingGroups(item, childRelationships, mapRoutingGroup, orderItemSummaryMap);
        } else {
            // If inventory is managed at child level, process each child individually
             System.debug(logginglevel.DEBUG, ' ----- starting processBundleProduct.processChildrenWithInventory');
            processChildrenWithInventory(item, childRelationships, input, mapRoutingGroup, locationInvtMap, mapLocation, orderItemSummaryMap, bundleChildrenRelationshipMap);
        }
    }
    
    
    private static void processOrderItem(OrderItemSummary orderItemSummary, RoutingActionInput input,
    Map<String, RoutingGroup> mapRoutingGroup,
    Map<String, List<ConnectApi.OCILocationAvailabilityOutputRepresentation>> locationInvtMap,
    Map<String, Schema.LocationGroupAssignment> mapLocation,
    Map<Id, OrderItemSummaryRelationship> bundleChildrenRelationshipMap) {
        Double missingQuantityToFulfill = orderItemSummary.QuantityAvailableToFulfill;
        
        
        for (String rankAvailableLocationToFulfill : input.rankAvailableLocationsToFulfill) {
            List<ConnectApi.OCILocationAvailabilityOutputRepresentation> locations = locationInvtMap.get(rankAvailableLocationToFulfill);
            ID currentLocationId = mapLocation.get(rankAvailableLocationToFulfill).LocationId;
            
            for (ConnectApi.OCILocationAvailabilityOutputRepresentation location : locations) {
                for (ConnectApi.OCIInventoryRecordOutputRepresentation inventoryRecord : location.inventoryRecords) {
                    if (inventoryRecord.stockKeepingUnit == orderItemSummary.StockKeepingUnit &&
                        inventoryRecord.availableToFulfill > 0 &&
                    missingQuantityToFulfill > 0.0) {
                        
                        RoutingItem routingItem = new RoutingItem();
                        routingItem.reservedAtLocationId = orderItemSummary.ReservedAtLocationId;
                        routingItem.orderItemSummaryId = orderItemSummary.Id;
                        
                        if(bundleChildrenRelationshipMap.containsKey(orderItemSummary.Id)){
                            routingItem.mainOrderItemSummary = bundleChildrenRelationshipMap.get(orderItemSummary.Id).MainOrderItemSummaryId;
                            routingItem.associatedItemInventory = bundleChildrenRelationshipMap.get(orderItemSummary.Id).AssociatedOrderItemInventory;
                        }
                        
                        if (inventoryRecord.availableToFulfill >= missingQuantityToFulfill) {
                            routingItem.quantity = missingQuantityToFulfill;
                            missingQuantityToFulfill = 0.0;
                        } else {
                            routingItem.quantity = inventoryRecord.availableToFulfill;
                            missingQuantityToFulfill -= inventoryRecord.availableToFulfill;
                        }
                        
                        addToRoutingGroup(mapRoutingGroup, currentLocationId, routingItem);
                    }
                }
            }
        }
    }
    
    
    /**
     * Processes children with inventory and calculates parent distribution.
     *
     * Example 1:
     * Parent: "Gaming Console Bundle" (Quantity: 2)
     * Children:
     *   - "PlayStation 5" (Quantity: 2)
     *   - "PlayStation Controller" (Quantity: 4)
     *
     * If Location A can fulfill:
     *   - 1 PlayStation 5
     *   - 2 PlayStation Controllers
     * And Location B can fulfill:
     *   - 1 PlayStation 5
     *   - 2 PlayStation Controllers
     *
     * Result:
     * Location A RoutingGroup:
     *   - "Gaming Console Bundle" (Quantity: 1)
     *   - "PlayStation 5" (Quantity: 1)
     *   - "PlayStation Controller" (Quantity: 2)
     * Location B RoutingGroup:
     *   - "Gaming Console Bundle" (Quantity: 1)
     *   - "PlayStation 5" (Quantity: 1)
     *   - "PlayStation Controller" (Quantity: 2)
     *
     * Example 2:
     * Parent: "Gaming Console Bundle" (Quantity: 1)
     * Children:
     *   - "PlayStation 5" (Quantity: 1)
     *   - "PlayStation Controller" (Quantity: 2)
     *   - "Game Disc" (Quantity: 1)
     *
     * If Location A can fulfill:
     *   - 1 PlayStation 5
     *   - 1 PlayStation Controller
     * And Location B can fulfill:
     *   - 1 PlayStation Controller
     *   - 1 Game Disc
     *
     * Result:
     * Location A RoutingGroup:
     *   - "Gaming Console Bundle" (Quantity: 0.67, rounded to 1)
     *   - "PlayStation 5" (Quantity: 1)
     *   - "PlayStation Controller" (Quantity: 1)
     * Location B RoutingGroup:
     *   - "Gaming Console Bundle" (Quantity: 0.33, rounded to 0)
     *   - "PlayStation Controller" (Quantity: 1)
     *   - "Game Disc" (Quantity: 1)
     */
    private static void processChildrenWithInventory(OrderItemSummary parentItem,
        List<OrderItemSummaryRelationship> childRelationships,
        RoutingActionInput input,
        Map<String, RoutingGroup> mapRoutingGroup,
        Map<String, List<ConnectApi.OCILocationAvailabilityOutputRepresentation>> locationInvtMap,
        Map<String, Schema.LocationGroupAssignment> mapLocation,
        Map<Id, OrderItemSummary> orderItemSummaryMap,
        Map<Id, OrderItemSummaryRelationship> bundleChildrenRelationshipMap) {
        
        System.debug(' ----- start processChildrenWithInventory:' + mapRoutingGroup + locationInvtMap);
        
        // Process child items and track which locations have child items
        Set<Id> locationsWithChildItems = new Set<Id>();
        for (OrderItemSummaryRelationship childRelationship : childRelationships) {
            OrderItemSummary childItem = orderItemSummaryMap.get(childRelationship.AssociatedOrderItemSummaryId);
            processOrderItem(childItem, input, mapRoutingGroup, locationInvtMap, mapLocation, bundleChildrenRelationshipMap);
            
            // Track locations that have child items
            for (RoutingGroup rg : mapRoutingGroup.values()) {
                for (RoutingItem ri : rg.routingItems) {
                    if (ri.orderItemSummaryId == childItem.Id) {
                        locationsWithChildItems.add(rg.fulfillFromLocationId);
                        break;
                    }
                }
            }
        }
        
        // Get the list of locations that have child items
        List<Id> locationsWithInventory = new List<Id>(locationsWithChildItems);
        Integer numLocations = locationsWithInventory.size();
        
        if (numLocations == 0) {
            return; // No inventory available for child items, nothing to distribute
        }
        
        Integer parentQuantity = (Integer)parentItem.QuantityAvailableToFulfill;
        Integer baseQuantity = parentQuantity / numLocations;
        Integer remainingQuantity = parentQuantity - (baseQuantity * numLocations);
        
        // Distribute parent quantity across locations with child items. If parent quantity is less than the number of groups needed to fulfill, 
        // some parent will have less quantity than other or ) in some cases
        // You could also choose to assign all parent quantities to the first group, or a completely different strategy
        for (Integer i = 0; i < numLocations; i++) {
            Id locationId = locationsWithInventory[i];
            Integer quantityForLocation = baseQuantity;
            
            if (i < remainingQuantity) {
                quantityForLocation++;
            }

            RoutingItem parentRoutingItem = new RoutingItem();
            parentRoutingItem.orderItemSummaryId = parentItem.Id;
            parentRoutingItem.quantity = quantityForLocation;
            parentRoutingItem.reservedAtLocationId = parentItem.ReservedAtLocationId;
            addToRoutingGroup(mapRoutingGroup, locationId, parentRoutingItem);
        }


        System.debug(' ----- Finished processChildrenWithInventory:' + mapRoutingGroup + locationInvtMap);
    }
    
    
    /**
     * Adds children to routing groups based on parent distribution.
     *
     * Example:
     * Parent: "Gaming Console Bundle" (Quantity: 2)
     * Children:
     *   - "PlayStation 5" (Quantity: 2, Scale: Proportional)
     *   - "PlayStation Controller" (Quantity: 4, Scale: Proportional)
     *
     * If parent is split:
     * Location A RoutingGroup (Parent Quantity: 1):
     *   - "PlayStation 5" (Quantity: 1)
     *   - "PlayStation Controller" (Quantity: 2)
     * Location B RoutingGroup (Parent Quantity: 1):
     *   - "PlayStation 5" (Quantity: 1)
     *   - "PlayStation Controller" (Quantity: 2)
     *
     * Example 2: Mixed scaling (Proportional and Constant)
     * Parent: "Gaming Console Bundle" (Quantity: 2)
     * Children:
     *   - "PlayStation 5" (Quantity: 2, Scale: Proportional)
     *   - "PlayStation Controller" (Quantity: 4, Scale: Proportional)
     *   - "Antivirus License" (Quantity: 1, Scale: Constant)
     *
     * If parent is split:
     * Location A RoutingGroup (Parent Quantity: 1):
     *   - "PlayStation 5" (Quantity: 1)
     *   - "PlayStation Controller" (Quantity: 2)
     *   - "Antivirus License" (Quantity: 1)
     * Location B RoutingGroup (Parent Quantity: 1):
     *   - "PlayStation 5" (Quantity: 1)
     *   - "PlayStation Controller" (Quantity: 2)
     *
     */
    private static void addChildrenToRoutingGroups(OrderItemSummary parentItem,
    List<OrderItemSummaryRelationship> childRelationships,
    Map<String, RoutingGroup> mapRoutingGroup,
    Map<Id, OrderItemSummary> orderItemSummaryMap) {
        // Keep track of remaining quantities for each child item
        Map<Id, Decimal> childItemRemainingQuantities = new Map<Id, Decimal>();
        
        Map<Id, OrderItemSummaryRelationship> childRelationshipsMap = new Map<Id, OrderItemSummaryRelationship>();
        
        // Initialize remaining quantities for child items
        for (OrderItemSummaryRelationship childRelationship : childRelationships) {
            OrderItemSummary childItem = orderItemSummaryMap.get(childRelationship.AssociatedOrderItemSummaryId);
            childItemRemainingQuantities.put(childItem.Id, childItem.QuantityAvailableToFulfill);
            childRelationshipsMap.put(childItem.Id, childRelationship);
        }
        
        
        // Distribute child items across parent routing groups
        for (RoutingGroup rg : mapRoutingGroup.values()) {
            List<RoutingItem> newRoutingItems = new List<RoutingItem>();
            for (RoutingItem ri : rg.routingItems) {
                if (ri.orderItemSummaryId == parentItem.Id) {
                    // Calculate the ratio of this routing item to the total parent quantity
                    Decimal parentQuantityRatio = ri.quantity / parentItem.QuantityAvailableToFulfill;
                    
                    for (OrderItemSummaryRelationship childRelationship : childRelationships) {
                        OrderItemSummary childItem = orderItemSummaryMap.get(childRelationship.AssociatedOrderItemSummaryId);
                        // Calculate the quantity to allocate for this child item in this routing group
                        Decimal childQuantityToAllocate = calculateChildQuantityToAllocate(childItem, parentQuantityRatio, childItemRemainingQuantities);
                        
                        if (childQuantityToAllocate > 0) {
                            // Create a new routing item for the child
                            RoutingItem childRoutingItem = new RoutingItem();
                            childRoutingItem.orderItemSummaryId = childItem.Id;
                            childRoutingItem.quantity = childQuantityToAllocate;
                            childRoutingItem.reservedAtLocationId = childItem.ReservedAtLocationId;
                            
                            if(childRelationshipsMap.containsKey(childItem.Id)){
                                childRoutingItem.mainOrderItemSummary = childRelationshipsMap.get(childItem.Id).MainOrderItemSummaryId;
                                childRoutingItem.associatedItemInventory = childRelationshipsMap.get(childItem.Id).AssociatedOrderItemInventory;
                            }
                            
                            newRoutingItems.add(childRoutingItem);
                            
                            // Update remaining quantity for the child item
                            childItemRemainingQuantities.put(childItem.Id, childItemRemainingQuantities.get(childItem.Id) - childQuantityToAllocate);
                        }
                    }
                }
            }
            rg.routingItems.addAll(newRoutingItems);
        }
    }
    
    
    /**
     * Calculates the quantity to allocate for a child item based on parent ratio.
     *
     * Example:
     * Parent: "Gaming Console Bundle" (Total Quantity: 3, Current RoutingGroup Quantity: 2)
     * Child: "PlayStation Controller" (Total Quantity: 6, Scale: Proportional)
     *
     * Scenario:
     * - This is the first RoutingGroup being processed.
     * - All 6 controllers are still available to be allocated.
     *
     * Calculation:
     * 1. Parent Ratio = Current RoutingGroup Quantity / Total Parent Quantity
     *    Parent Ratio = 2 / 3 ≈ 0.67
     *
     * 2. Initial Child Quantity to Allocate = Total Child Quantity * Parent Ratio
     *    Initial Child Quantity to Allocate = 6 * 0.67 = 4
     *
     * 3. Check against remaining quantity (which is 6, as this is the first allocation)
     *    Final Child Quantity to Allocate = min(4, 6) = 4
     *
     * Result:
     * - 4 PlayStation Controllers will be allocated to this RoutingGroup.
     * - The remaining quantity for future allocations will be updated to 2.
     *
     * @param childItem The child OrderItemSummary
     * @param parentQuantityRatio The ratio of parent quantity in current RoutingGroup to total parent quantity
     * @param childItemRemainingQuantities Map of remaining quantities for child items
     * @return The quantity to allocate for the child item in the current RoutingGroup
     */
    private static Decimal calculateChildQuantityToAllocate(OrderItemSummary childItem, Decimal parentQuantityRatio, Map<Id, Decimal> childItemRemainingQuantities) {
        // Get the remaining quantity for this child item
        Decimal remainingQuantity = childItemRemainingQuantities.get(childItem.Id);
        // Calculate the quantity to allocate based on the parent ratio, but don't exceed the remaining quantity
        Decimal quantityToAllocate = Math.min(remainingQuantity, childItem.QuantityAvailableToFulfill * parentQuantityRatio);
        // Round to two decimal places
        return quantityToAllocate.setScale(2, System.RoundingMode.HALF_UP);
    }
    
    
    private static void addToRoutingGroup(Map<String, RoutingGroup> mapRoutingGroup, Id locationId, RoutingItem routingItem) {
        // Add a routing item to the appropriate routing group, creating a new group if necessary
        if (mapRoutingGroup.containsKey(locationId)) {
            // If the routing group for this location already exists, add the routing item to it
            mapRoutingGroup.get(locationId).routingItems.add(routingItem);
        } else {
            // If the routing group doesn't exist, create a new one and add the routing item
            RoutingGroup rg = new RoutingGroup();
            rg.routingItems = new List<RoutingItem>{routingItem};
            rg.fulfillFromLocationId = locationId;
            mapRoutingGroup.put(locationId, rg);
        }
    }
}