public without sharing class EventRTRPDFController {
    
    public RTRData eventData {get;set;}
    public String themes {get;set;}

    public EventRTRPDFController() {

        String eventIdPageReference = ApexPages.currentPage().getParameters().get('Id');
        this.themes = UserInfo.getUiThemeDisplayed();
        Event event = [
            SELECT Id, VisitOpinion__c, Crop__r.Name, Account__r.parent.Name, Account__c,Subject,  CompletedEvent__c, Case__c, Checkin__c, CheckinDate__c, CheckInDone__c, Description, DurationInMinutes,
            EndDate, EventRelated__c, EventSubtype, EventType__r.Name, GeolocationPermission__c, OwnerId,
            Account__r.Name, Account__r.BillingAddress, Account__r.BillingCity, Account__r.BillingState, Account__r.BillingCountry, Account__r.BillingPostalCode, Account__r.BillingStreet,
            case__r.CaseNumber,  case__r.ClosedDate,  case__r.Comments,  case__r.ContactEmail,  case__r.ContactFax,  case__r.ContactId,  case__r.ContactMobile,  case__r.ContactPhone,  case__r.CreatedById, 
            case__r.CreatedDate,  case__r.Crop__r.Name,  case__r.CulturePlot__c,  case__r.CulturePlot__r.Name,  case__r.CurrencyIsoCode,  case__r.DamagedArea__c,  case__r.Description,  case__r.IncidentType__c,  case__r.IncidentTypePicklist__c, 
            case__r.IsClosed,  case__r.IsDeleted,  case__r.IsEscalated, case__r.MeasureUnit__c,  case__r.Origin,  case__r.ParentId, Case__r.AffectedArea__c,  Case__r.PercentageAffectedAreaCulture__c, case__r.PercentageAffectedArea__c, 
            case__r.Plot__c, case__r.Plot__r.Name,  case__r.Priority,  case__r.Reason,  case__r.RecordTypeId,  case__r.Status,  case__r.Subject, 
            case__r.Type,  StartDateTime, EndDateTime
            FROM Event WHERE Id =: eventIdPageReference LIMIT 1
        ];

        User userInfo = [
            SELECT Id, TerritoryRole__c, Name FROM User WHERE Id =: event.OwnerId LIMIT 1
        ];

        SalesTeam__c salesTeam = null;
        for(SalesTeam__c slTeam : [SELECT Id, DisplayName__c, Address__c, City__r.Name, CNPJ__c, IE__c, Phone__c, PostalCode__c 
                                    FROM SalesTeam__c 
                                    WHERE Name =:  userInfo.TerritoryRole__c LIMIT 1]){
            salesTeam = slTeam;
        }
        
        this.eventData = new RTRData(userInfo, event, salesTeam);
    }
    public static String getNotes(Set<Id> docIdSet){
        String noteDocument = '';
        for(ContentNote notess: [SELECT Id, Title, TextPreview, LatestPublishedVersion.ContentDocumentId FROM ContentNote WHERE LatestPublishedVersion.ContentDocumentId IN :docIdSet ORDER BY CreatedDate DESC LIMIT 1]){
            noteDocument = notess.TextPreview;
        }
        return noteDocument;
    }
    public static Set<Id> getDocsId(Id evtIdc){
        Set<Id> docIdSet = new Set<Id>();
        for(ContentDocumentLink links : [SELECT id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = : evtIdc]){
            docIdSet.add(links.ContentDocumentId);
        }
        return docIdSet;        
    }
    public static List<ImageData> getImages(Set<Id> docIdSet, Boolean hasCase){
        List<ImageData> returnVal = new List<ImageData>();
        Integer i = hasCase ? 1 : 0;
        for(ContentVersion links : [SELECT id, Description, ContentDocument.FileType, VersionData  FROM ContentVersion WHERE ContentDocumentId IN : docIdSet AND ContentDocument.FileType != 'PDF' and ContentDocument.FileType != 'SNOTE' ORDER BY CreatedDate DESC]){
            returnVal.add(new ImageData(links, i));
            i++;
        }
        return returnVal;        
    }


    public class RTRData {
        public String id                     {get;set;}
        public String borderStyleClass       {get;set;}
        public String hasCase                {get;set;}
        public String notee                  {get;set;}
        public Boolean hasCaseBoolean        {get;set;}
        public Boolean hasVisitOpinion        {get;set;}
        public Boolean hasImage              {get;set;}
        public String today                  {get;set;}
        public String todayPDF               {get;set;}

        public UserData usData               {get;set;}
        public CaseData caseData             {get;set;}
        public AccountData accData           {get;set;}
        public SalesTeamData salesTeam       {get;set;}
        public EventData eventData           {get;set;}

        public List<ImageData> attachList {get;set;}

        public RTRData(User userInfo, Event event, SalesTeam__c salesTeamData) {

            this.hasCaseBoolean = event.Case__c != null;
            this.hasVisitOpinion = event.VisitOpinion__c != null;
            this.hasCase =  this.hasCaseBoolean ? 'Sim' : 'Não';
            this.usData = new UserData(userInfo);
            this.eventData = new EventData(event);
            this.caseData =  this.hasCaseBoolean  ? new CaseData(event) : new CaseData();
            this.accData = new AccountData(event);
            this.salesTeam = salesTeamData != null ? new SalesTeamData(salesTeamData) : new SalesTeamData();

            Set<Id> docsIds = getDocsId(event.Id);
            this.attachList = getImages(docsIds, this.hasCaseBoolean);
            this.hasImage = !this.attachList.isEmpty();
            this.notee = getNotes(docsIds);

            this.borderStyleClass       = '';
            this.id                     = event.Id;
            this.today = DateTime.now().format('dd/MM/yyyy');
            this.todayPDF = DateTime.now().format('dd-MM-yyyy');
             
        }
    }
    public class ImageData{
        public String contentId                     {get;set;}
        public Boolean breaks       {get;set;}
        public String detail       {get;set;}
        public Object  img       {get;set;}
        public ImageData(ContentVersion cts, Integer index){
            this.breaks = Math.mod(index, 2) == 1;
            this.contentId = cts.Id;
            this.detail = cts.Description;
            Blob imgs = (Blob) cts.get('VersionData');
            this.img =  EncodingUtil.base64Encode(imgs);
        }
    }

    public class EventData {
        public String account                {get;set;}
        public String crop                {get;set;}
        public String VisitOpinion                {get;set;}
        public System.Location checkin       {get;set;}
        public String checkinDate          {get;set;}
        public Boolean checkInDone           {get;set;}
        public String description            {get;set;}
        public String Subject            {get;set;}
        public Integer durationInMinutes     {get;set;}
        public String startDate                  {get;set;}
        public String endDate                  {get;set;}
        public String eventRelated           {get;set;}
        public String eventSubtype           {get;set;}
        public String eventType              {get;set;}
        public Boolean geolocationPermission {get;set;}
        public EventData(Event eventCase) {
            this.VisitOpinion                   = eventCase.VisitOpinion__c;
            this.crop                   = eventCase.Crop__r.Name;
            this.account                = eventCase.Account__c;
            this.checkin                = eventCase.Checkin__c;
            this.checkinDate            = eventCase.CheckinDate__c?.format('dd/MM/yyyy HH:mm');
            this.checkInDone            = eventCase.CheckInDone__c;
            this.Subject                = eventCase.Subject;
            this.description            = eventCase.Description;
            this.durationInMinutes      = eventCase.DurationInMinutes;
            this.startDate              = eventCase.StartDateTime?.format('dd/MM/yyyy HH:mm');
            this.endDate                = eventCase.EndDateTime?.format('dd/MM/yyyy HH:mm');
            this.eventRelated           = eventCase.EventRelated__c;
            this.eventSubtype           = eventCase.EventSubtype;
            this.eventType              = eventCase.EventType__r.Name;
            this.geolocationPermission  = eventCase.GeolocationPermission__c;
        }
    }

    public class UserData {
        public String name                {get;set;}
        public UserData(User userInfo) {
            this.name                = userInfo.Name;
        }
    }

    public class AccountData {
        public String city                   {get;set;}
        public String country                {get;set;}
        public String postalCode             {get;set;}
        public String state                  {get;set;}
        public String street                 {get;set;}
        public String name             {get;set;}
        public String clienteName             {get;set;}
        public AccountData(Event eventCase) {
            this.name             = eventCase.Account__r.Name;
            this.clienteName            = eventCase.Account__r.Parent.Name;
            this.city                   = eventCase.Account__r.BillingCity;
            this.postalCode             = eventCase.Account__r.BillingPostalCode;
            this.state                  = eventCase.Account__r.BillingState;
            this.street                 = eventCase.Account__r.BillingStreet;
        }
    }
    
    public class SalesTeamData {
        public String Address       {get;set;}
        public String City          {get;set;}
        public String PostalCode    {get;set;}
        public String CNPJ          {get;set;}
        public String IE            {get;set;}
        public String Phone         {get;set;}
        public String Name          {get;set;}
        public SalesTeamData() {
            this.Address    = '';
            this.City       = '';
            this.PostalCode = '';
            this.CNPJ       = '';
            this.IE         = '';
            this.Phone      = '';
            this.Name       = '';
        }
        public SalesTeamData(SalesTeam__c salesTeam) {
            this.Name          = salesTeam.DisplayName__c;
            this.Address       = salesTeam.Address__c;
            this.City          = salesTeam.City__r.Name;
            this.PostalCode    = salesTeam.PostalCode__c;
            this.CNPJ          = salesTeam.CNPJ__c;
            this.Phone         = salesTeam.Phone__c;
            this.IE            = salesTeam.IE__c;
        }
    }

    public class CaseData {
        public String id                            {get;set;}
        public String caseNumber                    {get;set;}
        public Datetime closedDate                  {get;set;}
        public String comments                      {get;set;}
        public String crop                          {get;set;}
        public String culturePlot                   {get;set;}
        public String currencyIsoCode               {get;set;}
        public String damagedArea                  {get;set;}
        public String description                   {get;set;}
        public String incidentType                  {get;set;}
        public String incidentTypePicklist          {get;set;}
        public String origin                        {get;set;}
        public String parentId                      {get;set;}
        public String percentageAffectedArea       {get;set;}
        public String percentageAffectedAreaCulture{get;set;}
        public String plot                          {get;set;}
        public String priority                      {get;set;}
        public String reason                        {get;set;}
        public String recordTypeId                  {get;set;}
        public String status                        {get;set;}
        public String subject                       {get;set;}
        public String type                          {get;set;}

        public CaseData() {}
        public CaseData(Event eventCase) {
            this.id                     = eventCase.Case__r?.Id;
            this.caseNumber             = eventCase.Case__r?.CaseNumber;
            this.closedDate             = eventCase.Case__r?.ClosedDate;
            this.comments               = eventCase.Case__r?.Comments;
            this.crop                   = eventCase.Case__r?.Crop__r.Name;
            this.culturePlot            = eventCase.Case__r?.CulturePlot__c == null ? 'Não Informado': eventCase.Case__r?.CulturePlot__r.Name;
            this.currencyIsoCode        = eventCase.Case__r?.CurrencyIsoCode;
            this.damagedArea            = OrderPDFController.convertToBRL(eventCase.Case__r?.AffectedArea__c);
            this.description            = eventCase.Case__r?.Description;
            this.incidentType           = eventCase.Case__r?.IncidentType__c;
            this.incidentTypePicklist   = eventCase.Case__r?.IncidentTypePicklist__c;
            this.origin                 = eventCase.Case__r?.Origin;
            this.parentId               = eventCase.Case__r?.ParentId;
            this.percentageAffectedArea = OrderPDFController.convertToBRL(eventCase.Case__r?.PercentageAffectedArea__c == null ? 0 : eventCase.Case__r?.PercentageAffectedArea__c);
            this.percentageAffectedAreaCulture = OrderPDFController.convertToBRL(eventCase.Case__r?.PercentageAffectedAreaCulture__c == null ? 0 : eventCase.Case__r?.PercentageAffectedAreaCulture__c);
            this.plot                   = eventCase.Case__r?.Plot__c == null ? 'Não Informado': eventCase.Case__r?.Plot__r.Name;
            this.priority               = eventCase.Case__r?.Priority;
            this.reason                 = eventCase.Case__r?.Reason;
            this.recordTypeId           = eventCase.Case__r?.RecordTypeId;
            this.status                 = eventCase.Case__r?.Status;
            this.subject                = eventCase.Case__r?.Subject;
            this.type                   = eventCase.Case__r?.Type;
        }
    }

    @RemoteAction
    public static String createContentDistribuction(String contentVersionId, String eventId, String fileName) {
        
            ContentDocumentLink contentDocumentLink = CreateDocumentLink.createContentLink(contentVersionId, eventId);
            ContentDistribution contentDistribution = new ContentDistribution(
                Name                             = fileName,
                ContentVersionId                 = contentVersionId,
                PreferencesAllowViewInBrowser    = true,
                PreferencesLinkLatestVersion     = true,
                PreferencesNotifyOnVisit         = false,
                PreferencesPasswordRequired      = false,
                PreferencesAllowOriginalDownload = true
            );
            insert contentDistribution;

            ContentDistribution contentDistributionInserted = [SELECT Id, DistributionPublicUrl FROM ContentDistribution WHERE Id = :contentDistribution.Id];
            return contentDistributionInserted.DistributionPublicUrl;
    }

    @RemoteAction
    public static void saveRTR(String evtId, ImageData[] imgDataList, String details) {
        List<ContentVersion> contentUpdate = new List<ContentVersion>();
        for(ImageData imgs : imgDataList){
            contentUpdate.add(new ContentVersion(Id = imgs.contentid, Description = imgs.detail));
        }

        if(!contentUpdate.isEmpty())
            update contentUpdate;


        ContentNote noteRecord = new ContentNote(Title = 'PDF', Content = String.isBlank(details) ? Blob.valueOf('Vazio') : Blob.valueOf(details));
        
        Set<Id> docsIds = getDocsId(evtId);
        for(ContentNote cts  : [SELECT id FROM ContentNote WHERE Title = 'PDF' AND LatestPublishedVersion.ContentDocumentId  IN :docsIds]){
            noteRecord.Id = cts.id;
        }
        System.debug(noteRecord);
        if(noteRecord.Id == null){
            insert noteRecord;

            ContentDocumentLink link = new ContentDocumentLink();
            link.ContentDocumentId   = noteRecord.id;
            link.LinkedEntityId      = evtId;
            link.ShareType           = 'V';
            link.Visibility          = 'AllUsers';
            insert link;

        }
        else
            update noteRecord;
    }

    @RemoteAction
    public static String getUserSessionKey() {
        return UserInfo.getSessionId();
    }

}