import { fillOrderObject, dateTodayFormat, dateCreatedDateFormat  } from './utils';
import getRTVSalesTeam from '@salesforce/apex/GetAccountTeam.getRTVSalesTeam';
import FiscalDomicileAlert from '@salesforce/label/c.FiscalDomicileAlert';

const getBaseDataUtils = (varContext, data) => {
	if(data) {
		varContext.toastInfoErrorCurrencyDol	= data.ToastInfoErrorCurrencyDolar;
		varContext.toastInfoErrorDatePlusThirty = data.ToastInfoErrorDatePlusThirty;
		varContext.HasErrorDate = data.HasErrorDate;
		if(data.StatusOrder == '_iscreate_') {
			if(data.IsProp && data.HasErrorPropWithoutParentId == false) {
				varContext.orderObject["BillingAccount"]  = data.AccountBillingObj;
				varContext.orderObject["ShippingAccount"] = data.AccountShippingObj;
				varContext.clienteId					  = data.AccountObjNewAccount.Id;
				varContext.orderObject["Account"]		  = data.AccountObjNewAccount;
				varContext.orderObject["Account"].InternShippingCity__c = data.AccountShippingObj.InternShippingCity__c;
						varContext.orderObject["Account"].Blocked__c		 = data.AccountShippingObj.Blocked__c;
			} else {
				varContext.clienteId			  = data.AccountObj.Id;
				varContext.orderObject["Account"] = data.AccountObj;
			}
			varContext.hiddenProps					 = data.HaveProps;
			varContext.orderObject["ExpirationDate"] = data.DatePlusThirty;
			varContext.orderObject["OrderNumber"]	 = '---------';
			varContext.valueDataValidade			 = varContext.orderObject.ExpirationDate;
			varContext.hiddenRTV					 = !data.IsUserRtv;
			varContext.hiddenProps					 = data.HaveProps;
			varContext.orderObject["IsUserRtv"]		 = data.IsUserRtv;
			varContext.mapIdRtvToSalesTeams			 = varContext.cloneObj(JSON.parse(data.MapIdRtvToSalesTeams));
			if(varContext.hiddenProps == false) {
				varContext.orderObject["BillingAccount"]  = data.AccountObj;
				varContext.orderObject["ShippingAccount"] = data.AccountObj;
			}
			if(varContext.hiddenRTV == false) {
				varContext.orderObject["Rtv"] = data.CurrentUserRtv;
				varContext.salesTeamList	  = varContext.mapIdRtvToSalesTeams[varContext.orderObject.Rtv.Id];
				if (varContext.salesTeamList && varContext.salesTeamList.length == 1) {
					varContext.selectRecordSalesTeam(varContext.salesTeamList);
				}
			} else {
				varContext.orderObject["Rtv"] = null;
				varContext.hiddenSalesTeam	  = true;
				varContext.idsRtvs			  = Object.keys(varContext.mapIdRtvToSalesTeams);
			}
			varContext.checkedCurrencyReal				= true;
			varContext.orderObject.Currency				= 'BRL';
			varContext.orderObject.OrderItem			= [];
			varContext.orderItemObject.ShippingDivision = [];
			varContext.orderObject.Status				= 'Em digitação';
			varContext.hiddenShippingDivision	 		= true;
			varContext.handleGetPaymentForm(null);
			if(!varContext.orderObject["Account"].InternShippingCity__c){
				swal(FiscalDomicileAlert ,{ icon: "warning"});
				varContext.handleNewRecordAccount(null);
			}
            if(varContext.orderObject["Account"].Blocked__c){
                swal('Cliente bloqueado. Em caso de dúvida, contatar a Central de Cadastro.' ,{ icon: "warning"});
                varContext.handleNewRecordAccount(null);
            }
			varContext.showLoading(false);
		} else if (data.StatusOrder == '_isedit_') {

			varContext.Dates.DueDate				= data.PaymentDateOrder;
			varContext.Dates["EndContractDate"]	 = data.OrderObj.ContractEndDate__c;
			varContext.Dates["InitialContractDate"] = data.OrderObj.ContractStartDate__c;

			varContext.orderObject = fillOrderObject(varContext.orderObject, data);

			varContext.showLoading(true);
			varContext.handleGetRTVSalesTeam();

			varContext.dateToday		   = dateCreatedDateFormat(data.OrderObj.CreatedDate);
			varContext.checkedCurrencyDol  = !data.OrderCurrency;
			varContext.checkedCurrencyReal = data.OrderCurrency;
			varContext.valueDataValidade   = varContext.orderObject.ExpirationDate;
			varContext.clienteId		   = varContext.orderObject.Account.Id;
					
			varContext.axOrd["Rtv"]			 = varContext.orderObject["Rtv"];
			varContext.axOrd["Account"]		 = varContext.orderObject["Account"];
			varContext.axOrd["ShippingAccount"] = varContext.orderObject["ShippingAccount"];
			varContext.axOrd["SalesCondition"]  = varContext.orderObject["SalesCondition"];
			varContext.axOrd["Currency"]		= varContext.orderObject["Currency"];
			varContext.axOrd["DueDate"]		 = varContext.orderObject["DueDate"];
			varContext.axOrd["Crop"]			= varContext.orderObject["Crop"];
			varContext.axOrd["SalesTeam"]	   = varContext.orderObject["SalesTeam"];
			varContext.axOrd["ActivitySector"]  = varContext.orderObject["ActivitySector"];

			if(varContext.orderObject.ContractProduct != null)  varContext.productWithContract = true;
			if(varContext.orderObject.RecordType == "BarterSale" || varContext.orderObject.RecordType == 'ZCNO' || varContext.orderObject.RecordType == 'ZCEF' || varContext.orderObject.RecordType == 'ZCCO'){   
				varContext.checkedContract		= true;
				varContext.checkedSales		   = false;
				varContext.filtersales			= 'Contract';
				varContext.hideConclude		   = false;
				varContext.showDateContractField  = true;
				varContext.showTotalQuantity	  = true;
				varContext.showOrderContractField = false;
				if(varContext.orderObject.RecordType == "BarterSale") {
					varContext.hideSave				= true;
					varContext.showBarterContractField = true;
					varContext.hideConclude			= true;
				}else{
					varContext.showBarterContractField = false;
				}
				varContext.handleGetPaymentFormPicklistValues();
			}
			else{
				varContext.checkedSales		  = true;
				varContext.checkedContract	   = false;
				varContext.filtersales		   = 'Sales';
				varContext.showDateContractField = false;
				if(varContext.orderObject.RecordType == "AccountOrder" || varContext.orderObject.RecordType == 'CurrencySale' || varContext.orderObject.RecordType == 'FutureSale' || varContext.orderObject.RecordType == 'ZVTR' || varContext.orderObject.RecordType == 'ZVTS' || varContext.orderObject.RecordType == 'ZVTF') varContext.showOrderContractField = true;
				varContext.showBarterContractField = false;
				varContext.hideConclude			= false;
				varContext.hideSave				= false;
				varContext.showTotalQuantity	   = false;
				varContext.handleGetPaymentForm(varContext.orderObject.PaymentCondition.Id);
			}

			varContext.mapShippingDivisionObj = data.MapOrderItemIdToShippingDiv;
			varContext.setOrderItems(data.OrdItemList);
			varContext.setOrderItemCampaign(data.CampaignList);
			varContext.orderItemObject.ShippingDivision = [];
			varContext.itemContext = '_isEdit_';
			if(varContext.disabledCustomLookup == true || varContext.disabledNegotiationType == true || varContext.disabledPaymentForm){
				varContext.changeColorCustomLookups();
			}
			var x = null;
			x = varContext;
			varContext.orderObject.OrderItem.forEach(function (ordItem){
				if(ordItem.ShowDetails == null){
					ordItem.ShowDetails = true;
				}
				if(ordItem.DiscountPercent != 0 && ordItem.AdditionPercent == 0){
					ordItem.IsDiscount = true;
				}
				else{
					ordItem.IsDiscount = false;
				}
			});
			if((varContext.orderObject.Status == 'Recusado' || varContext.orderObject.Status == 'Retorna RTV') && varContext.orderObject.RecordType == 'BarterSale'){
				varContext.disabledBarterFields = false;
				varContext.creditLimitBloqued = true;
				varContext.disabledNegotiationType = true;
			}
			if(varContext.orderObject.Status == 'Em digitação' || varContext.orderObject.Status == 'Recusado' || varContext.orderObject.Status == 'Retorna RTV') {
				varContext.disabledCustomLookup = true;
				varContext.disabledContract =  true;
				varContext.disabledSalesCondition = true;
				varContext.disabledPaymentForm = false;
				varContext.disabledAllFields = false;
				varContext.disabledNegotiationType = true;
				varContext.disabledBarterFields = false;

				/*varContext.disabledCustomLookup = false;
				if(varContext.orderObject.OrderContractObj != null){
					varContext.disabledContract = true;
				}
				else{
					varContext.disabledContract = false;
				}
				varContext.disabledSalesCondition = false;
				varContext.disableConclude		 = false;*/
				if(varContext.orderObject.RecordType == "IndustryBonification" || varContext.orderObject.RecordType == "Bonification"){
					varContext.disabledPaymentForm = true;
				}
			} else {
				varContext.disabledAllFields	   = true;
				varContext.disableLastPageProducts = true;
				varContext.disableConclude		 = true;
				varContext.disableLastPageEdit	 = true;
				varContext.disablefreight		  = true;
				varContext.disabledAllObservation  = true;
				varContext.disabledPaymentForm	 = true;
				varContext.disabledNegotiationType = true;
				varContext.disabledBarterFields	= true;
				varContext.disabledCustomLookup	= true;
				varContext.disabledContract		= true;
				varContext.disabledSalesCondition  = true;
				varContext.viewProduct			 = true;
				varContext.itemContext			 = '_isView_';
				varContext.changeColorCustomLookups();
			}
			if( varContext.orderObject.Status == 'Retorna RTV' && varContext.orderObject.DeletedProductProcessSap == true){
				varContext.disabledReturnSap	   = true;
				varContext.disabledAllFields	   = true;
				varContext.disabledPaymentForm	 = true;
				varContext.disabledNegotiationType = true;
				varContext.disabledBarterFields	= true;
				varContext.disableLastPageProducts = true;
				varContext.disableConclude		 = false;
			}
			var totalPrice = varContext.orderObject.OrderItem.reduce((sum, item) => Number(sum) + Number(item.TotalValueItem), 0);
			varContext.orderObject.TotalPriceOrder = parseFloat(totalPrice).toFixed(2);
			varContext.hiddenCity = varContext.orderObject.ShippingAccount.hasOwnProperty("InternShippingCity__c") ? true : false;

			if (varContext.isRefuseReason) {
				varContext.itemContext					= '_isnew_';
				varContext.orderObject["OriginalOrderId"] = varContext.orderObject["Id"];
				varContext.orderObject["Id"]			  = null;
				varContext.orderObject.Status			 = 'Em digitação';
				varContext.orderObject["OrderNumber"]	 = '---------';
				varContext.orderObject.TotalPriceOrder	= parseFloat(0).toFixed(2);
				varContext.dateToday					  = dateTodayFormat();

				let refusalReasonCredit = 0;

				var that = varContext;
				data.OrdItemList.forEach((item) => {
					if (that.mapShippingDivisionObj[item.Id]) {
						that.mapShippingDivisionObj[item.Id].forEach((dr) => {
							if (dr.RefuseReason__c == '25') {
								let freight = ((dr.Quantity__c / item.Quantity) * item.FreightValue__c);
								let totalRefused = ((dr.Quantity__c * item.UnitPrice) + (freight ? freight : 0));
								refusalReasonCredit += totalRefused;
							}
						});
					}
				});
				varContext.orderObject.RefusalReasonCredit  = refusalReasonCredit;
				varContext.orderObject.TotalCredit		  = refusalReasonCredit;
				varContext.orderObject.OrderItem			= [];
				varContext.orderItemObject.ShippingDivision = [];
				varContext.RefuseReasonMargin			   = data.RefuseReasonMargin;
				varContext.disableConclude				  = false;
				varContext.disableLastPageProducts		  = false;
				varContext.viewProduct					  = false;
				varContext.disablefreight				   = false;
			}

			if (data.OrderObj.OriginalOrder__c) {
				varContext.disabledAllFields			   = true;
				varContext.disabledPaymentForm			 = true;
				varContext.disabledNegotiationType		 = true;
				varContext.disabledBarterFields			= true;
				varContext.disabledCustomLookup			= true;
				varContext.disabledSalesCondition		  = true;
				varContext.disabledContract				= true;
				varContext.orderObject["OriginalOrderId"]  = data.OrderObj.OriginalOrder__c;
				varContext.orderObject.RefusalReasonCredit = data.OrderObj.OldOrderCredit__c;
				varContext.orderObject.TotalCredit		 = parseFloat(parseFloat(varContext.orderObject.RefusalReasonCredit.toFixed(2)) - parseFloat(varContext.orderObject.TotalPriceOrder)).toFixed(2);
				varContext.RefuseReasonMargin			  = data.RefuseReasonMargin;
				varContext.isRefuseReason				  = true;
			}

			getRTVSalesTeam({accId: varContext.clienteId}).then(data => {
				if(data == null) {
					varContext.showLoading(false);
				} else {
					const obj					   = JSON.parse(data);
					varContext.mapIdRtvToSalesTeams = varContext.cloneObj(obj);
					if(varContext.hiddenRTV == false) {
						varContext.salesTeamList = varContext.mapIdRtvToSalesTeams[varContext.orderObject.Rtv.Id];
						if (varContext.salesTeamList && varContext.salesTeamList.length == 1) {
							varContext.selectRecordSalesTeam(varContext.salesTeamList);
						}
					} else {
						var mapRtv			   = JSON.parse(JSON.stringify(varContext.mapIdRtvToSalesTeams));
						varContext.salesTeamList = mapRtv[varContext.orderObject.Rtv.Id];
						if (varContext.salesTeamList && varContext.salesTeamList.length == 1) {
							varContext.selectRecordSalesTeam(varContext.salesTeamList);
						}
						varContext.hiddenSalesTeam = true;
						varContext.idsRtvs		 = Object.keys(varContext.mapIdRtvToSalesTeams);
					}
					varContext.showLoading(false);
				}
			}).catch(error => {
			});
					
		} else if(data.StatusOrder == '_isnew_') {
			varContext.hiddenProps					  = data.HaveProps;
			varContext.hiddenRTV						= !data.IsUserRtv;
			varContext.orderObject["IsUserRtv"]		 = data.IsUserRtv;
			varContext.orderObject["Rtv"]			   = data.CurrentUserRtv;
			varContext.orderObject.OrderItem			= [];
			varContext.orderObject["ExpirationDate"]	= data.DatePlusThirty;
			varContext.orderItemObject.ShippingDivision = [];
			varContext.orderObject.Status			   = 'Em digitação';
			varContext.checkedCurrencyReal			  = true;
			varContext.orderObject.Currency			 = 'BRL';
			varContext.orderObject["OrderNumber"]	   = '---------';
			varContext.handleGetPaymentForm(null);
			varContext.showLoading(false);
		}
	}
}

export { getBaseDataUtils };