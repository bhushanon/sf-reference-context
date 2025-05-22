public with sharing class ProductAnnouncementsController {
    @AuraEnabled(cacheable=true)
    public static List<Announcement__c> getActiveAnnouncements(Id productId) {
        Date today = Date.today();
        return [
            SELECT Id, Description__c, Type__c
            FROM Announcement__c
            WHERE Product__c = :productId
            AND Status__c = 'Active'
            AND StartDate__c <= :today
            AND EndDate__c >= :today
        ];
    }
}
