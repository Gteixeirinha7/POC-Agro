public with sharing class CampaignController {
    public CampaignController() {}

     @AuraEnabled(cacheable=true)
    public static List<CampaignResponse> getCampaign(String team, String account, String accGroup, String activitySector, String crop, String orderType, String coinType){

        List<SalesTeam__c> salesTeamInfos = [
            SELECT Id, Name, SalesOrg__c, ParentId__c, ParentId__r.ParentId__c
            FROM SalesTeam__c
            WHERE Id =: team
        ];

        System.debug(account);
        System.debug(accGroup);

        String cluster;
        String org;
        String office;

        for(SalesTeam__c salesTeam : salesTeamInfos){
            cluster = salesTeam.ParentId__r.ParentId__c;
            org = salesTeam.SalesOrg__c;
            office = salesTeam.ParentId__c;
        }

        System.debug('cluster + org + office --' + cluster + '   ' + org + '   ' + office );

        String query = '';

        query = 'SELECT Campaign__c CampaignId'                                           +
                ' FROM CampaignTargetAudience__c'                                         +
                ' WHERE (Cluster__c =: cluster OR Cluster__c = null)'                     +
                ' AND (SalesOrg__c =: org OR SalesOrg__c = null)'                         +
                ' AND (SalesOffice__c =: office OR SalesOffice__c = null)'                +
                ' AND (SalesTeam__c =: team OR SalesTeam__c = null)'                      +
                ' AND (Account__c =: account OR Account__c = null)'                       +
                ' AND (CustomerGroup__c includes (:accGroup) OR CustomerGroup__c = null)';

        //if(){
        //    query = query + ' ';
        //}

        query = query + ' Group By Campaign__c';

        System.debug(query);

        List<AggregateResult> campaignAudience = Database.query(query);

        System.debug(campaignAudience);

        List<String> campaignIds = new List<String>();

        for(AggregateResult campaignData : campaignAudience){
            campaignIds.add(String.valueOf(campaignData.get('CampaignId')));
        }

        System.debug(campaignIds);

        List<Campaign> campaignList = [
            SELECT Id, Name, IsActive, Status, Description, StartDate, EndDate, BudgetedCost, Currency__c, ActualCost, ExpectedRevenue, Condition__c, Accumulative__c, RecordType.DeveloperName
            FROM Campaign
            WHERE Id IN: campaignIds
            AND Crop__c =: crop
            AND (OrderRecordType__c includes (:orderType) OR OrderRecordType__c = null)
            AND (Currency__c = 'ALL' OR Currency__c =: coinType)
            AND StartDate <= TODAY
            AND EndDate >= TODAY
            AND IsActive = true
            AND (ActivitySector__c includes (:activitySector) OR ActivitySector__c = null)
            AND Status = 'In Progress'
        ];

        System.debug(campaignList);

        List<String> filteredCampaignIds = new List<String>();

        for(Campaign campaignData : campaignList){
            filteredCampaignIds.add(campaignData.Id);
        }

        List<CampaignProduct__c> campaignProductList = [
            SELECT Id, Name, Campaign__c, CanActivateRules__c, CanReceiveDiscount__c, Family__c, Manufacturer__c, ComercialName__c, Product2__c, AvailableQuantity__c,
                   MaxQuantity__c, UsedQuantity__c, UnitMeasurement__c
            FROM CampaignProduct__c
            WHERE Campaign__c IN: filteredCampaignIds
        ];

        System.debug(campaignProductList);

        List<CampaignProduct> convertedCampaignProduct = new List<CampaignProduct>();

        for (CampaignProduct__c campaignProduct : campaignProductList){
            convertedCampaignProduct.add(new CampaignProduct(campaignProduct));
        }

        System.debug(convertedCampaignProduct);

        List<CampaignRule__c> campaignRuleList = [
            SELECT Id, Name, ProductPercent__c, Campaign__c, PaymentCondition__c, PaymentDate__c, Discount__c, OrderDiscount__c, FixedUnitPrice__c,
                   CampaignProduct__c, MaximumQuantity__c, MinimumQuantity__c, UnitMeasurement__c, MaximumOrderValue__c, MinimumOrderValue__c, RecordType.DeveloperName
            FROM CampaignRule__c
            WHERE Campaign__c IN: filteredCampaignIds
            ORDER BY RecordType.DeveloperName, CampaignProduct__c, PaymentDate__c, PaymentCondition__c
        ];

        System.debug(campaignRuleList);

        List<CampaignRule> convertedCampaignRule = new List<CampaignRule>();

        for (CampaignRule__c campaignRule : campaignRuleList){
            convertedCampaignRule.add(new CampaignRule(campaignRule));
        }

        System.debug(convertedCampaignRule);

        Map<String, List<CampaignProduct>> campaignIdToCampaignProductList = new Map<String, List<CampaignProduct>>();
        for (CampaignProduct campaignProduct : convertedCampaignProduct) {
            if (campaignIdToCampaignProductList.containsKey(campaignProduct.Campaign)) {
                campaignIdToCampaignProductList.get(campaignProduct.Campaign).add(campaignProduct);
            } else {
                campaignIdToCampaignProductList.put(campaignProduct.Campaign, new List<CampaignProduct>{campaignProduct});
            }
        }

        Map<String, List<CampaignRule>> campaignIdToCampaignRuleList = new Map<String, List<CampaignRule>>();
        for (CampaignRule campaignRule : convertedCampaignRule) {
            if (campaignIdToCampaignRuleList.containsKey(campaignRule.Campaign)) {
                campaignIdToCampaignRuleList.get(campaignRule.Campaign).add(campaignRule);
            } else {
                campaignIdToCampaignRuleList.put(campaignRule.Campaign, new List<CampaignRule>{campaignRule});
            }
        }

        List<CampaignResponse> campaignResponteList = new List<CampaignResponse> ();

        for(Campaign campaignObj : campaignList){
            //if(campaignIdToCampaignProductList.containsKey(campaignObj.Id)){
                if(campaignIdToCampaignRuleList.containsKey(campaignObj.Id)){
                    campaignResponteList.add(new CampaignResponse(campaignObj, campaignIdToCampaignProductList.get(campaignObj.Id), campaignIdToCampaignRuleList.get(campaignObj.Id)));
                }
            //}
        }

        System.debug(campaignResponteList);
        return campaignResponteList;
    }

    @AuraEnabled
    public static CampaignSummaryModel getCampaignById(String campaignId) {
        return new CampaignSummaryModel(
            [SELECT Id, Name, Description, Accumulative__c, RecordType.Name FROM Campaign WHERE Id = :campaignId]
        );
    }

    public class CampaignSummaryModel {
        @AuraEnabled public String Name         {get;set;}
        @AuraEnabled public String Description  {get;set;}
        @AuraEnabled public String Acummulative {get;set;}
        @AuraEnabled public String Type         {get;set;}
        
        public CampaignSummaryModel(Campaign campaign) {
            this.Name = campaign.Name;
            this.Description = campaign.Description;
            this.Acummulative = !campaign.Accumulative__c ? 'Não cumulativa' : '';
            this.Type = campaign.RecordType?.Name;
        }
    }

    public class CampaignResponse {
        @AuraEnabled public String                Name            {get;set;}
        @AuraEnabled public Boolean               IsActive        {get;set;}
        @AuraEnabled public String                Status          {get;set;}
        @AuraEnabled public String                Description     {get;set;}
        @AuraEnabled public Date                  StartDate       {get;set;}
        @AuraEnabled public Date                  EndDate         {get;set;}
        @AuraEnabled public Decimal               BudgetedCost    {get;set;}
        @AuraEnabled public String                CurrencyIsoCode {get;set;}
        @AuraEnabled public Decimal               ActualCost      {get;set;}
        @AuraEnabled public Decimal               ExpectedRevenue {get;set;}
        @AuraEnabled public String                CampaignId      {get;set;}
        @AuraEnabled public List<CampaignProduct> ProductList     {get;set;}
        @AuraEnabled public List<CampaignRule>    RulesList       {get;set;}
        @AuraEnabled public Boolean               Condition       {get;set;}
        @AuraEnabled public Boolean               Accumulative    {get;set;}
        @AuraEnabled public String                RecordType      {get;set;}
        

        public CampaignResponse (Campaign campaign, List<CampaignProduct> productList, List<CampaignRule> rulesList){
            this.CampaignId      = campaign.Id;
            this.ProductList     = productList;
            this.RulesList       = rulesList;
            this.Name            = campaign.Name;
            if(campaign.IsActive == true){
                this.IsActive = true;
            } else {
                this.IsActive = false;
            }
            if(campaign.Accumulative__c == true){
                this.Accumulative = true;
            } else {
                this.Accumulative = false;
            }
            this.Status          = campaign.Status;
            this.Description     = campaign.Description;
            this.StartDate       = campaign.StartDate;
            this.EndDate         = campaign.EndDate;
            this.RecordType      = campaign.RecordType.DeveloperName;
            this.BudgetedCost    = campaign.BudgetedCost;
            this.CurrencyIsoCode = campaign.Currency__c;
            this.ActualCost      = campaign.ActualCost;
            this.ExpectedRevenue = campaign.ExpectedRevenue;
            if(campaign.Condition__c == true){
                this.Condition = true;
            } else {
                this.Condition = false;
            }
        }
    }

    public class CampaignProduct {
        @AuraEnabled public String  ProductId          {get;set;}
        @AuraEnabled public String  Id                 {get;set;}
        @AuraEnabled public String  Name               {get;set;}
        @AuraEnabled public String  Campaign           {get;set;}
        @AuraEnabled public Boolean CanActivateRules   {get;set;}
        @AuraEnabled public Boolean CanReceiveDiscount {get;set;}
        @AuraEnabled public String  Family             {get;set;}
        @AuraEnabled public String  Manufacturer       {get;set;}
        @AuraEnabled public String  Product2           {get;set;}
        @AuraEnabled public Decimal AvailableQuantity  {get;set;}
        @AuraEnabled public Decimal MaxQuantity        {get;set;}
        @AuraEnabled public Decimal UsedQuantity       {get;set;}
        @AuraEnabled public String  UnitMeasurement    {get;set;}
        @AuraEnabled public String  ComercialName      {get;set;}

        public CampaignProduct (CampaignProduct__c campaignProduct) {
            this.Id                 = campaignProduct.Id;
            this.Name               = campaignProduct.Name;
            this.Campaign           = campaignProduct.Campaign__c;
            if(campaignProduct.CanActivateRules__c == true){
                this.CanActivateRules = true;
            } else {
                this.CanActivateRules = false;
            }
            if(campaignProduct.CanReceiveDiscount__c == true){
                this.CanReceiveDiscount = true;
            } else {
                this.CanReceiveDiscount = false;
            }
            this.Family             = campaignProduct.Family__c;
            this.Manufacturer       = campaignProduct.Manufacturer__c;
            this.ComercialName       = campaignProduct.ComercialName__c;
            this.Product2           = campaignProduct.Product2__c;
            this.AvailableQuantity  = campaignProduct.AvailableQuantity__c;
            this.MaxQuantity        = campaignProduct.MaxQuantity__c;
            this.UsedQuantity       = campaignProduct.UsedQuantity__c;
            this.UnitMeasurement    = campaignProduct.UnitMeasurement__c;
        }
    }

    public class CampaignRule {
        @AuraEnabled public String  Id                {get;set;}
        @AuraEnabled public String  Name              {get;set;}
        @AuraEnabled public Decimal ProductPercent    {get;set;}
        @AuraEnabled public String  Campaign          {get;set;}
        @AuraEnabled public String  PaymentCondition  {get;set;}
        @AuraEnabled public Date    PaymentDate       {get;set;}
        @AuraEnabled public Decimal Discount          {get;set;}
        @AuraEnabled public Boolean OrderDiscount     {get;set;}
        @AuraEnabled public Boolean hasFixedUnitPrice {get;set;}
        @AuraEnabled public Decimal FixedUnitPrice    {get;set;}
        @AuraEnabled public String  CampaignProduct   {get;set;}
        @AuraEnabled public Decimal MaximumQuantity   {get;set;}
        @AuraEnabled public Decimal MinimumQuantity   {get;set;}
        @AuraEnabled public String  UnitMeasurement   {get;set;}
        @AuraEnabled public Decimal MaximumOrderValue {get;set;}
        @AuraEnabled public Decimal MinimumOrderValue {get;set;}
        @AuraEnabled public String  RecordType        {get;set;}

        public CampaignRule (CampaignRule__c campaignRule) {
            this.Id                = campaignRule.Id;
            this.Name              = campaignRule.Name;
            this.ProductPercent    = campaignRule.ProductPercent__c;
            this.Campaign          = campaignRule.Campaign__c;
            this.PaymentCondition  = campaignRule.PaymentCondition__c;
            this.PaymentDate       = campaignRule.PaymentDate__c;
            this.Discount          = campaignRule.Discount__c;
            if(campaignRule.OrderDiscount__c == true){
                this.OrderDiscount = true;
            } else {
                this.OrderDiscount = false;
            }
            this.FixedUnitPrice    = campaignRule.FixedUnitPrice__c;
            this.hasFixedUnitPrice = campaignRule.FixedUnitPrice__c != null ;
            this.CampaignProduct   = campaignRule.CampaignProduct__c;
            this.MaximumQuantity   = campaignRule.MaximumQuantity__c;
            this.MinimumQuantity   = campaignRule.MinimumQuantity__c;
            this.UnitMeasurement   = campaignRule.UnitMeasurement__c;
            this.MaximumOrderValue = campaignRule.MaximumOrderValue__c;
            this.MinimumOrderValue = campaignRule.MinimumOrderValue__c;
            this.RecordType        = campaignRule.RecordType.DeveloperName;
        }
    }
}