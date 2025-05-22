import { LightningElement, api, wire } from 'lwc';
import getAnnouncements from '@salesforce/apex/AnnouncementController.getAnnouncements';

export default class ProductAnnouncements extends LightningElement {
    @api recordId;
    announcements;

    @wire(getAnnouncements, { productId: '$recordId' })
    wiredAnnouncements({ error, data }) {
        if (data) {
            this.announcements = data.map(announcement => ({
                ...announcement,
                icon: this.getIconName(announcement.Type__c),
                description: announcement.Description__c,
                type: announcement.Type__c
            }));
        } else if (error) {
            console.error('Error fetching announcements:', error);
        }
    }

    getIconName(type) {
        switch (type) {
            case 'Info':
                return 'utility:info';
            case 'Warning':
                return 'utility:warning';
            case 'Update':
                return 'utility:refresh';
            case 'Critical':
                return 'utility:error';
            default:
                return 'utility:info';
        }
    }
}
