@isTest
private class AnnouncementControllerTest {
    @isTest
    static void testGetAnnouncements() {
        // Setup test data
        Product2 product = new Product2(Name = 'Test Product');
        insert product;

        Announcement__c announcement = new Announcement__c(
            Description__c = 'Test Announcement',
            Type__c = 'Info',
            Status__c = 'Active',
            Start_Date__c = Date.today().addDays(-1),
            End_Date__c = Date.today().addDays(1),
            Related_Product__c = product.Id
        );
        insert announcement;

        Test.startTest();
        List<Announcement__c> announcements = AnnouncementController.getAnnouncements(product.Id);
        Test.stopTest();

        // Assertions
        System.assertEquals(1, announcements.size(), 'There should be one announcement');
        System.assertEquals('Test Announcement', announcements[0].Description__c, 'The announcement description should match');
    }
}