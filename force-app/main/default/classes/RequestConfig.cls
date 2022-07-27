global abstract with sharing class RequestConfig {
	public Q instanceQ {get; set;}
	public Boolean isObjectsEmpty {get; set;}

    public ForcaAgroApp_loadBaseData.SyncData lastStamp {get; set;}

    public Integer queryLimit {get; set;}

    public List<String> recordList {get; set;}

	public RequestConfig(ForcaAgroApp_loadBaseData.SyncData lastStamp){
        this.lastStamp = lastStamp;
	}

    public RequestConfig(ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit) {
        this.lastStamp  = lastStamp;
        this.queryLimit = queryLimit;
    }

    public RequestConfig(ForcaAgroApp_loadBaseData.SyncData lastStamp, List<String> recordList){
		this.lastStamp = lastStamp;
        this.recordList = recordList;
	}

	global abstract String getType();

	public virtual Integer getLimit(){
		return this.queryLimit;
	}

	global abstract Set<String> getFields();

	public virtual List<QConditionGroup> getConditions(){
        return new List<QConditionGroup> {
            new QConditionGroup(
                new List<QCondition> {
			        Q.condition('SystemModStamp').isGreaterOrEquals(Datetime.newInstance(lastStamp.lastSyncStamp)),
                    Q.condition('Id').isGreaterThan(lastStamp.lastSyncId)
		        }
            ).setLogicalOperatorAsAnd(),
            new QConditionGroup(
                new List<QCondition> {
			        Q.condition('SystemModStamp').isGreaterThan(Datetime.newInstance(lastStamp.lastSyncStamp))
		        }
            ).setLogicalOperatorAsAnd()
        };
	}

	public virtual List<QOrder> getOrders(){
		return new List<QOrder>{
			Q.orderBy('SystemModStamp').ascending(),
            Q.orderBy('Id').ascending()
		};
	}

	public RequestConfig createQ(SObjectType fromType){
		this.instanceQ = new Q(fromType);
		return this;
	}

	public RequestConfig createQ(String fromType){
		this.instanceQ = new Q(fromType);
		return this;
	}

	public RequestConfig selectFields(Set<String> fields){
		this.instanceQ.selectFields(getFields());
		return this;
	}

	public RequestConfig addCondition(){
        for (QConditionGroup conditionGroup : getConditions()) 
            this.instanceQ.add(conditionGroup);
		return this;
	}

	public RequestConfig addOrder(){
		for (QOrder order : getOrders())
			this.instanceQ.add(order);

		return this;
	}

	public RequestConfig addLimit(){
		this.instanceQ.addLimit(getLimit());
		return this;
	}

	public RequestConfig addAllRows(){
		this.instanceQ.addAllRows();
		return this;
	}

	public virtual String build(){
        Long INITIAL_SYNC = 1430426733;

		createQ(getType())
		.selectFields(getFields())
		.addOrder()
		.addLimit()
        .addCondition();

		if (this.lastStamp.lastSyncStamp > INITIAL_SYNC && getType() != 'Freight__c'){
			addAllRows();
		}
		
		System.debug('[APEX LOG - ForcaAgroApp_loadBaseData] QBuild => ' + this.instanceQ.build());

		return this.instanceQ.build();
	}

	global class AccountConfig extends RequestConfig {

        public AccountConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'Account';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'Name',
                'CNPJ__c',
                'CPF__c',
                'StateRegistration__c',
                'ExternalId__c',
                'Email__c',
                'Phone__c',
                'ParentId',
                'Parent.ParentId',
                'InternShippingCity__c',
                'InternShippingCity__r.Name',
                'RecordType.DeveloperName',
                'NCDDate__c',
                'ShippingStreet',
                'FiscalDomicile__c',
                'ArealTotalMeters__c',
                'AreaTotal__c',
                'AreaCultivatedLand__c',
                'AreaCultivatedLandMeters__c',
                'Blocked__c',
                'IsDeleted',
                'SystemModStamp'
            };
        }
    }

    global class CropConfig extends RequestConfig {

        public CropConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'Crop__c';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'Name',
                'ExternalId__c',
                'StartDate__c',
                'EndDate__c',
                'Active__c',
                'IsDeleted',
                'SystemModStamp'
            };
        }
    }

    global class PaymentConditionConfig extends RequestConfig {

        public PaymentConditionConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'PaymentCondition__c';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'Name',
                'ExternalId__c',
                'PaymentForm__c',
                'PaymentType__c',
                'Active__c',
                'IsDeleted',
                'SystemModStamp'
            };
        }
    }

    global class FamilyConfig extends RequestConfig {

        public FamilyConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'Family__c';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'Name',
                'ExternalId__c',
                'Active__c',
                'IsDeleted',
                'SystemModStamp'
            };
        }
    }

    global class ProductConfig extends RequestConfig {

        public ProductConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'Product2';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'Name',
                'ProductCode',
                'ActivitySector__c',
                'Family__c',
                'GrossWeight__c',
                'GrossWeightUnity__c',
                'IsActive',
                'Multiplicity__c',
                'QuantityUnitOfMeasure',
                'SalesOrg__c ',
                'RemoveFreightValue__c',
                'ActivePrinciple__c',
                'Fornecedor__c',
                'Brand__c',
                'IsDeleted',
                'SystemModStamp'
            };
        }
    }

    global class CultureConfig extends RequestConfig {

        public CultureConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'Culture__c';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'Name',
                'ExternalId__c',
                'Active__c',
                'IsDeleted',
                'SystemModStamp'
            };
        }
    }

    global class ListPriceConfig extends RequestConfig {

        public ListPriceConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'ListPrice__c';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'Name',
                'ListPriceCode__c',
                'CustomerGroup__c',
                'Account__c',
                'Crop__c',
                'Currency__c',
                'Description__c',
                'EndDate__c',
                'InitialDate__c',
                'IsActive__c',
                'SalesOrg__c',
                'Priority__c',
                'InterestPriority__c',
                'Product2Id__c',
                'ProductFamily__c',
                'SalesOffice__c',
                'ActivitySector__c',
                'SalesTeam__c',
                'UnitPrice__c',
                'SalesCondition__c',
                'EffectiveDate__c',
                'InterestValue__c',
                'RecordType.DeveloperName',
                'CreatedDate',
                'PriceMultiplier__c',
                'Cost__c',
                'IsDeleted',
                'SystemModStamp'
            };
        }

        public override List<QConditionGroup> getConditions(){
            return new List<QConditionGroup> {
                new QConditionGroup(
                    new List<QCondition> {
                        Q.condition('SystemModStamp').isGreaterOrEquals(Datetime.newInstance(lastStamp.lastSyncStamp)),
                        Q.condition('Id').isGreaterThan(lastStamp.lastSyncId),
                        Q.condition('SalesCondition__c').notEqualsTo('18'),
                        Q.condition('IsActive__c').equalsTo(true)
                    }
                ).setLogicalOperatorAsAnd(),
                new QConditionGroup(
                    new List<QCondition> {
                        Q.condition('SystemModStamp').isGreaterThan(Datetime.newInstance(lastStamp.lastSyncStamp)),
                        Q.condition('SalesCondition__c').notEqualsTo('18'),
                        Q.condition('IsActive__c').notEqualsTo(true)
                    }
                ).setLogicalOperatorAsAnd()
            };
        }
    }

    global class FreightConfig extends RequestConfig {

        public FreightConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'Freight__c';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'ExternalId__c',
                'SourceCity__c',
                'DestinationCity__c',
                'StartDate__c',
                'EndDate__c',
                'Product2Id__c',
                'ValuePerTonDolar__c',
                'ValuePerTon__c',
                'Family__c',
                'Priority__c',
                'IsActive__c',
                'IsDeleted',
                'SystemModStamp'
            };
        }
    }

    global class OrderConfig extends RequestConfig {

        public OrderConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'Order';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'OrderNumber',
                'StatusSF__c',
                'StatusSAP__c',
                'CreatedDate',
                'AccountId',
                'Account.Name',
                'BillingAccount__c',
                'BillingAccount__r.Name',
                'ShippingAccount__c',
                'ShippingAccount__r.Name',
                'ShippingAccount__r.InternShippingCity__c',
                'ShippingAccount__r.InternShippingCity__r.Name',
                'RTV__c',
                'RTV__r.Name',
                'SalesTeam__c',
                'SalesTeam__r.Name',
                'SalesTeam__r.DistributionCenter__c',
                'SalesTeam__r.DistributionCenter__r.City__c',
                'SalesTeam__r.SalesOrg__c',
                'SalesTeam__r.ParentId__c',
                'RecordType.DeveloperName',
                'SalesCondition__c',
                'Currency__c',
                'EndDate',
                'Crop__c',
                'Crop__r.Name',
                'PaymentCondition__c',
                'PaymentForm__c',
                'PaymentDate__c',
                'Description',
                'TotalAmountWithFreight__c',
                'OriginalOrder__c',
                'OldOrderCredit__c',
                'ActivitySector__c',
                'ContainIntegrationError__c',
                'CommercialApproval__c',
                'DiscountApprover__c',
                'DiscountApprover__r.Name',
                'DiscountApprover2__c',
                'DiscountApprover2__r.Name',
                'DiscountApprover3__c',
                'DiscountApprover3__r.Name',
                'DiscountApprover4__c',
                'DiscountApprover4__r.Name',
                'Approved1__c',
                'Approved2__c',
                'Approved3__c',
                'Approved4__c',
                'FinancialAdministrativeManager__c',
                'FinancialAdministrativeManager__r.Name',
                'MarginApprover__r.Name',
                'CustomerGroup__c',

                'BarterType__c',
                'StrikePrice__c',
                'Commodity__c',
                'GrossUnitPrice__c',
                'UnitPrice__c',
                'InitialDeliveryDate__c',
                'EndDeliveryDate__c',
                'DeliveryQuantity__c',
                'Freight__c',
                'ProductionPickupLocation__c',
                'ProductionDeliveryLocation__c',
                'ShippingCrop__c',
                'ShippingCrop__r.Name',
                'AccountTradeName__c',
                'Trade__c',
                'Trade__r.Name',
                'DueDateFinancial__c',
                'CommercialMeasureUnit__c',
                'ContractEndDate__c',
                'ContractStartDate__c',
                'GrainTableApproval__c',

                'ContractOrder__c',
                'ObservationRTV__c',
                'LastModifiedDate',
                'DistributionPublicUrl__c',
                'DeletedProductProcessSap__c',

                'ContainStockError__c',
                'OrderRoute__c',
                
                'IsDeleted',
                'SystemModStamp'
            };
        }

        public override List<QConditionGroup> getConditions(){
            return new List<QConditionGroup> {
                new QConditionGroup(
                    new List<QCondition> {
                        Q.condition('SystemModStamp').isGreaterOrEquals(Datetime.newInstance(lastStamp.lastSyncStamp)),
                        Q.condition('Id').isGreaterThan(lastStamp.lastSyncId),
                        Q.condition('Crop__r.EndDate__c').isGreaterOrEquals(Date.today())
                    }
                ).setLogicalOperatorAsAnd(),
                new QConditionGroup(
                    new List<QCondition> {
                        Q.condition('SystemModStamp').isGreaterThan(Datetime.newInstance(lastStamp.lastSyncStamp)),
                        Q.condition('Crop__r.EndDate__c').isGreaterOrEquals(Date.today())
                    }
                ).setLogicalOperatorAsAnd()
            };
        }
    }

    global class OrderItemConfig extends RequestConfig {

        public OrderItemConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'OrderItem';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'ExternalId__c',
                'OrderId',
                'Product2.Family__c',
                'Product2.Family__r.Name',
                'Product2Id',
                'Product2.Name',
                'Product2.ProductCode',
                'Product2.ActivitySector__c',
                'Product2.QuantityUnitOfMeasure',
                'ListPrice__c',
                'ListPrice__r.Name',
                'ListPrice__r.UnitPrice__c',
                'InterestOrAntecipationDiscount__c',
                'InterestOrAntecipationDiscount__r.Name',
                'Quantity',
                'UnitPrice',
                'DiscountPercent__c',
                'DiscountAmount__c',
                'AdditionPercent__c',
                'AdditionAmount__c',
                'TotalPrice__c',
                'Freight__c',
                'FreightValue__c',
                'FreightValuePerTon__c',
                'Product2.GrossWeightUnity__c',
                'Product2.GrossWeight__c',
                'Culture__c',
                'Culture__r.Name',
                'RefuseCredit__c',
                'CalculatedInterest__c',
                'AnticipationDiscount__c',
                'InterestValue__c',
                'LastChangedPriceList__c',
                'DeletedProductSAP__c',
                'ContainStockError__c',
                'Margin__c',
                'FamilyMargin__c',
                'ProjectedMargin__c',
                'IsDeleted',
                'SystemModStamp'
            };
        }

        public override List<QConditionGroup> getConditions(){
            return new List<QConditionGroup> {
                new QConditionGroup(
                    new List<QCondition> {
                        Q.condition('SystemModStamp').isGreaterOrEquals(Datetime.newInstance(lastStamp.lastSyncStamp)),
                        Q.condition('Id').isGreaterThan(lastStamp.lastSyncId),
                        Q.condition('Order.Crop__r.EndDate__c').isGreaterOrEquals(Date.today())
                    }
                ).setLogicalOperatorAsAnd(),
                new QConditionGroup(
                    new List<QCondition> {
                        Q.condition('SystemModStamp').isGreaterThan(Datetime.newInstance(lastStamp.lastSyncStamp)),
                        Q.condition('Order.Crop__r.EndDate__c').isGreaterOrEquals(Date.today())
                    }
                ).setLogicalOperatorAsAnd()
            };
        }
    }

    global class ShippingDivisionConfig extends RequestConfig {

        public ShippingDivisionConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'ShippingDivision__c';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'OrderItem__c',
                'OrderItem__r.Product2Id',
                'DeliveryDate__c',
                'Quantity__c',
                'RefuseReason__c',
                'IsDeleted',
                'SystemModStamp'
            };
        }

        public override List<QConditionGroup> getConditions(){
            return new List<QConditionGroup> {
                new QConditionGroup(
                    new List<QCondition> {
                        Q.condition('SystemModStamp').isGreaterOrEquals(Datetime.newInstance(lastStamp.lastSyncStamp)),
                        Q.condition('Id').isGreaterThan(lastStamp.lastSyncId),
                        Q.condition('OrderItem__r.Order.Crop__r.EndDate__c').isGreaterOrEquals(Date.today())
                    }
                ).setLogicalOperatorAsAnd(),
                new QConditionGroup(
                    new List<QCondition> {
                        Q.condition('SystemModStamp').isGreaterThan(Datetime.newInstance(lastStamp.lastSyncStamp)),
                        Q.condition('OrderItem__r.Order.Crop__r.EndDate__c').isGreaterOrEquals(Date.today())
                    }
                ).setLogicalOperatorAsAnd()
            };
        }
    }

    global class CustomerPerOrgConfig extends RequestConfig {

        public CustomerPerOrgConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'CustomerPerOrg__c';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'Customer__c',
                'SalesOrg__c',
                'ClientGroup__c',
                'ActivitySector__c',
                'DistributionChannel__c',
                'Blocked__c',
                'IsDeleted',
                'SystemModStamp'
            };
        }
    }

    global class FinancialDueDateConfig extends RequestConfig {

        public FinancialDueDateConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'FinancialDueDate__c';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'Crop__c',
                'Commodity__c',
                'FinancialDueDate__c',
                'IsDeleted',
                'SystemModStamp'
            };
        }
    }

    global class FieldDependencyConfig extends RequestConfig {

        public FieldDependencyConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'FieldDependency__c';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'DependencyFieldKey__c',
                'DependencyField__c',
                'Value__c',
                'DependencyValue__c',
                'IsDeleted',
                'SystemModStamp'
            };
        }
    }

    global class RangeDiscountConfig extends RequestConfig {

        public RangeDiscountConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'RangeDiscount__c';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'ApprovingAuthority__c', 
                'CustomerCategory__c', 
                'Family__c', 
                'FinalDate__c', 
                'InitialDate__c', 
                'MaximaPercentage__c', 
                'MinimumPercentage__c', 
                'SalesOffice__c', 
                'Status__c', 
                'PaymentType__c', 
                'SalesOrg__c',
                'IsDeleted',
                'SystemModStamp'
            };
        }
    }

    global class ClientCNDStateConfig extends RequestConfig {

        public ClientCNDStateConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'ClientCNDState__c';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'Name',
                'IsDeleted',
                'SystemModStamp'
            };
        }
    }

    global class OrderTypesConfig extends RequestConfig {

        public OrderTypesConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'OrderTypes__c';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'Name',
                'SalesContracts__c',
                'SalesOrders__c',
                'IsDeleted',
                'SystemModStamp'
            };
        }
    }

    global class ProductManagementConfig extends RequestConfig {

        public ProductManagementConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'ProductManagement__c';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'Name',
                'Product2__c',
                'SalesTeam__c',
                'Crop__c',
                'InitialDate__c',
                'EndDate__c',
                'ExternalId__c',
                'CurrencyIsoCode',
                'UnitMeasurement__c',
                'RecordType.DeveloperName',   
                'Inventory__c',
                'FutureInventory__c',
                'SalesInventory__c',
                'DistributionCenter__c',
                'Tolerance__c',
                'Block__c',
                'IsActive__c',
                'IsDeleted',
                'SystemModStamp'
            };
        }

        public override List<QConditionGroup> getConditions(){
            List<RelatedUserSalesTeam__c> relatedUserSalesTeamList = RelatedUserSalesTeamDAO.getRelatedUserSalesTeamByRTV(
                new List<String>{UserInfo.getUserId()}, new Set<String>{'Id', 'SalesTeam__c', 'SalesTeam__r.DistributionCenter__c'}
            );

            List<String> salesTeamIds = new List<String>{null};
            List<String> distributionCenterIds = new List<String>{null};
            for (RelatedUserSalesTeam__c relatedUserSalesTeam : relatedUserSalesTeamList) {
                salesTeamIds.add(relatedUserSalesTeam.SalesTeam__c);
                distributionCenterIds.add(relatedUserSalesTeam.SalesTeam__r?.DistributionCenter__c);
            }

            return new List<QConditionGroup> {
                new QConditionGroup(
                    new List<QCondition> {
                        Q.condition('SystemModStamp').isGreaterOrEquals(Datetime.newInstance(lastStamp.lastSyncStamp)),
                        Q.condition('Id').isGreaterThan(lastStamp.lastSyncId),
                        Q.condition('SalesTeam__c').isIn(salesTeamIds),
                        Q.condition('DistributionCenter__c').isIn(distributionCenterIds),
                        Q.condition('IsActive__c').equalsTo(true)
                    }
                ).setLogicalOperatorAsAnd(),
                new QConditionGroup(
                    new List<QCondition> {
                        Q.condition('SystemModStamp').isGreaterThan(Datetime.newInstance(lastStamp.lastSyncStamp)),
                        Q.condition('SalesTeam__c').isIn(salesTeamIds),
                        Q.condition('DistributionCenter__c').isIn(distributionCenterIds),
                        Q.condition('IsActive__c').equalsTo(true)
                    }
                ).setLogicalOperatorAsAnd()
            };
        }

    }

    global class CampaignConfig extends RequestConfig {

        public CampaignConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'Campaign';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'Name',
                'StartDate',
                'EndDate',
                'Status',
                'Currency__c',
                'Description',
                'BudgetedCost',
                'ActualCost',
                'ExpectedRevenue',

                'OrderRecordType__c',
                'ActivitySector__c',
                'Crop__c',
                'RecordType.DeveloperName',
                'Accumulative__c',
                'Condition__c',
                'IsActive',

                'IsDeleted',
                'SystemModStamp'
            };
        }
    }

    global class CampaignProductConfig extends RequestConfig {

        public CampaignProductConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'CampaignProduct__c';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'Name',
                'MaxQuantity__c',
                'UsedQuantity__c',
                'AvailableQuantity__c',
                'UnitMeasurement__c',
                'Product2__c',
                'Family__c',
                'Manufacturer__c',
                'ComercialName__c',
                'Campaign__c',
                'CanActivateRules__c',
                'CanReceiveDiscount__c',
                'IsDeleted',
                'SystemModStamp'
            };
        }
    }

    global class CampaignRuleConfig extends RequestConfig {

        public CampaignRuleConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'CampaignRule__c';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'Name',
                'Campaign__c',
                'UnitMeasurement__c',
                'MinimumQuantity__c',
                'MaximumQuantity__c',
                'CampaignProduct__c',
                'ProductPercent__c',
                'MinimumOrderValue__c',
                'MaximumOrderValue__c',
                'PaymentDate__c',
                'PaymentCondition__c',
                'FixedUnitPrice__c',
                'Discount__c',
                'RecordType.DeveloperName',
                'OrderDiscount__c',
                'IsDeleted',
                'SystemModStamp'
            };
        }
    }

    global class CampaignOrderItemConfig extends RequestConfig {

        public CampaignOrderItemConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'CampaignOrderItem__c';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'Campaign__c',
                'CampaignProduct__c',
                'OrderItem__c',
                'OrderItem__r.Product2Id',
                'Discount__c',
                'FixedUnitPrice__c',
                'DiscountValue__c',
                'FixedUnitPriceCampaign__c',
                'IsDeleted',
                'SystemModStamp'
            };
        }
    }

    global class CampaignTargetAudienceConfig extends RequestConfig {

        public CampaignTargetAudienceConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'CampaignTargetAudience__c';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'Campaign__c',
                'Cluster__c',
                'SalesOrg__c',
                'SalesOffice__c',
                'SalesTeam__c',
                'Account__c',
                'Rating__c',
                'CustomerGroup__c',
                'IsDeleted',
                'SystemModStamp'
            };
        }
    }

    global class EventConfig extends RequestConfig {

        public EventConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'Event';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'Subject',
                'StartDateTime',
                'EndDateTime',
                'EventType__c',
                'OwnerId',
                'Owner.Name',
                'Account__c',
                'Account__r.Name',
                'Checkin__Latitude__s',
                'Checkin__Longitude__s',
                'VisitOpinion__c',
                'CheckInDone__c',
                'Description',
                'Case__c',
                'Case__r.CaseNumber',
                'Case__r.Subject',
                'Crop__c',
                'Crop__r.Name',
                'IsDeleted',
                'SystemModStamp'
            };
        }

        public override List<QConditionGroup> getConditions(){
            return new List<QConditionGroup> {
                new QConditionGroup(
                    new List<QCondition> {
                        Q.condition('SystemModStamp').isGreaterOrEquals(Datetime.newInstance(lastStamp.lastSyncStamp)),
                        Q.condition('Id').isGreaterThan(lastStamp.lastSyncId),
                        Q.condition('CreatedDate').isGreaterOrEquals((Datetime)Date.today().addDays(-30))
                    }
                ).setLogicalOperatorAsAnd(),
                new QConditionGroup(
                    new List<QCondition> {
                        Q.condition('SystemModStamp').isGreaterThan(Datetime.newInstance(lastStamp.lastSyncStamp)),
                        Q.condition('CreatedDate').isGreaterOrEquals((Datetime)Date.today().addDays(-30))
                    }
                ).setLogicalOperatorAsAnd()
            };
        }
    }

    global class EventTypesConfig extends RequestConfig {

        public EventTypesConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'EventTypes__c';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'Name',
                'IsActive__c',
                'MandatoryImagesQuantity__c',
                'IsDeleted',
                'SystemModStamp'
            };
        }
    }

    global class RatingCreditConfig extends RequestConfig {

        public RatingCreditConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'RatingCredit__c';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'Account__c',
                'Rating__c',
                'toLabel(RatingSAP__c) RatingSAP',
                'IsDeleted',
                'SystemModStamp'
            };
        }
    }

    global class ProjectedMarginConfig extends RequestConfig {

        public ProjectedMarginConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'ProjectedMargin__c';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'Family__c',
                'Crop__c',
                'SalesOrg__c',
                'Margin__c',
                'IsDeleted',
                'SystemModStamp'
            };
        }
    }

    
    global class DelimitedLandConfig extends RequestConfig {

        public DelimitedLandConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'DelimitedLand__c';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'Name',
                'Description__c',
                'Account__c',
                'AreaCultivated__c',
                'AreaNotAllocated__c',
                'AreaPasture__c',
                'AreaPreservation__c',
                'UnitMeasurement__c',
                'OwnerName__c',
                'TenantCulture__c',
                'TenantCulture__r.Name',
                'TenantValue__c',
                'TenantTax__c',
                'Tenant__c',
                'TenantArea__c',
                'ContractDate__c',
                'IsDeleted',
                'SystemModStamp'
            };
        }
    }

    global class DelimitedLandCulturesConfig extends RequestConfig {

        public DelimitedLandCulturesConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'DelimitedLandCultures__c';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'AreaCultivated__c',
                'Crop__c',
                'Culture__c',
                'Date__c',
                'DelimitedLand__c',
                'WarehouseCapability__c',
                'TechnologicalLevel__c',
                'IsDeleted',
                'SystemModStamp'
            };
        }
    }

    global class UserConfig extends RequestConfig {

        public UserConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'User';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'Name',
                'IsActive',
                'SystemModStamp'
            };
        }
    }

    global class CaseConfig extends RequestConfig {

        public CaseConfig (ForcaAgroApp_loadBaseData.SyncData lastStamp, Integer queryLimit){
            super(lastStamp, queryLimit);
        }
        
        public override String getType(){
            return 'Case';
        }

        public override Set<String> getFields(){
            return new Set<String>{
                'Id',
                'CaseNumber',
                'Subject',
                'Description',
                'IncidentTypePicklist__c',
                'Origin',
                'AccountId',
                'Crop__c',
                'Plot__c',
                'CulturePlot__c',
                'DamagedArea__c',
                'IsDeleted',
                'SystemModStamp'
            };
        }
    }

}