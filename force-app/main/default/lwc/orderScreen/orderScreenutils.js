import { fillOrderObject, dateTodayFormat, dateCreatedDateFormat  } from './utils';
import getRTVSalesTeam from '@salesforce/apex/GetAccountTeam.getRTVSalesTeam';
import FiscalDomicileAlert from '@salesforce/label/c.FiscalDomicileAlert';
import getCustomerPerOrg from '@salesforce/apex/CustomerPerOrgController.getCustomerPerOrg';
import getProjectedMargins from '@salesforce/apex/OrderScreenController.getProjectedMargins';
import getPaymentTypePicklistValues from '@salesforce/apex/OrderScreenController.getPaymentTypePicklistValues';
import getSalesOfficeValues from '@salesforce/apex/OrderScreenController.getSalesOfficeValues';
import getRangeDiccount from '@salesforce/apex/OrderScreenController.getRangeDiccount';
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
						varContext.orderObject["Account"]		 = data.AccountObjNewAccount;
						varContext.orderObject["Account"].InternShippingCity__c		 = data.AccountShippingObj.InternShippingCity__c;
						varContext.orderObject["Account"].Blocked__c		 = data.AccountShippingObj.Blocked__c;
					} else {
						varContext.clienteId			  = data.AccountObj.Id;
						varContext.orderObject["Account"] = data.AccountObj;
					}
					varContext.hiddenProps				   = data.HaveProps;
					varContext.orderObject["ExpirationDate"] = data.DatePlusThirty;
					varContext.orderObject["OrderNumber"]	= '---------';
					varContext.valueDataValidade			 = varContext.orderObject.ExpirationDate;
					varContext.hiddenRTV					 = !data.IsUserRtv;
					varContext.hiddenProps				   = data.HaveProps;
					varContext.orderObject["IsUserRtv"]	  = data.IsUserRtv;
					varContext.mapIdRtvToSalesTeams		  = varContext.cloneObj(JSON.parse(data.MapIdRtvToSalesTeams));
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
						varContext.hiddenSalesTeam	= true;
						varContext.idsRtvs			= Object.keys(varContext.mapIdRtvToSalesTeams);
					}
					varContext.checkedCurrencyReal			  = true;
					varContext.orderObject.Currency			 = 'BRL';
					varContext.orderObject.OrderItem			= [];
					varContext.orderItemObject.ShippingDivision = [];
					varContext.orderObject.Status			   = 'Em digitação';
					varContext.hiddenShippingDivision	 	  = true;
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

                    varContext.Dates.DueDate                             = data.PaymentDateOrder;
                    varContext.Dates["EndContractDate"]                  = data.OrderObj.ContractEndDate__c;
                    varContext.Dates["InitialContractDate"]              = data.OrderObj.ContractStartDate__c;

                    varContext.orderObject = fillOrderObject(varContext.orderObject, data);

                    varContext.showLoading(true);
                    getRTVSalesTeam({accId: varContext.clienteId}).then(data => {
                        if(data == null) {
                        } else {
                            const obj                 = JSON.parse(data);
                            varContext.mapIdRtvToSalesTeams = varContext.cloneObj(obj);
                            varContext.salesTeamList = varContext.mapIdRtvToSalesTeams[varContext.orderObject.Rtv.Id];
                            if (varContext.salesTeamList && varContext.salesTeamList.length == 1) {
                                varContext.selectRecordSalesTeam(varContext.salesTeamList);
                            }
                        }
                        getCustomerPerOrg({accountId: varContext.orderObject.Account.Id, orgId: varContext.orderObject.SalesTeam.SalesOrg__c, activitySector: null}).then(data => {
                        if(data) {
                            if(data.HaveSector == true) {
                                varContext.template.querySelectorAll('c-show-picklist-value').forEach(element => {
                                    if(element.picklistName == 'activitySectorPickList') element.setPickListOptions(data.ActivitySectorList)
                                });
                            }
                        varContext.showLoading(false);
                        }
                        }).catch(error => {
                            swal("Erro: " + JSON.stringify(error.body.message) ,{ icon: "warning"}).then((action) => {
                                varContext.orderObject.SalesTeam     = null;
                                varContext.hiddenSalesSector1        = false;
                                varContext.orderObject.CustomerGroup = null;
                            });
                        });
                    }).catch(error => {
                    });

                    varContext.dateToday                                 = dateCreatedDateFormat(data.OrderObj.CreatedDate);
					varContext.checkedCurrencyDol						= !data.OrderCurrency;
					varContext.checkedCurrencyReal					   = data.OrderCurrency;
					varContext.valueDataValidade						 = varContext.orderObject.ExpirationDate;
					varContext.clienteId								 = varContext.orderObject.Account.Id;
                    
                    varContext.axOrd["Rtv"]              = varContext.orderObject["Rtv"];
                    varContext.axOrd["Account"]          = varContext.orderObject["Account"];
                    varContext.axOrd["ShippingAccount"]  = varContext.orderObject["ShippingAccount"];
                    varContext.axOrd["SalesCondition"]   = varContext.orderObject["SalesCondition"];
                    varContext.axOrd["Currency"]         = varContext.orderObject["Currency"];
                    varContext.axOrd["DueDate"]          = varContext.orderObject["DueDate"];
                    varContext.axOrd["Crop"]             = varContext.orderObject["Crop"];
                    varContext.axOrd["SalesTeam"]        = varContext.orderObject["SalesTeam"];
                    varContext.axOrd["ActivitySector"]   = varContext.orderObject["ActivitySector"];


                    if(varContext.orderObject.ContractProduct != null)  varContext.productWithContract = true;
                    if(varContext.orderObject.RecordType == "BarterSale" || varContext.orderObject.RecordType == 'ZCNO' || varContext.orderObject.RecordType == 'ZCEF' || varContext.orderObject.RecordType == 'ZCCO'){   
                        varContext.checkedContract = true;
                        varContext.checkedSales = false;
                        varContext.filtersales = 'Contract';
                        varContext.hideConclude                          = false;
                        varContext.showDateContractField                 = true;
                        varContext.showTotalQuantity                     = true;
                        varContext.showOrderContractField                = false;
                        if(varContext.orderObject.RecordType == "BarterSale") {
                            varContext.hideSave                     = true;
                            varContext.showBarterContractField      = true;
                            varContext.hideConclude                 = true;
                        }else{
                            varContext.showBarterContractField      = false;
                        }
                        varContext.handleGetPaymentFormPicklistValues();
                    }
                    else{
                        varContext.checkedSales = true;
                        varContext.checkedContract = false;
                        varContext.filtersales = 'Sales';
                        varContext.showDateContractField                 = false;
                        if(varContext.orderObject.RecordType == "AccountOrder" || varContext.orderObject.RecordType == 'CurrencySale' || varContext.orderObject.RecordType == 'FutureSale' || varContext.orderObject.RecordType == 'ZVTR' || varContext.orderObject.RecordType == 'ZVTS' || varContext.orderObject.RecordType == 'ZVTF') varContext.showOrderContractField = true;
                        varContext.showBarterContractField               = false;
                        varContext.hideConclude                          = false;
                        varContext.hideSave                              = false;
                        varContext.showTotalQuantity                     = false;
                        varContext.handleGetPaymentForm(varContext.orderObject.PaymentCondition.Id);
                    }

                    varContext.mapShippingDivisionObj                    = data.MapOrderItemIdToShippingDiv;
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
                        varContext.disabledBarterFields = true;
                        varContext.creditLimitBloqued = true;
                        varContext.disabledNegotiationType = true;
                    }
                    if(varContext.orderObject.Status == 'Em digitação' || varContext.orderObject.Status == 'Recusado' || varContext.orderObject.Status == 'Retorna RTV') {
                        varContext.disabledCustomLookup = false;
                        if(varContext.orderObject.OrderContractObj != null){
                            varContext.disabledContract = true;
                        }
                        else{
                            varContext.disabledContract = false;
                        }
                        varContext.disabledSalesCondition = false;
                        if(varContext.orderObject.RecordType == "IndustryBonification" || varContext.orderObject.RecordType == "Bonification"){
                            varContext.disabledPaymentForm = true;
                        }
                    } else {
                        varContext.disabledAllFields      = true;
                        varContext.disableLastPageProducts = true;
                        varContext.disableConclude         = true;
                        varContext.disableLastPageEdit    = true;
                        varContext.disablefreight         = true;
                        varContext.disabledAllObservation = true;
                        varContext.disabledPaymentForm    = true;
                        varContext.disabledNegotiationType = true;
                        varContext.disabledBarterFields   = true;
                        varContext.disabledCustomLookup   = true;
                        varContext.disabledContract = true;
                        varContext.disabledSalesCondition = true;
                        varContext.viewProduct            = true;
                        varContext.itemContext            = '_isView_';
                        varContext.changeColorCustomLookups();
                    }
                    if( varContext.orderObject.Status == 'Retorna RTV' && varContext.orderObject.DeletedProductProcessSap == true){
                        varContext.disabledReturnSap      = true;
                        varContext.disabledAllFields      = true;
                        varContext.disabledPaymentForm    = true;
                        varContext.disabledNegotiationType = true;
                        varContext.disabledBarterFields   = true;
                        varContext.disableLastPageProducts = true;
                        varContext.disableConclude         = false;
                    }
                    var totalPrice = varContext.orderObject.OrderItem.reduce((sum, item) => Number(sum) + Number(item.TotalValueItem), 0);
                    varContext.orderObject.TotalPriceOrder = parseFloat(totalPrice).toFixed(2);
                    varContext.hiddenCity = varContext.orderObject.ShippingAccount.hasOwnProperty("InternShippingCity__c") ? true : false;

                    if (varContext.isRefuseReason) {
                        varContext.itemContext = '_isnew_';
                        varContext.orderObject["OriginalOrderId"] = varContext.orderObject["Id"];
                        varContext.orderObject["Id"] = null;
                        varContext.orderObject.Status = 'Em digitação';
                        varContext.orderObject["OrderNumber"] = '---------';
                        varContext.orderObject.TotalPriceOrder = parseFloat(0).toFixed(2);
                        varContext.dateToday = dateTodayFormat();

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
                        varContext.orderObject.RefusalReasonCredit = refusalReasonCredit;
                        varContext.orderObject.TotalCredit = refusalReasonCredit;
                        varContext.orderObject.OrderItem = [];
                        varContext.orderItemObject.ShippingDivision = [];
                        varContext.RefuseReasonMargin = data.RefuseReasonMargin;
                        varContext.disableConclude = false;
                        varContext.disableLastPageProducts = false;
                        varContext.viewProduct = false;
                        varContext.disablefreight = false;
                    }
                    if (data.OrderObj.OriginalOrder__c) {
                        varContext.disabledAllFields = true;
                        varContext.disabledPaymentForm = true;
                        varContext.disabledNegotiationType = true;
                        varContext.disabledBarterFields = true;
                        varContext.disabledCustomLookup = true;
                        varContext.disabledSalesCondition = true;
                        varContext.disabledContract = true;
                        varContext.orderObject["OriginalOrderId"] = data.OrderObj.OriginalOrder__c;
                        varContext.orderObject.RefusalReasonCredit = data.OrderObj.OldOrderCredit__c;
                        varContext.orderObject.TotalCredit = parseFloat(parseFloat(varContext.orderObject.RefusalReasonCredit.toFixed(2)) - parseFloat(varContext.orderObject.TotalPriceOrder)).toFixed(2);
                        varContext.RefuseReasonMargin = data.RefuseReasonMargin;
                        varContext.isRefuseReason = true;
                    }

					if(varContext.orderObject.OrderItem.length > 0){
                        varContext.disabledCustomLookup = true;
                        varContext.disabledSalesCondition = true;
                        varContext.disabledNegotiationType = true;
                        varContext.disabledPaymentForm = true;
                    }
                    
                    varContext.showLoading(false);
                } else if(data.StatusOrder == '_isnew_') {
                    varContext.hiddenProps                      = data.HaveProps;
                    varContext.hiddenRTV                        = !data.IsUserRtv;
                    varContext.orderObject["IsUserRtv"]         = data.IsUserRtv;
                    varContext.orderObject["Rtv"]               = data.CurrentUserRtv;
                    varContext.orderObject.OrderItem            = [];
                    varContext.orderObject["ExpirationDate"]    = data.DatePlusThirty;
                    varContext.orderItemObject.ShippingDivision = [];
                    varContext.orderObject.Status               = 'Em digitação';
                    varContext.checkedCurrencyReal              = true;
                    varContext.orderObject.Currency             = 'BRL';
                    varContext.orderObject["OrderNumber"]       = '---------';
                    varContext.handleGetPaymentForm(null);
                    varContext.showLoading(false);
                }
            }
}


	const findApprovingAuthority = async (effectiveDate, endDate, family, minDiscount, salesOffice, customerCategory, varContext) => {
		var GGN ;
		var clusterDirector;
		var paymentType;
        var mktManager;
        var finManager;
        var salesDirector;
		let authList = [];
		
		await getPaymentTypePicklistValues({pcId: varContext.orderObject.PaymentCondition.Id}).then(data => {
			if (data) paymentType = data;
		}).catch(error => {varContext.showLoading(false);});

		await getSalesOfficeValues({sfId: salesOffice}).then(data => {
			if (data) {   
				if(data.GGN__c) GGN = data.GGN__r.Name;
                if(data.ParentId__r.FinancialAdministrativeManager__c) finManager = data.ParentId__r.FinancialAdministrativeManager__r.Name;
                if(data.ParentId__r.MarketingManager__c) mktManager = data.ParentId__r.MarketingManager__r.Name;
				if(data.SalesDirector__c) {
                    clusterDirector = data.SalesDirector__r.Name;
                    salesDirector = data.SalesDirector__r.Name;
                }
				else if(data.ParentId__r.Director__c) clusterDirector = data.ParentId__r.Director__r.Name;
			}
		}).catch(error => {varContext.showLoading(false);});

        if(varContext.orderObject.DueDate != null && varContext.orderItemObject.ListPrice != null){
            var paymentDate = new Date(varContext.orderObject.DueDate);
            var effectiveDate = new Date(varContext.orderItemObject.ListPrice.EffectiveDate);
            //getTime() trabalha com milissegundos logo 2592000000ms = 30 dias.
            if(paymentDate.getTime() > effectiveDate.getTime()+2592000000){
                if(finManager) {
                    varContext.orderObject.hasFinManager = true;
                    varContext.finAuth = finManager;
                }
            }
        }
        else{
            varContext.orderObject.hasFinManager = false;
        }

        if(varContext.orderObject.RecordType == "IndustryBonification" || varContext.orderObject.RecordType == "Bonification"){
            if(varContext.orderObject.RecordType == "IndustryBonification"){
                if(mktManager) varContext.mktAuth = mktManager;
            }
            else{
                if(salesDirector){
                    varContext.mktAuth = salesDirector;
                }
                else{
                    varContext.mktAuth = clusterDirector;
                }
            }
            varContext.orderObject.hasMktManager = true;
            return authList;
        }
        else {
            varContext.orderObject.hasMktManager = false;
        }

		await getRangeDiccount({salesOfficeId: salesOffice, familyId: family, startData: effectiveDate, endData: endDate, customer: customerCategory,
			paymentType: paymentType, minDiscount: minDiscount}).then(data => {
			if (data) {
				if(varContext.orderObject.SalesTeam.Manager__c){
                    varContext.orderObject.hasDiscAuth = true;
                    authList.push(varContext.orderObject.SalesTeam.Manager__r.Name);
                }
				if (data.includes('ClusterDirector')){
                    varContext.orderObject.hasDiscAuth = true;
					if(GGN) authList.push(GGN);
					if(varContext.orderObject.SalesTeam.SalesOrg__r.Director__c) authList.push(varContext.orderObject.SalesTeam.SalesOrg__r.Director__r.Name);
					if(clusterDirector) authList.push(clusterDirector);
				}
				if (data.includes('InvesteeDirector')){
                    varContext.orderObject.hasDiscAuth = true;
					if(GGN) authList.push(GGN);
					if(varContext.orderObject.SalesTeam.SalesOrg__r.Director__c) authList.push(varContext.orderObject.SalesTeam.SalesOrg__r.Director__r.Name);
				}
				if (data == 'GGN'){
                    varContext.orderObject.hasDiscAuth = true;
					if(GGN) authList.push(GGN);
				}
				return authList;
			}
		}).catch(error => {varContext.showLoading(false);});
		return authList;
	}

	const findAuth = async (ordItemList, varContext) =>  {
		let famMap = {};
		varContext.authArray = [];
        let slParent = varContext.orderObject.SalesTeam.ParentId__c;
        let cGroup = varContext.orderObject.CustomerGroup;
		for(var i=0; i<ordItemList.length; i++){
            let item = ordItemList[i];
			let key = item.Product2.Family__r.Name;
			if(!famMap[key]) famMap[key] = {items: [], data: []};
			famMap[key].items.push(item);
            let returnData = await findApprovingAuthority(item.ListPrice.EffectiveDate, item.ListPrice.EndDate, item.Product2.Family__c, item.DiscountPercent,slParent,cGroup, varContext )
			famMap[key].data.push(returnData);
		}

		for(var j=0; j<Object.keys(famMap).length; j++){
            let item = Object.keys(famMap)[j];
			let i = 0;
		let vals = 0;
		famMap[item].items.forEach(function(ordItem){
			vals += Number(ordItem.DiscountPercent);
			i++;
		});
        i = i == 0 ? 1 : i;
		let allAuth = {};
		famMap[item].data.forEach(function(auth, index){
		    auth.forEach(function(ath){
			    if(!allAuth[ath]) allAuth[ath] = {name:ath, index: (item+'_'+index)};
		    });
		});
        let currDev = varContext.authArray.find(itens => itens.name  == item);
        if(!currDev){
            varContext.authArray.push({ Name: item,
                Discount: ((vals / i).toFixed(4)),
                Authority: Object.values(allAuth),
                HasAuthority:  Object.values(allAuth).length > 0,
                index: varContext.authArray.length});
            }
        }
        //Inactive Margin
        /*
        console.log('findAuth: ordItemList = ' +JSON.stringify(ordItemList));
        var mapFamilyItem =[];                
        ordItemList.forEach(item =>{
            var mapItem =mapFamilyItem.find(map => {
                return map.family === item.Product2.Family__c;
            });
            if (mapItem){
                mapItem.items.push(item);
            }
            else{
                var newMap ={
                    family: item.Product2.Family__c,
                    familyName: item.Product2.Family__r.Name,
                    items: []
                }
                newMap.items.push(item)
                mapFamilyItem.push(newMap);
            }
            console.log('Family__c: '+item.Product2.Family__c);
            console.log('margin: ' +item.margin);
            console.log('UnitValue:' +item.UnitValue);
        })

        let orderId =varContext.recordId;
        console.log('SalesOrg__c: ' +JSON.stringify(varContext.orderObject.SalesTeam.SalesOrg__c));
        console.log('Crop: ' +JSON.stringify(varContext.orderObject.Crop.Id));
        console.log('conta = ' +orderId);
        
        let readMargins =[];
        console.log('getProjectedMargins');
        await getProjectedMargins({
            
            cropId: varContext.orderObject.Crop.Id,
            salesteamId: varContext.orderObject.SalesTeam.Id,
            salesOrgId: varContext.orderObject.SalesTeam.SalesOrg__c
            }).then(projMargins =>{
            readMargins =JSON.parse(JSON.stringify(projMargins));
            if (!('erro' in projMargins)){                
                console.log('found Margins:\n' +JSON.stringify(projMargins));
                console.log('directorName =' +projMargins.directorName);
            }
            if ('marketingManagerId' in projMargins){
                varContext.orderObject['marketingManagerId'] =projMargins.marketingManagerId;
                if ('marketingManagerName' in projMargins){
                    varContext.orderObject['marketingManagerName'] =projMargins.marketingManagerName;
                }
                else{
                    varContext.orderObject['marketingManagerName'] = null;
                }
            } 
            console.log('mapFamilyItem: ' +JSON.stringify(mapFamilyItem));
            mapFamilyItem.forEach(curMap => {
                var totalMargin =0;
                var quantMargins =0;
                // let needMarkManagApprove =false;
                var hasNullZeroMargin =true;
                console.log('Family: ' +curMap.familyName +' has ' +curMap.items.length +' item(s).');
                curMap.items.forEach(curItem =>{    
                    // console.log('cost = ' +curItem.Cost);  
                    console.log('curItem: ' +JSON.stringify(curItem));              
                    // if ('margin' in curItem == false){
                    //     console.log('orderScreenUtils.findAuth: hasNullZeroMargin =true');
                    //     hasNullZeroMargin =true;
                    // }
                    // else{
                    //     console.log('curItem.margin: ' +curItem.margin); 
                    //     if (curItem.margin==null || curItem.margin==0){
                    //         console.log('orderScreenUtils.findAuth: hasNullZeroMargin =true');
                    //         hasNullZeroMargin =true;
                    //     }
                    // }                        
                    if ('margin' in curItem && curItem.margin!=null){
                        hasNullZeroMargin =false;
                        quantMargins =quantMargins+1;
                        totalMargin =Number(totalMargin) +Number(curItem.margin);
                    }
                    // if (('margin' in curItem) ==false ||
                    //         curItem.margin ==null ||
                    //         Number(curItem.margin)==0){
                    //     // varContext.orderObject['MarginApprover'] =readMargins.directorId;
                    //     // needMarkManagApprove =true;
                    // }                    
                })
                var familyMargin =null;
                if (quantMargins>0){
                    familyMargin =totalMargin/quantMargins;                
                    // familyMargin =parseFloat(familyMargin).toFixed(4);
                }
                let readMargin =readMargins.margins.find(marg => marg.family == curMap.family);
                let readMarginValue =null;
                let margFamilyMargApprov =false;
                if (readMargin){
                    readMarginValue =readMargin.margin.Margin__c;
                    margFamilyMargApprov =( familyMargin!=null && readMargin.margin.Margin__c > familyMargin);
                    if (familyMargin!=null && readMargin.margin.Margin__c ==0){
                        console.log('orderScreenUtils.findAuth: Margin__c =0 => hasNullZeroMargin =true');
                        hasNullZeroMargin =true;     
                    }
                }
                else{
                    console.log('orderScreenUtils.findAuth: (!readMargin) => hasNullZeroMargin =true');
                    hasNullZeroMargin =true;                    
                }
                curMap['hasNullCost'] =false;
                curMap.items.forEach(curItem =>{
                    if (('Cost' in curItem && curItem.Cost ==null)
                        || 'Cost' in curItem ==false){
                        curMap.hasNullCost =true;
                    }
                    else{
                        console.log('found cost: ' +curItem.Cost);
                    }
                    curItem['projectedMargin'] =readMarginValue;
                    curItem['familyMargin'] =null;
                    if (familyMargin!=null){
                        curItem['familyMargin'] =familyMargin;
                    }                    
                    curItem['needApproval'] =margFamilyMargApprov;
                })    

                //  curMap['hasNullCost']
                //  hasNullZeroMargin
                console.log('hasNullCost: ' +curMap['hasNullCost']);
                console.log('hasNullZeroMargin: ' +hasNullZeroMargin);

                if (curMap['hasNullCost']==true || hasNullZeroMargin==true){
                    // if (hasNullZeroMargin ){
                        let valAuth = varContext.authArray.find(item => item.Name == curMap.familyName);
                        let message =varContext.orderObject.marketingManagerName + ' - Aprovação por Marketing';
                        console.log('orderScreenUtils.findAuth: adding message "' +message +'"');
                        if(!valAuth?.Authority?.find(item => item.name == message)){                        
                            varContext.authArray.find(item => item.Name == curMap.familyName)?.Authority.push({
                                name: message,
                                index: 'authItem'+varContext.authArray.length
                            });
                            varContext.authArray.find(item => item.Name == curMap.familyName)['HasAuthority'] =true;
                            console.log('authArray: '+JSON.stringify(varContext.authArray.find(item => item.Name == curMap.familyName).Authority));
                        }
                        // varContext.orderObject['MarginApprover'] =projMargins.marketingManagerId;  
                        varContext.orderObject['needsMarketMangr'] =true;                  
                    //}
                    // else{
                    //     if (curMap['hasNullCost']==true){
                    //         let valAuth = varContext.authArray.find(item => item.Name == curMap.familyName);
                    //         let message =readMargins.directorName + ' - Aprovação por Custo';
                    //         if(!valAuth?.Authority?.find(item => item.name == message)){                        
                    //             varContext.authArray.find(item => item.Name == curMap.familyName)?.Authority.push({
                    //                 name: message,
                    //                 index: 'authItem'+varContext.authArray.length});
                    //         }     
                    //         // varContext.orderObject['MarginApprover'] =projMargins.marketingManagerId;   
                    //         varContext.orderObject['needsMarketMangr'] =true;                                          
                    //     }
                    // }                    
                    varContext.orderObject['MarginApprover'] =projMargins.marketingManagerId;  
                }
                else{
                    if (margFamilyMargApprov==true){
                        let valAuth = varContext.authArray.find(item => item.Name == curMap.familyName);
                        let message = readMargins.directorName + ' - Aprovação de margem';
                        console.log('orderScreenUtils.findAuth: adding message "' +message +'"');
                        // console.log('precisa aprovador da margem: "' +readMargins.directorName);
                        console.log('valAuth: '+JSON.stringify(valAuth));
                        if(!valAuth?.Authority?.find(item => item.name == message)){                        
                            varContext.authArray.find(item => item.Name == curMap.familyName)?.Authority.push({
                                name: message,
                                index: 'authItem'+varContext.authArray.length
                            });
                            varContext.authArray.find(item => item.Name == curMap.familyName)['HasAuthority'] =true;
                            console.log('authArray: '+JSON.stringify(varContext.authArray.find(item => item.Name == curMap.familyName).Authority));
                        }
                        varContext.orderObject['MarginApprover'] =readMargins.directorId;
                    }
                } 

                // if (needMarkManagApprove){
                //     if ('marketingManagerId' in projMargins){
                //         varContext.orderObject['MarginApprover'] =projMargins.marketingManagerId;
                //         varContext.orderObject['needsMarketMangr'] =true;
                //     }
                    
                // }
                // if (margFamilyMargApprov && curMap['hasNullCost'] ==false){
                //     let valAuth = varContext.authArray.find(item => item.Name == curMap.familyName);
                //     console.log('precisa aprovador da margem: "' +readMargins.directorName);
                //     if(!valAuth?.Authority?.find(item => item.name == readMargins.directorName + ' - Aprovação de margem')){                        
                //         varContext.authArray.find(item => item.Name == curMap.familyName)?.Authority.push({
                //             name: readMargins.directorName + ' - Aprovação de margem',
                //             index: 'authItem'+varContext.authArray.length});
                //     }
                //     varContext.orderObject['MarginApprover'] =readMargins.directorId;
                // }
                // if (curMap['hasNullCost'] ==true){
                //     let valAuth = varContext.authArray.find(item => item.Name == curMap.familyName);
                //     if(!valAuth?.Authority?.find(item => item.name == readMargins.directorName + ' - Aprovação por Custo')){                        
                //         varContext.authArray.find(item => item.Name == curMap.familyName)?.Authority.push({
                //             name: readMargins.directorName + ' - Aprovação por Custo',
                //             index: 'authItem'+varContext.authArray.length});
                //     }
                //     varContext.orderObject['MarginApprover'] =readMargins.directorId;                    
                // }
                // if (hasNullZeroMargin && varContext.orderObject.marketingManagerName !=null){
                //     let valAuth = varContext.authArray.find(item => item.Name == curMap.familyName);
                //     var message =varContext.orderObject.marketingManagerName + ' - Aprovação por Marketing';
                //     if(!valAuth?.Authority?.find(item => item.name == message)){                        
                //         varContext.authArray.find(item => item.Name == curMap.familyName)?.Authority.push({
                //             name: message,
                //             index: 'authItem'+varContext.authArray.length});
                //     }
                //     varContext.orderObject['MarginApprover'] =projMargins.marketingManagerId;                     
                // }
                // console.log('curMap: ' +JSON.stringify(curMap));
            })

        })


        console.log('Finished findAuth');*/
    }

export { getBaseDataUtils, findAuth };