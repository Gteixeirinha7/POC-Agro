import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const fillOrderBarter = (oldObj, obj) => {
	let returnObj  = oldObj;
	returnObj.BarterType				 =  obj.orderObjectBarter.BarterType;
	returnObj.StrikePrice				=  obj.orderObjectBarter.StrikePrice;
	returnObj.GrossUnitPrice			 =  obj.orderObjectBarter.GrossUnitPrice;
	returnObj.CommUnitPrice			  =  obj.orderObjectBarter.CommUnitPrice;
	returnObj.InitialDeliveryDate		=  obj.orderObjectBarter.InitialDeliveryDate;
	returnObj.EndDeliveryDate			=  obj.orderObjectBarter.EndDeliveryDate;
	returnObj.PaymentForm				=  obj.orderObjectBarter.PaymentForm;
	returnObj.Trade					  =  obj.orderObjectBarter.Trade;
	returnObj.FinancialDueDate		   =  obj.orderObjectBarter.FinancialDueDate;
	returnObj.Commodity				  =  obj.orderObjectBarter.Commodity;
	returnObj.CommercialMeasureUnit	  =  obj.orderObjectBarter.CommercialMeasureUnit;
	returnObj.ShippingCrop			   =  obj.orderObjectBarter.ShippingCrop;
	returnObj.BillingCrop				=  obj.orderObjectBarter.BillingCrop;
	returnObj.TotalDeliveryQuantity	  =  obj.orderObjectBarter.TotalDeliveryQuantity;
	returnObj.CommFreigthMode			=  obj.orderObjectBarter.CommFreigthMode;
	returnObj.ProductionDeliveryLocation =  obj.orderObjectBarter.ProductionDeliveryLocation;
	returnObj.ProductionPickupLocation   =  obj.orderObjectBarter.ProductionPickupLocation;
	returnObj.Bloqued					=  obj.orderObjectBarter.Bloqued;
	returnObj.Rating					 =  obj.orderObjectBarter.Rating;	
	return returnObj;	
};

const nullOrderItemObjectUtils = (obj) => {
	obj.Product2	  = null; 
	obj.UnitValue	 = null;
	obj.UnitValueWithSevenDecimalCases	= null;
	obj.TotalValueItem	= null;
	obj.DiscountPercent	   = null;
	obj.DiscountPercentWithSixDecimalCases = null;
	obj.DiscountValue	 = null;
	obj.Quantity	  = null;
	obj.PriceList	 = null;
	obj.ListPrice	 = null;
	obj.Freigth	   = null;
	obj.Family	= null;
	obj.Culture	   = null;
	obj.ShippingDivision	  = [];
	obj.InternShippingCity	= null;
	obj.FreigthMode	   = null;
	obj.InterestListValue	 = null;
	obj.PriceListWithoutInterest	  = null;
	obj.InterestList	  = null;
	obj.QuantityUnitOfMeasure	 = null;
	obj.Id	= null;
	obj.DiscountValueWithSevenDecimalCases = null;
	obj.AdditionValue	 = null;
	obj.AdditionPercent	   = null;
	return obj;	
};

const getOrderItemCreateOrderControllerUtils = (obj, ordObj) => {
	let oiObj = {};
	oiObj.productId			  = obj.Product2.Id;
	oiObj.QuantityUnitOfMeasure  = obj.QuantityUnitOfMeasure;
	oiObj.listPriceId			= obj.ListPrice.Id;
	oiObj.unitPrice			  = parseFloat(obj.UnitValueWithSevenDecimalCases);
	oiObj.listPrice			  = parseFloat(obj.PriceListWithoutInterest);
	oiObj.quantity			   = parseFloat(obj.Quantity);
	oiObj.freightValue		   = parseFloat(obj.Freigth);
	oiObj.freightType			= obj.FreigthMode;
	oiObj.discountPercent		= parseFloat(obj.DiscountPercentWithSixDecimalCases);
	oiObj.discountValue		  = parseFloat(obj.DiscountValueWithSevenDecimalCases);
	oiObj.additionValue		  = parseFloat(obj.AdditionValueWithSevenDecimalCases);
	oiObj.additionPercent		= parseFloat(obj.AdditionPercentWithSixDecimalCases);
	oiObj.cultureId			  = obj.Culture.Id;
	oiObj.LastChangedPriceList   = obj.LastChangedPriceList;
	oiObj.Id					 = obj.Id;
	oiObj.incoterms1			 = obj.FreigthMode;
	oiObj.incoterms2			 = ordObj.ShippingAccount.hasOwnProperty("InternShippingCity__c") ? ordObj.ShippingAccount.InternShippingCity__r.Name : null;
	oiObj.status				 = ordObj.Status;
	oiObj.destinationCityId	  = ordObj.ShippingAccount.hasOwnProperty("InternShippingCity__c") ? ordObj.ShippingAccount.InternShippingCity__c : null;
	oiObj.sourceCityId		   = ordObj.SalesTeam.DistributionCenter__r.City__c;
	oiObj.interestListPriceId	= obj.InterestList != null ? obj.InterestList.Id : null;
	oiObj.antecipationDiscount   = obj.InterestList != null && obj.InterestList.RecordType.DeveloperName == 'ZDJ1' ? parseFloat(obj.InterestListValue) : null;
	oiObj.interestValue		  = obj.InterestList != null && obj.InterestList.RecordType.DeveloperName == 'ZJ01' ? parseFloat(obj.InterestListValue) : null;
	oiObj.interest			   = obj.Freigth != parseFloat(0).toFixed(2) ? obj.FreigthData.ValuePerTon__c : null;
	return oiObj;	
};

const fillAxOrd = (oldObj, obj) => {
	let returnObj = oldObj;
	returnObj["Rtv"]					= obj["Rtv"];
	returnObj["Account"]				= obj["Account"];
	returnObj["IsUserRtv"]			  = obj["IsUserRtv"];
	returnObj["BillingAccount"]		 = obj["BillingAccount"];
	returnObj["ShippingAccount"]		= obj["ShippingAccount"];
	returnObj["SalesCondition"]		 = obj["SalesCondition"];
	returnObj["PaymentForm"]			= obj["PaymentForm"];
	returnObj["RecordType"]			 = obj["RecordType"];
	returnObj["Currency"]			   = obj["Currency"];
	returnObj["DueDate"]				= obj["DueDate"];
	returnObj["Crop"]				   = obj["Crop"];
	returnObj["PaymentCondition"]	   = obj["PaymentCondition"];
	returnObj["ExpirationDate"]		 = obj["ExpirationDate"];
	returnObj["EndContractDate"]		= obj["EndContractDate"];
	returnObj["InitialContractDate"]	= obj["InitialContractDate"];
	returnObj["SalesTeam"]			  = obj["SalesTeam"]; 
	returnObj["SalesOrg"]			   = obj["SalesOrg"];
	returnObj["CustomerGroup"]		  = obj["CustomerGroup"];
	returnObj["RecordType"]			 = obj["RecordType"];
	returnObj["Id"]					 = obj["Id"];
	returnObj["Status"]				 = obj["Status"];
	returnObj["OrderNumber"]			= obj["OrderNumber"];
	returnObj["ActivitySector"]		 = obj["ActivitySector"];
	return returnObj;	
};
const fillNewProduct2= (obj) => {
	  return {"Id": obj.Product2.Id ,
				"Name": obj.Product2.Name,
				"Multiplicity__c": obj.Product2.Multiplicity__c,
				"QuantityUnitOfMeasure": obj.Product2.QuantityUnitOfMeasure ,
				"ProductCode": obj.Product2.ProductCode ,
				"GrossWeightUnity__c": obj.Product2.GrossWeightUnity__c,
				"Family__c": obj.Product2.Family__c ,
				"Brand__c": obj.Product2.Brand__c,
				"GrossWeight__c": obj.Product2.GrossWeight__c ,
				"RemoveFreightValue__c" : obj.Product2.RemoveFreightValue__c,
				"ActivitySector__c": obj.Product2.ActivitySector__c,
				"Family__r":{"Id": obj.Product2.Family__r.Id , "Name": obj.Product2.Family__r.Name}};
}

const fillNewListPrice= (obj) => {
	return {"AccountId": obj.ListPrice__r.Account__c,"Crop": obj.ListPrice__r.Crop__c,"Currencys": obj.ListPrice__r.Currency__c,
				"EffectiveDate": obj.ListPrice__r.EffectiveDate__c,"EndDate": obj.ListPrice__r.EndDate__c, "ExternalId": obj.ListPrice__r.ExternalId__c,"Id": obj.ListPrice__c,
				"InitialDate": obj.ListPrice__r.InitialDate__c,"IsActive": obj.ListPrice__r.IsActive__c,"Name": obj.ListPrice__r.Name,"Priority": obj.ListPrice__r.Priority__c,
				"Product2Id": obj.ListPrice__r.Product2Id__c, "RecordType": obj.ListPrice__r.RecordType.Id,"RecordTypeName": obj.ListPrice__r.RecordType.Name,
				"SalesCondition": obj.ListPrice__r.SalesCondition__c, "SalesOrg": obj.ListPrice__r.SalesOrg__c, "SalesTeam": obj.ListPrice__r.SalesTeam__c,
				"UnitMeasurement": obj.ListPrice__r.UnitMeasurement__c, "UnitPrice": obj.ListPrice__r.UnitPrice__c, "PriceMultiplier": obj.ListPrice__r.PriceMultiplier__c};
				
}

