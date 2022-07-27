public class EventLocationCheckinController {

	@AuraEnabled
    public static String updateEvent(String eventId, Decimal latValue, Decimal lngValue){

        Event event = new Event(
            Id                          = eventId,
            CheckInDone__c              = true,
            Checkin__Latitude__s        = latValue,
            Checkin__Longitude__s       = lngValue,
            CheckinDate__c              = Datetime.now(),
            OwnerId                     = UserInfo.getUserId(),
            GeolocationPermission__c    = true
        );

        Database.update(event, false);
        
        return eventId;

	}
}