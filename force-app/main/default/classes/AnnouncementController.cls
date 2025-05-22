public with sharing class AnnouncementController {
    @AuraEnabled(cacheable=true)
    public static List<Announcement__c> getAnnouncements(Id productId) {
        Date today = Date.today();
        return [
            SELECT Id, Description__c, Type__c
            FROM Announcement__c
            WHERE Related_Product__c = :productId
            AND Status__c = 'Active'
            AND Start_Date__c <= :today
            AND End_Date__c >= :today
        ];
    }
}