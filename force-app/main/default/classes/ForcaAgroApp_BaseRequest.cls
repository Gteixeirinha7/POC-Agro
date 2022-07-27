global abstract with sharing class ForcaAgroApp_BaseRequest {

	public List<String> id;
	protected ForcaAgroApp_loadBaseData.SyncData lastStamp = null;
	protected Integer size;

	public ForcaAgroApp_BaseRequest() {
		this.lastStamp = new ForcaAgroApp_loadBaseData.SyncData('', null);
	}

	public ForcaAgroApp_loadBaseData.SyncData getLastStamp() {
		return this.lastStamp;
	}

	public Integer getSize() {
		return this.size;
	}

    public virtual List<SObject> executeQ(RequestConfig config){
		return Database.query(config.build());
	}

	public virtual Boolean fillRequest(RequestConfig config){
		List<SObject> records = executeQ(config);
		
		for (SObject sobj : records)
			parseData(sobj);

		this.size = records.size();

		if (records.size() > 0) {
			SObject lastRecord = records.get(records.size() - 1);

			this.lastStamp = new ForcaAgroApp_loadBaseData.SyncData(
				(String)lastRecord.get('Id'),
				((DateTime)lastRecord.get('SystemModStamp')).getTime()
			);
		}

		if (this.id.size() >= config.getLimit())
			return true;
		return false;
	}

	global abstract void parseData(SObject sobj);

	public static String getDate(Datetime dt) {
		return dt != null ? String.valueOf(dt.date()) : null; 
	}

	public static String getHour(Datetime dt) {
		return dt != null ? dt.hour() + ':' + dt.minute() : null;
	}

	global class AccountRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> name, code, cnpj, cpf, ie, email, phone, parentId, parentParentId, cityId, cityName, devName, ncdDate, address, fiscalDomicile;
		List<Decimal> areaTotalMeters, areaTotal, areaCultivatedLand, areaCultivatedLandMeters;
		List<Boolean> blocked, deleted;

        public AccountRequest(){
			super();
			this.id              = new List<String>();
			this.name            = new List<String>();
            this.code            = new List<String>();
            this.cnpj            = new List<String>();
			this.cpf             = new List<String>();
            this.ie              = new List<String>();
            this.email           = new List<String>();
            this.phone           = new List<String>();
            this.parentId        = new List<String>();
			this.parentParentId  = new List<String>();
			this.cityId	 		 = new List<String>();
			this.cityName	 	 = new List<String>();
			this.devName	 	 = new List<String>();
			this.ncdDate		 = new List<String>();
			this.address		 = new List<String>();
			this.fiscalDomicile	 = new List<String>();
			this.areaTotalMeters = new List<Decimal>();
			this.areaTotal 		 = new List<Decimal>();
			this.areaCultivatedLand = new List<Decimal>();
			this.areaCultivatedLandMeters = new List<Decimal>();
			this.blocked		 = new List<Boolean>();
			this.deleted         = new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            Account account = (Account)sobj;

			this.id.add(account.Id);
			this.name.add(account.Name);
            this.code.add(account.ExternalId__c);
			this.cpf.add(account.CPF__c);
            this.cnpj.add(account.CNPJ__c);
            this.ie.add(account.StateRegistration__c);
            this.email.add(account.Email__c);
            this.phone.add(account.Phone__c);
            this.parentId.add(account.ParentId);
			this.parentParentId.add(account.Parent?.ParentId);
			this.cityId.add(account.InternShippingCity__c);
			this.cityName.add(account.InternShippingCity__c != null ? account.InternShippingCity__r.Name : '');
			this.devName.add(account.RecordType.DeveloperName);
			this.ncdDate.add(String.valueOf(account.NCDDate__c));
			this.address.add(account.ShippingStreet);
			this.fiscalDomicile.add(account.FiscalDomicile__c);
			this.areaTotalMeters.add(account.ArealTotalMeters__c);
			this.areaTotal.add(account.AreaTotal__c);
			this.areaCultivatedLand.add(account.AreaCultivatedLand__c);
			this.areaCultivatedLandMeters.add(account.AreaCultivatedLandMeters__c);
			this.blocked.add(account.Blocked__c);
			this.deleted.add(account.isDeleted);
        }
    }

	global class CropRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> name, code, startDate, endDate;
		List<Boolean> isActive, deleted;

        public CropRequest(){
			super();
			this.id              = new List<String>();
			this.name            = new List<String>();
            this.code            = new List<String>();
            this.startDate       = new List<String>();
            this.endDate         = new List<String>();
            this.isActive		 = new List<Boolean>();
            this.deleted         = new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            Crop__c crop = (Crop__c)sobj;

			this.id.add(crop.Id);
			this.name.add(crop.Name);
            this.code.add(crop.ExternalId__c);
            this.startDate.add(String.valueOf(crop.StartDate__c));
            this.endDate.add(String.valueOf(crop.EndDate__c));
            this.isActive.add(crop.Active__c);
            this.deleted.add(crop.isDeleted);
        }
    }

	global class PaymentConditionRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> name, code, paymentFormOptions, paymentType;
		List<Boolean> deleted, isActive;

        public PaymentConditionRequest(){
			super();
			this.id              	= new List<String>();
			this.name            	= new List<String>();
            this.code            	= new List<String>();
			this.paymentFormOptions = new List<String>();
			this.paymentType		= new List<String>();
			this.isActive         	= new List<Boolean>();
            this.deleted         	= new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            PaymentCondition__c paymentCondition = (PaymentCondition__c)sobj;

			this.id.add(paymentCondition.Id);
			this.name.add(paymentCondition.Name);
            this.code.add(paymentCondition.ExternalId__c);
			this.paymentFormOptions.add(paymentCondition.PaymentForm__c);
			this.paymentType.add(paymentCondition.PaymentType__c);
			this.isActive.add(paymentCondition.Active__c);
            this.deleted.add(paymentCondition.isDeleted);
        }
    }

	global class FamilyRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> name, code;
		List<Boolean> deleted, isActive;

        public FamilyRequest(){
			super();
			this.id              = new List<String>();
			this.name            = new List<String>();
            this.code            = new List<String>();
			this.isActive        = new List<Boolean>();
            this.deleted         = new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            Family__c family = (Family__c)sobj;

			this.id.add(family.Id);
			this.name.add(family.Name);
            this.code.add(family.ExternalId__c);
			this.isActive.add(family.Active__c);
            this.deleted.add(family.isDeleted);
        }
    }

	global class ProductRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> name, code, activitySector, familyId, grossWeightUnity, quantityUnitOfMeasure, salesOrgId, activePrinciple, manufacturer, brand;
		List<Decimal> grossWeight, multiplicity;
		List<Boolean> removeFreightValue, isActive, deleted;

        public ProductRequest(){
			super();
			this.id              		= new List<String>();
			this.name            		= new List<String>();
            this.code            		= new List<String>();
			this.activitySector			= new List<String>();
			this.familyId				= new List<String>();
			this.grossWeight			= new List<Decimal>();
			this.grossWeightUnity		= new List<String>();
			this.multiplicity			= new List<Decimal>();
			this.quantityUnitOfMeasure	= new List<String>();
			this.salesOrgId				= new List<String>();
			this.activePrinciple		= new List<String>();
			this.manufacturer			= new List<String>();
			this.brand       			= new List<String>();
			this.removeFreightValue		= new List<Boolean>();
			this.isActive				= new List<Boolean>();
            this.deleted         		= new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            Product2 product = (Product2)sobj;

			this.id.add(product.Id);
			this.name.add(product.Name);
            this.code.add(product.ProductCode);
			this.activitySector.add(product.ActivitySector__c);
			this.familyId.add(product.Family__c);
			this.grossWeight.add(product.GrossWeight__c);
			this.grossWeightUnity.add(product.GrossWeightUnity__c);
			this.multiplicity.add(product.Multiplicity__c);
			this.quantityUnitOfMeasure.add(product.QuantityUnitOfMeasure);
			this.salesOrgId.add(product.SalesOrg__c);
			this.activePrinciple.add(product.ActivePrinciple__c);
			this.manufacturer.add(product.Fornecedor__c);
			this.brand.add(product.Brand__c);
			this.removeFreightValue.add(product.RemoveFreightValue__c);
			this.isActive.add(product.IsActive);
            this.deleted.add(product.isDeleted);
        }
    }

	global class CultureRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> name, code;
		List<Boolean> deleted, isActive;

        public CultureRequest(){
			super();
			this.id              = new List<String>();
			this.name            = new List<String>();
            this.code            = new List<String>();
			this.isActive        = new List<Boolean>();
            this.deleted         = new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            Culture__c culture = (Culture__c)sobj;

			this.id.add(culture.Id);
			this.name.add(culture.Name);
            this.code.add(culture.ExternalId__c);
			this.isActive.add(culture.Active__c);
            this.deleted.add(culture.isDeleted);
        }
    }

	global class ListPriceRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> name, code, customerGroup, cropId, accountId, coin, endDate, initialDate, salesOrgId, productId, productFamilyId,
					 salesOfficeId, salesSector, salesTeamId, salesCondition, effectiveDate, devName, createdDate;
		List<Decimal> priority, interestPriority, unitPrice, interestPercentage, multiplicity, cost;
		List<Boolean> isActive, deleted;

        public ListPriceRequest(){
			super();
			this.id              	= new List<String>();
			this.name            	= new List<String>();
            this.code            	= new List<String>();
			this.customerGroup		= new List<String>();
			this.accountId			= new List<String>();
			this.cropId				= new List<String>();
			this.coin				= new List<String>();
			this.endDate			= new List<String>();
			this.initialDate		= new List<String>();
			this.salesOrgId			= new List<String>();
			this.productId			= new List<String>();
			this.productFamilyId	= new List<String>();
			this.salesOfficeId		= new List<String>();
			this.salesSector		= new List<String>();
			this.salesTeamId		= new List<String>();
			this.salesCondition		= new List<String>();
			this.effectiveDate		= new List<String>();
			this.devName			= new List<String>();
			this.createdDate		= new List<String>();
			this.priority			= new List<Decimal>();
			this.interestPriority	= new List<Decimal>();
			this.unitPrice			= new List<Decimal>();
			this.interestPercentage	= new List<Decimal>();
			this.multiplicity		= new List<Decimal>();
			this.cost				= new List<Decimal>();
			this.isActive         	= new List<Boolean>();
            this.deleted         	= new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            ListPrice__c  listPrice = (ListPrice__c)sobj;

			this.id.add(listPrice.Id);
			this.name.add(listPrice.Name);
            this.code.add(listPrice.ListPriceCode__c);
			this.cropId.add(listPrice.Crop__c);
			this.customerGroup.add(listPrice.CustomerGroup__c);
			this.accountId.add(listPrice.Account__c);
			this.coin.add(listPrice.Currency__c);
			this.endDate.add(String.valueOf(listPrice.EndDate__c));
			this.initialDate.add(String.valueOf(listPrice.InitialDate__c));
			this.salesOrgId.add(listPrice.SalesOrg__c);
			this.productId.add(listPrice.Product2Id__c);
			this.productFamilyId.add(listPrice.ProductFamily__c);
			this.salesOfficeId.add(listPrice.SalesOffice__c);
			this.salesSector.add(listPrice.ActivitySector__c);
			this.salesTeamId.add(listPrice.SalesTeam__c);
			this.salesCondition.add(listPrice.SalesCondition__c);
			this.effectiveDate.add(String.valueOf(listPrice.EffectiveDate__c));
			this.devName.add(String.valueOf(listPrice.RecordType.DeveloperName));
			this.createdDate.add(listPrice.CreatedDate != null ? String.valueOf(Date.ValueOf(listPrice.CreatedDate)) : '');
			this.priority.add(listPrice.Priority__c);
			this.interestPriority.add(listPrice.InterestPriority__c);
			this.unitPrice.add(listPrice.UnitPrice__c);
			this.interestPercentage.add(listPrice.InterestValue__c);
			this.multiplicity.add(listPrice.PriceMultiplier__c);
			this.cost.add(listPrice.Cost__c);
			this.isActive.add(listPrice.IsActive__c);
            this.deleted.add(listPrice.isDeleted);
        }
    }

	global class FreightRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> code, sourceCity, destinationCity, startDate, endDate, productId, familyId;
		List<Decimal> valueUSD, valueBRL, priority;
		List<Boolean> isActive, deleted;

        public FreightRequest(){
			super();
			this.id              	= new List<String>();
			this.code            	= new List<String>();
            this.sourceCity         = new List<String>();
			this.destinationCity	= new List<String>();
			this.startDate			= new List<String>();
			this.endDate			= new List<String>();
			this.productId			= new List<String>();
			this.familyId			= new List<String>();
			this.valueUSD			= new List<Decimal>();
			this.valueBRL		    = new List<Decimal>();
			this.priority		    = new List<Decimal>();
			this.isActive         	= new List<Boolean>();
            this.deleted         	= new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            Freight__c freight = (Freight__c)sobj;

			this.id.add(freight.Id);
			this.code.add(freight.ExternalId__c);
			this.sourceCity.add(freight.SourceCity__c);
			this.destinationCity.add(freight.DestinationCity__c);
			this.startDate.add(String.valueOf(freight.StartDate__c));
			this.endDate.add(String.valueOf(freight.EndDate__c));
			this.productId.add(freight.Product2Id__c);
			this.familyId.add(freight.Family__c);
			this.valueUSD.add(freight.ValuePerTonDolar__c);
			this.valueBRL.add(freight.ValuePerTon__c);
			this.priority.add(freight.Priority__c);
			this.isActive.add(freight.IsActive__c);
            this.deleted.add(freight.isDeleted);
        }
    }

	global class OrderRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> code, status, statusSAP, issueDate, accountId, accountName, billingAccountId, billingAccountName,
					 deliveryAccountId, deliveryAccountName, deliveryAccountCityId, deliveryAccountCityName, rtvId, rtvName, salesTeamId,
					 salesTeamName, salesTeamCity, salesTeamOrgId, salesTeamOfficeId, orderType, salesCondition, coin, validateDate,
					 cropId, cropName, paymentCondition, paymentMethod, paymenteDate, note, originalOrder, 
					 activitySector, discountApproverName, discountApprover2Name, discountApprover3Name, discountApprover4Name, financialAdministrativeName, marginApprover, customerGroup,
					 barterType, commodity, barterInicialDate, barterFinalDate, commFreight, pickupLocation, deliveryLocation, shippingCropId, 
					 shipingCropName, trade, tradeId, tradeName, financialDueDate, commercialMeasureUnit, contractEndDate, contractStartDate, contractId, observationRTV, lastModifiedDate, distributionPublicUrl, route;
		List<Decimal> totalValue, oldOrderCredit, strikePrice, commGrossValue, commLiquidValue, totalDeliveryQtd;
		List<Boolean> deleted, containIntegrationError, commercialApproval, approved1, approved2, approved3, approved4, grainTableApproval, deletedProductSAP, containStockError;

        public OrderRequest(){
			super();
			this.id              		 		= new List<String>();
			this.code            		 		= new List<String>();
			this.status					 		= new List<String>();
			this.statusSAP					 	= new List<String>();
			this.issueDate				 		= new List<String>();
			this.accountId				 		= new List<String>();
			this.accountName			 		= new List<String>();
			this.billingAccountId		 		= new List<String>();
			this.billingAccountName		 		= new List<String>();
			this.deliveryAccountId		 		= new List<String>();
			this.deliveryAccountName	 		= new List<String>();
			this.deliveryAccountCityName	 	= new List<String>();
			this.deliveryAccountCityId	 		= new List<String>();
			this.rtvId					 		= new List<String>();
			this.rtvName				 		= new List<String>();
			this.salesTeamId			 		= new List<String>();
			this.salesTeamName			 		= new List<String>();
			this.salesTeamCity					= new List<String>();
			this.salesTeamOrgId			 		= new List<String>();
			this.salesTeamOfficeId		 		= new List<String>();
			this.orderType				 		= new List<String>();
			this.salesCondition			 		= new List<String>();
			this.coin					 		= new List<String>();
			this.validateDate			 		= new List<String>();
			this.cropId					 		= new List<String>();
			this.cropName				 		= new List<String>();
			this.paymentCondition		 		= new List<String>();
			this.paymentMethod			 		= new List<String>();
			this.paymenteDate			 		= new List<String>();
			this.note					 		= new List<String>();
			this.activitySector			 		= new List<String>();
			this.originalOrder			 		= new List<String>();
			this.discountApproverName			= new List<String>();
			this.discountApprover2Name			= new List<String>();
			this.discountApprover3Name			= new List<String>();
			this.discountApprover4Name			= new List<String>();
			this.financialAdministrativeName	= new List<String>();
			this.marginApprover					= new List<String>();
			this.customerGroup					= new List<String>();

			this.contractId						= new List<String>();
			this.observationRTV					= new List<String>();
			this.lastModifiedDate				= new List<String>();
			this.distributionPublicUrl			= new List<String>();
			this.route							= new List<String>();

			this.barterType 					= new List<String>();
			this.commodity 						= new List<String>();
			this.barterInicialDate 				= new List<String>();
			this.barterFinalDate 				= new List<String>();
			this.commFreight 					= new List<String>();
			this.pickupLocation 				= new List<String>();
			this.deliveryLocation 				= new List<String>();
			this.shippingCropId 				= new List<String>();
			this.shipingCropName 				= new List<String>();
			this.trade							= new List<String>();
			this.tradeId 						= new List<String>();
			this.tradeName 						= new List<String>();
			this.financialDueDate 				= new List<String>();
			this.commercialMeasureUnit 			= new List<String>();
			this.contractEndDate 				= new List<String>();
			this.contractStartDate 				= new List<String>();
			this.strikePrice				 	= new List<Decimal>();
			this.commGrossValue			 		= new List<Decimal>();
			this.commLiquidValue				= new List<Decimal>();
			this.totalDeliveryQtd			 	= new List<Decimal>();

			this.totalValue				 		= new List<Decimal>();
			this.oldOrderCredit			 		= new List<Decimal>();
			this.commercialApproval				= new List<Boolean>();
			this.containIntegrationError 		= new List<Boolean>();
			this.approved1						= new List<Boolean>(); 
			this.approved2						= new List<Boolean>(); 
			this.approved3						= new List<Boolean>(); 
			this.approved4						= new List<Boolean>();
            this.deleted         		 		= new List<Boolean>();
			this.grainTableApproval				= new List<Boolean>();
			this.deletedProductSAP				= new List<Boolean>();
			this.containStockError				= new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            Order order = (Order)sobj;

			this.id.add(order.Id);
			this.code.add(order.OrderNumber);
			this.status.add(order.StatusSF__c);
			this.statusSAP.add(order.StatusSAP__c);
			this.issueDate.add(order.CreatedDate != null ? String.valueOf(Date.ValueOf(order.CreatedDate)) : '');
			this.accountId.add(order.AccountId);
			this.accountName.add(order.Account.Name);
			this.billingAccountId.add(order.BillingAccount__c);
			this.billingAccountName.add(order.BillingAccount__r.Name);
			this.deliveryAccountId.add(order.ShippingAccount__c);
			this.deliveryAccountName.add(order.ShippingAccount__r?.Name);
			this.deliveryAccountCityId.add(order.ShippingAccount__r?.InternShippingCity__c);
			this.deliveryAccountCityName.add(order.ShippingAccount__r?.InternShippingCity__r?.Name);
			this.rtvId.add(order.RTV__c);
			this.rtvName.add(order.RTV__r.Name);
			this.salesTeamId.add(order.SalesTeam__c);
			this.salesTeamName.add(order.SalesTeam__r?.Name);
			this.salesTeamCity.add(order.SalesTeam__r?.DistributionCenter__r?.City__c);
			this.salesTeamOrgId.add(order.SalesTeam__r?.SalesOrg__c);
			this.salesTeamOfficeId.add(order.SalesTeam__r?.ParentId__c);
			this.orderType.add(order.RecordType.DeveloperName);
			this.salesCondition.add(order.SalesCondition__c);
			this.coin.add(order.Currency__c);
			this.validateDate.add(order.EndDate != null ? String.valueOf(Date.ValueOf(order.EndDate)) : '');
			this.cropId.add(order.Crop__c);
			this.cropName.add(order.Crop__r.Name);
			this.paymentCondition.add(order.PaymentCondition__c);
			this.paymentMethod.add(order.PaymentForm__c);
			this.paymenteDate.add(String.valueOf(order.PaymentDate__c));
			this.note.add(order.Description);
			this.originalOrder.add(order.OriginalOrder__c);
			this.totalValue.add(order.TotalAmountWithFreight__c);
			this.oldOrderCredit.add(order.OldOrderCredit__c);
			this.activitySector.add(order.ActivitySector__c);
			this.containIntegrationError.add(order.ContainIntegrationError__c);
			this.commercialApproval.add(order.CommercialApproval__c);
			this.discountApproverName.add(order.DiscountApprover__r?.Name);
			this.discountApprover2Name.add(order.DiscountApprover2__r?.Name);
			this.discountApprover3Name.add(order.DiscountApprover3__r?.Name);
			this.discountApprover4Name.add(order.DiscountApprover4__r?.Name);
			this.financialAdministrativeName.add(order.FinancialAdministrativeManager__r?.Name);
			this.marginApprover.add(order.MarginApprover__r?.Name);
			this.customerGroup.add(order.CustomerGroup__c);

			this.barterType.add(order.BarterType__c);
            this.strikePrice.add(order.StrikePrice__c);
            this.commodity.add(order.Commodity__c);
            this.commGrossValue.add(order.GrossUnitPrice__c);
            this.commLiquidValue.add(order.UnitPrice__c);
            this.barterInicialDate.add(String.valueOf(order.InitialDeliveryDate__c));
            this.barterFinalDate.add(String.valueOf(order.EndDeliveryDate__c));
            this.totalDeliveryQtd.add(order.DeliveryQuantity__c);
            this.commFreight.add(order.Freight__c);
            this.pickupLocation.add(order.ProductionPickupLocation__c);
            this.deliveryLocation.add(order.ProductionDeliveryLocation__c);
            this.shippingCropId.add(order.ShippingCrop__c);
            this.shipingCropName.add(order.ShippingCrop__r?.Name);
			this.trade.add(order.AccountTradeName__c);
            this.tradeId.add(order.Trade__c);
            this.tradeName.add(order.Trade__r?.Name);
            this.financialDueDate.add(String.valueOf(order.DueDateFinancial__c));
            this.commercialMeasureUnit.add(order.CommercialMeasureUnit__c);
            this.contractEndDate.add(String.valueOf(order.ContractEndDate__c));
            this.contractStartDate.add(String.valueOf(order.ContractStartDate__c));
			this.grainTableApproval.add(order.GrainTableApproval__c);
			this.deletedProductSAP.add(order.DeletedProductProcessSap__c);

			this.contractId.add(order.ContractOrder__c);
			this.observationRTV.add(order.ObservationRTV__c);
			this.lastModifiedDate.add(order.LastModifiedDate != null ? String.valueOf(Date.ValueOf(order.LastModifiedDate)) : '');
			this.distributionPublicUrl.add(order.DistributionPublicUrl__c);
			this.route.add(order.OrderRoute__c);

			this.approved1.add(order.Approved1__c);
			this.approved2.add(order.Approved2__c);
			this.approved3.add(order.Approved3__c);
			this.approved4.add(order.Approved4__c);
            this.deleted.add(order.isDeleted);
			this.containStockError.add(order.ContainStockError__c);
        }
    }

	global class OrderItemRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> code, orderId, familyId, familyName, productId, productName, productCode, productActivitySector,
					 qtdUnitMeasure, listPriceId, listPriceName, interestListPriceId, interestListPriceName, freightModality, 
					 cultureId, cultureName, productGrossWeightUnity, lastChangedPriceList;
		List<Decimal> listPriceValue, quantity, unitPrice, discountPercentage, discountValue, additionPercentage, additionValue, 
				      totalValue, freightValue, freightValuePerTon, productGrossWeight, refuseCredit, interest, antecipationDiscount, 
					  interestValue, margin, familyMargin, projectedMargin;
		List<Boolean> deleted, deletedProductSAP, containStockError;

        public OrderItemRequest(){
			super();
			this.id              		 = new List<String>();
			this.code            		 = new List<String>();
			this.orderId				 = new List<String>(); 
			this.familyId				 = new List<String>(); 
			this.familyName				 = new List<String>(); 
			this.productId				 = new List<String>(); 
			this.productName			 = new List<String>(); 
			this.productCode			 = new List<String>(); 
			this.productActivitySector	 = new List<String>();
			this.qtdUnitMeasure			 = new List<String>(); 
			this.listPriceId			 = new List<String>(); 
			this.listPriceName			 = new List<String>();
			this.interestListPriceId	 = new List<String>();
			this.interestListPriceName	 = new List<String>(); 
			this.freightModality		 = new List<String>(); 
			this.cultureId				 = new List<String>(); 
			this.cultureName			 = new List<String>();
			this.productGrossWeightUnity = new List<String>();
			this.lastChangedPriceList	 = new List<String>();
			this.listPriceValue 		 = new List<Decimal>(); 
			this.quantity 				 = new List<Decimal>(); 
			this.unitPrice 				 = new List<Decimal>(); 
			this.discountPercentage 	 = new List<Decimal>(); 
			this.discountValue 			 = new List<Decimal>();
			this.additionPercentage 	 = new List<Decimal>(); 
			this.additionValue 			 = new List<Decimal>(); 
			this.totalValue 			 = new List<Decimal>(); 
			this.freightValue 			 = new List<Decimal>();
			this.freightValuePerTon		 = new List<Decimal>();
			this.productGrossWeight 	 = new List<Decimal>();
			this.refuseCredit			 = new List<Decimal>();
			this.interest			 	 = new List<Decimal>();
			this.antecipationDiscount 	 = new List<Decimal>();
			this.interestValue		 	 = new List<Decimal>();
            this.deleted         		 = new List<Boolean>();
			this.deletedProductSAP		 = new List<Boolean>();
			this.containStockError		 = new List<Boolean>();
			this.margin					 = new List<Decimal>();
			this.familyMargin			 = new List<Decimal>();
			this.projectedMargin		 = new List<Decimal>();
        }

        public override void parseData(SObject sobj){
            OrderItem orderItem = (OrderItem)sobj;

			this.id.add(orderItem.Id);
			this.code.add(orderItem.ExternalId__c);
			this.orderId.add(orderItem.OrderId);
			this.familyId.add(orderItem.Product2.Family__c);
			this.familyName.add(orderItem.Product2?.Family__r?.Name);
			this.productId.add(orderItem.Product2Id);
			this.productName.add(orderItem.Product2.Name);
			this.productCode.add(orderItem.Product2.ProductCode);
			this.productActivitySector.add(orderItem.Product2.ActivitySector__c);
			this.qtdUnitMeasure.add(orderItem.Product2.QuantityUnitOfMeasure);
			this.listPriceId.add(orderItem.ListPrice__c);
			this.listPriceName.add(orderItem.ListPrice__r?.Name);
			this.interestListPriceId.add(orderItem.InterestOrAntecipationDiscount__c);
			this.interestListPriceName.add(orderItem.InterestOrAntecipationDiscount__r?.Name);
			this.freightModality.add(orderItem.Freight__c);
			this.cultureId.add(orderItem.Culture__c);
			this.cultureName.add(orderItem.Culture__r.Name);
			this.listPriceValue.add(orderItem.ListPrice__c != null ? orderItem.ListPrice__r.UnitPrice__c : 0); 
			this.quantity.add(orderItem.Quantity); 
			this.unitPrice.add(orderItem.UnitPrice); 
			this.discountPercentage.add(orderItem.DiscountPercent__c != null ? orderItem.DiscountPercent__c : 0); 
			this.discountValue.add(orderItem.DiscountAmount__c); 
			this.additionPercentage.add(orderItem.AdditionPercent__c != null ? orderItem.AdditionPercent__c : 0); 
			this.additionValue.add(orderItem.AdditionAmount__c); 
			this.totalValue.add(orderItem.TotalPrice__c); 
			this.freightValue.add(orderItem.FreightValue__c != null ? orderItem.FreightValue__c : 0); 
			this.freightValuePerTon.add(orderItem.FreightValuePerTon__c != null ? orderItem.FreightValuePerTon__c : 0);
			this.productGrossWeightUnity.add(orderItem.Product2.GrossWeightUnity__c);
			this.productGrossWeight.add(orderItem.Product2.GrossWeight__c);
			this.refuseCredit.add(orderItem.RefuseCredit__c);
			this.interest.add(orderItem.CalculatedInterest__c);
			this.antecipationDiscount.add(orderItem.AnticipationDiscount__c);
			this.interestValue.add(orderItem.InterestValue__c);
			this.lastChangedPriceList.add(String.valueOf(orderItem.LastChangedPriceList__c));
            this.deleted.add(orderItem.isDeleted);
			this.deletedProductSAP.add(orderItem.DeletedProductSAP__c);
			this.containStockError.add(orderItem.ContainStockError__c);
			this.margin.add(orderItem.Margin__c);
			this.familyMargin.add(orderItem.FamilyMargin__c);
			this.projectedMargin.add(orderItem.ProjectedMargin__c);
        }
    }
	
	global class ShippingDivisionRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> orderItemId, productId, deliveryDate, refuseReason;
		List<Decimal> quantity;
		List<Boolean> deleted;

        public ShippingDivisionRequest(){
			super();
			this.id             = new List<String>();
			this.orderItemId    = new List<String>();
			this.productId		= new List<String>(); 
			this.deliveryDate	= new List<String>(); 
			this.refuseReason   = new List<String>();
			this.quantity		= new List<Decimal>(); 
            this.deleted        = new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            ShippingDivision__c shippingDivision = (ShippingDivision__c)sobj;

			this.id.add(shippingDivision.Id);
			this.orderItemId.add(shippingDivision.OrderItem__c);
			this.productId.add(shippingDivision.OrderItem__r.Product2Id);
			this.deliveryDate.add(String.valueOf(shippingDivision.DeliveryDate__c));
			this.refuseReason.add(shippingDivision.RefuseReason__c);
			this.quantity.add(shippingDivision.Quantity__c);
            this.deleted.add(shippingDivision.isDeleted);
        }
    }

	global class OrderTypeRequest{
		@TestVisible
		String orderTypeId, orderTypeName;

        public OrderTypeRequest(String orderTypeId, String orderTypeName){
			this.orderTypeId    = orderTypeId;
			this.orderTypeName  = orderTypeName;
        }
    }

	global class ActivitySectorRequest{
		@TestVisible
		String activitySectorId, activitySectorName;

        public ActivitySectorRequest(String activitySectorId, String activitySectorName){
			this.activitySectorId    = activitySectorId;
			this.activitySectorName  = activitySectorName;
        }
    }

	global class SalesConditionRequest{
		@TestVisible
		String salesConditionId, salesConditionName;

        public SalesConditionRequest(String salesConditionId, String salesConditionName){
			this.salesConditionId    = salesConditionId;
			this.salesConditionName  = salesConditionName;
        }
    }
		
	global class PaymentMethodRequest{
		@TestVisible
		String paymentMethodId, paymentMethodName;

        public PaymentMethodRequest(String paymentMethodId, String paymentMethodName){
			this.paymentMethodId    = paymentMethodId;
			this.paymentMethodName  = paymentMethodName;
        }
    }

	global class OrderStatusRequest{
		@TestVisible
		String statusId, statusName;

        public OrderStatusRequest(String statusId, String statusName){
			this.statusId    = statusId;
			this.statusName  = statusName;
        }
    }

	global class OrderStatusSAPRequest{
		@TestVisible
		String statusId, statusName;

        public OrderStatusSAPRequest(String statusId, String statusName){
			this.statusId    = statusId;
			this.statusName  = statusName;
        }
    }

	global class BarterTypeRequest{
		@TestVisible
		String barterTypeId, barterTypeName;

        public BarterTypeRequest(String barterTypeId, String barterTypeName){
			this.barterTypeId    = barterTypeId;
			this.barterTypeName  = barterTypeName;
        }
    }

	global class CommodityRequest{
		@TestVisible
		String commodityId, commodityName;

        public CommodityRequest(String commodityId, String commodityName){
			this.commodityId    = commodityId;
			this.commodityName  = commodityName;
        }
    }

	global class CustomerPerOrgRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> accountId, salesOrgId, customerGroup, activitySector, distribuctionChannel;
		List<Boolean> isBlocked, deleted;

        public CustomerPerOrgRequest(){
			super();
			this.id             		= new List<String>();
			this.accountId    			= new List<String>();
			this.salesOrgId				= new List<String>(); 
			this.customerGroup			= new List<String>(); 
			this.activitySector 		= new List<String>();
			this.distribuctionChannel 	= new List<String>();
			this.isBlocked				= new List<Boolean>(); 
            this.deleted        		= new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            CustomerPerOrg__c customerPerOrg = (CustomerPerOrg__c)sobj;

			this.id.add(customerPerOrg.Id);
			this.accountId.add(customerPerOrg.Customer__c);
			this.salesOrgId.add(customerPerOrg.SalesOrg__c);
			this.customerGroup.add(customerPerOrg.ClientGroup__c);
			this.activitySector.add(customerPerOrg.ActivitySector__c);
			this.distribuctionChannel.add(customerPerOrg.DistributionChannel__c);
			this.isBlocked.add(customerPerOrg.Blocked__c);
            this.deleted.add(customerPerOrg.isDeleted);
        }
    }

	global class FinancialDueDateRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> cropId, commodity, financialDueDate;
		List<Boolean> deleted;

        public FinancialDueDateRequest(){
			super();
			this.id             		= new List<String>();
			this.cropId    				= new List<String>();
			this.commodity				= new List<String>(); 
			this.financialDueDate		= new List<String>(); 
            this.deleted        		= new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            FinancialDueDate__c financialDueDate = (FinancialDueDate__c)sobj;

			this.id.add(financialDueDate.Id);
			this.cropId.add(financialDueDate.Crop__c);
			this.commodity.add(financialDueDate.Commodity__c);
			this.financialDueDate.add(String.valueOf(financialDueDate.FinancialDueDate__c));
            this.deleted.add(financialDueDate.isDeleted);
        }
    }

	global class FieldDependencyRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> dependencyFieldKey, dependencyField, value, dependencyValue;
		List<Boolean> deleted;

        public FieldDependencyRequest(){
			super();
			this.id             	= new List<String>();
			this.dependencyFieldKey = new List<String>();
			this.dependencyField	= new List<String>(); 
			this.value				= new List<String>(); 
            this.dependencyValue    = new List<String>();
			this.deleted        	= new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            FieldDependency__c fieldDependency = (FieldDependency__c)sobj;

			this.id.add(fieldDependency.Id);
			this.dependencyFieldKey.add(fieldDependency.DependencyFieldKey__c);
			this.dependencyField.add(fieldDependency.DependencyField__c);
            this.value.add(fieldDependency.Value__c);
			this.dependencyValue.add(fieldDependency.DependencyValue__c);
			this.deleted.add(fieldDependency.isDeleted);
		}
	}

	global class RangeDiscountRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> approvingAuthority, customerCategory, familyId, finalDate, initialDate, salesOfficeId, status, paymentType, salesOrgId;
		List<Decimal> maximumPercentage, minimumPercentage;
		List<Boolean> deleted;

        public RangeDiscountRequest(){
			super();
			this.id					= new List<String>();
			this.approvingAuthority = new List<String>();
			this.customerCategory 	= new List<String>(); 
			this.familyId 			= new List<String>(); 
			this.finalDate 			= new List<String>();
			this.initialDate 		= new List<String>();
			this.salesOfficeId 		= new List<String>();
			this.status 			= new List<String>();
			this.paymentType 		= new List<String>();
			this.salesOrgId 		= new List<String>();
			this.maximumPercentage 	= new List<Decimal>();
			this.minimumPercentage 	= new List<Decimal>();
            this.deleted        	= new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            RangeDiscount__c rangeDiscount = (RangeDiscount__c)sobj;

			this.id.add(rangeDiscount.Id);
			this.approvingAuthority.add(rangeDiscount.ApprovingAuthority__c); 
            this.customerCategory.add(rangeDiscount.CustomerCategory__c); 
            this.familyId.add(rangeDiscount.Family__c); 
            this.finalDate.add(String.valueOf(rangeDiscount.FinalDate__c)); 
            this.initialDate.add(String.valueOf(rangeDiscount.InitialDate__c)); 
            this.salesOfficeId.add(rangeDiscount.SalesOffice__c); 
            this.status.add(rangeDiscount.Status__c); 
            this.paymentType.add(rangeDiscount.PaymentType__c); 
            this.salesOrgId.add(rangeDiscount.SalesOrg__c);
			this.maximumPercentage.add(rangeDiscount.MaximaPercentage__c); 
            this.minimumPercentage.add(rangeDiscount.MinimumPercentage__c); 
            this.deleted.add(rangeDiscount.isDeleted);
        }
    }

	global class ClientCNDStateRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> states;
		List<Boolean> deleted;

        public ClientCNDStateRequest(){
			super();
			this.id         = new List<String>();
			this.states 	= new List<String>();
			this.deleted	= new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            ClientCNDState__c fieldDependency = (ClientCNDState__c)sobj;

			this.id.add(fieldDependency.Id);
			this.states.add(fieldDependency.Name);
			this.deleted.add(fieldDependency.isDeleted);
		}
	}
	
	global class OrderTypesRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> name, salesContracts, salesOrders;
		List<Boolean> deleted;

        public OrderTypesRequest(){
			super();
			this.id         	= new List<String>();
			this.name 			= new List<String>();
			this.salesContracts = new List<String>();
			this.salesOrders 	= new List<String>();
			this.deleted		= new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            OrderTypes__c orderTypes = (OrderTypes__c)sobj;

			this.id.add(orderTypes.Id);
			this.name.add(orderTypes.Name);
			this.salesContracts.add(orderTypes.SalesContracts__c);
			this.salesOrders.add(orderTypes.SalesOrders__c);
			this.deleted.add(orderTypes.isDeleted);
		}
	}

	global class ProductManagementRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> name, productId, salesTeamId, cropId, initialDate, endDate, externalId, unitMeasurement, type, currencyIsoCode, distCenterId;
		List<Decimal> inventory, futureInventory, salesInventory, tolerance;
		List<Boolean> block, isActive, deleted;

        public ProductManagementRequest(){
			super();
			this.id         		= new List<String>();
			this.name 				= new List<String>();
			this.productId 			= new List<String>();
			this.salesTeamId		= new List<String>();
			this.cropId 			= new List<String>();
			this.initialDate 		= new List<String>();
			this.endDate 			= new List<String>();
			this.externalId 		= new List<String>();
			this.unitMeasurement 	= new List<String>();
			this.type			 	= new List<String>();
			this.currencyIsoCode	= new List<String>();
			this.distCenterId		= new List<String>();
			this.inventory 			= new List<Decimal>();
			this.futureInventory	= new List<Decimal>();
			this.salesInventory 	= new List<Decimal>();
			this.tolerance			= new List<Decimal>();
			this.isActive 			= new List<Boolean>();
			this.block 				= new List<Boolean>();
			this.deleted			= new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            ProductManagement__c productManagement = (ProductManagement__c)sobj;

			this.id.add(productManagement.Id);
			this.name.add(productManagement.Name);
			this.productId.add(productManagement.Product2__c);
			this.salesTeamId.add(productManagement.SalesTeam__c);
			this.cropId.add(productManagement.Crop__c);
			this.initialDate.add(String.valueOf(productManagement.InitialDate__c));
			this.endDate.add(String.valueOf(productManagement.EndDate__c));
			this.externalId.add(productManagement.ExternalId__c);
			this.unitMeasurement.add(productManagement.UnitMeasurement__c);
			this.type.add(productManagement.RecordType.DeveloperName);
			this.currencyIsoCode.add(productManagement.CurrencyIsoCode);
			this.inventory.add(productManagement.Inventory__c);
			this.futureInventory.add(productManagement.FutureInventory__c);
			this.salesInventory.add(productManagement.SalesInventory__c);
			this.tolerance.add(productManagement.Tolerance__c);
			this.distCenterId.add(productManagement.DistributionCenter__c);
			this.block.add(productManagement.Block__c);
			this.isActive.add(productManagement.IsActive__c);
			this.deleted.add(productManagement.isDeleted);
		}
	}
	
	global class CustomLabelRequest{
		@TestVisible
		String name, value;

        public CustomLabelRequest(String name, String value){
			this.name   = name;
			this.value  = value;
        }
    }

	global class CampaignRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> name, startDate, endDate, status, coin, description, orderRecordType, activitySector, crop, type;
		List<Decimal> budgetedCost, actualCost, expectedRevenue;
		List<Boolean> deleted, accumulative, condition, isActive;

        public CampaignRequest(){
			super();
			this.id         		= new List<String>();
			this.name 				= new List<String>();
			this.startDate			= new List<String>();
			this.endDate			= new List<String>();
			this.status				= new List<String>();
			this.coin				= new List<String>();
			this.description		= new List<String>();
			this.orderRecordType	= new List<String>();
			this.activitySector		= new List<String>();
			this.crop				= new List<String>();
			this.type				= new List<String>();
			this.budgetedCost		= new List<Decimal>();
			this.actualCost			= new List<Decimal>();
			this.expectedRevenue	= new List<Decimal>();
			this.accumulative		= new List<Boolean>();
			this.condition			= new List<Boolean>();
			this.isActive			= new List<Boolean>();
			this.deleted			= new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            Campaign campaign = (Campaign)sobj;

			this.id.add(campaign.Id);
			this.name.add(campaign.Name);
			this.startDate.add(String.valueOf(campaign.StartDate));
            this.endDate.add(String.valueOf(campaign.EndDate));
            this.status.add(campaign.Status);
            this.coin.add(campaign.Currency__c);
            this.description.add(campaign.Description);
            this.budgetedCost.add(campaign.BudgetedCost);
            this.actualCost.add(campaign.ActualCost);
            this.expectedRevenue.add(campaign.ExpectedRevenue);
            this.orderRecordType.add(campaign.OrderRecordType__c);
            this.activitySector.add(campaign.ActivitySector__c);
            this.crop.add(campaign.Crop__c);
			this.type.add(campaign.RecordType?.DeveloperName);
            this.accumulative.add(campaign.Accumulative__c);
            this.condition.add(campaign.Condition__c);
			this.isActive.add(campaign.IsActive);
			this.deleted.add(campaign.isDeleted);
		}
	}

	global class CampaignProductRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> name, productId, familyId, manufacturer, campaignId, unitMeasurement, comercialName;
		List<Decimal> maxQuantity, usedQuantity, availableQuantity;
		List<Boolean> deleted, activateRules, receiveDiscount;

        public CampaignProductRequest(){
			super();
			this.id         		= new List<String>();
			this.name 				= new List<String>();
			this.productId			= new List<String>();
			this.familyId			= new List<String>();
			this.manufacturer		= new List<String>();
			this.comercialName		= new List<String>();
			this.campaignId			= new List<String>();
			this.unitMeasurement	= new List<String>();
			this.maxQuantity		= new List<Decimal>();
			this.usedQuantity		= new List<Decimal>();
			this.availableQuantity	= new List<Decimal>();
			this.activateRules		= new List<Boolean>();
			this.receiveDiscount	= new List<Boolean>();
			this.deleted			= new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            CampaignProduct__c campaignProduct = (CampaignProduct__c)sobj;

			this.id.add(campaignProduct.Id);
			this.name.add(campaignProduct.Name);
			this.maxQuantity.add(campaignProduct.MaxQuantity__c);
            this.usedQuantity.add(campaignProduct.UsedQuantity__c);
            this.availableQuantity.add(campaignProduct.AvailableQuantity__c);
			this.unitMeasurement.add(campaignProduct.UnitMeasurement__c);
            this.productId.add(campaignProduct.Product2__c);
            this.familyId.add(campaignProduct.Family__c);
            this.manufacturer.add(campaignProduct.Manufacturer__c);
            this.comercialName.add(campaignProduct.ComercialName__c);
            this.campaignId.add(campaignProduct.Campaign__c);
			this.activateRules.add(campaignProduct.CanActivateRules__c);
			this.receiveDiscount.add(campaignProduct.CanReceiveDiscount__c);
			this.deleted.add(campaignProduct.isDeleted);
		}
	}

	global class CampaignRuleRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> name, campaignId, campaignProductId, paymentCondition, type, paymentDate, unitMeasurement;
		List<Decimal> minimumQuantity, maximumQuantity, productPercent, minimumValue, maximumValue, unitPrice, discount;
		List<Boolean> deleted, orderDiscount;

        public CampaignRuleRequest(){
			super();
			this.id         		= new List<String>();
			this.name 				= new List<String>();
			this.campaignId			= new List<String>();
			this.campaignProductId	= new List<String>();
			this.paymentCondition	= new List<String>();
			this.type				= new List<String>();
			this.paymentDate		= new List<String>();
			this.unitMeasurement	= new List<String>();
			this.minimumQuantity	= new List<Decimal>();
			this.maximumQuantity	= new List<Decimal>();
			this.productPercent		= new List<Decimal>();
			this.minimumValue		= new List<Decimal>();
			this.maximumValue		= new List<Decimal>();
			this.unitPrice			= new List<Decimal>();
			this.discount			= new List<Decimal>();
			this.orderDiscount		= new List<Boolean>();
			this.deleted			= new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            CampaignRule__c campaignRule = (CampaignRule__c)sobj;

			this.id.add(campaignRule.Id);
			this.name.add(campaignRule.Name);
			this.campaignId.add(campaignRule.Campaign__c);
            this.unitMeasurement.add(campaignRule.UnitMeasurement__c);
            this.minimumQuantity.add(campaignRule.MinimumQuantity__c);
            this.maximumQuantity.add(campaignRule.MaximumQuantity__c);
            this.productPercent.add(campaignRule.ProductPercent__c);
            this.minimumValue.add(campaignRule.MinimumOrderValue__c);
            this.maximumValue.add(campaignRule.MaximumOrderValue__c);
            this.paymentDate.add(String.valueOf(campaignRule.PaymentDate__c));
            this.paymentCondition.add(campaignRule.PaymentCondition__c);
            this.campaignProductId.add(campaignRule.CampaignProduct__c);
            this.unitPrice.add(campaignRule.FixedUnitPrice__c);
            this.discount.add(campaignRule.Discount__c);
            this.type.add(campaignRule.RecordType.DeveloperName);
            this.orderDiscount.add(campaignRule.OrderDiscount__c);
			this.deleted.add(campaignRule.isDeleted);
		}
	}

	global class CampaignOrderItemRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> campaignId, campaignProductId, orderItemId, productId;
		List<Decimal> discount, fixedUnitPrice, discountValue;
		List<Boolean> isFixedUnitPrice, deleted;

        public CampaignOrderItemRequest(){
			super();
			this.id         		= new List<String>();
			this.campaignId			= new List<String>();
			this.campaignProductId	= new List<String>();
			this.orderItemId		= new List<String>();
			this.productId			= new List<String>();
			this.discount			= new List<Decimal>();
			this.fixedUnitPrice		= new List<Decimal>();
			this.discountValue		= new List<Decimal>();
			this.isFixedUnitPrice	= new List<Boolean>();
			this.deleted			= new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            CampaignOrderItem__c campaignOrderItem = (CampaignOrderItem__c)sobj;

			this.id.add(campaignOrderItem.Id);
			this.campaignId.add(campaignOrderItem.Campaign__c);
			this.campaignProductId.add(campaignOrderItem.CampaignProduct__c);
			this.orderItemId.add(campaignOrderItem.OrderItem__c);
			this.productId.add(campaignOrderItem.OrderItem__r.Product2Id);
			this.discount.add(campaignOrderItem.Discount__c);
			this.fixedUnitPrice.add(campaignOrderItem.FixedUnitPrice__c);
			this.discountValue.add(campaignOrderItem.DiscountValue__c);
			this.isFixedUnitPrice.add(campaignOrderItem.FixedUnitPriceCampaign__c);
			this.deleted.add(campaignOrderItem.isDeleted);
		}
	}

	global class CampaignTargetAudienceRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> campaignId, clusterId, salesOrgId, salesOfficeId, salesTeamId, accountId, customerGroup;
		List<Boolean> deleted;

        public CampaignTargetAudienceRequest(){
			super();
			this.id         		= new List<String>();
			this.campaignId			= new List<String>();
			this.clusterId			= new List<String>();
			this.salesOrgId			= new List<String>();
			this.salesOfficeId		= new List<String>();
			this.salesTeamId		= new List<String>();
			this.accountId			= new List<String>();
			this.customerGroup		= new List<String>();
			this.deleted			= new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            CampaignTargetAudience__c campaignTargetAudience = (CampaignTargetAudience__c)sobj;

			this.id.add(campaignTargetAudience.Id);
			this.campaignId.add(campaignTargetAudience.Campaign__c);
			this.clusterId.add(campaignTargetAudience.Cluster__c);
            this.salesOrgId.add(campaignTargetAudience.SalesOrg__c);
            this.salesOfficeId.add(campaignTargetAudience.SalesOffice__c);
            this.salesTeamId.add(campaignTargetAudience.SalesTeam__c);
			this.accountId.add(campaignTargetAudience.Account__c);
            this.customerGroup.add(campaignTargetAudience.CustomerGroup__c);
			this.deleted.add(campaignTargetAudience.isDeleted);
		}
	}

	global class EventRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> subject, startDate, startTime, endDate, endTime, eventTypeId, visitOpinion, description, 
					 accountId, accountName, ownerId, ownerName, caseId, caseName, cropId, cropName;
		List<Decimal> checkinLatitude, checkinLongitude;
		List<Boolean> checkInDone, deleted;

        public EventRequest(){
			super();
			this.id         		= new List<String>();
			this.subject			= new List<String>();
			this.startDate			= new List<String>();
			this.startTime			= new List<String>();
			this.endDate			= new List<String>();
			this.endTime			= new List<String>();
			this.eventTypeId		= new List<String>();
			this.ownerId			= new List<String>();
			this.ownerName			= new List<String>();
			this.visitOpinion		= new List<String>();
			this.description		= new List<String>();
			this.accountId			= new List<String>();
			this.accountName		= new List<String>();
			this.caseId				= new List<String>();
			this.caseName			= new List<String>();
			this.cropId				= new List<String>();
			this.cropName			= new List<String>();
			this.checkinLatitude	= new List<Decimal>();
			this.checkinLongitude	= new List<Decimal>();
			this.checkInDone		= new List<Boolean>();
			this.deleted			= new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            Event event = (Event)sobj;

			this.id.add(event.Id);
			this.subject.add(event.Subject);
			this.startDate.add(getDate(event.StartDateTime));
			this.startTime.add(getHour(event.StartDateTime));
			this.endDate.add(getDate(event.EndDateTime));
			this.endTime.add(getHour(event.EndDateTime));
			this.eventTypeId.add(event.EventType__c);
			this.visitOpinion.add(event.VisitOpinion__c);
			this.ownerId.add(event.OwnerId);
			this.ownerName.add(event.Owner.Name);
			this.description.add(event.Description);
			this.accountId.add(event.Account__c);
			this.accountName.add(event.Account__r?.Name);
			this.caseId.add(event.Case__c);
			this.caseName.add(event.Case__c != null ? ('[' + event.Case__r?.CaseNumber + '] - ' + event.Case__r?.Subject) : '');
			this.cropId.add(event.Crop__c);
			this.cropName.add(event.Crop__r?.Name);
			this.checkinLatitude.add(event.Checkin__Latitude__s);
			this.checkinLongitude.add(event.Checkin__Longitude__s);
			this.checkInDone.add(event.CheckInDone__c);
			this.deleted.add(event.isDeleted);
		}
	}

	global class EventTypesRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> name;
		List<Decimal> mandatoryImagesQuantity;
		List<Boolean> isActive, deleted;

        public EventTypesRequest(){
			super();
			this.id         	= new List<String>();
			this.name 			= new List<String>();
			this.mandatoryImagesQuantity = new List<Decimal>();
			this.isActive 		= new List<Boolean>();
			this.deleted		= new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            EventTypes__c eventTypes = (EventTypes__c)sobj;

			this.id.add(eventTypes.Id);
			this.name.add(eventTypes.Name);
			this.mandatoryImagesQuantity.add(eventTypes.MandatoryImagesQuantity__c);
			this.isActive.add(eventTypes.IsActive__c);
			this.deleted.add(eventTypes.isDeleted);
		}
	}

	global class RatingCreditRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> accountId, rating, ratingSAP;
		List<Boolean> deleted;

        public RatingCreditRequest(){
			super();
			this.id         = new List<String>();
			this.accountId 	= new List<String>();
			this.rating 	= new List<String>();
			this.ratingSAP 	= new List<String>();
			this.deleted	= new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            RatingCredit__c ratingCredit = (RatingCredit__c)sobj;

			this.id.add(ratingCredit.Id);
			this.accountId.add(ratingCredit.Account__c);
			this.rating.add(ratingCredit.Rating__c);
			this.ratingSAP.add(ratingCredit.get('RatingSAP') != null ? (String)ratingCredit.get('RatingSAP') : '');
			this.deleted.add(ratingCredit.isDeleted);
		}
	}

	global class ProjectedMarginRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> familyId, cropId, salesOrgId;
		List<Decimal> margin;
		List<Boolean> deleted;

        public ProjectedMarginRequest(){
			super();
			this.id         = new List<String>();
			this.familyId	= new List<String>();
			this.cropId		= new List<String>();
			this.salesOrgId	= new List<String>();
			this.margin		= new List<Decimal>();
			this.deleted	= new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            ProjectedMargin__c projectedMargin = (ProjectedMargin__c)sobj;

			this.id.add(projectedMargin.Id);
			this.familyId.add(projectedMargin.Family__c);
			this.cropId.add(projectedMargin.Crop__c);
			this.salesOrgId.add(projectedMargin.SalesOrg__c);
			this.margin.add(projectedMargin.Margin__c);
			this.deleted.add(projectedMargin.isDeleted);
		}
	}
	global class DelimitedLandRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> name, description, accountId, unitMeasurement, ownerName, tenantCultureId, tenantCultureName, contractDate;
		List<Decimal> areaCultivated, areaNotAllocated, areaPasture, areaPreservation, tenantValue, tenantTax, tenantArea;
		List<Boolean> deleted, tenant;

        public DelimitedLandRequest(){
			super();
			this.id         		= new List<String>();
			this.name		 		= new List<String>();
			this.description 		= new List<String>();
			this.accountId 			= new List<String>();
			this.unitMeasurement 	= new List<String>();
			this.ownerName			= new List<String>();
			this.tenantCultureId	= new List<String>();
			this.tenantCultureName	= new List<String>();
			this.contractDate		= new List<String>();
			this.areaCultivated 	= new List<Decimal>();
			this.areaNotAllocated 	= new List<Decimal>();
			this.areaPasture 		= new List<Decimal>();
			this.areaPreservation 	= new List<Decimal>();
			this.tenantValue		= new List<Decimal>();
			this.tenantTax			= new List<Decimal>();
			this.tenantArea			= new List<Decimal>();
			this.tenant				= new List<Boolean>();
			this.deleted			= new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            DelimitedLand__c delimitedLand = (DelimitedLand__c)sobj;

			this.id.add(delimitedLand.Id);
			this.name.add(delimitedLand.Name);
			this.description.add(delimitedLand.Description__c);
			this.accountId.add(delimitedLand.Account__c);
			this.areaCultivated.add(delimitedLand.AreaCultivated__c);
			this.areaNotAllocated.add(delimitedLand.AreaNotAllocated__c);
			this.areaPasture.add(delimitedLand.AreaPasture__c);
			this.areaPreservation.add(delimitedLand.AreaPreservation__c);
			this.unitMeasurement.add(delimitedLand.UnitMeasurement__c);
			this.ownerName.add(delimitedLand.OwnerName__c);
			this.tenantCultureId.add(delimitedLand.TenantCulture__c);
			this.tenantCultureName.add(delimitedLand.TenantCulture__r?.Name);
			this.tenantValue.add(delimitedLand.TenantValue__c);
			this.tenantTax.add(delimitedLand.TenantTax__c);
			this.tenant.add(delimitedLand.Tenant__c);
			this.tenantArea.add(delimitedLand.TenantArea__c);
			this.contractDate.add(String.valueOf(delimitedLand.ContractDate__c));
			this.deleted.add(delimitedLand.isDeleted);
		}
	}

	global class DelimitedLandCulturesRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> cropId, cultureId, plantingDate, delimitedLand, technologicalLevel;
		List<Decimal> areaCultivated, warehouseCapability;
		List<Boolean> deleted;

        public DelimitedLandCulturesRequest(){
			super();
			this.id         	= new List<String>();
			this.cropId 		= new List<String>();
			this.cultureId 		= new List<String>();
			this.plantingDate	= new List<String>();
			this.delimitedLand 	= new List<String>();
			this.technologicalLevel  = new List<String>();
			this.warehouseCapability = new List<Decimal>();
			this.areaCultivated = new List<Decimal>();
			this.deleted		= new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            DelimitedLandCultures__c delimitedLandCultures = (DelimitedLandCultures__c)sobj;

			this.id.add(delimitedLandCultures.Id);
			this.areaCultivated.add(delimitedLandCultures.AreaCultivated__c);
			this.cropId.add(delimitedLandCultures.Crop__c);
			this.cultureId.add(delimitedLandCultures.Culture__c);
			this.plantingDate.add(String.valueOf(delimitedLandCultures.Date__c));
			this.delimitedLand.add(delimitedLandCultures.DelimitedLand__c);
			this.warehouseCapability.add(delimitedLandCultures.WarehouseCapability__c);
			this.technologicalLevel.add(delimitedLandCultures.TechnologicalLevel__c);
			this.deleted.add(delimitedLandCultures.isDeleted);
		}
	}

	global class UnitMeasurementRequest{
		@TestVisible
		String unitId, unitName;

        public UnitMeasurementRequest(String unitId, String unitName){
			this.unitId    = unitId;
			this.unitName  = unitName;
        }
    }

	global class UserRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> name;
		List<Boolean> isActive;

        public UserRequest(){
			super();
			this.id         	= new List<String>();
			this.name 			= new List<String>();
			this.isActive 		= new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            User user = (User)sobj;

			this.id.add(user.Id);
			this.name.add(user.Name);
			this.isActive.add(user.IsActive);
		}
	}
	
	global class TechnologicalLevelRequest{
		@TestVisible
		String levelId, levelName;

        public TechnologicalLevelRequest(String levelId, String levelName){
			this.levelId    = levelId;
			this.levelName  = levelName;
        }
    }

	global class IncidentTypeRequest{
		@TestVisible
		String incidentId, incidentName;

        public IncidentTypeRequest(String incidentId, String incidentName){
			this.incidentId    = incidentId;
			this.incidentName  = incidentName;
        }
    }

	global class CaseStatusRequest{
		@TestVisible
		String statusId, statusName;

        public CaseStatusRequest(String statusId, String statusName){
			this.statusId    = statusId;
			this.statusName  = statusName;
        }
    }

	global class CasePriorityRequest{
		@TestVisible
		String priorityId, priorityName;

        public CasePriorityRequest(String priorityId, String priorityName){
			this.priorityId    = priorityId;
			this.priorityName  = priorityName;
        }
    }

	global class CaseOriginRequest{
		@TestVisible
		String originId, originName;

        public CaseOriginRequest(String originId, String originName){
			this.originId    = originId;
			this.originName  = originName;
        }
    }

	global class CaseRequest extends ForcaAgroApp_BaseRequest {
		@TestVisible
		List<String> caseNumber, subject, description, incidentTypePicklist, origin, accountId, cropId, plotId, culturePlotId;
		List<Decimal> damagedArea;
		List<Boolean> isActive, deleted;

        public CaseRequest(){
			super();
			this.id         			= new List<String>();
			this.caseNumber 			= new List<String>();
			this.subject 				= new List<String>();
			this.description 			= new List<String>();
			this.incidentTypePicklist 	= new List<String>();
			this.origin 				= new List<String>();
			this.accountId 				= new List<String>();
			this.cropId 				= new List<String>();
			this.plotId 				= new List<String>();
			this.culturePlotId 			= new List<String>();
			this.damagedArea 			= new List<Decimal>();
			this.deleted				= new List<Boolean>();
        }

        public override void parseData(SObject sobj){
            Case caseObj = (Case)sobj;

			this.id.add(caseObj.Id);
			this.caseNumber.add(caseObj.CaseNumber);
			this.subject.add(caseObj.Subject);
			this.description.add(caseObj.Description);
			this.incidentTypePicklist.add(caseObj.IncidentTypePicklist__c);
			this.origin.add(caseObj.Origin);
			this.accountId.add(caseObj.AccountId);
			this.cropId.add(caseObj.Crop__c);
			this.plotId.add(caseObj.Plot__c);
			this.culturePlotId.add(caseObj.CulturePlot__c);
			this.damagedArea.add(caseObj.DamagedArea__c);
			this.deleted.add(caseObj.isDeleted);
		}
	}
	
}