const fillNewOrderItem= (obj, ordObj) => {
	console.log('fillNewOrderItem: ' +JSON.stringify(obj))
	let oiObj = {};
	oiObj.Product2							 = fillNewProduct2(obj);
	oiObj.ListPrice							= fillNewListPrice(obj);
	oiObj.Multiplicity						 = parseFloat((obj.Product2.Multiplicity__c).toFixed(3)) == parseFloat(0) ? parseFloat(1) : parseFloat((obj.Product2.Multiplicity__c).toFixed(3));
	oiObj.QuantityUnitOfMeasure				= obj.Product2.QuantityUnitOfMeasure;
	oiObj.LastChangedPriceList				 = ordObj.Id != undefined ? obj.LastChangedPriceList__c : dateTodayWithoutFormat();
	oiObj.DeletedProductSap					= obj.DeletedProductSAP__c;
	oiObj.UnitValue							= parseFloat(obj.UnitPrice).toFixed(2);
	oiObj.UnitValueWithSevenDecimalCases	   = parseFloat(obj.UnitPrice);
	oiObj.PriceList							= obj.AnticipationDiscount__c != null ? parseFloat(Number(obj.CustomListPrice__c) - Number(obj.AnticipationDiscount__c)).toFixed(7) : obj.InterestValue__c != null ? parseFloat(Number(obj.CustomListPrice__c) + Number(obj.InterestValue__c)).toFixed(7) : Number(obj.CustomListPrice__c);
	oiObj.PriceListWithoutInterest			 = parseFloat(obj.CustomListPrice__c).toFixed(2);
	oiObj.Quantity							 = obj.Quantity__c;
	oiObj.TotalValueItem					   = obj.TotalPrice__c;
	oiObj.DiscountPercent					  = obj.DiscountPercent__c ? parseFloat((obj.DiscountPercent__c).toFixed(3)) : (0).toFixed(3);
	oiObj.DiscountPercentWithSixDecimalCases   = parseFloat(obj.DiscountPercent__c);
	oiObj.DiscountValueWithSevenDecimalCases   = parseFloat(obj.DiscountAmount__c);
	oiObj.DiscountValue						= parseFloat(parseFloat(obj.DiscountAmount__c).toFixed(2));
	oiObj.AdditionValue						= obj.AdditionAmmount__c ? parseFloat(parseFloat(obj.AdditionAmmount__c).toFixed(2)) : (0).toFixed(2);
	oiObj.AdditionPercent					  = obj.AdditionPercent__c ? parseFloat(parseFloat(obj.AdditionPercent__c).toFixed(3)): (0).toFixed(3);
	oiObj.AdditionValueWithSevenDecimalCases   = parseFloat(obj.AdditionAmount__c);
	oiObj.Cost								 = parseFloat(obj.Cost__c);
	oiObj.AdditionPercentWithSixDecimalCases   = parseFloat(obj.AdditionPercent__c);
	oiObj.Family							   = {"Id": obj.Product2.Family__r.Id ,"Name": obj.Product2.Family__r.Name};
	oiObj.Culture							  = {"Id": obj.Culture__r.Id ,"Name": obj.Culture__r.Name};
	oiObj.FreigthMode						  = obj.Freight__c;
	oiObj.Campaign							 = [];
	oiObj.Freigth							  = obj.FreightValue__c;
	oiObj.FreigthData						  = {"ValuePerTon__c": obj.CalculatedInterest__c};
	oiObj.InterestListValue					= obj.hasOwnProperty("AnticipationDiscount__c") ? obj.AnticipationDiscount__c : obj.hasOwnProperty("InterestValue__c") ? obj.InterestValue__c : null;
	oiObj.InterestListValueName				= obj.hasOwnProperty("AnticipationDiscount__c") ? 'Desconto de Antecipação (Unitário)'  : obj.hasOwnProperty("InterestValue__c") ? 'Juros Unitário' : null;
	oiObj.Id								   = obj.Id;
	oiObj.InterestList						 = obj.hasOwnProperty("InterestOrAntecipationDiscount__c") ? {"Id": obj.InterestOrAntecipationDiscount__r.Id, "Name": obj.InterestOrAntecipationDiscount__r.Name, "RecordType": {"DeveloperName":obj.InterestOrAntecipationDiscount__r.RecordType.DeveloperName}} : null;
	oiObj.InternShippingCity				   = ordObj.ShippingAccount.hasOwnProperty("InternShippingCity__c") ? { "Id": ordObj.ShippingAccount.InternShippingCity__r.Id, "Name": ordObj.ShippingAccount.InternShippingCity__r.Name } : null;
	oiObj.BorderColor						  = oiObj.DeletedProductSap ? 'card card-lista-pedido border-danger' : 'card card-lista-pedido border-primary';
	oiObj.margin							   = 'Margin__c' in obj ? obj.Margin__c : null;
	oiObj.projectedMargin					  = 'ProjectedMargin__c' in obj ? obj.ProjectedMargin__c : null;
	oiObj.familyMargin						 = 'FamilyMargin__c' in obj ? obj.FamilyMargin__c : null;
	return oiObj;
}

const fillOrderObject = (obj, data) => {
	let returnObj = obj;
	returnObj["Rtv"]						= {"Id": data.OrderObj.RTV__r.Id, "User": {"Name": data.OrderObj.RTV__r.Name}, "UserId": data.OrderObj.RTV__r.Id};
	returnObj["Account"]					= data.AccountObj;
	returnObj["IsUserRtv"]				  = data.IsUserRtv;
	returnObj["BillingAccount"]			 = data.AccountBillingObj;
	returnObj["ShippingAccount"]			= data.AccountShippingObj;
	returnObj["SalesCondition"]			 = data.OrderObj.SalesCondition__c;
	returnObj["PaymentForm"]				= data.OrderObj.PaymentForm__c;
	returnObj["RecordType"]				 = data.OrderObj.RecordType.Id;
	returnObj["Currency"]				   = data.OrderObj.Currency__c;
	returnObj["DueDate"]					= data.PaymentDateOrder;
	returnObj["Crop"]					   = data.CropObj;
	returnObj["PaymentCondition"]		   = data.PaymentConditionObj;
	returnObj["ExpirationDate"]			 = data.OrderObj.EndDate;
	returnObj["SalesTeam"]				  = data.OrderObj.SalesTeam__r; 
	returnObj["SalesOrg"]				   = data.OrderObj.SalesOrg__c;
	returnObj["CustomerGroup"]			  = data.OrderObj.CustomerGroup__c;
	returnObj["RecordType"]				 = data.OrderObj.RecordType.DeveloperName;
	returnObj["Id"]						 = data.OrderObj.Id;
	returnObj["Status"]					 = data.OrderObj.StatusSF__c;
	returnObj["OrderNumber"]				= data.OrderObj.OrderNumber;
	returnObj["ActivitySector"]			 = data.OrderObj.ActivitySector__c;
	returnObj["PassedGrainTable"]		   = data.OrderObj.GrainTableApproval__c;
	returnObj["BarterType"]				 = data.OrderObj.BarterType__c;
	returnObj["Commodity"]				  = data.OrderObj.Commodity__c;
	returnObj["ShippingCrop"]			   = data.ShippingCrop;
	returnObj["BillingCrop"]				= data.OrderObj.BillingCrop__c;
	returnObj["GrossUnitPrice"]			 = data.OrderObj.GrossUnitPrice__c;
	returnObj["CommUnitPrice"]			  = data.OrderObj.UnitPrice__c;
	returnObj["CommercialMeasureUnit"]	  = data.OrderObj.CommercialMeasureUnit__c;
	returnObj["CommFreigthMode"]			= data.OrderObj.CommodityShipping__c;
	returnObj["InitialDeliveryDate"]		= data.OrderObj.InitialDeliveryDate__c;
	returnObj["EndDeliveryDate"]			= data.OrderObj.EndDeliveryDate__c;
	returnObj["EndContractDate"]			= data.OrderObj.ContractEndDate__c;
	returnObj["InitialContractDate"]		= data.OrderObj.ContractStartDate__c;
	returnObj["TotalDeliveryQuantity"]	  = data.OrderObj.DeliveryQuantity__c;
	returnObj["ProductionDeliveryLocation"] = data.OrderObj.ProductionDeliveryLocation__c;
	returnObj["ProductionPickupLocation"]   = data.OrderObj.ProductionPickupLocation__c;
	returnObj["StrikePrice"]				= data.OrderObj.StrikePrice__c;
	returnObj["FinancialDueDate"]		   = data.OrderObj.DueDateFinancial__c;
	returnObj["Trade"]					  = data.Trade;
	returnObj["EndContract"]				= data.OrderObj.ContractEndDate__c;
	returnObj["InitialContractDate"]		= data.OrderObj.ContractStartDate__c;
	returnObj["ContractProduct"]			= data.OrderContractObj;
	returnObj["Route"]					  = data.OrderObj.OrderRoute__c;
	returnObj.DeletedProductProcessSap	  = data.OrderObj.DeletedProductProcessSap__c;
	returnObj.CustomerGroup				 = data.OrderObj.CustomerGroup__c;

	return returnObj;
}

