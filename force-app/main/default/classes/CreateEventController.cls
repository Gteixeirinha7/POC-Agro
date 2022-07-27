@RestResource(urlMapping='/ForcaAgroApp/1_0/sendEventData/*')
global with sharing class CreateEventController {

    @HttpPost
    global static EventResponse createEventApp(String eventReq){
        EventResponse eventResponse = null;
        Savepoint sp = null;

        EventRequest eventRequest = (EventRequest)JSON.deserialize(eventReq, EventRequest.class);
        try{
            sp = Database.setSavepoint();

            Event event = serializeEvent(eventRequest);

            if (eventRequest.deleted) {
                List<Event> eventList = [SELECT Id FROM Event WHERE Id = :event.Id];
                if (eventList.size() > 0) {
                    Database.DeleteResult delResult = Database.delete(event, false);

                    if(delResult.isSuccess()){
                        return new EventResponse(eventRequest, delResult.getId());
                    } else {
                        return new EventResponse(delResult.getErrors()[0].getMessage(), eventRequest);
                    }
                } else {
                    return new EventResponse(eventRequest, event.Id);
                }
            } else {
                Boolean updateContext = (event.Id != null);

                Database.SaveResult upsResult = updateContext ? Database.update(event, false) : Database.insert(event, false); 

                if(upsResult.isSuccess()){
                    return new EventResponse(eventRequest, upsResult.getId());
                } else {
                    return new EventResponse(upsResult.getErrors()[0].getMessage(), eventRequest);
                }
            }

        } catch (Exception e) {
            Database.rollback(sp);
            eventResponse = new EventResponse(e, eventRequest);
        }

        return eventResponse;
    }

    global class EventRequest extends EventBaseRequest{}

    global abstract class EventBaseRequest{
        public String   id              {get;set;}
        public Integer  appCode         {get;set;}
        public String   subject         {get;set;}
        public String   accountId       {get;set;}
        public String   caseId          {get;set;}
        public String   cropId          {get;set;}
        public String   startDate       {get;set;}
        public String   startTime       {get;set;}
        public String   endDate         {get;set;}
        public String   endTime         {get;set;}
        public String   eventTypeId     {get;set;}
        public String   ownerId         {get;set;}
        public Location checkIn         {get;set;}
        public String   checkInDate     {get;set;}
        public String   checkInHour     {get;set;}
        public String   visitOpinion    {get;set;}
        public Boolean  checkInDone     {get;set;}
        public Boolean  geoLocationPermission {get;set;}
        public Boolean  deleted         {get;set;}
    }

    public static Event serializeEvent(EventRequest eventRequest) {
        Event event = new Event(
            Id                      = eventRequest.id,
            Subject                 = eventRequest.subject,
            Account__c              = eventRequest.accountId,
            Case__c                 = eventRequest.caseId, 
            Crop__c                 = eventRequest.cropId,
            StartDateTime           = buildDatetime(eventRequest.startDate, eventRequest.startTime),
            EndDateTime             = buildDatetime(eventRequest.endDate, eventRequest.endTime),
            EventType__c            = eventRequest.eventTypeId,
            OwnerId                 = eventRequest.ownerId
        );

        if (event.OwnerId == UserInfo.getUserId()) {
            event.VisitOpinion__c = eventRequest.visitOpinion;

            if (!checkInDone(eventRequest)) {
                event.Checkin__Latitude__s    = eventRequest.checkIn?.latitude;
                event.Checkin__Longitude__s   = eventRequest.checkIn?.longitude;
                event.CheckInDone__c          = eventRequest.checkInDone;
                event.CheckinDate__c          = buildDatetime(eventRequest.checkInDate, eventRequest.checkInHour);
                event.GeolocationPermission__c = eventRequest.geoLocationPermission;
            }
        }

        return event;
    }

    global class Location {
        public Decimal latitude  {get;set;}
        public Decimal longitude {get;set;}
    }

    public static Boolean checkInDone(EventRequest eventRequest) {
        if (eventRequest.id != null) {
            Event event = [SELECT Id, CheckInDone__c FROM Event WHERE Id = :eventRequest.Id LIMIT 1];
            return event.CheckInDone__c;
        } else return false;
    }

    public static Datetime buildDatetime(String dateStr, String hourStr) {
        if (String.isNotBlank(dateStr) && String.isNotBlank(hourStr)) {
            return Datetime.newInstance(
                Integer.valueOf(dateStr.split('-')[0]), 
                Integer.valueOf(dateStr.split('-')[1]), 
                Integer.valueOf(dateStr.split('-')[2]), 
                Integer.valueOf(hourStr.split(':')[0]), 
                Integer.valueOf(hourStr.split(':')[1]), 
                0
            );
        } else return null;
    }

    global class EventResponse extends EventBaseRequest{
        public Boolean hasError {get;set;}
        public String errorMsg  {get;set;}

        public EventResponse(Exception ex, EventRequest eventRequest){
            this.hasError = true;
            this.errorMsg = ex.getMessage() + '\n Erro :' + ex.getStackTraceString();
            this.appCode  = eventRequest.appCode;
            this.deleted  = eventRequest.deleted;
        } 
        public EventResponse(String error, EventRequest eventRequest){
            this.hasError = true;
            this.errorMsg = error;
            this.appCode  = eventRequest.appCode;
            this.deleted  = eventRequest.deleted;
        }
        public EventResponse(EventRequest eventRequest, String eventId){
            this.hasError = false;
            this.errorMsg = null;
            this.id       = eventId;
            this.appCode  = eventRequest.appCode;
            this.deleted  = eventRequest.deleted;
        }  
    }
}
