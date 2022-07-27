@RestResource(urlMapping='/ForcaAgroApp/1_0/loadBaseData/*')
global with sharing class ForcaAgroApp_loadBaseData {
	public ForcaAgroApp_loadBaseData() {}

    public static final Long INITIAL_SYNC = 1430426733;

    @HttpPost
    global static ReturnData doPost(SyncStampData lastSyncStamp) {
        System.debug('lastSyncStamp =>' + lastSyncStamp);

        Integer loadedRowCount  = 0, 
                queryLimit      = 10000;
        Boolean hasMore         = false,
                specific        = false;

        String minVersion = AppVersion__c.getValues('Brota')?.MinVersion__c;

        ReturnData returnData = new ReturnData(
            new UserData(
                UserInfo.getUserId(),
                UserInfo.getFirstName() + ' ' + UserInfo.getLastName(),
                UserInfo.getUserName()
            ),
            minVersion
        );

        try{
            { // Object => Account
                if (availableRows(queryLimit, 'Account')) {
                    System.debug('// Object => Account');
                    ForcaAgroApp_BaseRequest.AccountRequest accountRequest = new ForcaAgroApp_BaseRequest.AccountRequest();

                    specific = accountRequest.fillRequest(
                        new RequestConfig.AccountConfig(
                            validateLastSync(lastSyncStamp.accountSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, accountRequest.getSize());
                    lastSyncStamp.accountSync = accountRequest.getLastStamp();
                    returnData.addRequest(accountRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }
            
            { // Object => ListPrice__c
                if (availableRows(queryLimit, 'ListPrice__c')) {
                    System.debug('// Object => ListPrice__c');
                    ForcaAgroApp_BaseRequest.ListPriceRequest listPriceRequest = new ForcaAgroApp_BaseRequest.ListPriceRequest();

                    specific = listPriceRequest.fillRequest(
                        new RequestConfig.ListPriceConfig(
                            validateLastSync(lastSyncStamp.listPriceSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, listPriceRequest.getSize());
                    lastSyncStamp.listPriceSync = listPriceRequest.getLastStamp();
                    returnData.addRequest(listPriceRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => Crop__c
                if (availableRows(queryLimit, 'Crop__c')) {
                    System.debug('// Object => Crop__c');
                    ForcaAgroApp_BaseRequest.CropRequest cropRequest = new ForcaAgroApp_BaseRequest.CropRequest();

                    specific = cropRequest.fillRequest(
                        new RequestConfig.CropConfig(
                            validateLastSync(lastSyncStamp.cropSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, cropRequest.getSize());
                    lastSyncStamp.cropSync = cropRequest.getLastStamp();
                    returnData.addRequest(cropRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => PaymentCondition__c
                if (availableRows(queryLimit, 'PaymentCondition__c')) {
                    System.debug('// Object => PaymentCondition__c');
                    ForcaAgroApp_BaseRequest.PaymentConditionRequest paymentConditionRequest = new ForcaAgroApp_BaseRequest.PaymentConditionRequest();

                    specific = paymentConditionRequest.fillRequest(
                        new RequestConfig.PaymentConditionConfig(
                            validateLastSync(lastSyncStamp.paymentConditionSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, paymentConditionRequest.getSize());
                    lastSyncStamp.paymentConditionSync = paymentConditionRequest.getLastStamp();
                    returnData.addRequest(paymentConditionRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => Family__c
                if (availableRows(queryLimit, 'Family__c')) {
                    System.debug('// Object => Family__c');
                    ForcaAgroApp_BaseRequest.FamilyRequest familyRequest = new ForcaAgroApp_BaseRequest.FamilyRequest();

                    specific = familyRequest.fillRequest(
                        new RequestConfig.FamilyConfig(
                            validateLastSync(lastSyncStamp.familySync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, familyRequest.getSize());
                    lastSyncStamp.familySync = familyRequest.getLastStamp();
                    returnData.addRequest(familyRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => Product2
                if (availableRows(queryLimit, 'Product2')) {
                    System.debug('// Object => Product2');
                    ForcaAgroApp_BaseRequest.ProductRequest productRequest = new ForcaAgroApp_BaseRequest.ProductRequest();

                    specific = productRequest.fillRequest(
                        new RequestConfig.ProductConfig(
                            validateLastSync(lastSyncStamp.productSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, productRequest.getSize());
                    lastSyncStamp.productSync = productRequest.getLastStamp();
                    returnData.addRequest(productRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => Culture__c
                if (availableRows(queryLimit, 'Culture__c')) {
                    System.debug('// Object => Culture__c');
                    ForcaAgroApp_BaseRequest.CultureRequest cultureRequest = new ForcaAgroApp_BaseRequest.CultureRequest();

                    specific = cultureRequest.fillRequest(
                        new RequestConfig.CultureConfig(
                            validateLastSync(lastSyncStamp.cultureSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, cultureRequest.getSize());
                    lastSyncStamp.cultureSync = cultureRequest.getLastStamp();
                    returnData.addRequest(cultureRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => Freight__c
                if (availableRows(queryLimit, 'Freight__c')) {
                    System.debug('// Object => Freight__c');
                    ForcaAgroApp_BaseRequest.FreightRequest freightRequest = new ForcaAgroApp_BaseRequest.FreightRequest();

                    specific = freightRequest.fillRequest(
                        new RequestConfig.FreightConfig(
                            validateLastSync(lastSyncStamp.freightSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, freightRequest.getSize());
                    lastSyncStamp.freightSync = freightRequest.getLastStamp();
                    returnData.addRequest(freightRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => Order
                if (availableRows(queryLimit, 'Order')) {
                    System.debug('// Object => Order');
                    ForcaAgroApp_BaseRequest.OrderRequest orderRequest = new ForcaAgroApp_BaseRequest.OrderRequest();

                    specific = orderRequest.fillRequest(
                        new RequestConfig.OrderConfig(
                            validateLastSync(lastSyncStamp.orderSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, orderRequest.getSize());
                    lastSyncStamp.orderSync = orderRequest.getLastStamp();
                    returnData.addRequest(orderRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => OrderItem
                if (availableRows(queryLimit, 'OrderItem')) {
                    System.debug('// Object => OrderItem');
                    ForcaAgroApp_BaseRequest.OrderItemRequest orderItemRequest = new ForcaAgroApp_BaseRequest.OrderItemRequest();

                    specific = orderItemRequest.fillRequest(
                        new RequestConfig.OrderItemConfig(
                            validateLastSync(lastSyncStamp.orderItemSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, orderItemRequest.getSize());
                    lastSyncStamp.orderItemSync = orderItemRequest.getLastStamp();
                    returnData.addRequest(orderItemRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => ShippingDivision__c
                if (availableRows(queryLimit, 'ShippingDivision__c')) {
                    System.debug('// Object => ShippingDivision__c');
                    ForcaAgroApp_BaseRequest.ShippingDivisionRequest shippingDivisionRequest = new ForcaAgroApp_BaseRequest.ShippingDivisionRequest();

                    specific = shippingDivisionRequest.fillRequest(
                        new RequestConfig.ShippingDivisionConfig(
                            validateLastSync(lastSyncStamp.shippingDivisionSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, shippingDivisionRequest.getSize());
                    lastSyncStamp.shippingDivisionSync = shippingDivisionRequest.getLastStamp();
                    returnData.addRequest(shippingDivisionRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => CustomerPerOrg__c
                if (availableRows(queryLimit, 'CustomerPerOrg__c')) {
                    System.debug('// Object => CustomerPerOrg__c');
                    ForcaAgroApp_BaseRequest.CustomerPerOrgRequest customerPerOrgRequest = new ForcaAgroApp_BaseRequest.CustomerPerOrgRequest();

                    specific = customerPerOrgRequest.fillRequest(
                        new RequestConfig.CustomerPerOrgConfig(
                            validateLastSync(lastSyncStamp.customerPerOrgSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, customerPerOrgRequest.getSize());
                    lastSyncStamp.customerPerOrgSync = customerPerOrgRequest.getLastStamp();
                    returnData.addRequest(customerPerOrgRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => FinancialDueDate__c
                if (lastSyncStamp.financialDueDateSync != null && availableRows(queryLimit, 'FinancialDueDate__c')) {
                    System.debug('// Object => FinancialDueDate__c');
                    ForcaAgroApp_BaseRequest.FinancialDueDateRequest financialDueDateRequest = new ForcaAgroApp_BaseRequest.FinancialDueDateRequest();

                    specific = financialDueDateRequest.fillRequest(
                        new RequestConfig.FinancialDueDateConfig(
                            validateLastSync(lastSyncStamp.financialDueDateSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, financialDueDateRequest.getSize());
                    lastSyncStamp.financialDueDateSync = financialDueDateRequest.getLastStamp();
                    returnData.addRequest(financialDueDateRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => FinancialDueDate__c
                if (lastSyncStamp.fieldDependencySync != null && availableRows(queryLimit, 'FieldDependency__c')) {
                    System.debug('// Object => FieldDependency__c');
                    ForcaAgroApp_BaseRequest.FieldDependencyRequest fieldDependencyRequest = new ForcaAgroApp_BaseRequest.FieldDependencyRequest();

                    specific = fieldDependencyRequest.fillRequest(
                        new RequestConfig.FieldDependencyConfig(
                            validateLastSync(lastSyncStamp.fieldDependencySync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, fieldDependencyRequest.getSize());
                    lastSyncStamp.fieldDependencySync = fieldDependencyRequest.getLastStamp();
                    returnData.addRequest(fieldDependencyRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => RangeDiscount__c
                if (lastSyncStamp.rangeDiscountSync != null && availableRows(queryLimit, 'RangeDiscount__c')) {
                    System.debug('// Object => RangeDiscount__c');
                    ForcaAgroApp_BaseRequest.RangeDiscountRequest rangeDiscountRequest = new ForcaAgroApp_BaseRequest.RangeDiscountRequest();

                    specific = rangeDiscountRequest.fillRequest(
                        new RequestConfig.RangeDiscountConfig(
                            validateLastSync(lastSyncStamp.rangeDiscountSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, rangeDiscountRequest.getSize());
                    lastSyncStamp.rangeDiscountSync = rangeDiscountRequest.getLastStamp();
                    returnData.addRequest(rangeDiscountRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => ClientCNDState__c
                if (lastSyncStamp.clientCNDStateSync != null && availableRows(queryLimit, 'ClientCNDState__c')) {
                    System.debug('// Object => ClientCNDState__c');
                    ForcaAgroApp_BaseRequest.ClientCNDStateRequest clientCNDStateRequest = new ForcaAgroApp_BaseRequest.ClientCNDStateRequest();

                    specific = clientCNDStateRequest.fillRequest(
                        new RequestConfig.ClientCNDStateConfig(
                            validateLastSync(lastSyncStamp.clientCNDStateSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, clientCNDStateRequest.getSize());
                    lastSyncStamp.clientCNDStateSync = clientCNDStateRequest.getLastStamp();
                    returnData.addRequest(clientCNDStateRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => OrderTypes__c
                if (lastSyncStamp.orderTypesSync != null && availableRows(queryLimit, 'OrderTypes__c')) {
                    System.debug('// Object => OrderTypes__c');
                    ForcaAgroApp_BaseRequest.OrderTypesRequest orderTypesRequest = new ForcaAgroApp_BaseRequest.OrderTypesRequest();

                    specific = orderTypesRequest.fillRequest(
                        new RequestConfig.OrderTypesConfig(
                            validateLastSync(lastSyncStamp.orderTypesSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, orderTypesRequest.getSize());
                    lastSyncStamp.orderTypesSync = orderTypesRequest.getLastStamp();
                    returnData.addRequest(orderTypesRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => ProductManagement__c
                if (lastSyncStamp.productManagementSync != null && availableRows(queryLimit, 'ProductManagement__c')) {
                    System.debug('// Object => ProductManagement__c');
                    ForcaAgroApp_BaseRequest.ProductManagementRequest productManagementRequest = new ForcaAgroApp_BaseRequest.ProductManagementRequest();

                    specific = productManagementRequest.fillRequest(
                        new RequestConfig.ProductManagementConfig(
                            validateLastSync(lastSyncStamp.productManagementSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, productManagementRequest.getSize());
                    lastSyncStamp.productManagementSync = productManagementRequest.getLastStamp();
                    returnData.addRequest(productManagementRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => Campaign
                if (lastSyncStamp.campaignSync != null && availableRows(queryLimit, 'Campaign')) {
                    System.debug('// Object => Campaign');
                    ForcaAgroApp_BaseRequest.CampaignRequest campaignRequest = new ForcaAgroApp_BaseRequest.CampaignRequest();

                    specific = campaignRequest.fillRequest(
                        new RequestConfig.CampaignConfig(
                            validateLastSync(lastSyncStamp.campaignSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, campaignRequest.getSize());
                    lastSyncStamp.campaignSync = campaignRequest.getLastStamp();
                    returnData.addRequest(campaignRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => CampaignProduct__c
                if (lastSyncStamp.campaignProductSync != null && availableRows(queryLimit, 'CampaignProduct__c')) {
                    System.debug('// Object => CampaignProduct__c');
                    ForcaAgroApp_BaseRequest.CampaignProductRequest campaignProductRequest = new ForcaAgroApp_BaseRequest.CampaignProductRequest();

                    specific = campaignProductRequest.fillRequest(
                        new RequestConfig.CampaignProductConfig(
                            validateLastSync(lastSyncStamp.campaignProductSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, campaignProductRequest.getSize());
                    lastSyncStamp.campaignProductSync = campaignProductRequest.getLastStamp();
                    returnData.addRequest(campaignProductRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => CampaignRule__c
                if (lastSyncStamp.campaignRuleSync != null && availableRows(queryLimit, 'CampaignRule__c')) {
                    System.debug('// Object => CampaignRule__c');
                    ForcaAgroApp_BaseRequest.CampaignRuleRequest campaignRuleRequest = new ForcaAgroApp_BaseRequest.CampaignRuleRequest();

                    specific = campaignRuleRequest.fillRequest(
                        new RequestConfig.CampaignRuleConfig(
                            validateLastSync(lastSyncStamp.campaignRuleSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, campaignRuleRequest.getSize());
                    lastSyncStamp.campaignRuleSync = campaignRuleRequest.getLastStamp();
                    returnData.addRequest(campaignRuleRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => CampaignOrderItem__c
                if (lastSyncStamp.campaignOrderItemSync != null && availableRows(queryLimit, 'CampaignOrderItem__c')) {
                    System.debug('// Object => CampaignOrderItem__c');
                    ForcaAgroApp_BaseRequest.CampaignOrderItemRequest campaignOrderItemRequest = new ForcaAgroApp_BaseRequest.CampaignOrderItemRequest();

                    specific = campaignOrderItemRequest.fillRequest(
                        new RequestConfig.CampaignOrderItemConfig(
                            validateLastSync(lastSyncStamp.campaignOrderItemSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, campaignOrderItemRequest.getSize());
                    lastSyncStamp.campaignOrderItemSync = campaignOrderItemRequest.getLastStamp();
                    returnData.addRequest(campaignOrderItemRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => CampaignTargetAudience__c
                if (lastSyncStamp.campaignTargetAudienceSync != null && availableRows(queryLimit, 'CampaignTargetAudience__c')) {
                    System.debug('// Object => CampaignTargetAudience__c');
                    ForcaAgroApp_BaseRequest.CampaignTargetAudienceRequest campaignTargetAudienceRequest = new ForcaAgroApp_BaseRequest.CampaignTargetAudienceRequest();

                    specific = campaignTargetAudienceRequest.fillRequest(
                        new RequestConfig.CampaignTargetAudienceConfig(
                            validateLastSync(lastSyncStamp.campaignTargetAudienceSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, campaignTargetAudienceRequest.getSize());
                    lastSyncStamp.campaignTargetAudienceSync = campaignTargetAudienceRequest.getLastStamp();
                    returnData.addRequest(campaignTargetAudienceRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => Event
                if (lastSyncStamp.eventSync != null && availableRows(queryLimit, 'Event')) {
                    System.debug('// Object => Event');
                    ForcaAgroApp_BaseRequest.EventRequest eventRequest = new ForcaAgroApp_BaseRequest.EventRequest();

                    specific = eventRequest.fillRequest(
                        new RequestConfig.EventConfig(
                            validateLastSync(lastSyncStamp.eventSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, eventRequest.getSize());
                    lastSyncStamp.eventSync = eventRequest.getLastStamp();
                    returnData.addRequest(eventRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => EventTypes__c
                if (lastSyncStamp.eventTypesSync != null && availableRows(queryLimit, 'EventTypes__c')) {
                    System.debug('// Object => EventTypes__c');
                    ForcaAgroApp_BaseRequest.EventTypesRequest eventTypesRequest = new ForcaAgroApp_BaseRequest.EventTypesRequest();

                    specific = eventTypesRequest.fillRequest(
                        new RequestConfig.EventTypesConfig(
                            validateLastSync(lastSyncStamp.eventTypesSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, eventTypesRequest.getSize());
                    lastSyncStamp.eventTypesSync = eventTypesRequest.getLastStamp();
                    returnData.addRequest(eventTypesRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => RatingCredit__c
                if (lastSyncStamp.ratingCreditSync != null && availableRows(queryLimit, 'RatingCredit__c')) {
                    System.debug('// Object => RatingCredit__c');
                    ForcaAgroApp_BaseRequest.RatingCreditRequest ratingCreditRequest = new ForcaAgroApp_BaseRequest.RatingCreditRequest();

                    specific = ratingCreditRequest.fillRequest(
                        new RequestConfig.RatingCreditConfig(
                            validateLastSync(lastSyncStamp.ratingCreditSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, ratingCreditRequest.getSize());
                    lastSyncStamp.ratingCreditSync = ratingCreditRequest.getLastStamp();
                    returnData.addRequest(ratingCreditRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => ProjectedMargin__c
                if (lastSyncStamp.projectedMarginSync != null && availableRows(queryLimit, 'ProjectedMargin__c')) {
                    System.debug('// Object => ProjectedMargin__c');
                    ForcaAgroApp_BaseRequest.ProjectedMarginRequest projectedMarginRequest = new ForcaAgroApp_BaseRequest.ProjectedMarginRequest();

                    specific = projectedMarginRequest.fillRequest(
                        new RequestConfig.ProjectedMarginConfig(
                            validateLastSync(lastSyncStamp.projectedMarginSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, projectedMarginRequest.getSize());
                    lastSyncStamp.projectedMarginSync = projectedMarginRequest.getLastStamp();
                    returnData.addRequest(projectedMarginRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }
            
            { // Object => DelimitedLand__c
                if (lastSyncStamp.delimitedLandSync != null && availableRows(queryLimit, 'DelimitedLand__c')) {
                    System.debug('// Object => DelimitedLand__c');
                    ForcaAgroApp_BaseRequest.DelimitedLandRequest delimitedLandRequest = new ForcaAgroApp_BaseRequest.DelimitedLandRequest();

                    specific = delimitedLandRequest.fillRequest(
                        new RequestConfig.DelimitedLandConfig(
                            validateLastSync(lastSyncStamp.delimitedLandSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, delimitedLandRequest.getSize());
                    lastSyncStamp.delimitedLandSync = delimitedLandRequest.getLastStamp();
                    returnData.addRequest(delimitedLandRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => Case
                if (lastSyncStamp.caseSync != null && availableRows(queryLimit, 'Case')) {
                    System.debug('// Object => Case');
                    ForcaAgroApp_BaseRequest.caseRequest caseRequest = new ForcaAgroApp_BaseRequest.CaseRequest();

                    specific = caseRequest.fillRequest(
                        new RequestConfig.CaseConfig(
                            validateLastSync(lastSyncStamp.caseSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, caseRequest.getSize());
                    lastSyncStamp.caseSync = caseRequest.getLastStamp();
                    returnData.addRequest(caseRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => DelimitedLandCultures__c
                if (lastSyncStamp.delimitedLandCulturesSync != null && availableRows(queryLimit, 'DelimitedLandCultures__c')) {
                    System.debug('// Object => DelimitedLandCultures__c');
                    ForcaAgroApp_BaseRequest.DelimitedLandCulturesRequest delimitedLandCulturesRequest = new ForcaAgroApp_BaseRequest.DelimitedLandCulturesRequest();

                    specific = delimitedLandCulturesRequest.fillRequest(
                        new RequestConfig.DelimitedLandCulturesConfig(
                            validateLastSync(lastSyncStamp.delimitedLandCulturesSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, delimitedLandCulturesRequest.getSize());
                    lastSyncStamp.delimitedLandCulturesSync = delimitedLandCulturesRequest.getLastStamp();
                    returnData.addRequest(delimitedLandCulturesRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => user
                if (lastSyncStamp.userSync != null && availableRows(queryLimit, 'user')) {
                    System.debug('// Object => user');
                    ForcaAgroApp_BaseRequest.UserRequest userRequest = new ForcaAgroApp_BaseRequest.UserRequest();

                    specific = userRequest.fillRequest(
                        new RequestConfig.UserConfig(
                            validateLastSync(lastSyncStamp.userSync),
                            queryLimit
                        )
                    );

                    queryLimit = updateLimit(queryLimit, userRequest.getSize());
                    lastSyncStamp.userSync = userRequest.getLastStamp();
                    returnData.addRequest(userRequest);
                    hasMore = verifyHasMore(hasMore, specific);
                }
            }

            { // Object => Config
                if (availableRows(queryLimit, 'Config')) {
                    System.debug('// Object => Config');

                    Map<Id, List<GetAccountTeam.SalesTeamResponse>> salesTeamMap = GetAccountTeam.GetAccountTeam(null, false);
                    
                    List<GetAccountTeam.SalesTeamResponse> salesTeamRequest = new List<GetAccountTeam.SalesTeamResponse>();
                    for (String userId : salesTeamMap.keySet()) {
                        salesTeamRequest.addAll(salesTeamMap.get(userId));
                    }

                    returnData.addRequest(salesTeamRequest);


                    List<ForcaAgroApp_BaseRequest.ActivitySectorRequest> activitySectorRequest = new List<ForcaAgroApp_BaseRequest.ActivitySectorRequest>();
                    Schema.DescribeFieldResult activitySectorFieldResult = Order.ActivitySector__c.getDescribe();
                    List<Schema.PicklistEntry> activitySectorValues = activitySectorFieldResult.getPicklistValues();
                    for(Schema.PicklistEntry activitySectorValue : activitySectorValues){
                        activitySectorRequest.add(new ForcaAgroApp_BaseRequest.ActivitySectorRequest(activitySectorValue.getValue(), activitySectorValue.getLabel()));
                    }
                    returnData.addRequest(activitySectorRequest);


                    List<ForcaAgroApp_BaseRequest.PaymentMethodRequest> paymentMethodRequest = new List<ForcaAgroApp_BaseRequest.PaymentMethodRequest>();
                    Schema.DescribeFieldResult paymentMethodFieldResult = Order.PaymentForm__c.getDescribe();
                    List<Schema.PicklistEntry> paymentMethodValues = paymentMethodFieldResult.getPicklistValues();
                    for(Schema.PicklistEntry paymentMethodValue : paymentMethodValues){
                        paymentMethodRequest.add(new ForcaAgroApp_BaseRequest.PaymentMethodRequest(paymentMethodValue.getValue(), paymentMethodValue.getLabel()));
                    }
                    returnData.addRequest(paymentMethodRequest);


                    List<ForcaAgroApp_BaseRequest.SalesConditionRequest> salesConditionRequest = new List<ForcaAgroApp_BaseRequest.SalesConditionRequest>();
                    for(SalesCondition__c salesCondition : SalesConditionDAO.getActiveSalesConditions(new Set<String>{'Id, Name, ExternalId__c'})){
                        salesConditionRequest.add(new ForcaAgroApp_BaseRequest.SalesConditionRequest(salesCondition.ExternalId__c, salesCondition.Name));
                    }
                    returnData.addRequest(salesConditionRequest);

                    List<ForcaAgroApp_BaseRequest.OrderStatusRequest> orderStatusRequest = new List<ForcaAgroApp_BaseRequest.OrderStatusRequest>();
                    Schema.DescribeFieldResult orderStatusFieldResult = Order.StatusSF__c.getDescribe();
                    List<Schema.PicklistEntry> orderStatusValues = orderStatusFieldResult.getPicklistValues();
                    for(Schema.PicklistEntry orderStatusValue : orderStatusValues){
                        orderStatusRequest.add(new ForcaAgroApp_BaseRequest.OrderStatusRequest(orderStatusValue.getValue(), orderStatusValue.getLabel()));
                    }
                    returnData.addRequest(orderStatusRequest);

                    List<ForcaAgroApp_BaseRequest.OrderStatusSAPRequest> orderStatusSAPRequest = new List<ForcaAgroApp_BaseRequest.OrderStatusSAPRequest>();
                    Schema.DescribeFieldResult orderStatusSAPFieldResult = Order.StatusSAP__c.getDescribe();
                    List<Schema.PicklistEntry> orderStatusSAPValues = orderStatusSAPFieldResult.getPicklistValues();
                    for(Schema.PicklistEntry orderStatusValue : orderStatusSAPValues){
                        orderStatusSAPRequest.add(new ForcaAgroApp_BaseRequest.OrderStatusSAPRequest(orderStatusValue.getValue(), orderStatusValue.getLabel()));
                    }
                    returnData.addRequest(orderStatusSAPRequest);

                    List<ForcaAgroApp_BaseRequest.BarterTypeRequest> barterTypeRequest = new List<ForcaAgroApp_BaseRequest.BarterTypeRequest>();
                    Schema.DescribeFieldResult barterTypeFieldResult = Order.BarterType__c.getDescribe();
                    List<Schema.PicklistEntry> barterTypeValues = barterTypeFieldResult.getPicklistValues();
                    for(Schema.PicklistEntry barterTypeValue : barterTypeValues){
                        barterTypeRequest.add(new ForcaAgroApp_BaseRequest.BarterTypeRequest(barterTypeValue.getValue(), barterTypeValue.getLabel()));
                    }
                    returnData.addRequest(barterTypeRequest);

                    List<ForcaAgroApp_BaseRequest.CommodityRequest> commodityRequest = new List<ForcaAgroApp_BaseRequest.CommodityRequest>();
                    Schema.DescribeFieldResult commodityFieldResult = Order.Commodity__c.getDescribe();
                    List<Schema.PicklistEntry> commodityValues = commodityFieldResult.getPicklistValues();
                    for(Schema.PicklistEntry commodityValue : commodityValues){
                        commodityRequest.add(new ForcaAgroApp_BaseRequest.CommodityRequest(commodityValue.getValue(), commodityValue.getLabel()));
                    }
                    returnData.addRequest(commodityRequest);
                    
                    List<ForcaAgroApp_BaseRequest.OrderTypeRequest> orderTypeRequest = new List<ForcaAgroApp_BaseRequest.OrderTypeRequest>();
                    for(RecordType recordType : [SELECT Id, DeveloperName, Name FROM RecordType WHERE SobjectType = 'Order' AND IsActive = true]){
                        orderTypeRequest.add(new ForcaAgroApp_BaseRequest.OrderTypeRequest(recordType.DeveloperName, recordType.Name));
                    }
                    returnData.addRequest(orderTypeRequest);

                    List<ForcaAgroApp_BaseRequest.UnitMeasurementRequest> unitMeasurementRequest = new List<ForcaAgroApp_BaseRequest.UnitMeasurementRequest>();
                    Schema.DescribeFieldResult unitMeasurementFieldResult = DelimitedLand__c.UnitMeasurement__c.getDescribe();
                    List<Schema.PicklistEntry> unitMeasurementValues = unitMeasurementFieldResult.getPicklistValues();
                    for(Schema.PicklistEntry unitMeasurementValue : unitMeasurementValues){
                        unitMeasurementRequest.add(new ForcaAgroApp_BaseRequest.UnitMeasurementRequest(unitMeasurementValue.getValue(), unitMeasurementValue.getLabel()));
                    }
                    returnData.addRequest(unitMeasurementRequest);

                    List<ForcaAgroApp_BaseRequest.TechnologicalLevelRequest> technologicalLevelRequest = new List<ForcaAgroApp_BaseRequest.TechnologicalLevelRequest>();
                    Schema.DescribeFieldResult technologicalLevalFieldResult = DelimitedLandCultures__c.TechnologicalLevel__c.getDescribe();
                    List<Schema.PicklistEntry> technologicalLevalValues = technologicalLevalFieldResult.getPicklistValues();
                    for(Schema.PicklistEntry technologicalValue : technologicalLevalValues){
                        technologicalLevelRequest.add(new ForcaAgroApp_BaseRequest.TechnologicalLevelRequest(technologicalValue.getValue(), technologicalValue.getLabel()));
                    }
                    returnData.addRequest(technologicalLevelRequest);

                    List<ForcaAgroApp_BaseRequest.IncidentTypeRequest> incidentTypeRequest = new List<ForcaAgroApp_BaseRequest.IncidentTypeRequest>();
                    Schema.DescribeFieldResult incidentTypeFieldResult = Case.IncidentTypePicklist__c.getDescribe();
                    List<Schema.PicklistEntry> incidentTypeValues = incidentTypeFieldResult.getPicklistValues();
                    for(Schema.PicklistEntry incidentTypeValue : incidentTypeValues){
                        incidentTypeRequest.add(new ForcaAgroApp_BaseRequest.IncidentTypeRequest(incidentTypeValue.getValue(), incidentTypeValue.getLabel()));
                    }
                    returnData.addRequest(incidentTypeRequest);

                    List<ForcaAgroApp_BaseRequest.CaseOriginRequest> caseOriginRequest = new List<ForcaAgroApp_BaseRequest.CaseOriginRequest>();
                    Schema.DescribeFieldResult caseOriginFieldResult = Case.Origin.getDescribe();
                    List<Schema.PicklistEntry> caseOriginValues = caseOriginFieldResult.getPicklistValues();
                    for(Schema.PicklistEntry caseOriginValue : caseOriginValues){
                        caseOriginRequest.add(new ForcaAgroApp_BaseRequest.CaseOriginRequest(caseOriginValue.getValue(), caseOriginValue.getLabel()));
                    }
                    returnData.addRequest(caseOriginRequest);

                    List<ForcaAgroApp_BaseRequest.CustomLabelRequest> customLabelRequest = new List<ForcaAgroApp_BaseRequest.CustomLabelRequest>();
                    customLabelRequest.add(new ForcaAgroApp_BaseRequest.CustomLabelRequest('PDF_Obs_Title', System.Label.OrderPDF_ObsTitle));
                    customLabelRequest.add(new ForcaAgroApp_BaseRequest.CustomLabelRequest('PDF_Obs_Text', System.Label.OrderPDF_ObsText));
                    customLabelRequest.add(new ForcaAgroApp_BaseRequest.CustomLabelRequest('ForcaAgroSiteURL', System.Label.ForcaAgroSiteURL));
                    customLabelRequest.add(new ForcaAgroApp_BaseRequest.CustomLabelRequest('DeletedProductAlert', System.Label.DeletedProductAlert));
                    customLabelRequest.add(new ForcaAgroApp_BaseRequest.CustomLabelRequest('FiscalDomicileAlert', System.Label.FiscalDomicileAlert));
                    customLabelRequest.add(new ForcaAgroApp_BaseRequest.CustomLabelRequest('StockAlert', System.Label.StockAlert));
                    returnData.addRequest(customLabelRequest);
                    
                    returnData.addRequest(MargemMotivoRecusa__c.getValues('Margem Pedido').Margem__c);
                    hasMore = false;
                }
            }

            {
                returnData.addSyncStamps(lastSyncStamp);
                returnData.addHasMore(hasMore);
                returnData.updateUserData();
            }
        }
        catch(Exception e){
            returnData.error = new ReturnError(e.getMessage(), e.getStackTraceString());
            System.debug(e.getMessage());
        }

        return returnData;
    }

    global static Boolean availableRows(Integer queryLimit, String type) {
        System.debug(String.format('[QUERYLIMIT] {0} => {1}', new List<String>{String.valueOf(queryLimit), type}));
        return queryLimit > 0;
    }

    global static Integer updateLimit(Integer queryLimit, Integer requestSize) {
        return queryLimit - requestSize;
    }

    global static SyncData validateLastSync(SyncData syncData){
        Long INITIAL_SYNC = 1430426733;
        
        if (syncData.lastSyncStamp == null || syncData.lastSyncStamp < INITIAL_SYNC)
            return new SyncData('', INITIAL_SYNC);
        else 
            return syncData;
    }

    global static Boolean verifyHasMore(Boolean hasMore, Boolean specific){
        return hasMore || specific;
    }

    global class SyncData {
        public Long     lastSyncStamp {get; set;}
        public String   lastSyncId {get; set;}

        public SyncData (String lastSyncId, Long lastSyncStamp) {
            this.lastSyncId    = lastSyncId;
            this.lastSyncStamp = lastSyncStamp;
        }
    }

    global class SyncStampData {
        public String   appVersion                  {get;set;}
        public SyncData accountSync                 {get;set;}
        public SyncData listPriceSync               {get;set;}
        public SyncData cropSync                    {get;set;}
        public SyncData paymentConditionSync        {get;set;}
        public SyncData familySync                  {get;set;}
        public SyncData productSync                 {get;set;}
        public SyncData cultureSync                 {get;set;}
        public SyncData freightSync                 {get;set;}
        public SyncData orderSync                   {get;set;}
        public SyncData orderItemSync               {get;set;}
        public SyncData shippingDivisionSync        {get;set;}
        public SyncData customerPerOrgSync          {get;set;}
        public SyncData financialDueDateSync        {get;set;}
        public SyncData fieldDependencySync         {get;set;}
        public SyncData rangeDiscountSync           {get;set;}
        public SyncData clientCNDStateSync          {get;set;}
        public SyncData orderTypesSync              {get;set;}
        public SyncData productManagementSync       {get;set;}
        public SyncData campaignSync                {get;set;}
        public SyncData campaignProductSync         {get;set;}
        public SyncData campaignRuleSync            {get;set;}
        public SyncData campaignOrderItemSync       {get;set;}
        public SyncData campaignTargetAudienceSync  {get;set;}
        public SyncData eventSync                   {get;set;}
        public SyncData eventTypesSync              {get;set;}
        public SyncData userSync                    {get;set;}
        public SyncData ratingCreditSync            {get;set;}
        public Boolean  geoLocationPermission       {get;set;}
        public String   checkInDate                 {get;set;}
        public String   checkInHour                 {get;set;}
        public SyncData projectedMarginSync         {get;set;}
        public SyncData delimitedLandSync           {get;set;}
        public SyncData delimitedLandCulturesSync   {get;set;}
        public SyncData caseSync                    {get;set;}
    }
    
    global class ReturnData{
        public UserData userData;
        public SyncStampData syncData;
        public ReturnError error;
        public Boolean hasMore;
        public String minVersion;

        public ForcaAgroApp_BaseRequest.AccountRequest accountRequest;
        public ForcaAgroApp_BaseRequest.ListPriceRequest listPriceRequest;
        public ForcaAgroApp_BaseRequest.CropRequest cropRequest;
        public ForcaAgroApp_BaseRequest.PaymentConditionRequest paymentConditionRequest;
        public ForcaAgroApp_BaseRequest.FamilyRequest familyRequest;
        public ForcaAgroApp_BaseRequest.ProductRequest productRequest;
        public ForcaAgroApp_BaseRequest.CultureRequest cultureRequest;
        public ForcaAgroApp_BaseRequest.FreightRequest freightRequest;
        public ForcaAgroApp_BaseRequest.OrderRequest orderRequest;
        public ForcaAgroApp_BaseRequest.OrderItemRequest orderItemRequest;
        public ForcaAgroApp_BaseRequest.ShippingDivisionRequest shippingDivisionRequest;
        public ForcaAgroApp_BaseRequest.CustomerPerOrgRequest customerPerOrgRequest;
        public ForcaAgroApp_BaseRequest.FinancialDueDateRequest financialDueDateRequest;
        public ForcaAgroApp_BaseRequest.FieldDependencyRequest fieldDependencyRequest;
        public ForcaAgroApp_BaseRequest.RangeDiscountRequest rangeDiscountRequest;
        public ForcaAgroApp_BaseRequest.ClientCNDStateRequest clientCNDStateRequest;
        public ForcaAgroApp_BaseRequest.OrderTypesRequest orderTypesRequest;
        public ForcaAgroApp_BaseRequest.ProductManagementRequest productManagementRequest;
        public ForcaAgroApp_BaseRequest.CampaignRequest campaignRequest;
        public ForcaAgroApp_BaseRequest.CampaignProductRequest campaignProductRequest;
        public ForcaAgroApp_BaseRequest.CampaignRuleRequest campaignRuleRequest;
        public ForcaAgroApp_BaseRequest.CampaignOrderItemRequest campaignOrderItemRequest; 
        public ForcaAgroApp_BaseRequest.CampaignTargetAudienceRequest campaignTargetAudienceRequest; 
        public ForcaAgroApp_BaseRequest.EventRequest eventRequest;
        public ForcaAgroApp_BaseRequest.EventTypesRequest eventTypesRequest;
        public ForcaAgroApp_BaseRequest.RatingCreditRequest ratingCreditRequest;
        public ForcaAgroApp_BaseRequest.ProjectedMarginRequest projectedMarginRequest;
        public ForcaAgroApp_BaseRequest.DelimitedLandRequest delimitedLandRequest;
        public ForcaAgroApp_BaseRequest.DelimitedLandCulturesRequest delimitedLandCulturesRequest;
        public ForcaAgroApp_BaseRequest.UserRequest userRequest;
        public ForcaAgroApp_BaseRequest.CaseRequest caseRequest;

        public List<GetAccountTeam.SalesTeamResponse> salesTeamRequest;

        public List<ForcaAgroApp_BaseRequest.OrderTypeRequest> orderTypeRequest;
        public List<ForcaAgroApp_BaseRequest.ActivitySectorRequest> activitySectorRequest;
        public List<ForcaAgroApp_BaseRequest.SalesConditionRequest> salesConditionRequest;
        public List<ForcaAgroApp_BaseRequest.PaymentMethodRequest> paymentMethodRequest;
        public List<ForcaAgroApp_BaseRequest.OrderStatusRequest> orderStatusRequest;
        public List<ForcaAgroApp_BaseRequest.OrderStatusSAPRequest> orderStatusSAPRequest;
        public List<ForcaAgroApp_BaseRequest.BarterTypeRequest> barterTypeRequest;
        public List<ForcaAgroApp_BaseRequest.CommodityRequest> commodityRequest;
        public List<ForcaAgroApp_BaseRequest.UnitMeasurementRequest> unitMeasurementRequest;
        public List<ForcaAgroApp_BaseRequest.TechnologicalLevelRequest> technologicalLevelRequest;
        public List<ForcaAgroApp_BaseRequest.IncidentTypeRequest> incidentTypeRequest;
        public List<ForcaAgroApp_BaseRequest.CaseOriginRequest> caseOriginRequest;
       
        public List<ForcaAgroApp_BaseRequest.CustomLabelRequest> customLabelRequest;

        public Decimal refuseReasonMargem;

        public void addRequest(ForcaAgroApp_BaseRequest request){
            if (request instanceof ForcaAgroApp_BaseRequest.AccountRequest)
                this.accountRequest             = (ForcaAgroApp_BaseRequest.AccountRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.ListPriceRequest)
                this.listPriceRequest           = (ForcaAgroApp_BaseRequest.ListPriceRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.CropRequest)
                this.cropRequest                = (ForcaAgroApp_BaseRequest.CropRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.PaymentConditionRequest)
                this.paymentConditionRequest    = (ForcaAgroApp_BaseRequest.PaymentConditionRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.FamilyRequest)
                this.familyRequest              = (ForcaAgroApp_BaseRequest.FamilyRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.ProductRequest)
                this.productRequest             = (ForcaAgroApp_BaseRequest.ProductRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.CultureRequest)
                this.cultureRequest             = (ForcaAgroApp_BaseRequest.CultureRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.FreightRequest)
                this.freightRequest             = (ForcaAgroApp_BaseRequest.FreightRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.OrderRequest)
                this.orderRequest               = (ForcaAgroApp_BaseRequest.OrderRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.OrderItemRequest)
                this.orderItemRequest           = (ForcaAgroApp_BaseRequest.OrderItemRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.ShippingDivisionRequest)
                this.shippingDivisionRequest    = (ForcaAgroApp_BaseRequest.ShippingDivisionRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.CustomerPerOrgRequest)
                this.customerPerOrgRequest      = (ForcaAgroApp_BaseRequest.CustomerPerOrgRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.FinancialDueDateRequest)
                this.financialDueDateRequest    = (ForcaAgroApp_BaseRequest.FinancialDueDateRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.FieldDependencyRequest)
                this.fieldDependencyRequest     = (ForcaAgroApp_BaseRequest.FieldDependencyRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.RangeDiscountRequest)
                this.rangeDiscountRequest       = (ForcaAgroApp_BaseRequest.RangeDiscountRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.ClientCNDStateRequest)
                this.clientCNDStateRequest      = (ForcaAgroApp_BaseRequest.ClientCNDStateRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.OrderTypesRequest)
                this.orderTypesRequest          = (ForcaAgroApp_BaseRequest.OrderTypesRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.ProductManagementRequest)
                this.productManagementRequest   = (ForcaAgroApp_BaseRequest.ProductManagementRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.CampaignRequest)
                this.campaignRequest            = (ForcaAgroApp_BaseRequest.CampaignRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.CampaignProductRequest)
                this.campaignProductRequest     = (ForcaAgroApp_BaseRequest.CampaignProductRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.CampaignRuleRequest)
                this.campaignRuleRequest        = (ForcaAgroApp_BaseRequest.CampaignRuleRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.CampaignOrderItemRequest)
                this.campaignOrderItemRequest   = (ForcaAgroApp_BaseRequest.CampaignOrderItemRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.CampaignTargetAudienceRequest)
                this.campaignTargetAudienceRequest   = (ForcaAgroApp_BaseRequest.CampaignTargetAudienceRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.EventRequest)
                this.eventRequest   = (ForcaAgroApp_BaseRequest.EventRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.EventTypesRequest)
                this.eventTypesRequest   = (ForcaAgroApp_BaseRequest.EventTypesRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.RatingCreditRequest)
                this.ratingCreditRequest        = (ForcaAgroApp_BaseRequest.RatingCreditRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.ProjectedMarginRequest)
                this.projectedMarginRequest     = (ForcaAgroApp_BaseRequest.ProjectedMarginRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.DelimitedLandRequest)
                this.delimitedLandRequest   = (ForcaAgroApp_BaseRequest.DelimitedLandRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.DelimitedLandCulturesRequest)
                this.delimitedLandCulturesRequest   = (ForcaAgroApp_BaseRequest.DelimitedLandCulturesRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.UserRequest)
                this.userRequest   = (ForcaAgroApp_BaseRequest.UserRequest)request;
            if (request instanceof ForcaAgroApp_BaseRequest.CaseRequest)
                this.caseRequest   = (ForcaAgroApp_BaseRequest.CaseRequest)request;
        }

        public void addRequest(List<GetAccountTeam.SalesTeamResponse> salesTeamRequest){
            this.salesTeamRequest = salesTeamRequest;
        }

        public void addRequest(Decimal refuseReasonMargem){
            this.refuseReasonMargem = refuseReasonMargem;
        }

        public void addRequest(List<ForcaAgroApp_BaseRequest.OrderTypeRequest> orderTypeRequest){
            this.orderTypeRequest = orderTypeRequest;
        }

        public void addRequest(List<ForcaAgroApp_BaseRequest.ActivitySectorRequest> activitySectorRequest){
            this.activitySectorRequest = activitySectorRequest;
        }

        public void addRequest(List<ForcaAgroApp_BaseRequest.SalesConditionRequest> salesConditionRequest){
            this.salesConditionRequest = salesConditionRequest;
        }

        public void addRequest(List<ForcaAgroApp_BaseRequest.PaymentMethodRequest> paymentMethodRequest){
            this.paymentMethodRequest = paymentMethodRequest;
        }

        public void addRequest(List<ForcaAgroApp_BaseRequest.OrderStatusRequest> orderStatusRequest){
            this.orderStatusRequest = orderStatusRequest;
        }

        public void addRequest(List<ForcaAgroApp_BaseRequest.OrderStatusSAPRequest> orderStatusSAPRequest){
            this.orderStatusSAPRequest = orderStatusSAPRequest;
        }

        public void addRequest(List<ForcaAgroApp_BaseRequest.BarterTypeRequest> barterTypeRequest){
            this.barterTypeRequest = barterTypeRequest;
        }

        public void addRequest(List<ForcaAgroApp_BaseRequest.CommodityRequest> commodityRequest){
            this.commodityRequest = commodityRequest;
        }

        public void addRequest(List<ForcaAgroApp_BaseRequest.UnitMeasurementRequest> unitMeasurementRequest){
            this.unitMeasurementRequest = unitMeasurementRequest;
        }

        public void addRequest(List<ForcaAgroApp_BaseRequest.TechnologicalLevelRequest> technologicalLevelRequest){
            this.technologicalLevelRequest = technologicalLevelRequest;
        }
        
        public void addRequest(List<ForcaAgroApp_BaseRequest.IncidentTypeRequest> incidentTypeRequest){
            this.incidentTypeRequest = incidentTypeRequest;
        }

        public void addRequest(List<ForcaAgroApp_BaseRequest.CaseOriginRequest> caseOriginRequest){
            this.caseOriginRequest = caseOriginRequest;
        }

        public void addRequest(List<ForcaAgroApp_BaseRequest.CustomLabelRequest> customLabelRequest){
            this.customLabelRequest = customLabelRequest;
        }


        public void addSyncStamps(SyncStampData syncData) {
            this.syncData = syncData;
        }

        public void addHasMore(Boolean hasMore) {
            this.hasMore = hasMore;
        }

        public ReturnData(UserData userData, String minVersion){
            this.userData   = userData;
            this.hasMore    = false;
            this.minVersion = minVersion;
        }

        public void updateUserData(){
            update new User(
                Id = UserInfo.getUserId(), 
                LastSyncedDate__c = Datetime.now(), 
                AppVersion__c = this.syncData.appVersion,
                GeolocationPermission__c = this.syncData.geoLocationPermission != null ? this.syncData.geoLocationPermission : false,
                LastGeolocationPermissionDate__c = CreateEventController.buildDatetime(this.syncData.checkInDate, this.syncData.checkInHour)
            );
        }
    }

    global class ReturnError {
        public String type, message;

        public ReturnError(String type, String message) {
            this.type = type;
            this.message = message;
        }
    }
    
    global class UserData{
        String userId, userName, userLogin, userProfile, userExternalId, avaliableNegotiations;
        Long lastSyncUser;
        
        public UserData(String userId, String userName, String userLogin){
            this.userId                 = userId;
            this.userName               = userName;
            this.userLogin              = userLogin;

            User currentUser            = getUserById(userId);
            this.userProfile	        = currentUser.Profile.Name;
            this.userExternalId         = currentUser.ExternalId__c;
            this.avaliableNegotiations  = currentUser.AvaliableNegotiations__c;
            this.lastSyncUser           = Datetime.now().getTime(); 
        }

        public User getUserById(String userId){
            return ([SELECT Profile.Name, ExternalId__c, AvaliableNegotiations__c FROM User WHERE Id =: userId]);
        }

    }
}