const fillOrderItemCampaignObject = (obj, data) => {
	let returnObj				   = obj;
	returnObj["Id"]				 = data.Id;
	returnObj["campaignId"]		 = data.Campaign__c;
	returnObj["name"]			   = data.Campaign__r.Name;
	returnObj["orderItem"]		  = data.OrderItem__c;
	returnObj["campaignProductId"]  = data.CampaignProduct__c;
	returnObj["fixedPrice"]		 = data.FixedUnitPrice__c;
	returnObj["hasFixedUnitPrice"]  = data.FixedUnitPriceCampaign__c;
	returnObj["discountPercentage"] = data.Discount__c;
	returnObj["discountValue"]	  = data.DiscountValue__c;
	returnObj["hasDiscountOrder"]   = false;
	returnObj["isAccumulative"]	 = data.Accumulative__c;
	returnObj["invalid"]			= false;
	returnObj["campaign"]		   = data.Campaign__c;
	returnObj["RecordType"]		 = data.Campaign__r.RecordType.DeveloperName;

	return returnObj;
}

const handleFreigth = (ordItem, currency, data) => {

	ordItem.FreigthData = data;
	if(currency == 'BRL') {
		if(ordItem.Product2.GrossWeightUnity__c == 'KG') {
			ordItem.Freigth = parseFloat((Number(ordItem.Product2.GrossWeight__c) * Number(ordItem.Quantity) * Number(ordItem.FreigthData.ValuePerTon__c)) / 1000).toFixed(2);
		} else if (ordItem.Product2.GrossWeightUnity__c == 'TO') {
			ordItem.Freigth = parseFloat(Number(ordItem.Product2.GrossWeight__c) * Number(ordItem.Quantity) * Number(ordItem.FreigthData.ValuePerTon__c)).toFixed(2);
		}
	} else if(currency == 'USD') {
		if(ordItem.Product2.GrossWeightUnity__c == 'KG') {
			ordItem.Freigth = parseFloat((Number(ordItem.Product2.GrossWeight__c) * Number(ordItem.Quantity) * Number(ordItem.FreigthData.ValuePerTonDolar__c)) / 1000).toFixed(2);
		} else if (ordItem.Product2.GrossWeightUnity__c == 'TO') {
			ordItem.Freigth = parseFloat(Number(ordItem.Product2.GrossWeight__c) * Number(ordItem.Quantity) * Number(ordItem.FreigthData.ValuePerTonDolar__c)).toFixed(2);
		}
	}
	ordItem.TotalValueItem  = parseFloat(parseFloat(ordItem.TotalValueItem) + parseFloat(ordItem.Freigth)).toFixed(2);
	return ordItem;
}

const dateTodayFormat = () => {
	var data = new Date(),
		dia  = data.getDate().toString(),
		diaF = (dia.length == 1) ? '0'+dia : dia,
		mes  = (data.getMonth()+1).toString(),
		mesF = (mes.length == 1) ? '0'+mes : mes,
		anoF = data.getFullYear();
	return diaF+"/"+mesF+"/"+anoF;
}
const dateTodayWithoutFormat= () => {
	var data = new Date(),
		dia  = data.getDate().toString(),
		diaF = (dia.length == 1) ? '0'+dia : dia,
		mes  = (data.getMonth()+1).toString(),
		mesF = (mes.length == 1) ? '0'+mes : mes,
		anoF = data.getFullYear();
	return anoF+"-"+mesF+"-"+diaF;
}
const dateCreatedDateFormat = (date) => {
	var data = new Date(date),
		dia  = data.getDate().toString(),
		diaF = (dia.length == 1) ? '0'+dia : dia,
		mes  = (data.getMonth()+1).toString(),
		mesF = (mes.length == 1) ? '0'+mes : mes,
		anoF = data.getFullYear();
	return diaF+"/"+mesF+"/"+anoF;
}

const handleDiscount = (ordItem, totalMonths) => {
	ordItem.AdditionValue = 0;
	ordItem.AdditionPercent = 0;
	ordItem.PriceListWithoutInterest = parseFloat(ordItem.ListPrice.UnitPrice).toFixed(2);
	ordItem.InterestListValue = ordItem.InterestList == null ? null : (totalMonths * parseFloat(ordItem.InterestList.InterestValue__c)) / 100;
	ordItem.InterestListValue = ordItem.InterestListValue == null ? null : parseFloat(ordItem.ListPrice.UnitPrice * ordItem.InterestListValue).toFixed(7);
	ordItem.PriceList = parseFloat(parseFloat(parseFloat(ordItem.PriceListWithoutInterest).toFixed(7)) - parseFloat(parseFloat(ordItem.InterestListValue).toFixed(7)));
	ordItem.DiscountValue = parseFloat((parseFloat(ordItem.DiscountPercent) * ordItem.ListPrice.UnitPrice) / 100).toFixed(2);
	ordItem.DiscountValueWithSevenDecimalCases = parseFloat((parseFloat(ordItem.DiscountPercent) * ordItem.ListPrice.UnitPrice) / 100).toFixed(7)
	ordItem.IsDiscount = true;
	ordItem.InterestListValueName = 'Desconto de Antecipação (Unitário)';
	ordItem.UnitPrice = ordItem.ListPrice.UnitPrice;
	ordItem.UnitValue = parseFloat(ordItem.PriceList - parseFloat(ordItem.DiscountValue)).toFixed(2);
	ordItem.UnitValueWithSevenDecimalCases = parseFloat(ordItem.PriceList - ordItem.DiscountValue).toFixed(7);
	ordItem.TotalValueItem = (ordItem.UnitValueWithSevenDecimalCases * parseFloat(ordItem.Quantity).toFixed(2)).toFixed(2);
	return ordItem;
}

const handleAddition = (ordItem, totalMonths) => {
	ordItem.DiscountValue = 0;
	ordItem.DiscountPercent = 0;
	ordItem.PriceListWithoutInterest = parseFloat(ordItem.ListPrice.UnitPrice).toFixed(2);
	ordItem.InterestListValue = ordItem.InterestList == null ? null : (totalMonths * parseFloat(ordItem.InterestList.InterestValue__c)) / 100;
	ordItem.InterestListValue = ordItem.InterestListValue == null ? null : parseFloat(ordItem.ListPrice.UnitPrice * ordItem.InterestListValue).toFixed(7);
	ordItem.PriceList = parseFloat(parseFloat(parseFloat(ordItem.PriceListWithoutInterest).toFixed(7)) + parseFloat(parseFloat(ordItem.InterestListValue).toFixed(7)));
	ordItem.AdditionValue = parseFloat((parseFloat(ordItem.AdditionPercent) * ordItem.ListPrice.UnitPrice) / 100).toFixed(2);
	ordItem.AdditionValueWithSevenDecimalCases = parseFloat((parseFloat(ordItem.AdditionPercent) * ordItem.ListPrice.UnitPrice) / 100).toFixed(7);
	ordItem.IsDiscount = false;
	ordItem.InterestListValueName = 'Juros Unitário';
	ordItem.UnitPrice = ordItem.ListPrice.UnitPrice;
	ordItem.UnitValue = parseFloat(ordItem.PriceList + parseFloat(ordItem.AdditionValueWithSevenDecimalCases)).toFixed(2);
	ordItem.UnitValueWithSevenDecimalCases = parseFloat(ordItem.PriceList + ordItem.AdditionValueWithSevenDecimalCases).toFixed(7);
	ordItem.TotalValueItem = (ordItem.UnitValueWithSevenDecimalCases * parseFloat(ordItem.Quantity).toFixed(2)).toFixed(2);
	return ordItem;
}

