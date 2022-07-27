public class OrderScreenController {
    
    @AuraEnabled
    public static Event getEventData(String eventid) {
        return [SELECT AccountId, Description, Subject, Crop__c FROM Event WHERE Id = :eventId LIMIT 1];
    }
    
    @AuraEnabled
    public static ReadProjectedMargins getProjectedMargins(
            String cropId, String salesOrgId, String salesteamId ){
        List<ProjectedMargin__c> projMargins =[
            SELECT Id, Family__c, Margin__c
            FROM ProjectedMargin__c
            WHERE Crop__c =:cropId
                AND SalesOrg__c =: salesOrgId
        ];
        SalesTeam__c curSalesOrg =[SELECT Id, ParentId__r.SalesDirector__r.Name,
            ParentId__r.ParentId__r.Director__r.Name,
            ParentId__r.ParentId__r.MarketingManager__c,
            ParentId__r.ParentId__r.MarketingManager__r.Name
            FROM SalesTeam__c WHERE Id =:salesteamId];
        List<ReadProjectedMargin> margins =new List<ReadProjectedMargin>();
        for(ProjectedMargin__c margin: projMargins){
            margins.add(new ReadProjectedMargin( margin));
        }
        String dirId =  curSalesOrg.ParentId__r.SalesDirector__c != null ?  curSalesOrg.ParentId__r.SalesDirector__c : curSalesOrg.ParentId__r.ParentId__r.Director__c;
        String dirName =  curSalesOrg.ParentId__r.SalesDirector__c != null ?  curSalesOrg.ParentId__r.SalesDirector__r.Name : curSalesOrg.ParentId__r.ParentId__r.Director__r.Name;
        return new ReadProjectedMargins(margins, dirName, dirId,
            curSalesOrg.ParentId__r.ParentId__r.MarketingManager__c,
            curSalesOrg.ParentId__r.ParentId__r.MarketingManager__r.Name);
    }

    @AuraEnabled
    public static DelimitedLandData getDelimitedLand(String accId, String CropId, String cultureId) {
        return new DelimitedLandData(accId, cultureId, CropId);
    }
    @AuraEnabled
    public static OrderScreenBaseData getBaseData(String recordId) {
        System.debug('RECORDID: ' + recordId);
        String objectName                    = findObjectNameFromRecordIdPrefix(recordId);
        Account acc                          = null;
        Account accBilling                   = null;
        Account accShipping                  = null;
        Crop__c crop                         = null;
        Crop__c shippingCrop                 = null;
        PaymentCondition__c paymentCondition = null;
        Order ord                            = null;
        Order ordContract                            = null;
        List<OrderItem> ordItemList          = new List<OrderItem>();
        List<CampaignOrderItem__c> campaign  = new List<CampaignOrderItem__c>();
        Boolean isRtv                        = getUserProfileInfo(UserInfo.getProfileId());
        User userRtv  = isRtv == true ? getUserRtv(UserInfo.getUserId()) : null;
        System.debug(isRtv);
        System.debug(objectName);
        if(objectName == 'Account') {
            acc = getAccountDataFilter(recordId);
        } else if(objectName == 'Order') {
            ord              = getOrderData(recordId);
            ordContract      = ord.ContractOrder__c != null ? getOrderData(ord.ContractOrder__c) : ordContract;
            ordItemList      = getOrderItemData(ord.Id);
            List<String> oiIds = new List<String>();
            for(OrderItem orderItem : ordItemList) {
                System.debug('orderItem.margin__c' + orderItem.margin__c);
                oiIds.add(orderItem.Id);
            }
            campaign         = getCampaignOrderItemData(oiIds);
            acc              = ord.AccountId           == null ? null : getAccountData(ord.AccountId);
            accBilling       = ord.BillingAccount__c   == null ? null : getAccountData(ord.BillingAccount__c);
            accShipping      = ord.ShippingAccount__c  == null ? null : getAccountData(ord.ShippingAccount__c);
            crop             = ord.Crop__c             == null ? null : getCropData(ord.Crop__c);
            shippingCrop     = ord.ShippingCrop__c     == null ? null : getCropData(ord.ShippingCrop__c);
            paymentCondition = ord.PaymentCondition__c == null ? null : getPaymentConditionData(ord.PaymentCondition__c);
        }

        return new OrderScreenBaseData(ord, ordContract, acc, accBilling, accShipping, crop, shippingCrop, paymentCondition, acc != null ? getAllProp(acc.Id) : null, isRtv, userRtv, ordItemList, campaign);
    }
    
    public static String findObjectNameFromRecordIdPrefix(String recordIdOrPrefix){
        String objectName = '';
        try{
            String myIdPrefix = String.valueOf(recordIdOrPrefix).substring(0,3);
            Map<String, Schema.SObjectType> gd =  Schema.getGlobalDescribe(); 
             
            for(Schema.SObjectType stype : gd.values()){
                Schema.DescribeSObjectResult r = stype.getDescribe();
                String prefix = r.getKeyPrefix();
                //System.debug('Prefix is ' + prefix);
                 
                if(prefix!=null && prefix.equals(myIdPrefix)){
                    objectName = r.getName();
                    //System.debug('Object Name! ' + objectName);
                    break;
                }
            }
        } catch(Exception e) {
            System.debug(e);
        }
        return objectName;
    }

    public static Boolean getUserProfileInfo(Id profId) {
        System.debug('PROFID: ' + profId);
        String profileName = [SELECT Id, Name from Profile WHERE Id =:profId].Name;

        Boolean isRtv = profileName == 'RTV' ? true : false;
        
        return isRtv;
    }

    public static User getUserRtv(Id userId) {

        User rtv = [SELECT Id, Name from User WHERE Id =:userId];

        return rtv;
    }

    public static Account getAccountData(Id accId) {
        return [SELECT Id, Name, ExternalId__c, NCDDate__c, SalesOrg__c, ActivitySector__c, Blocked__c, InternShippingCity__c, InternShippingCity__r.Name, InternShippingCity__r.Id, ParentId, Parent.ExternalId__c FROM Account WHERE Id = :accId LIMIT 1];
    }

    public static Account getAccountDataFilter(Id accId) {
        List<Account> acc = new List<Account>();
        
        acc = [SELECT Id, Name, ExternalId__c, NCDDate__c, SalesOrg__c, ActivitySector__c, Blocked__c, InternShippingCity__c, InternShippingCity__r.Name, InternShippingCity__r.Id, RecordType.DeveloperName, ParentId, Parent.ExternalId__c, Parent.Name, Parent.NCDDate__c FROM Account WHERE Id = :accId LIMIT 1];

        return acc != null && !acc.isEmpty() ? acc[0]: null;
    }

    public static Crop__c getCropData(Id cropId) {
        return [SELECT id, Name FROM Crop__c WHERE Id = :cropId LIMIT 1];
    }

    public static PaymentCondition__c getPaymentConditionData(Id pcId) {
        return [SELECT id, Name, PaymentForm__c FROM PaymentCondition__c WHERE Id = :pcId LIMIT 1];
    }
    @AuraEnabled(cacheable=true)
    public static string getPaymentFormPicklistValues(Id pcId) {
        if(pcId == null) return null;
        return [SELECT PaymentForm__c FROM PaymentCondition__c WHERE Id = :pcId LIMIT 1].PaymentForm__c;
    }
    @AuraEnabled(cacheable=true)
    public static string getPaymentTypePicklistValues(Id pcId) {
        if(pcId == null) return null;
        return [SELECT PaymentType__c FROM PaymentCondition__c WHERE Id = :pcId LIMIT 1].PaymentType__c;
    }
    
    @AuraEnabled(cacheable=true)
    public static Order getContractInformation(Id contractId) {
        if(contractId == null) return null;
        return [SELECT Id, PaymentDate__c, BarterType__c, BillingAccount__c, BillingAccount__r.Name, ShippingAccount__c, ShippingAccount__r.Name, ShippingAccount__r.InternShippingCity__c , ShippingAccount__r.Blocked__c , ShippingAccount__r.InternShippingCity__r.Name, RTV__c,EndDate, RTV__r.Name, SalesTeam__c,SalesTeam__r.Name, SalesTeam__r.ParentId__c , SalesTeam__r.DistributionCenter__r.City__c, SalesCondition__c, ActivitySector__c, Currency__c, Crop__c, Crop__r.Name, PaymentCondition__c,PaymentCondition__r.Name, PaymentForm__c  FROM Order WHERE Id = : contractId LIMIT 1];
    }

    @AuraEnabled(cacheable=true)
    public static PaymentCondition__c getPaymentConditionBarter(String exId){
        return [SELECT Name FROM PaymentCondition__c WHERE ExternalId__c =: exId LIMIT 1]; 
    }

    @AuraEnabled(cacheable=true)
    public static SalesOffice__c getSalesOfficeValues(Id sfId) {
        if(sfId == null) return null;
        return [SELECT ParentId__r.Name, ParentId__r.Director__r.Name, ParentId__r.Director__c, SalesDirector__c, SalesDirector__r.Name, GGN__c, GGN__r.Name, ParentId__r.MarketingManager__c, ParentId__r.MarketingManager__r.Name, ParentId__r.FinancialAdministrativeManager__c, ParentId__r.FinancialAdministrativeManager__r.Name FROM SalesOffice__c WHERE Id = :sfId LIMIT 1];
    }

    @AuraEnabled(cacheable=true)
    public static string getRangeDiccount(Id salesOfficeId, Id familyId, Date startData, Date endData, String customer, String paymentType, Double minDiscount) {
        if(salesOfficeId == null || familyId == null || startData == null || endData == null || customer == null || paymentType == null || minDiscount == null) return null;
        Set<String> returnVal  = new Set<String>();
        for(RangeDiscount__c range : [SELECT MinimumPercentage__c, ApprovingAuthority__c, MaximaPercentage__c 
                                        FROM RangeDiscount__c 
                                        WHERE SalesOffice__c =: salesOfficeId 
                                        AND Family__c =: familyId 
                                        AND CustomerCategory__c =: customer 
                                        AND InitialDate__c <= TODAY 
                                        AND FinalDate__c >= TODAY  
                                        AND PaymentType__c =: paymentType
                                        AND Status__C = 'Aprovado' 
                                        AND MinimumPercentage__c <= :minDiscount
                                        AND MaximaPercentage__c >= :minDiscount 
                                        ORDER BY MinimumPercentage__c ASC]){
            returnVal.add(range.ApprovingAuthority__c);   
        }
        return String.join(new List<String>(returnVal), ';');
    }
    @AuraEnabled(cacheable=true)
    public static Boolean getClientState(Id clientId){
        Account client = [SELECT InternShippingCity__r.Name, Blocked__c, InternShippingCity__c FROM Account WHERE Id =: clientId];
        ClientCNDState__c ClientCND = [SELECT Name FROM ClientCNDState__c LIMIT 1];
        if(client.InternShippingCity__c == null){
            return false;
        }
        String clientState = client.InternShippingCity__r.Name.right(2);
        if(ClientCND.Name.contains(clientState)){
            return true;
        }
        return false;
    }
    public static Order getOrderData(Id ordId) {
        return [SELECT Id, 
        MarginApprover__C, MarginApprover__r.Name,
        OwnerId, ContractId, ContractOrder__c,
        AccountId, Pricebook2Id, DeletedProductProcessSap__c, 
        OpportunityId, QuoteId, RecordType.Id, RecordType.Name, RecordType.DeveloperName,
        EffectiveDate, EndDate, IsReductionOrder, Status,
        Description, CustomerAuthorizedById, CustomerAuthorizedDate,
        CompanyAuthorizedById, CompanyAuthorizedDate, Type, BillingStreet,
        BillingCity, BillingState, BillingPostalCode, BillingCountry,
        BillingLatitude, BillingLongitude, BillingGeocodeAccuracy,
        BillingAddress, ShippingStreet, ShippingCity, ShippingState,
        ShippingPostalCode, ShippingCountry, ShippingLatitude,
        ShippingLongitude, ShippingGeocodeAccuracy,
        ShippingAddress, Name, PoDate, PoNumber,
        CustomerGroup__c, SalesOrg__c,
        OrderReferenceNumber, BillToContactId, ShipToContactId,
        ActivatedDate, ActivatedById, StatusCode, OrderNumber,
        TotalAmount, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, IsDeleted,
        SystemModstamp, LastViewedDate, LastReferencedDate, ActivitySector__c, ApprovalJustification__c,
        ApproverDiscountAmount__c, BillingAccount__c, CommercialApproval__c, ContainIntegrationError__c,
        CreatedDateApp__c, Crop__c, Currency__c, CustomerOrderNumber__c, 
        DiscountApprover__c, DiscountApprover2__c, DiscountApprover3__c, DiscountApprover4__c, 
        DistributionCenter__c, DistributionChannel__c, ExternalIdApp__c, ExternalId__c, Freight__c,
        IntegrationErrorMessage__c, OrderCreator__c, OrderMotive__c, ParentOrderReferenceType__c,
        PaymentCondition__c, PaymentDate__c, RTV__c, RTV__r.Name, RTV__r.Id, SalesCondition__c, SalesTeam__r.Name, SalesTeam__r.DistributionCenter__r.City__c, SalesTeam__r.Id, SalesTeam__r.ParentId__c, SalesTeam__r.Manager__c, SalesTeam__r.SalesOrg__r.Director__c, SalesTeam__r.SalesOrg__r.Director__r.Name, SalesTeam__r.Manager__r.name, SalesOffice__c, 
        SalesTeam__c, ShippingAccount__c, StatusSAP__c, StatusSF__c, TotalAmountWithFreight__c,
        TotalFreightValue__c, FinancialAdministrativeManager__c, BonificationApprovalNote__c,
        DiscountApprovalNote__c, PaymentForm__c, RegistrationApprovalNote__c,
        GrainTableApproval__c, BarterType__c, Commodity__c, ShippingCrop__c, BillingCrop__c, GrossUnitPrice__c, UnitPrice__c, CommodityShipping__c, InitialDeliveryDate__c, EndDeliveryDate__c, 
        ProductionDeliveryLocation__c, ProductionPickupLocation__c, StrikePrice__c, DueDateFinancial__c, AccountTradeName__c, CommercialMeasureUnit__c, ContractEndDate__c, ContractStartDate__c, TotalDeliveryQuantity__c, DeliveryQuantity__c, OriginalOrder__c, OldOrderCredit__c, OrderRoute__c
        FROM Order WHERE Id = :ordId LIMIT 1];
    }

    public static List<OrderItem> getOrderItemData(Id ordId) {
        return [SELECT 
        Id, LowerMargin__c, Cost__c, ProjectedMargin__c, Margin__c, FamilyMargin__c, OrderMargin__c, Product2Id, DeletedProductSap__c, ContractProductCredit__c, IsDeleted, OrderId, PricebookEntryId, OriginalOrderItemId, QuoteLineItemId, FreightValuePerTon__c, AvailableQuantity, Quantity, UnitPrice, ListPrice, TotalPrice__c, TotalPrice, ServiceDate, EndDate, Description, CreatedDate,
        CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, OrderItemNumber, BilledQuantity__c, Center__c, CommercialApproval__c, Culture__c, DestinationCity__c, DestinationCity__r.Name,DiscountAmount__c, DiscountPercent__c, ExternalId__c,
        FreightValue__c, Freight__c, ListPriceWithoutInterest__c, LastChangedPriceList__c, ListPrice__c, OfferDiscount__c, Quantity__c, RefuseReason__c, SourceCity__c, Status__c, UnitMeasure__c, CustomListPrice__c, Product2.Name, Product2.Multiplicity__c, Incoterms1__c, Incoterms2__c,
        Product2.QuantityUnitOfMeasure, Product2.Brand__c, Product2.ProductCode, Product2.GrossWeightUnity__c, Product2.Family__c, Product2.GrossWeight__c, Product2.ActivitySector__c, ListPrice__r.Account__c, ListPrice__r.Cost__c, ListPrice__r.Crop__c, ListPrice__r.Currency__c,
         ListPrice__r.EffectiveDate__c, ListPrice__r.EndDate__c, ListPrice__r.ExternalId__c, ListPrice__r.Id, ListPrice__r.InitialDate__c, ListPrice__r.IsActive__c, ListPrice__r.PriceMultiplier__c,  ListPrice__r.Name, ListPrice__r.Priority__c, ListPrice__r.Product2Id__c, ListPrice__r.RecordType.Id,
         ListPrice__r.RecordType.Name, InterestOrAntecipationDiscount__c, InterestOrAntecipationDiscount__r.Name, InterestOrAntecipationDiscount__r.Id, InterestOrAntecipationDiscount__r.RecordType.DeveloperName, ListPrice__r.SalesCondition__c, CalculatedInterest__c, InterestValue__c, AnticipationDiscount__c,
         ListPrice__r.SalesOrg__c, ListPrice__r.SalesTeam__c, ListPrice__r.UnitMeasurement__c, ListPrice__r.UnitPrice__c, AdditionAmount__c, AdditionPercent__c, Culture__r.Id, Culture__r.Name, Culture__r.ExternalId__c, Product2.Family__r.Id, Product2.Family__r.Name FROM OrderItem WHERE OrderId =: ordId];
    }

    public static List<CampaignOrderItem__c> getCampaignOrderItemData(List<String> ordItemId) {
        return [SELECT Id, OrderItem__c, Campaign__c, Campaign__r.Name, Campaign__r.RecordType.DeveloperName, Campaign__r.Accumulative__c, Discount__c, CurrencyIsoCode,	Name,FixedUnitPriceCampaign__c, FixedUnitPrice__c, CampaignProduct__c, DiscountValue__c FROM CampaignOrderItem__c WHERE OrderItem__c IN: ordItemId];
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getAllProp(Id accId) {
        List<Account> accountProp = new List<Account>();

        accountProp = [SELECT Id, Name, InternShippingCity__c, InternShippingCity__r.Name, InternShippingCity__r.Id FROM Account WHERE RecordType.DeveloperName = 'Property' AND (ParentId = :accId OR Parent.ParentId = :accId) LIMIT 1];

        return accountProp != null && !accountProp.isEmpty() ? accountProp: null;
    }

    @AuraEnabled
    public static FinancialDueDate__c getRecordFinancialDueDate(String crop, String commodity){
        return [SELECT Id, FinancialDueDate__c FROM FinancialDueDate__c WHERE Crop__c =: crop AND Commodity__c =: commodity LIMIT 1];
    }

    @AuraEnabled
    public static String getPicklistValues(String dependencyFieldKey, String dependencyField, String value){
        return FieldDependencyDAO.getFieldDependency(dependencyFieldKey, dependencyField, value, new Set<String>{'Id', 'DependencyValue__c'}).DependencyValue__c;
        //[SELECT Id, DependencyFieldKey__c, DependencyField__c, Value__c, DependencyValue__c FROM FieldDependency__c WHERE DependencyFieldKey__c =: dependencyFieldKey AND DependencyField__c =: dependencyField AND Value__c =: value LIMIT 1].DependencyValue__c;
    }
    @AuraEnabled
    public static List<SalesCondition__c> getSalesConditionValues(){
        List<SalesCondition__c> salesCondition = new List<SalesCondition__c>();
        salesCondition = [SELECT ExternalId__c, Name FROM SalesCondition__c WHERE IsActive__c = true];
        return salesCondition;
    }

    public class DelimitedLandData{
        @AuraEnabled public Boolean hasDelimitedLand {get;set;}
        @AuraEnabled public Boolean hasDelimitedLandCulture {get;set;}
        @AuraEnabled public String totalcultureMeters {get;set;}
        @AuraEnabled public String cultureName {get;set;}
        @AuraEnabled public String cultureMeters {get;set;}
        @AuraEnabled public String delimitedLandMeters {get;set;}

        public DelimitedLandData(String accId, String cultureId, String CropId){ 
            this.getAccount(accId);
            this.getCultureDelimited(accId, cultureId, CropId);
        }
        public void getAccount(String accId){ 
            Account acc = [SELECT id, AreaCultivatedLandMeters__c, ArealTotalMeters__c FROM Account WHERE Id = :accId LIMIT 1];
            this.hasDelimitedLand    = acc.ArealTotalMeters__c > 0;
            this.totalcultureMeters  = this.convertToString(acc.AreaCultivatedLandMeters__c);
            this.delimitedLandMeters = this.convertToString(acc.ArealTotalMeters__c) ;
        }
        public void getCultureDelimited(String accId, String cultureId, String CropId){ 
            Decimal totals = 0;
            for(DelimitedLandCultures__c culture : [SELECT Id, DelimitedLand__c, Culture__c, TotalAreaMeters__c, Culture__r.Name FROM DelimitedLandCultures__c WHERE Culture__c = :cultureId AND DelimitedLand__r.Account__c = :accId AND Crop__c = :CropId]){
                totals += culture.TotalAreaMeters__c;
                this.cultureName = culture.Culture__r.Name;
            }
            this.hasDelimitedLandCulture = totals > 0;
            this.cultureMeters           = this.convertToString(totals);
        }
        public String convertToString(Decimal num){
            List<String> args = new String[]{'0','number','###.###.###,##'};
            
            String numConverted =  String.format(num.setScale(2).format(), args);

            numConverted += numConverted.indexOf(',') == -1 ? ',00' : numConverted.indexOf(',') == numConverted.length() - 2 ? '0' : '';

            return numConverted;
        } 
    }

    public class UserVO {
        @AuraEnabled public String Name {get;set;}

        public UserVO (Order orderObject) {
            this.Name = orderObject.RTV__r.Name;
        }
    }

    public class RtvVO { 
        @AuraEnabled public String Id     {get;set;}
        @AuraEnabled public UserVO User   {get;set;} 
        @AuraEnabled public String UserId {get;set;}

        public RtvVO (Order orderObject) {
            this.Id     = orderObject.RTV__r.Id;
            this.User   = new UserVO(orderObject);
            this.UserId = orderObject.RTV__r.Id;
        }
    }

    public class OrderVO {
        @AuraEnabled public RtvVO Rtv                                                                          {get;set;}
        @AuraEnabled public Account Account                                                                     {get;set;} 
        @AuraEnabled public Boolean IsUserRtv                                                                  {get;set;} 
        @AuraEnabled public Account BillingAccount                                                             {get;set;} 
        @AuraEnabled public Account ShippingAccount                                                            {get;set;} 
        @AuraEnabled public String SalesCondition                                                              {get;set;} 
        @AuraEnabled public String PaymentForm                                                                 {get;set;} 
        //@AuraEnabled public String RecordType                                                                {get;set;}
        //@AuraEnabled public String Currency                                                                  {get;set;} 
        @AuraEnabled public Date DueDate                                                                       {get;set;}         
        @AuraEnabled public Crop__c Crop                                                                       {get;set;}         
        @AuraEnabled public PaymentCondition__c PaymentCondition                                               {get;set;}         
        @AuraEnabled public Date ExpirationDate                                                                {get;set;} 
        @AuraEnabled public SObject SalesTeam                                                                  {get;set;}  
        @AuraEnabled public String SalesOrg                                                                    {get;set;} 
        @AuraEnabled public String CustomerGroup                                                               {get;set;} 
        @AuraEnabled public String RecordType                                                                  {get;set;}
        @AuraEnabled public String Id                                                                          {get;set;} 
        @AuraEnabled public String Status                                                                      {get;set;} 
        @AuraEnabled public String OrderNumber                                                                 {get;set;} 
        @AuraEnabled public String ActivitySector                                                              {get;set;} 
        @AuraEnabled public Boolean PassedGrainTable                                                           {get;set;} 
        @AuraEnabled public String BarterType                                                                  {get;set;} 
        @AuraEnabled public String Commodity                                                                   {get;set;} 
        @AuraEnabled public Crop__c ShippingCrop                                                               {get;set;}         
        @AuraEnabled public String BillingCrop                                                                 {get;set;} 
        @AuraEnabled public Decimal GrossUnitPrice                                                             {get;set;} 
        @AuraEnabled public Decimal CommUnitPrice                                                              {get;set;} 
        @AuraEnabled public String CommercialMeasureUnit                                                       {get;set;} 
        @AuraEnabled public String CommFreigthMode                                                             {get;set;} 
        @AuraEnabled public Date InitialDeliveryDate                                                           {get;set;} 
        @AuraEnabled public Date EndDeliveryDate                                                               {get;set;} 
        @AuraEnabled public Date EndContractDate                                                               {get;set;} 
        @AuraEnabled public Date InitialContractDate                                                           {get;set;} 
        @AuraEnabled public Decimal TotalDeliveryQuantity                                                      {get;set;} 
        @AuraEnabled public String ProductionDeliveryLocation                                                  {get;set;} 
        @AuraEnabled public String ProductionPickupLocation                                                    {get;set;} 
        @AuraEnabled public Decimal StrikePrice                                                                {get;set;} 
        @AuraEnabled public Date FinancialDueDate                                                              {get;set;} 
        @AuraEnabled public String Trade                                                                       {get;set;} 
        @AuraEnabled public Order ContractProduct                                                              {get;set;} 
        @AuraEnabled public Boolean DeletedProductProcessSap                                                   {get;set;}  

        public OrderVO(Order orderObject, Account account, Boolean isUserRtv, Account billingAccount, Account shippingAccount, Date dueDate, Crop__c crop, PaymentCondition__c paymentCondition, Crop__c shippingCrop, Order contractProduct) {
            this.Rtv                        = new RtvVO(orderObject);
            this.Account                    = account;
            this.IsUserRtv                  = isUserRtv;
            this.BillingAccount             = billingAccount;
            this.ShippingAccount            = shippingAccount;
            this.SalesCondition             = orderObject.SalesCondition__c;
            this.PaymentForm                = orderObject.PaymentForm__c;
            //this.RecordType                 = orderObject.RecordType.Id;
            //this.Currency                   = orderObject.Currency__c;
            this.DueDate                    = dueDate;
            this.Crop                       = crop;
            this.PaymentCondition           = paymentCondition;
            this.ExpirationDate             = Date.today().addMonths(1);
            this.SalesTeam                  = orderObject.SalesTeam__r;
            this.SalesOrg                   = orderObject.SalesOrg__c;
            this.CustomerGroup              = orderObject.CustomerGroup__c;
            this.RecordType                 = orderObject.RecordType.DeveloperName;
            this.Id                         = orderObject.Id;
            this.Status                     = orderObject.StatusSF__c;
            this.OrderNumber                = orderObject.OrderNumber;
            this.ActivitySector             = orderObject.ActivitySector__c;
            this.PassedGrainTable           = orderObject.GrainTableApproval__c;
            this.BarterType                 = orderObject.BarterType__c;
            this.Commodity                  = orderObject.Commodity__c;
            this.ShippingCrop               = shippingCrop;
            this.BillingCrop                = orderObject.BillingCrop__c;
            this.GrossUnitPrice             = orderObject.GrossUnitPrice__c;
            this.CommUnitPrice              = orderObject.UnitPrice__c;
            this.CommercialMeasureUnit      = orderObject.CommercialMeasureUnit__c;
            this.CommFreigthMode            = orderObject.CommodityShipping__c;
            this.InitialDeliveryDate        = orderObject.InitialDeliveryDate__c;
            this.EndDeliveryDate            = orderObject.EndDeliveryDate__c;
            this.EndContractDate            = orderObject.ContractEndDate__c;
            this.InitialContractDate        = orderObject.ContractStartDate__c;
            this.TotalDeliveryQuantity      = orderObject.DeliveryQuantity__c;
            this.ProductionDeliveryLocation = orderObject.ProductionDeliveryLocation__c;
            this.ProductionPickupLocation   = orderObject.ProductionPickupLocation__c;
            this.StrikePrice                = orderObject.StrikePrice__c;
            this.FinancialDueDate           = orderObject.DueDateFinancial__c;
            this.Trade                      = orderObject.AccountTradeName__c;
            this.DeletedProductProcessSap   = orderObject.DeletedProductProcessSap__c;
            this.ContractProduct            = contractProduct;
        }
    }

    public class OrderScreenBaseData {
        @AuraEnabled public List<Account> PropListAccount                                  {get; set;}      
        @AuraEnabled public Date DateNCD                                                   {get; set;}
        @AuraEnabled public Date DateToday                                                 {get; set;}
        @AuraEnabled public Boolean HasErrorDate                                           {get; set;}
        @AuraEnabled public String StatusOrder                                             {get; set;}
        @AuraEnabled public Id AccountId                                                   {get; set;}
        @AuraEnabled public Id OrderId                                                     {get; set;}
        @AuraEnabled public Account AccountObj                                             {get; set;}
        @AuraEnabled public NewAccount AccountObjNewAccount                                {get; set;}
        @AuraEnabled public ToastInfo ToastInfoErrorDate                                   {get; set;}
        @AuraEnabled public ToastInfo ToastInfoErrorDatePlusThirty                         {get; set;}
        @AuraEnabled public ToastInfo ToastInfoErrorCurrencyDolar                          {get; set;}
        @AuraEnabled public String DatePlusThirty                                          {get; set;}
        @AuraEnabled public Order OrderObj                                                 {get; set;}
        @AuraEnabled public Order OrderContractObj                                         {get; set;}
        @AuraEnabled public Account AccountBillingObj                                      {get; set;}
        @AuraEnabled public Account AccountShippingObj                                     {get; set;}
        @AuraEnabled public Crop__c CropObj                                                {get; set;}
        @AuraEnabled public PaymentCondition__c PaymentConditionObj                        {get; set;} 
        @AuraEnabled public Id OrderRecordTypeId                                           {get; set;}
        @AuraEnabled public Boolean IsUserRtv                                              {get; set;}
        @AuraEnabled public Date PaymentDateOrder                                          {get; set;}
        @AuraEnabled public Boolean OrderCurrency                                          {get; set;}
        @AuraEnabled public Boolean HaveProps                                              {get; set;}
        @AuraEnabled public Boolean IsProp                                                 {get; set;}
        @AuraEnabled public Boolean IsPropAndHaveParent                                    {get; set;}
        @AuraEnabled public Boolean HasErrorPropWithoutParentId                            {get; set;}
        @AuraEnabled public User CurrentUserRtv                                            {get; set;}
        @AuraEnabled public Map<Id, List<ShippingDivision__c>> MapOrderItemIdToShippingDiv {get; set;}
        @AuraEnabled public List<OrderItem> OrdItemList                                    {get; set;}
        @AuraEnabled public List<CampaignOrderItem__c> CampaignList                        {get; set;}
        @AuraEnabled public String MapIdRtvToSalesTeams                                    {get; set;}
        @AuraEnabled public OrderVO orderObject                                            {get; set;}

        //Barter
        @AuraEnabled public Boolean PassedGrainTable                                       {get; set;}
        @AuraEnabled public String  BarterType                                             {get; set;}
        @AuraEnabled public String  Commodity                                              {get; set;}
        @AuraEnabled public Crop__c  ShippingCrop                                           {get; set;}
        @AuraEnabled public String  BillingCrop                                            {get; set;}
        @AuraEnabled public Decimal GrossUnitPrice                                         {get; set;}
        @AuraEnabled public Decimal UnitPrice                                              {get; set;}
        @AuraEnabled public String  CommercialMeasureUnit                                  {get; set;}
        @AuraEnabled public String  CommodityShipping                                      {get; set;}
        @AuraEnabled public Date    InitialDeliveryDate                                    {get; set;}
        @AuraEnabled public Date    EndDeliveryDate                                        {get; set;}
        @AuraEnabled public Date    ContractEndDate                                        {get; set;}
        @AuraEnabled public Date    ContractStartDate                                      {get; set;}
        @AuraEnabled public Decimal TotalDeliveryQuantity                                  {get; set;}

        //COMM -> CIF
        @AuraEnabled public String  ProductionDeliveryLocation                             {get; set;}

        //COMM -> FOB
        @AuraEnabled public String  ProductionPickupLocation                               {get; set;}

        //FinancialBarter
        @AuraEnabled public Decimal StrikePrice                                            {get; set;}
        @AuraEnabled public Date    DueDateFinancial                                       {get; set;}

        //TriangulationBarter
        @AuraEnabled public String  Trade                                                  {get; set;}

        @AuraEnabled public Decimal RefuseReasonMargin                                      {get; set;}

        public OrderScreenBaseData(Order ord, Order ordContract, Account acc, Account accBilling, Account accShipping, Crop__c crop, Crop__c shippingCrop, PaymentCondition__c paymentCondition, List<Account> propriedadesList, Boolean isRtvUser, User rtvUser, List<OrderItem> ordItemList, List<CampaignOrderItem__c> campaign) {
            this.PropListAccount              = new List<Account>();
            this.ToastInfoErrorDate           = new ToastInfo('Erro', 'Este cliente não está disponível para criar um pedido, pois a data de certidão negativa de crédito é menor do que a data de hoje.', 'Error');
            this.ToastInfoErrorCurrencyDolar  = new ToastInfo('Erro', 'Você não pode selecionar a moeda \'Real\' para a Condição de venda \'Venda Dolar\' ', 'Error');
            this.ToastInfoErrorDatePlusThirty = new ToastInfo('Erro', 'A data de validade não pode ser menor do que a data de hoje.', 'Error');
            this.DateToday                    = System.Date.Today();
            this.DatePlusThirty               = getDayInLWCDateFormat(this.DateToday);

            this.RefuseReasonMargin           = MargemMotivoRecusa__c.getValues('Margem Pedido') != null ? MargemMotivoRecusa__c.getValues('Margem Pedido').Margem__c : 0;

            if(ord != null) {
                this.MapOrderItemIdToShippingDiv  = new Map<Id, List<ShippingDivision__c>>();
                this.OrdItemList                  = new List<OrderItem>();
                this.StatusOrder                  = '_isedit_';
                this.AccountId                    = ord.AccountId;
                this.DateNCD                      = acc.NCDDate__c;
                this.AccountObj                   = acc;
                this.OrderObj                     = ord;
                this.OrderContractObj             = ordContract;
                this.AccountBillingObj            = accBilling;
                this.AccountShippingObj           = accShipping;
                this.CropObj                      = crop;
                this.PaymentConditionObj          = paymentCondition;
                this.OrderRecordTypeId            = ord.RecordType.Id;
                this.HasErrorDate                 = this.DateNCD < this.DateToday ? true : false;
                this.IsUserRtv                    = isRtvUser;
                this.PaymentDateOrder             = ord.PaymentDate__c == null  ? null  : date.newInstance(ord.PaymentDate__c.year(), ord.PaymentDate__c.month(), ord.PaymentDate__c.day());
                this.OrderCurrency                = ord.Currency__c    == 'BRL' ? true  : false;
                this.HaveProps                    = propriedadesList   == null  ? false : true;
                this.OrdItemList                  = ordItemList;
                this.CampaignList                 = campaign;
                this.MapOrderItemIdToShippingDiv  = this.OrdItemList   != null ? setMapIdToShippingDiv(this.OrdItemList) : null;
                this.PassedGrainTable             = ord.GrainTableApproval__c  == null  ? false : ord.GrainTableApproval__c;
                this.BarterType                   = ord.BarterType__c;
                this.Commodity                    = ord.Commodity__c;
                this.ShippingCrop                 = shippingCrop;
                this.BillingCrop                  = ord.BillingCrop__c;
                this.GrossUnitPrice               = ord.GrossUnitPrice__c;
                this.UnitPrice                    = ord.UnitPrice__c;
                this.CommercialMeasureUnit        = ord.CommercialMeasureUnit__c;
                this.CommodityShipping            = ord.CommodityShipping__c;
                this.InitialDeliveryDate          = ord.InitialDeliveryDate__c == null  ? null  : date.newInstance(ord.InitialDeliveryDate__c.year(), ord.InitialDeliveryDate__c.month(), ord.InitialDeliveryDate__c.day());
                this.EndDeliveryDate              = ord.EndDeliveryDate__c     == null  ? null  : date.newInstance(ord.EndDeliveryDate__c.year(), ord.EndDeliveryDate__c.month(), ord.EndDeliveryDate__c.day());
                this.ContractEndDate              = ord.ContractEndDate__c     == null  ? null  : date.newInstance(ord.ContractEndDate__c.year(), ord.ContractEndDate__c.month(), ord.ContractEndDate__c.day());
                this.ContractStartDate            = ord.ContractStartDate__c   == null  ? null  : date.newInstance(ord.ContractStartDate__c.year(), ord.ContractStartDate__c.month(), ord.ContractStartDate__c.day());
                this.TotalDeliveryQuantity        = ord.DeliveryQuantity__c;
                this.ProductionDeliveryLocation   = ord.ProductionDeliveryLocation__c;
                this.ProductionPickupLocation     = ord.ProductionPickupLocation__c;
                this.StrikePrice                  = ord.StrikePrice__c;
                this.DueDateFinancial             = ord.DueDateFinancial__c    == null  ? null  : date.newInstance(ord.DueDateFinancial__c.year(), ord.DueDateFinancial__c.month(), ord.DueDateFinancial__c.day());
                this.Trade                        = ord.AccountTradeName__c;
                this.orderObject                  = new OrderVO(
                    this.OrderObj, 
                    this.AccountObj, 
                    this.IsUserRtv, 
                    this.AccountBillingObj, 
                    this.AccountShippingObj,
                    this.PaymentDateOrder,
                    this.CropObj, 
                    this.PaymentConditionObj,
                    this.ShippingCrop,
                    this.OrderContractObj);
            } else if (acc != null) {
                this.StatusOrder         = '_iscreate_';
                this.IsProp              = acc.RecordType.DeveloperName == 'Property' ? true : false;
                this.IsPropAndHaveParent = this.IsProp == true && acc.ParentId != null  ? true : false;
                if(this.IsProp == true) {
                    if(this.IsPropAndHaveParent == true) {
                        this.AccountObjNewAccount        = new NewAccount(acc.ParentId, acc.Parent.Name, acc.NCDDate__c, acc.Parent.ExternalId__c);
                        this.AccountBillingObj           = acc;
                        this.AccountShippingObj          = acc;
                        this.DateNCD                     = this.AccountObjNewAccount.NCDDate;
                        this.HasErrorDate                = this.DateNCD < this.DateToday ? true: false;
                        this.HaveProps                   = true;
                        this.IsUserRtv                   = isRtvUser;
                        this.CurrentUserRtv              = rtvUser;
                        this.HasErrorPropWithoutParentId = false;
                        this.MapIdRtvToSalesTeams        = GetAccountTeam.getRTVSalesTeam(this.AccountObjNewAccount.Id);
                    } else {
                        this.HasErrorPropWithoutParentId = true;
                        this.HaveProps      = propriedadesList == null ? false : true;
                        this.CurrentUserRtv = rtvUser;
                        this.IsUserRtv      = isRtvUser;
                    }
                } else {
                    this.AccountObj                  = acc;
                    this.DateNCD                     = this.AccountObj.NCDDate__c;
                    this.HasErrorDate                = this.DateNCD < this.DateToday ? true: false;
                    this.HaveProps                   = propriedadesList == null ? false : true;
                    this.IsUserRtv                   = isRtvUser;
                    this.CurrentUserRtv              = rtvUser;
                    this.HasErrorPropWithoutParentId = false;
                    this.MapIdRtvToSalesTeams        = GetAccountTeam.getRTVSalesTeam(this.AccountObj.Id);
                }
            } else {
                this.StatusOrder    = '_isnew_';
                this.HaveProps      = propriedadesList == null ? false : true;
                this.CurrentUserRtv = rtvUser;
                this.IsUserRtv      = isRtvUser;
            }
        }

        public String getDayInLWCDateFormat(Date todayDate) {
            Date dateTodayAddDays = todayDate.addDays(30);   
            Integer day           = dateTodayAddDays.day();
            Integer month         = dateTodayAddDays.month();
            String monthPadLeft   = String.valueOf(month).leftPad(2, '0');
            Integer year          = dateTodayAddDays.year();
            String dayString      = year + '-' + monthPadLeft + '-' + day;
            return dayString;
        }

        public Map<Id, List<ShippingDivision__c>> setMapIdToShippingDiv(List<OrderItem> ordItemList) {
            Map<Id, List<ShippingDivision__c>> mapIdToShip = new Map<Id, List<ShippingDivision__c>>();
            List<Id> ordItemIdList = new List<Id>();

            for(OrderItem ordItem : ordItemList) {
                ordItemIdList.add(ordItem.Id);
            }
            List<ShippingDivision__c> shipList = new List<ShippingDivision__c>();

            shipList = [SELECT Id, OwnerId, IsDeleted, Name,
            CreatedDate, CreatedById, LastModifiedDate,
            LastModifiedById, SystemModstamp, LastActivityDate,
            LastViewedDate, LastReferencedDate,
            ConfirmedQuantity__c, DeliveryDate__c,
            ExternalId__c, OrderItem__c,
            Quantity__c, RefuseReason__c FROM ShippingDivision__c WHERE OrderItem__c IN : ordItemIdList];

            if(!shipList.isEmpty()) {
                for(ShippingDivision__c sd : shipList) {
                    if(mapIdToShip.containsKey(sd.OrderItem__c)) {
                        List<ShippingDivision__c> shipListPopulate = mapIdToShip.get(sd.OrderItem__c);
                        shipListPopulate.add(sd);
                        mapIdToShip.put(sd.OrderItem__c, shipListPopulate);
                    } else {
                        mapIdToShip.put(sd.OrderItem__c, new List<ShippingDivision__c> { sd });
                    }
                }
            }
            return mapIdToShip;
        }
    }

    public class NewAccount {
        @AuraEnabled public String Id    {get;set;}
        @AuraEnabled public String Name  {get;set;}
        @AuraEnabled public Date NCDDate {get;set;}
        @AuraEnabled public String ParentExternalId {get;set;}

        public NewAccount(String id, String name, Date ncdDate, String parentExternalId) {
            this.Id      = id;
            this.Name    = name;
            this.NCDDate = ncdDate;
            this.ParentExternalId = parentExternalId;
        }
    }

    public class ToastInfo {
        @AuraEnabled public String Title   {get;set;}
        @AuraEnabled public String Message {get;set;}
        @AuraEnabled public String Type    {get;set;}

        public ToastInfo(String title, String message, String type) {
            this.Title   = title;
            this.Message = message;
            this.Type    = type;
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<InventoryResponse> handleInventory(List<String> productIds, String salesTeamId, List<String> measureList, String cropId){
        System.debug('orderItemList == ' + productIds + 'salesTeamId ==' + salesTeamId);
        List<SalesTeam__c> salesTeamList = [
            SELECT Id, DistributionCenter__r.ExternalId__c
            FROM SalesTeam__c
            WHERE Id =: salesTeamId
        ];
        System.debug('salesTeamId == ' + salesTeamId);

        List<String> centerIds = new List<String>();
        String distId = null;
        for(SalesTeam__c salesTeam : salesTeamList){
            centerIds.add(salesTeam.DistributionCenter__c);
            distId = salesTeam.DistributionCenter__r?.ExternalId__c;
        }
        System.debug('centerIds == ' + centerIds);

        List<String> productCodes = new List<String>();
        for(Product2 product : [SELECT Id, ExternalId__c FROM Product2 WHERE Id IN :productIds]){
            productCodes.add(product.ExternalId__c);
        }

        queryInventory(distId, productCodes);

        String query = '';

        query = 'SELECT Id, FutureInventory__c, Tolerance__c, Inventory__c, SalesInventory__c, Product2__c, UnitMeasurement__c, Block__c' +
                ' FROM ProductManagement__c'                                                                                              +
                ' WHERE Recordtype.Developername = \'SalesStock\''                                                                        +
                ' AND Product2__c IN: productIds'                                                                                         +
                ' AND DistributionCenter__c IN: centerIds'                                                                                +
                ' AND Crop__c =: cropId'                                                                                                  +
                ' AND UnitMeasurement__c IN: measureList';

        List<ProductManagement__c> inventoryList = Database.query(query);

        System.debug('inventoryList == ' + inventoryList);
        Map<String, ProductManagement__c> inventoryMap = new Map<String, ProductManagement__c>();

        if(!inventoryList.isEmpty()){

            for(ProductManagement__c inventory : inventoryList){
                if(inventory.Product2__c != null){
                    inventoryMap.put(inventory.Product2__c,inventory);
                }
            }
        }
        List<InventoryResponse> inventoryResponseList = new List<InventoryResponse>();
        System.debug('inventoryMap == ' + inventoryMap);
        for(String productId : productIds){
            if(inventoryMap.containsKey(productId)){
                ProductManagement__c inventory = inventoryMap.get(productId);
                System.debug(inventory);
                inventoryResponseList.add(new InventoryResponse(inventory ,true, productId));
            }
            else {
                inventoryResponseList.add(new InventoryResponse(false, productId));
            }
        }
        System.debug('inventoryResponseList == ' + inventoryResponseList);
        return  inventoryResponseList;
    }
    public static void queryInventory(String distributionId, List<String> productExternalIds ) {
        Map<String, ProductManagement__c> inventoryMapToUpsert = InventoryQueryIntegration.queryInventory(
            new List<String>{distributionId}, productExternalIds, false
        );

        if (!inventoryMapToUpsert.isEmpty()) {
            Database.upsert(inventoryMapToUpsert.values(), ProductManagement__c.ExternalId__c, false);
        }
    }

    public class InventoryResponse {
        @AuraEnabled public String ProductId {get;set;}
        @AuraEnabled public String UnitMeasurement {get;set;}
        @AuraEnabled public Boolean HasInventory {get;set;}
        @AuraEnabled public Decimal Quantity {get;set;}
        @AuraEnabled public Boolean Block {get;set;}

        public InventoryResponse (ProductManagement__c productManagement, Boolean hasInventory, String productId){
            this.Block         = productManagement.Block__c;
            this.ProductId      = productId;
            this.HasInventory   = hasInventory;
            if(hasInventory){
                this.Quantity       = productManagement.Tolerance__c == null ? 0 : productManagement.Tolerance__c;
                this.Quantity       += productManagement.Inventory__c == null ? 0 : productManagement.Inventory__c;
                this.Quantity       += productManagement.FutureInventory__c == null ? 0 : productManagement.FutureInventory__c;
                this.Quantity       -= productManagement.SalesInventory__c == null ? 0 : productManagement.SalesInventory__c;
                this.UnitMeasurement = productManagement.UnitMeasurement__c;
            }
            else {
                this.Quantity       = null;
                this.UnitMeasurement = null;
            }
        }

        public InventoryResponse (Boolean hasInventory, String productId){
            this.ProductId      = productId;
            this.HasInventory   = hasInventory;
            this.Quantity       = null;
            this.UnitMeasurement = null;
        }
    }

    public class ReadProjectedMargin {
        @AuraEnabled public ProjectedMargin__c margin  {get;set;}
        @AuraEnabled public String             family  {get;set;}
        @AuraEnabled public String             Id      {get;set;}

        public ReadProjectedMargin( ProjectedMargin__c margin){
            this.margin = margin;
            this.family = margin.Family__c;
            this.Id     = margin.Id;
        }
    }

    public class ReadProjectedMargins {
        @AuraEnabled public String erro  {get;set;}
        @AuraEnabled public List<ReadProjectedMargin> margins {get;set;}
        @AuraEnabled public String directorName {get;set;}
        @AuraEnabled public String directorId {get;set;}
        @AuraEnabled public String marketingManagerId {get;set;}
        @AuraEnabled public String marketingManagerName {get;set;}

        public ReadProjectedMargins(List<ReadProjectedMargin> margins,
                String directorName,
                String directorId,
                String marketingManagerId,
                String marketingManagerName) {
            this.margins      = margins;
            this.directorName  = directorName;
            this.marketingManagerId =marketingManagerId;
            this.marketingManagerName =marketingManagerName;
            if (this.directorName==null){
                this.directorName ='[Nome de diretor não está cadastrado :(]';
            }
            this.directorId =directorId;
        }

        public ReadProjectedMargins(String erro){
            this.erro =erro;
        }
    }    
}