const handleInventoryCheck = (ordItem, inventory, status) => {
	ordItem.hasInventory = true;
	if(inventory.Block){
		ordItem.BorderColor = 'card card-lista-pedido border-danger';
		ordItem.Block = inventory.Block;
		ordItem.ShowErrorDetails = true;
	}
	else{
		ordItem.ShowErrorDetails = false;
		ordItem.Block = false;
		ordItem.BorderColor = 'card card-lista-pedido border-primary';
	}
	ordItem.stockQuantity = inventory.Quantity;
	if (inventory.Quantity < ordItem.Quantity && inventory.Block) {
		ordItem.Block = true;
		ordItem.ShowErrorDetails = true;
		if(status == 'Retorna RTV'){
			ordItem.hasInventoryError = false;
			ordItem.hasInventoryErrorRTV = true;
		}
		else {
			ordItem.hasInventoryError = true;
			ordItem.hasInventoryErrorRTV = false;
		}
	} else {
		ordItem.Block = false;
		ordItem.ShowErrorDetails = false;
		ordItem.BorderColor = 'card card-lista-pedido border-primary';
		ordItem.hasInventoryError = false;
	}

	if (ordItem.Block) {
		ordItem.showBlockMessage = true;
		ordItem.showInventoryErrorMessage = false;
	}
	else if (!ordItem.Block && (ordItem.hasInventoryError || ordItem.hasInventoryErrorRTV)) {
		ordItem.showBlockMessage = false;
		ordItem.showInventoryErrorMessage = true;
	}
	return ordItem;
}

const handleNullStock = (ordItem) => {
	ordItem.hasInventory = false;
	ordItem.stockQuantity = null;
	ordItem.stockMeasure = null;
	ordItem.hasInventoryErrorRTV = false;
	ordItem.hasInventoryError = false;
	return ordItem;
}

const validateCampaign = (data, varContext) => {
	varContext.campaignList = JSON.parse(JSON.stringify(data));
	var x = null;
	x = varContext;

	varContext.campaignList.forEach(function(campaign) {

		campaign.show			= true;
		campaign.styleCard	   = "card card-lista-pedido border-secondary card-margin-for-modal availableCampaign";
		campaign.labelBackground = "labelBackground";
		campaign.styleTitle	  = "content styleTitle";
		campaign.actionMethod	= "selectCampaign";

		campaign.ProductList = campaign.ProductList ? campaign.ProductList : [];

		let campaignProductActivators = campaign.ProductList.filter(item => item.CanActivateRules == true);

		if (campaign.Condition) {
			campaignProductActivators.forEach(campaignProduct => {
				let orderItems = getOrderItensByCampaignProduct(x.orderObject.OrderItem, campaignProduct);
				if (orderItems.length == 0) {
					campaign.invalid = true;
				}
			});
		} 
		// else {
		//	 let hasProductActivator = false;
		//	 campaignProductActivators.forEach(campaignProduct => {
		//		 let orderItems = getOrderItensByCampaignProduct(x.orderObject.OrderItem, campaignProduct);
		//		 if (orderItems.length >= 0) {
		//			 hasProductActivator = true;
		//		 }
		//	 });
		//	 if (!hasProductActivator) {
		//		 campaign.invalid = true;
		//	 }
		// }

		if (campaign.RulesList.length > 0) {
			campaign.RulesList.forEach(rule => {

				if (!rule.CampaignProduct) {
					campaign.ProductList.forEach(campaignProduct => {
						let orderItems = getOrderItensByCampaignProduct(x.orderObject.OrderItem, campaignProduct);

						if (campaignProduct.MaxQuantity > 0) {
							var isInvalidMaxQtd;

							let sumProductQtdTon = orderItems.reduce((acc, obj) => {
								return acc + obj.Quantity}, 0);
							let availableQtdTon = campaignProduct.AvailableQuantity;
							if (availableQtdTon < sumProductQtdTon) {
								isInvalidMaxQtd = true;
							} else {
								isInvalidMaxQtd = false;
							}

							if (isInvalidMaxQtd) {
								rule.invalid = true;
							}
						}
					});
				}

				if (rule.RecordType == 'ProductMix') { //campaign type -> ProductMix

					if (campaign.ProductList.length > 0) {
						if (campaignProductActivators && campaignProductActivators.length > 0) {
							let productCount = 0;
							campaignProductActivators.forEach(campaignProduct => {
								let orderItems = getOrderItensByCampaignProduct(x.orderObject.OrderItem, campaignProduct);

								productCount += orderItems.length;

								if (campaignProduct.MaxQuantity > 0) {
									var isInvalidMaxQtd;

									let sumProductQtdTon = orderItems.reduce((acc, obj) => {
										return acc + obj.Quantity}, 0);
									let availableQtdTon = campaignProduct.AvailableQuantity;
									if (availableQtdTon < sumProductQtdTon) {
										isInvalidMaxQtd = true;
									} else {
										isInvalidMaxQtd = false;
									}

									if (isInvalidMaxQtd) {
										rule.invalid = true;
									}
								}
							});

							if (rule.MaximumQuantity < productCount || rule.MinimumQuantity > productCount) {
								rule.invalid = true;
							}
						} else {
							rule.invalid = true;
						}
					} else {
						rule.invalid = true;
					}

				} else if (rule.RecordType == 'PaymentDate') { //campaign type -> PaymentDate
					if (rule.PaymentCondition && rule.PaymentDate) {
						if (x.orderObject.PaymentCondition.Id != rule.PaymentCondition || x.orderObject.DueDate > rule.PaymentDate) {
							rule.invalid = true;
						}
					} else {
						if (rule.PaymentCondition && x.orderObject.PaymentCondition.Id != rule.PaymentCondition) {
							rule.invalid = true;
						}

						if (rule.PaymentDate && x.orderObject.DueDate > rule.PaymentDate) {
							rule.invalid = true;
						}
					}

					if (!rule.CampaignProduct) {
						campaignProductActivators.forEach(campaignProduct => {
							if (campaignProduct.MaxQuantity > 0) {
								if (campaignProduct.MaxQuantity > 0) {
									let orderItems = getOrderItensByCampaignProduct(x.orderObject.OrderItem, campaignProduct);
									var isInvalidMaxQtd;

									let sumProductQtdTon = orderItems.reduce((acc, obj) => {
										return acc + obj.Quantity}, 0);
									let availableQtdTon = campaignProduct.AvailableQuantity;
									if (availableQtdTon < sumProductQtdTon) {
										isInvalidMaxQtd = true;
									} else {
										isInvalidMaxQtd = false;
									}

									if (isInvalidMaxQtd) {
										rule.invalid = true;
									}
								}
							}
						});
					} else {
						let specificProduct;

						campaign.ProductList.forEach(campaignProduct => {
							if(campaignProduct.Id == rule.CampaignProduct){
								specificProduct = campaignProduct;
							}
						});
						if (specificProduct) {
							if (specificProduct.MaxQuantity > 0) {
								let orderItems = getOrderItensByCampaignProduct(x.orderObject.OrderItem, specificProduct);
								var isInvalidMaxQtd;

								let sumProductQtdTon = orderItems.reduce((acc, obj) => {
									return acc + obj.Quantity}, 0);
								let availableQtdTon = specificProduct.AvailableQuantity;
								if (availableQtdTon < sumProductQtdTon) {
									isInvalidMaxQtd = true;
								} else {
									isInvalidMaxQtd = false;
								}

								if (isInvalidMaxQtd) {
									rule.invalid = true;
								}
							}
						} else {
							rule.invalid = true;
						}
					}
									
					} else if (rule.RecordType == 'QuantityCampaign') { //campaign type -> QuantityCampaign

						if (campaign.ProductList.length > 0) {
							if (!rule.CampaignProduct) {
								if (campaignProductActivators && campaignProductActivators.length > 0) {
									campaignProductActivators.forEach(campaignProduct => {
										let orderItems = x.orderObject.OrderItem.filter(item =>
												 item.Product2.Id == campaignProduct.Product2 ||
												 item.Product2.Family__r.Id == campaignProduct.Family ||
												 (item.Product2.Manufacturer__c != null && item.Product2.Manufacturer__c != undefined && item.Product2.Manufacturer__c.toLowerCase() == campaignProduct.Manufacturer.toLowerCase()) ||
												 (item.Product2.Brand__c != null && item.Product2.Brand__c != undefined && item.Product2.Brand__c.toLowerCase() == campaignProduct.ComercialName.toLowerCase()));

										let sumProductQtdTon = orderItems.reduce((acc, obj) => {
											return acc + obj.Quantity
										}, 0);

										let maxQtdTon = rule.MaximumQuantity;
										let minQtdTon = rule.MinimumQuantity;

										if (maxQtdTon < sumProductQtdTon || minQtdTon > sumProductQtdTon) {
											rule.invalid = true;
										}

										// if (campaignProduct.MaxQuantity > 0) {
										//	 var isInvalidMaxQtd;

										//	 let sumProductQtdTon = orderItems.reduce((acc, obj) => {
										//		 return acc + obj.Quantity}, 0);
										//	 let availableQtdTon = campaignProduct.AvailableQuantity;
										//	 if (availableQtdTon < sumProductQtdTon) {
										//		 isInvalidMaxQtd = true;
										//	 } else {
										//		 isInvalidMaxQtd = false;
										//	 }

										//	 if (isInvalidMaxQtd) {
										//		 rule.invalid = true;
										//	 }
										// }
									});
								} else {
									rule.invalid = true;
								}
							} else {
								let specificProduct;

								campaign.ProductList.forEach(campaignProduct => {
									if(campaignProduct.Id == rule.CampaignProduct){
										specificProduct = campaignProduct;
									}
								});
								if (specificProduct) {
									let orderItems = x.orderObject.OrderItem.filter(item =>
												item.Product2.Id == specificProduct.Product2 ||
												item.Product2.Family__r.Id == specificProduct.Family ||
												(item.Product2.Manufacturer__c != null && item.Product2.Manufacturer__c != undefined && item.Product2.Manufacturer__c.toLowerCase() == specificProduct.Manufacturer.toLowerCase()) ||
												 (item.Product2.Brand__c != null && item.Product2.Brand__c != undefined && item.Product2.Brand__c.toLowerCase() == specificProduct.ComercialName.toLowerCase()));

									let sumProductQtdTon = orderItems.reduce((acc, obj) => {
										return acc + obj.Quantity
									}, 0);

									let maxQtdTon = rule.MaximumQuantity;
									let minQtdTon = rule.MinimumQuantity;

									if (maxQtdTon < sumProductQtdTon || minQtdTon > sumProductQtdTon) {
										rule.invalid = true;
									}

									if (specificProduct.MaxQuantity > 0) {
										var isInvalidMaxQtd;

										let sumProductQtdTon = orderItems.reduce((acc, obj) => {
											return acc + obj.Quantity}, 0);
										let availableQtdTon = specificProduct.AvailableQuantity;
										if (availableQtdTon < sumProductQtdTon) {
											isInvalidMaxQtd = true;
										} else {
											isInvalidMaxQtd = false;
										}

										if (isInvalidMaxQtd) {
											rule.invalid = true;
										}
									}
								} else {
									rule.invalid = true;
								}
							}
						} else {
							rule.invalid = true;
						}

					} else if (rule.RecordType == 'VariableConstraints') { //campaign type -> VariableConstraints

						if ((rule.MinimumOrderValue && parseFloat(x.orderObject.TotalPriceOrder) < rule.MinimumOrderValue) || (parseFloat(x.orderObject.TotalPriceOrder) > rule.MaximumOrderValue && rule.MaximumOrderValue)) {
							rule.invalid = true;
						}

						// if (campaign.ProductList.length > 0) {
							if (!rule.CampaignProduct) {
								if (campaignProductActivators && campaignProductActivators.length > 0) {
									let orderItemList = [];
									campaignProductActivators.forEach(campaignProduct => {
										let orderItems = x.orderObject.OrderItem.filter(item =>
												 item.Product2.Id == campaignProduct.Product2 ||
												 item.Product2.Family__r.Id == campaignProduct.Family ||
												 (item.Product2.Manufacturer__c != null && item.Product2.Manufacturer__c != undefined && item.Product2.Manufacturer__c.toLowerCase() == campaignProduct.Manufacturer.toLowerCase()) ||
												 (item.Product2.Brand__c != null && item.Product2.Brand__c != undefined && item.Product2.Brand__c.toLowerCase() == campaignProduct.ComercialName.toLowerCase()));

										// if (campaignProduct.MaxQuantity > 0) {
										//	 var isInvalidMaxQtd;

										//	 let sumProductQtdTon = orderItems.reduce((acc, obj) => {
										//		 return acc + obj.Quantity}, 0);
										//	 let availableQtdTon = campaignProduct.AvailableQuantity;
										//	 if (availableQtdTon < sumProductQtdTon) {
										//		 isInvalidMaxQtd = true;
										//	 } else {
										//		 isInvalidMaxQtd = false;
										//	 }

										//	 if (isInvalidMaxQtd) {
										//		 rule.invalid = true;
										//	 }
										// }

										orderItems.forEach(item => {
											if (!orderItemList.find(oi => oi.Product2.Id == item.Product2.Id)) {
												orderItemList.push(item);
											}
										});
									});
									let itemTotalValue = orderItemList.reduce((acc, obj) => {
										return acc + obj.TotalValueItem
									}, 0);

									let totalPercent = (itemTotalValue * 100) / x.orderObject.TotalPriceOrder;

									if (rule.ProductPercent && totalPercent < rule.ProductPercent) {
										rule.invalid = true;
									}
								} 
								// else {
								//	 rule.invalid = true;
								// }
							} else {
								let specificProduct;

								campaign.ProductList.forEach(campaignProduct => {
									if(campaignProduct.Id == rule.CampaignProduct){
										specificProduct = campaignProduct;
									}
								});
								if (specificProduct) {
									let orderItemList = [];
									let orderItems = x.orderObject.OrderItem.filter(item =>
										item.Product2.Id == specificProduct.Product2 ||
										item.Product2.Family__c == specificProduct.Family ||
										(item.Product2.Manufacturer__c != null && item.Product2.Manufacturer__c != undefined && item.Product2.Manufacturer__c.toLowerCase() == specificProduct.Manufacturer.toLowerCase()) ||
										(item.Product2.Brand__c != null && item.Product2.Brand__c != undefined && item.Product2.Brand__c.toLowerCase() == specificProduct.ComercialName.toLowerCase()));

									if (specificProduct.MaxQuantity > 0) {
										var isInvalidMaxQtd;

										let sumProductQtdTon = orderItems.reduce((acc, obj) => {
											return acc + obj.Quantity}, 0);
										let availableQtdTon = specificProduct.AvailableQuantity;
										if (availableQtdTon < sumProductQtdTon) {
											isInvalidMaxQtd = true;
										} else {
											isInvalidMaxQtd = false;
										}

										if (isInvalidMaxQtd) {
											rule.invalid = true;
										}
									}

									orderItems.forEach(item => {
										if (!orderItemList.find(oi => oi.Product2.Id == item.Product2.Id)) {
											orderItemList.push(item);
										}
									});
									let itemTotalValue = orderItems.reduce((acc, obj) => {
										return acc + obj.TotalPriceOrder
									}, 0);

									let totalPercent = (itemTotalValue * 100) / x.orderObject.TotalPriceOrder;

									if (rule.ProductPercent && totalPercent < rule.ProductPercent) {
										rule.invalid = true;
									}
								} else {
									rule.invalid = true;
								}
							}
						// } else {
						//	 rule.invalid = true;
						// }
					}

					if(rule.invalid != true){
						rule.invalid = false;
					}
				});
		} else {
			rule.invalid = true;
		}
	});

	varContext.campaignList.filter(item => item.show).forEach(campaign => {
		let validRules = campaign.RulesList.find(rule => !rule.invalid);
		if (!validRules) {
			campaign.invalid = true;
			campaign.styleTitle	  = "content styleErrorTitle";
			campaign.styleCard	   = "card card-lista-pedido border-secondary card-margin-for-modal campaignErrorBackground";
			campaign.labelBackground = "labelErrorBackground";
			campaign.actionMethod	= "";
		}
	});

	return varContext.campaignList;
}

	const applyCampaignDiscounts = (varContext) => {

		var totalOrderDiscount = 0;
		var totalPrice = 0;

		varContext.orderObject.OrderItem.forEach(function(ordItem) {
			let totalDiscount = 0;
			if(ordItem.Campaign.length > 0) {
				ordItem.Campaign.forEach(campaign => {

					if (campaign.hasFixedUnitPrice) {
						ordItem.DiscountPercent = 0;
						ordItem.DiscountPercentWithSixDecimalCases = 0;
						ordItem.DiscountValue = 0;
						ordItem.DiscountValueWithSevenDecimalCases = 0;
						ordItem.AdditionValue = 0;
						ordItem.AdditionValueWithSevenDecimalCases = 0;
						ordItem.AdditionPercent = 0;
						ordItem.AdditionPercentWithSixDecimalCases = 0;
					}

					var listPriceWithInterestAndDiscounts = parseFloat(ordItem.PriceList) + parseFloat(ordItem.AdditionValueWithSevenDecimalCases) - parseFloat(ordItem.DiscountValueWithSevenDecimalCases);

					if (parseFloat(campaign.fixedPrice) > 0) {
						totalDiscount += parseFloat(campaign.discountValue);
					} else {
						totalDiscount += (parseFloat(campaign.discountPercentage) * listPriceWithInterestAndDiscounts) / 100;
					}
				});
			}
			var listPriceWithInterestAndDiscounts = parseFloat(ordItem.PriceList) + parseFloat(ordItem.AdditionValueWithSevenDecimalCases) - parseFloat(ordItem.DiscountValueWithSevenDecimalCases);

			ordItem.UnitValue = parseFloat(parseFloat(listPriceWithInterestAndDiscounts - parseFloat(totalDiscount)).toFixed(2));
			ordItem.UnitValueWithSevenDecimalCases = listPriceWithInterestAndDiscounts - parseFloat(totalDiscount);
			ordItem.listPriceValueWithInterestAndCampaign = listPriceWithInterestAndDiscounts - totalDiscount;
			ordItem.UnitValue = ordItem.listPriceValueWithInterestAndCampaign.toFixed(2);
			ordItem.UnitValueWithSevenDecimalCases = ordItem.listPriceValueWithInterestAndCampaign;
			ordItem.TotalCampaignDiscount = ordItem.Quantity * totalDiscount;
			totalOrderDiscount += ordItem.TotalCampaignDiscount;
			ordItem.TotalValueWithoutCampaign = listPriceWithInterestAndDiscounts * parseFloat(ordItem.Quantity);
			totalPrice += parseFloat(ordItem.TotalValueItem);

		});

		varContext.orderObject.TotalPriceOrder = totalPrice;
		varContext.orderObject.TotalCampaignDiscount = totalOrderDiscount;
		varContext.orderObject.TotalCampaignDisocuntPercentage = ((parseFloat(varContext.orderObject.TotalCampaignDiscount) * 100) / (parseFloat(varContext.orderObject.TotalPriceOrder) + parseFloat(varContext.orderObject.TotalCampaignDiscount)));
		varContext.orderObject.TotalPriceOrderWithoutCampaign = parseFloat(varContext.orderObject.TotalPriceOrder) + parseFloat(varContext.orderObject.TotalCampaignDiscount);

		varContext.orderObject.hasCampaign = true;

	}

	const removeCampaignFromItem = (varContext, campaignId) => {
		var x = null;
		x = varContext;
		varContext.orderObject.OrderItem.forEach(item => {
			item.Campaign = item.Campaign.filter(cp => cp.campaignId != campaignId);
			let totalDiscount = 0;
			item.Campaign.forEach(campaign => {

				if (campaign.hasFixedUnitPrice) {
					item.DiscountPercent = 0;
					item.DiscountPercentWithSixDecimalCases = 0;
					item.DiscountValue = 0;
					item.DiscountValueWithSevenDecimalCases = 0;
					item.AdditionValue = 0;
					item.AdditionValueWithSevenDecimalCases = 0;
					item.AdditionPercent = 0;
					item.AdditionPercentWithSixDecimalCases = 0;
				}

				var listPriceWithInterestAndDiscounts = parseFloat(item.PriceList) + parseFloat(item.AdditionValueWithSevenDecimalCases) - parseFloat(item.DiscountValueWithSevenDecimalCases);

				if (parseFloat(campaign.discountValue) != 0) {
					totalDiscount += parseFloat(campaign.discountValue);
				} else {
					totalDiscount += campaign.discountPercentage * listPriceWithInterestAndDiscounts - parseFloat(totalDiscount);
				}
			});

			//if (!x.orderObject.OrderItem.find(ordItem => ordItem.hasCampaign)) {
			//	x.orderObject.hasCampaign = false;
			//}

			var listPriceWithInterestAndDiscounts = parseFloat(item.PriceList) + parseFloat(item.AdditionValueWithSevenDecimalCases) - parseFloat(item.DiscountValueWithSevenDecimalCases);

			item.UnitValue = parseFloat(parseFloat(listPriceWithInterestAndDiscounts - parseFloat(totalDiscount)).toFixed(2));
			item.UnitValueWithSevenDecimalCases = listPriceWithInterestAndDiscounts - parseFloat(totalDiscount);
			item.listPriceValueWithInterestAndCampaign = parseFloat(item.UnitValue);
			//item.UnitPrice = item.listPriceValueWithInterestAndCampaign + parseFloat(item.AdditionValue) - parseFloat(item.DiscountValue);
			item.TotalValueItem = parseFloat((item.UnitValueWithSevenDecimalCases * item.Quantity).toFixed(2));

			if(item.Campaign.length == 0) {
				item.TotalCampaignDiscount = 0;
				item.TotalValueWithoutCampaign = 0;
				item.hasCampaign = false;
			} else {
				item.TotalCampaignDiscount = item.Quantity * totalDiscount;
				item.TotalValueWithoutCampaign = listPriceWithInterestAndDiscounts * parseFloat(item.Quantity);
				item.hasCampaign = true;
			}

			let orderCampaignDiscount = 0;
			let orderTotalValue = 0;

			x.orderObject.OrderItem.forEach((item) => {
				orderTotalValue += parseFloat(item.TotalValueItem);
				orderCampaignDiscount += parseFloat(item.TotalCampaignDiscount);
			});
			x.orderObject.TotalPriceOrder = orderTotalValue;
			x.orderObject.TotalCampaignDiscount = orderCampaignDiscount;
			x.orderObject.TotalCampaignDisocuntPercentage = ((x.orderObject.TotalCampaignDiscount * 100) / (x.orderObject.TotalPriceOrder + x.orderObject.TotalCampaignDiscount));
			x.orderObject.TotalPriceOrderWithoutCampaign = x.orderObject.TotalPriceOrder + x.orderObject.TotalCampaignDiscount;
		});
	}

	const validateAccumulativeAndIndustryCampaign = (varContext) => {
		var x = null;
		x = varContext;
		varContext.orderObject.OrderItem.forEach(item => {
			if (item.Campaign.length > 0) {
			let industryCampaign = item.Campaign.filter(campaign => campaign.RecordType == 'Industry');
			let notAccumulativeCampaign = item.Campaign.filter(campaign => !campaign.isAccumulative);
				item.Campaign.forEach(campaign => {
					var campaignValidation = varContext.campaignList.find(filteredCampaign => filteredCampaign.CampaignId == campaign.campaignId);
					if ((!campaign.isAccumulative && notAccumulativeCampaign.length > 1) || (campaign.RecordType == 'Industry' && industryCampaign.length > 1) || campaignValidation.invalid) {
						campaign.invalid = true;
					} else {
						campaign.invalid = false;
					}
				});
			} else {
				item.Campaign.forEach(campaign => {
					campaign.invalid = false;
				});
			}
		});
	}
	const getOrderItensByCampaignProduct = (orderItems, campaignProduct) => {
		return orderItems.filter(item =>
			item.Product2.Id == campaignProduct.Product2 ||
			item.Product2.Family__c == campaignProduct.Family ||
			(item.Product2.Manufacturer__c != null && item.Product2.Manufacturer__c != undefined && item.Product2.Manufacturer__c.toLowerCase() == campaignProduct.Manufacturer.toLowerCase()) ||
			(item.Product2.Brand__c != null && item.Product2.Brand__c != undefined && item.Product2.Brand__c.toLowerCase() == campaignProduct.ComercialName.toLowerCase())
		);
	}

	const applyCampaignDiscountsAndValidation = (varContext, campaignId) => {
		varContext.showLoading(true);

		let orderUpdate = {
			finalPrice: 0,
			finalDiscount: 0,
			orderItem: [],
		};
		
		let campaign = varContext.campaignList.find(campaign => campaign.CampaignId == campaignId);

		if(campaign.invalid){
			varContext.showLoading(false);
			return;
		}

		// let productsKeys = [];

		// campaign.ProductList.filter(
		//	 item => item.CanReceiveDiscount == true
		// ).forEach(cp => {
		//	 if (cp.Product2 || cp.Family || cp.Manufacturer) {
		//		 productsKeys.push(
		//			 cp.Product2 ? cp.Product2 :
		//			 (cp.Family ? cp.Family  : cp.Manufacturer)
		//		 );
		//	 }
		// });

		var x = null;
		x = varContext;

		let campaignToAllItens = [];

		let orderItemWithThisCampaign = [];

		varContext.orderObject.OrderItem.forEach(orderItem => {
			if (orderItem.Campaign.find(cp => cp.campaignId == campaign.CampaignId)) {
				orderItemWithThisCampaign.push(orderItem.Product2.Id);
			}
		})

		removeCampaignFromItem(varContext, campaign.CampaignId);
		//this.orderObject.OrderItem.forEach(item => {
		//	if (item.Campaign.length > 0) {
		//		item.Campaign = item.Campaign.filter(cp => cp.campaignId != campaign.CampaignId);
		//	}
		//});

		varContext.orderObject.OrderItem.forEach(orderItem => {

				campaign.ProductList = campaign.ProductList ? campaign.ProductList : [];

				var campaignProduct;

				campaign.ProductList.filter(
					item => item.CanReceiveDiscount == true
				).forEach(cp => {
					if (cp.Product2 == orderItem.Product2.Id || cp.Family == orderItem.Product2.Family__c || (cp.Manufacturer != null && cp.Manufacturer != undefined && cp.Manufacturer.toLowerCase() == orderItem.Product2.Manufacturer__c.toLowerCase()) || (cp.ComercialName != null && cp.ComercialName != undefined && cp.ComercialName.toLowerCase() == orderItem.Product2.Brand__c.toLowerCase())) {
						campaignProduct = cp.Id;
					}
				});

				orderItem = x.cloneObj(orderItem);
				//orderItem.Campaign = [];

				let orderItemCampaign = {
					campaignId: campaign.CampaignId,
					name: campaign.Name,
					orderItem: orderItem.code,
					productId: campaignProduct,
					campaignProductId: null,
					fixedPrice: 0,
					RecordType: campaign.RecordType,
					discountPercentage: 0,
					discountValue: 0,
					hasDiscountOrder: false,
					hasFixedUnitPrice: false,
					isAccumulative: campaign.Accumulative,
					invalid: false,
				};

				campaign.RulesList.forEach(rule => {
					if (!rule.invalid) {
						if (rule.OrderDiscount) {
							orderItemCampaign.hasDiscountOrder = true;
							if (rule.FixedUnitPrice) {
								orderItemCampaign.fixedPrice = rule.FixedUnitPrice;
								orderItemCampaign.hasFixedUnitPrice = true;
								orderItemCampaign.discountValue = parseFloat(orderItem.PriceList) - rule.FixedUnitPrice;
							} else {
								orderItemCampaign.discountPercentage = rule.Discount;
							}
						} else {

							if (!rule.CampaignProduct || rule.CampaignProduct == undefined) {

								if (rule.FixedUnitPrice) {
									orderItemCampaign.fixedPrice = rule.FixedUnitPrice;
									orderItemCampaign.hasFixedUnitPrice = true;
									orderItemCampaign.discountValue = parseFloat(orderItem.PriceList) - rule.FixedUnitPrice;
								} else {
									orderItemCampaign.discountPercentage = rule.Discount;
								}

								if (rule.FixedUnitPrice) {
									orderItemCampaign.fixedPrice = rule.FixedUnitPrice;
									orderItemCampaign.hasFixedUnitPrice = true;
									orderItemCampaign.discountValue = parseFloat(orderItem.PriceList) - rule.FixedUnitPrice;
								} else {
									orderItemCampaign.discountPercentage = rule.Discount;
								}

								let campaignProduct = campaign.ProductList.find(
									item => (item.Product2 == orderItem.Product2.Id ||
										item.Family == orderItem.Product2.Family__c ||
										(item.Manufacturer != null && item.Manufacturer != undefined && item.Manufacturer.toLowerCase() == orderItem.Product2.Manufacturer__c.toLowerCase()) ||
										(item.ComercialName != null && item.ComercialName != undefined && item.ComercialName.toLowerCase() == orderItem.Product2.Brand__c.toLowerCase()))
								);

								if (campaignProduct) {
									orderItemCampaign.campaignProductId = campaignProduct.Id;
								}
							} else {
								let campaignProduct = campaign.ProductList.find(item => item.Id == rule.CampaignProduct);
								if (campaignProduct.Product2 == orderItem.Product2.Id ||
									campaignProduct.Family == orderItem.Product2.Family__c ||
									(campaignProduct.Manufacturer != null && campaignProduct.Manufacturer != undefined && campaignProduct.Manufacturer.toLowerCase() == orderItem.Product2.Manufacturer__c.toLowerCase()) ||
									(campaignProduct.ComercialName != null && campaignProduct.ComercialName != undefined && campaignProduct.ComercialName.toLowerCase() == orderItem.Product2.Brand__c.toLowerCase())) {
									
									if (rule.FixedUnitPrice) {
										orderItemCampaign.fixedPrice = rule.FixedUnitPrice;
										orderItemCampaign.hasFixedUnitPrice = true;
										orderItemCampaign.discountValue = parseFloat(orderItem.PriceList) - rule.FixedUnitPrice;
									} else {
										orderItemCampaign.discountPercentage = rule.Discount;
									}

									orderItemCampaign.campaignProductId = campaignProduct.Id;
								}
							}
						}
					}
				if((orderItemCampaign.hasFixedUnitPrice && orderItem.Campaign[0]) ||
				   (!orderItemCampaign.hasFixedUnitPrice && orderItem.Campaign.filter(item => item.hasFixedUnitPrice)[0])){
						orderItemCampaign.discountPercentage = 0;
						orderItemCampaign.fixedPrice = 0; 
					}
				});

				let specificCampaignProduct = campaign.ProductList.find(
					item => (item.Product2 == orderItem.Product2.Id ||
							item.Family == orderItem.Product2.Family__c ||
							(item.Manufacturer != null && item.Manufacturer != undefined && item.Manufacturer.toLowerCase() == orderItem.Product2.Manufacturer__c.toLowerCase()) ||
							(item.ComercialName != null && item.ComercialName != undefined && item.ComercialName.toLowerCase() == orderItem.Product2.Brand__c.toLowerCase()))
				); 

				if (campaign.ProductList.length == 0 || (specificCampaignProduct && specificCampaignProduct.CanReceiveDiscount)) {
					if (orderItemCampaign.discountPercentage > 0 || orderItemCampaign.fixedPrice > 0) {
						orderItemCampaign.campaignProduct = campaign.ProductList;
						if (orderItemWithThisCampaign.includes(orderItem.Product2.Id)){
							orderItem.Campaign.push(orderItemCampaign);
						}
					}
				}

				let totalDiscount = 0;
				orderItem.Campaign.forEach(campaign => {

					if(campaign.hasFixedUnitPrice) {
						orderItem.DiscountPercent = 0;
						orderItem.DiscountPercentWithSixDecimalCases = 0;
						orderItem.DiscountValue = 0;
						orderItem.DiscountValueWithSevenDecimalCases = 0;
						orderItem.AdditionValue = 0;
						orderItem.AdditionValueWithSevenDecimalCases = 0;
						orderItem.AdditionPercent = 0;
						orderItem.AdditionPercentWithSixDecimalCases = 0;
					}

					var listPriceWithInterestAndDiscounts = parseFloat(orderItem.PriceList) + parseFloat(orderItem.AdditionValueWithSevenDecimalCases) - parseFloat(orderItem.DiscountValueWithSevenDecimalCases);

					if (campaign.hasFixedUnitPrice) {
						totalDiscount += campaign.discountValue;
						campaign.discountPercentage = (campaign.discountValue * 100) / listPriceWithInterestAndDiscounts;
					
					} else {
						totalDiscount += ((campaign.discountPercentage * listPriceWithInterestAndDiscounts) / 100);
						campaign.discountValue = (campaign.discountPercentage * listPriceWithInterestAndDiscounts) / 100;
						campaign.fixedPrice = listPriceWithInterestAndDiscounts - ((campaign.discountPercentage * listPriceWithInterestAndDiscounts)/100);
					}
					if (campaign.hasDiscountOrder) {
						campaignToAllItens.push(orderItemCampaign);
					} else {

					}
				});

				var listPriceWithInterestAndDiscounts = parseFloat(orderItem.PriceList) + parseFloat(orderItem.AdditionValueWithSevenDecimalCases) - parseFloat(orderItem.DiscountValueWithSevenDecimalCases);

				orderItem.UnitValue = parseFloat(parseFloat(listPriceWithInterestAndDiscounts - parseFloat(totalDiscount)).toFixed(2));
				orderItem.UnitValueWithSevenDecimalCases = listPriceWithInterestAndDiscounts - parseFloat(totalDiscount);
				//item.UnitValueWithSevenDecimalCases = parseFloat(parseFloat(item.PriceList) + parseFloat(item.AdditionValue) - parseFloat(item.DiscountValue)).toFixed(7);
				orderItem.listPriceValueWithInterestAndCampaign = parseFloat(orderItem.UnitValue);
				orderItem.TotalValueItem = parseFloat((orderItem.UnitValueWithSevenDecimalCases * orderItem.Quantity).toFixed(2));
				orderItem.TotalCampaignDiscount = orderItem.Quantity * totalDiscount;
				//item.TotalValueWithoutCampaign = item.TotalValueItem + item.TotalDiscount;

				//orderItem.listPriceValueWithInterestAndCampaign = parseFloat(orderItem.UnitValue) - totalDiscount;
				//orderItem.UnitPrice = orderItem.listPriceValueWithInterestAndCampaign;
				//orderItem.TotalDiscount = orderItem.Quantity * totalDiscount;
				//orderItem.TotalValueItem = orderItem.UnitPrice * orderItem.Quantity;

				var newRegister = true;

				if(orderUpdate.orderItem.length == 0) {
					if(!orderItem.TotalCampaignDiscount){
						orderItem.TotalCampaignDiscount = 0;
					}
					orderUpdate.orderItem.push(orderItem);
					orderUpdate.finalPrice += orderItem.TotalValueItem;
					orderUpdate.finalDiscount += orderItem.TotalCampaignDiscount;
					newRegister = false;
				} else {
					orderUpdate.orderItem.forEach(function(ordItem) {
						if(ordItem.Product2.Id == orderItem.Product2.Id){
							newRegister = false;
						}
					});
				}

				if(newRegister) {
					if(!orderItem.TotalCampaignDiscount){
						orderItem.TotalCampaignDiscount = 0;
					}
					orderUpdate.orderItem.push(orderItem);
					orderUpdate.finalPrice += orderItem.TotalValueItem;
					orderUpdate.finalDiscount += orderItem.TotalCampaignDiscount;
				}
		});

		let orderTotalValue = 0;
		x.orderObject.OrderItem.forEach((item) => {
			if(!item.Campaign.find(cp => cp.id == campaign.CampaignId)  && !((campaign.hasFixedUnitPrice && item.Campaign[0]) || (!campaign.hasFixedUnitPrice && item.Campaign.filter(its => its.hasFixedUnitPrice)[0]))) {
			item = x.cloneObj(item);

			if (campaignToAllItens.length > 0) {
				campaignToAllItens.forEach(campaign => {
					item.HasChange = true;

					let campaignProduct = campaign.campaignProduct ? campaign.campaignProduct.find(
						cp => (cp.Product2 == item.Product2.Id ||
							cp.Family == item.Product2.Family__c ||
							(cp.Manufacturer != null && cp.Manufacturer != undefined && cp.Manufacturer.toLowerCase() == item.Product2.Manufacturer__c.toLowerCase()) ||
							(cp.ComercialName != null && cp.ComercialName != undefined && cp.ComercialName.toLowerCase() == item.Product2.Brand__c.toLowerCase()))
					) : null; 

					if ((!campaignProduct || campaignProduct.length == 0) || (campaignProduct && campaignProduct.CanReceiveDiscount)) {

						if (!item.Campaign.find(cp => cp.id == campaign.CampaignId)) {
							item.Campaign.push(campaign);

							let totalDiscount = 0;
							item.Campaign.forEach(campaign => {

								if(campaign.hasFixedUnitPrice) {c/campaignModal
									item.DiscountPercent = 0;
									item.DiscountPercentWithSixDecimalCases = 0;
									item.DiscountValue = 0;
									item.DiscountValueWithSevenDecimalCases = 0;
									item.AdditionValue = 0;
									item.AdditionValueWithSevenDecimalCases = 0;
									item.AdditionPercent = 0;
									item.AdditionPercentWithSixDecimalCases = 0;
								}

								var listPriceWithInterestAndDiscounts = parseFloat(item.PriceList) + parseFloat(item.AdditionValueWithSevenDecimalCases) - parseFloat(item.DiscountValueWithSevenDecimalCases);

								if (campaign.hasFixedUnitPrice) {
									totalDiscount += campaign.discountValue;
									campaign.discountPercentage = (campaign.discountValue * 100) / listPriceWithInterestAndDiscounts;
								} else {
									totalDiscount += ((campaign.discountPercentage * listPriceWithInterestAndDiscounts) / 100);
									campaign.discountValue = (campaign.discountPercentage * listPriceWithInterestAndDiscounts) / 100;
									campaign.fixedPrice = listPriceWithInterestAndDiscounts - (campaign.discountPercentage * listPriceWithInterestAndDiscounts);
								}
							});

							var listPriceWithInterestAndDiscounts = parseFloat(item.PriceList) + parseFloat(item.AdditionValueWithSevenDecimalCases) - parseFloat(item.DiscountValueWithSevenDecimalCases);

							item.UnitValue = parseFloat(parseFloat(listPriceWithInterestAndDiscounts - parseFloat(totalDiscount)).toFixed(2));
							item.UnitValueWithSevenDecimalCases = listPriceWithInterestAndDiscounts - parseFloat(totalDiscount);
							//item.UnitValueWithSevenDecimalCases = parseFloat(parseFloat(item.PriceList) + parseFloat(item.AdditionValue) - parseFloat(item.DiscountValue)).toFixed(7);
							item.listPriceValueWithInterestAndCampaign = parseFloat(item.UnitValue);
							item.TotalValueItem = parseFloat((item.UnitValueWithSevenDecimalCases * item.Quantity).toFixed(2));
							item.TotalCampaignDiscount = item.Quantity * totalDiscount;
							//item.TotalValueWithoutCampaign = item.TotalValueItem + item.TotalDiscount;


							//item.listPriceValueWithInterestAndCampaign = parseFloat(item.UnitValue) - totalDiscount;
							//item.UnitPrice = item.listPriceValueWithInterestAndCampaign;
							//item.TotalDiscount = item.Quantity * totalDiscount;
							//item.TotalValueItem = item.UnitPrice * item.Quantity;
						}
					}
				});
			}
		
			var newRegister = true;

			if(orderUpdate.orderItem.length == 0) {
				if(!item.TotalCampaignDiscount){
					item.TotalCampaignDiscount = 0;
				}
				orderUpdate.orderItem.push(item);
				orderUpdate.finalPrice += item.TotalValueItem;
				orderUpdate.finalDiscount += item.TotalCampaignDiscount;
			} else {
				orderUpdate.orderItem.forEach(function(orderItem) {
					if(orderItem.Product2.Id == item.Product2.Id){
						newRegister = false;
					}
				});
			}

			if(newRegister) {
				orderUpdate.orderItem.push(item);
				orderUpdate.finalPrice += item.TotalValueItem;
				orderUpdate.finalDiscount += item.TotalCampaignDiscount? item.TotalCampaignDiscount : 0;
			}
		}
		});
		var newOrderValues = orderUpdate;
		varContext.orderObject.TotalPriceOrder = newOrderValues.finalPrice;
		varContext.orderObject.TotalCampaignDiscount = newOrderValues.finalDiscount;
		varContext.orderObject.TotalCampaignDisocuntPercentage = ((varContext.orderObject.TotalCampaignDiscount * 100) / (varContext.orderObject.TotalPriceOrder + varContext.orderObject.TotalCampaignDiscount));
		varContext.orderObject.TotalPriceOrderWithoutCampaign = varContext.orderObject.TotalPriceOrder + varContext.orderObject.TotalCampaignDiscount;

		var t = varContext;
		newOrderValues.orderItem.forEach(item => {
			let orderItem = t.orderObject.OrderItem.find(oi => oi.Product2.Id == item.Product2.Id);
			if (orderItem != null || orderItem != undefined) {
				orderItem.Campaign = item.Campaign;
				if (orderItem.Campaign.length > 0) {
					orderItem.listPriceValueWithInterestAndCampaign = item.listPriceValueWithInterestAndCampaign;
					orderItem.UnitPrice = item.UnitPrice;
					orderItem.UnitValue = orderItem.UnitPrice;
					orderItem.UnitValueWithSevenDecimalCases = parseFloat(parseFloat(orderItem.UnitPrice) + parseFloat(orderItem.AdditionValueWithSevenDecimalCases) - parseFloat(orderItem.DiscountValueWithSevenDecimalCases)).toFixed(7)
					orderItem.TotalValueItem = item.TotalValueItem;
					orderItem.TotalCampaignDiscount = parseFloat(item.TotalCampaignDiscount).toFixed(2);
					orderItem.TotalValueWithoutCampaign = parseFloat(parseFloat(orderItem.PriceList) + parseFloat(orderItem.AdditionValueWithSevenDecimalCases) - parseFloat(orderItem.DiscountValueWithSevenDecimalCases)) * parseFloat(orderItem.Quantity);
					orderItem.hasCampaign = true;
				} else {
					orderItem.TotalCampaignDiscount = 0;
					orderItem.TotalValueWithoutCampaign = 0;
					t.orderObject.TotalPriceOrder += orderItem.TotalValueItem;
					t.orderObject.TotalCampaignDisocuntPercentage = ((t.orderObject.TotalCampaignDiscount * 100) / (t.orderObject.TotalPriceOrder + t.orderObject.TotalCampaignDiscount));
					t.orderObject.TotalPriceOrderWithoutCampaign = t.orderObject.TotalPriceOrder + t.orderObject.TotalCampaignDiscount;
					orderItem.hasCampaign = false;
				}
			}
		});

		var hasCampaign = false;

		varContext.orderObject.OrderItem.forEach(orderItem => {
			if (orderItem.Campaign.length > 0) {
				hasCampaign = true;
			}
		});

		if (hasCampaign) {
			varContext.orderObject.hasCampaign = true;
			validateAccumulativeAndIndustryCampaign(varContext);
			applyCampaignDiscounts(varContext);
		} else {
			varContext.orderObject.hasCampaign = false;
		}
	}

export { fillOrderObject, fillOrderBarter, nullOrderItemObjectUtils, getOrderItemCreateOrderControllerUtils, fillAxOrd, fillNewProduct2, fillNewListPrice, fillNewOrderItem, dateTodayFormat, dateTodayWithoutFormat, dateCreatedDateFormat, handleFreigth, handleDiscount, handleAddition, handleInventoryCheck, handleNullStock, validateCampaign, fillOrderItemCampaignObject, applyCampaignDiscounts, removeCampaignFromItem, validateAccumulativeAndIndustryCampaign, applyCampaignDiscountsAndValidation };
