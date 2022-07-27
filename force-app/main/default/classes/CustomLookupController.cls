public with sharing class CustomLookupController {
    
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecords(String objectApiName, String fieldApiName, String fieldApiNames, String filter, String searchTerm, String recordId, Boolean byFocus) {
        System.debug(objectApiName);
        System.debug(fieldApiName);
        System.debug(filter);
        System.debug(searchTerm);
        System.debug(recordId);
        System.debug(fieldApiNames);

        if(recordId == null) {
            recordId = '';
        } else if (filter == null) {
            filter = '';
        }
        System.debug((recordId != null));
        System.debug((recordId != ''));
        System.debug(filter.contains('replace'));
        if((recordId != null && recordId != '') && (filter.contains('replace'))) {
            filter = filter.replace('replace', recordId);
            System.debug('filter: '+ filter);
        }
        if(byFocus == true) {
            String query = 'SELECT Id, ' + fieldApiNames +
                            ' FROM '    + objectApiName +
                            ' WHERE ';
                List<String> fieldList = fieldApiName.split(';');
                List<String> conditions = new List<String>();
                for (String field : fieldList) {
                    conditions.add(' ' + field + ' LIKE \'%' + searchTerm + '%\'');
                }
                query += '(' + String.join(conditions, ' OR ') + ')';
                query += filter + ' LIMIT 10';

                List<SObject> recordsList =
                Database.query(query);

                return recordsList;
        } else {
            if(String.isNotBlank(searchTerm)) {
                String query = 'SELECT Id, ' + fieldApiNames +
                                ' FROM '    + objectApiName +
                                ' WHERE ';
                List<String> fieldList = fieldApiName.split(';');
                List<String> conditions = new List<String>();
                for (String field : fieldList) {
                    conditions.add(' ' + field + ' LIKE \'%' + searchTerm + '%\'');
                }
                query += '(' + String.join(conditions, ' OR ') + ')';
                query += filter + ' LIMIT 10';

                List<SObject> recordsList =
                Database.query(query);

                return recordsList;
            }
            else {
                return NULL;
            }
        }
    }
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecordContracts(String client, String parentAccountId, String searchTerm, String recordType) {
        List<String> recordTypeList = new List<String>();
        if (recordType == 'ZCCO' || recordType == 'ZCNO') {
            recordTypeList.add('BarterSale');
        }
        recordTypeList.add(recordType);
        List<String> orderIdList = new List<String>();
        System.debug(client);
        String searchLike = '%'+searchTerm+'%';
        if(String.isNotBlank(client)) {
            List<Order> recordsList =[SELECT Id, OrderNumber, ContractOrder__c, ContractOrder__r.Id, RecordType.Name
            FROM Order 
            WHERE (RecordType.DeveloperName IN: recordTypeList)
            AND ContractStartDate__c <= TODAY 
            AND ContractEndDate__c >= TODAY 
            AND (AccountId =: client OR AccountId =: parentAccountId)
            AND (StatusSAP__c = '3' OR StatusSAP__c = '4') 
            AND (OrderNumber LIKE :searchLike OR RecordType.Name LIKE :searchLike)
            ORDER BY OrderNumber ASC];

            for(Order record : recordsList){
                orderIdList.add(record.Id);
            }

            List<String> prodContractList = getRecordValidsContracts(orderIdList);
            List<SObject> recordsListWithProducts =[SELECT Id, OrderNumber, ContractOrder__c, ContractOrder__r.Id, RecordType.Name
            FROM Order 
            WHERE (RecordType.DeveloperName IN: recordTypeList)
            AND Id =: prodContractList
            AND ContractStartDate__c <= TODAY 
            AND ContractEndDate__c >= TODAY 
            AND (AccountId =: client OR AccountId =: parentAccountId)
            AND (StatusSAP__c = '3' OR StatusSAP__c = '4') 
            AND (OrderNumber LIKE :searchLike OR RecordType.Name LIKE :searchLike) 
            ORDER BY OrderNumber ASC];

            return recordsListWithProducts;
        }
        else {
            return NULL;
        }
    }
    @AuraEnabled(cacheable=true)
    public static List<String> getRecordValidsContracts(List<String> ordersIds){
        System.debug(ordersIds);
        Map<Id,Decimal> shipMap = new Map <Id,Decimal>();
        Map<Id,Decimal> shipContractMap = new Map <Id,Decimal>();
        Map<Id,Map<Id, Decimal>> balance = new Map<Id,Map<Id, Decimal>>();
        List<Id> contractsList = new List<Id>();
        for(ShippingDivision__c sd : [SELECT Id, OrderItem__c, Quantity__c, RefuseReason__c, OrderItem__r.OrderId, OrderItem__r.Product2Id 
                                        FROM ShippingDivision__c 
                                        WHERE (OrderItem__r.Order.ContractOrder__c IN: ordersIds OR OrderItem__r.OrderId IN :ordersIds)
                                        AND OrderItem__r.Order.StatusSF__c NOT IN ('Em digitação', 'Retorna RTV', 'Cancelado')
                                        AND OrderItem__r.Order.StatusSAP__C NOT IN ('X')]){
            populateMapShip(sd.OrderItem__r.Product2Id, (ordersIds.contains(sd.OrderItem__r.OrderId) ? shipContractMap : shipMap), sd);
            if(balance.containsKey(sd.OrderItem__r.OrderId)){
                balance.get(sd.OrderItem__r.OrderId).put(sd.OrderItem__r.Product2Id, 0);
            }else{
                balance.put(sd.OrderItem__r.OrderId, new Map<Id, Decimal>{sd.OrderItem__r.Product2Id => 0});
            }
        }
        System.debug('balance: ' + balance);
        for(Id prodMapId : balance.keySet()){
            for(Id prodId : balance.get(prodMapId).keySet()){
                Decimal qtdProduct = (shipMap.containsKey(prodId) ? shipMap.get(prodId) : 0);
                Decimal qtdContractProduct = shipContractMap.containsKey(prodId) ? shipContractMap.get(prodId) : 0;
                System.debug('(qtdContractProduct - qtdProduct): ' + (qtdContractProduct - qtdProduct));
                if((qtdContractProduct - qtdProduct) > 0 && qtdContractProduct != null && qtdProduct != null){
                    if(!contractsList.contains(prodMapId)){
                        System.debug('novo na lista');
                        contractsList.add(prodMapId);
                    }
                }
                System.debug('contractsList: ' + contractsList);
            }    
        }
        return contractsList;
    }

    @AuraEnabled(cacheable=true)
    public static Map<Id, Decimal> getRecordContractsProducts(List<String> ordersIds){
        System.debug(ordersIds);
        Map<Id,Decimal> shipMap = new Map <Id,Decimal>();
        Map<Id,Decimal> shipContractMap = new Map <Id,Decimal>();
        Map<Id, Decimal> balance = new Map<Id, Decimal>();
        for(ShippingDivision__c sd : [SELECT Id, OrderItem__c, Quantity__c, RefuseReason__c, OrderItem__r.OrderId, OrderItem__r.Product2Id 
                                        FROM ShippingDivision__c 
                                        WHERE (OrderItem__r.Order.ContractOrder__c IN: ordersIds OR OrderItem__r.OrderId IN :ordersIds)
                                        AND OrderItem__r.Order.StatusSF__c NOT IN ('Em digitação', 'Retorna RTV', 'Cancelado')
                                        AND OrderItem__r.Order.StatusSAP__C NOT IN ('X')]){
            populateMapShip(sd.OrderItem__r.Product2Id, (ordersIds.contains(sd.OrderItem__r.OrderId) ? shipContractMap : shipMap), sd);
            balance.put(sd.OrderItem__r.Product2Id, 0);

            System.debug(shipContractMap);
            System.debug(shipMap);
        }
        for(Id prodId : balance.keySet()){
            System.debug(shipContractMap);
            System.debug(prodId);
            Decimal qtdProduct = (shipMap.containsKey(prodId) ? shipMap.get(prodId) : 0);
            Decimal qtdContractProduct = shipContractMap.containsKey(prodId) ? shipContractMap.get(prodId) : 0;
            System.debug(qtdProduct);
            System.debug(qtdContractProduct);
            System.debug(balance);
            if((qtdContractProduct - qtdProduct) > 0) {
                balance.put(prodId, qtdContractProduct - qtdProduct);
            }
        }
        return balance;
    }
    public static void populateMapShip(Id key, Map<Id, Decimal> shipMap, ShippingDivision__c sd){
        if(!shipMap.containsKey(key))
            shipMap.put(key, 0);
        shipMap.put(key, shipMap.get(key) + getQuantityShip(sd));
    }
    public static Decimal getQuantityShip(ShippingDivision__c sd){
        System.debug(sd);
        return sd.Quantity__c * (sd.RefuseReason__c == null ? 1 : -1);
    }

    /*@AuraEnabled(cacheable=true)
    public static Map<String, Decimal> getRecordContractsProducts(List<String> ordersIds) {
        List<SObject> recordsList;
        List<String> productsIds = new List<String>();
        System.debug('ordersIds: ' + ordersIds);
        Map<String, Decimal> productMap = new Map<String, Decimal>();
        List<OrderItem> recordsProductsList = [
            SELECT Id, Quantity, Product2Id, Product2.Id FROM OrderItem WHERE OrderId =: ordersIds];
        System.debug('recordsProductsList: ' + recordsProductsList);
        if(recordsProductsList != null){
            for (OrderItem orderItens : recordsProductsList) {
                System.debug('orderItem: ' + orderItens.Id);
                productsIds.add(orderItens.Id);
                productMap.put(orderItens.Id,orderItens.Quantity);
            }
        }
        System.debug('productsIds: ' + productsIds);
        Map<String, Decimal> orderItemMap = new Map<String, Decimal>();
        if(productsIds != null){
            List<ShippingDivision__c> shippingDivisionList = [
                SELECT Id, Quantity__c, OrderItem__c, RefuseReason__c FROM ShippingDivision__c WHERE OrderItem__c =: productsIds
            ];
        
            System.debug('shippingDivisionList: ' + shippingDivisionList);
            if (shippingDivisionList != null) {
                for (ShippingDivision__c shippingList : shippingDivisionList) {
                    if (shippingList.RefuseReason__c == null) {
                        if (orderItemMap.containsKey(shippingList.OrderItem__c)) {
                            Decimal quantity = orderItemMap.get(shippingList.OrderItem__c);
                            orderItemMap.put(shippingList.OrderItem__c,(shippingList.Quantity__c + quantity));
                        }
                        else {
                            orderItemMap.put(shippingList.OrderItem__c, shippingList.Quantity__c);
                        }
                    }
                }
                System.debug('orderItemMap: ' + orderItemMap);
                Map<String, Decimal> productsrecords = new Map<String, Decimal>();
                for (OrderItem orderItem : recordsProductsList) {
                    Decimal orderItemShippingQuantity =  orderItemMap.get(orderItem.Id);
                    System.debug('entrou: ' + orderItemShippingQuantity);
                    System.debug('orderItem.Quantity: ' + orderItem.Quantity);
                    if((orderItem.Quantity - orderItemShippingQuantity) > 0 ){
                        System.debug('chegou: ');
                        productsrecords.put(orderItem.Product2.Id,(orderItem.Quantity - orderItemShippingQuantity));
                    }
                }
                System.debug('productsrecords: ' + productsrecords);
                if (productsrecords.isEmpty()) {
                    System.debug('productsrecords2: ' + productsrecords);
                    return null;
                }
                return productsrecords;
            }else{
                return productMap;
            }
        }else{
            return null;
        }
    }*/
    @AuraEnabled(cacheable=true)
    public static Decimal getProductCost(String productId){
        List<ListPrice__c> curPrices =[SELECT Id, Cost__c, Product2Id__c
            FROM ListPrice__c
            WHERE IsActive__c =true
                AND Product2Id__c =:productId
            LIMIT: 1];  
        if (curPrices.isEmpty()){
            return null;
        }
        return curPrices[0].Cost__c;
    }

    @AuraEnabled(cacheable=true)
    public static OrderItem getContractInfo(String orderId, String productId) {

        OrderItem recordsList = [SELECT  Id, Cost__c, Culture__c,Culture__r.Name,ListPrice__c, ContractProductCredit__c, LastChangedPriceList__c, ListPrice__r.Name, ListPrice__r.UnitPrice__c, UnitPrice, Quantity, TotalPrice, DiscountAmount__c, DiscountPercent__c, UnitMeasure__c, AdditionPercent__c, PriceListEffectiveDate__c, AdditionAmount__c
        FROM OrderItem WHERE OrderId =: orderId AND Product2Id =: productId LIMIT 1];
        return recordsList;
    }

    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecordTypePrincipleName(String filter) {

        List<SObject> recordsList = [SELECT  Id, Name, RemoveFreightValue__c, ActivePrinciple__c, Multiplicity__c, QuantityUnitOfMeasure, ProductCode, GrossWeightUnity__c,Family__c, Family__r.Id, Family__r.Name, GrossWeight__c, ActivitySector__c 
        FROM Product2 WHERE ActivePrinciple__c =: filter AND IsActive = True];
        return recordsList;
    }

    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecordTypePrincipleNameWithContract(String filter, List<String> contract) {

        List<SObject> recordsList = [SELECT  Id, Name, RemoveFreightValue__c, ActivePrinciple__c, Multiplicity__c, QuantityUnitOfMeasure, ProductCode, GrossWeightUnity__c,Family__c, Family__r.Id, Family__r.Name, GrossWeight__c, ActivitySector__c 
        FROM Product2 WHERE ActivePrinciple__c =: filter AND IsActive = True AND Id =: contract];
        return recordsList;
    }
    @AuraEnabled(cacheable=true)
    public static List<Product2> getRecordPrincipleName(String familyName, String searchValue) {
        List<String> productStringList = new List<String>();
        List<Product2> productList = new List<Product2>();
        List<Product2> recordsList = new List<Product2>();
        if (searchValue == null) {
            recordsList = [SELECT  Id, Name, RemoveFreightValue__c, ActivePrinciple__c, Multiplicity__c, QuantityUnitOfMeasure, ProductCode, GrossWeightUnity__c,Family__c, Family__r.Id, Family__r.Name, GrossWeight__c, ActivitySector__c 
            FROM Product2 WHERE ActivePrinciple__c != null AND Family__r.Name =: familyName AND IsActive = True LIMIT 10];
        }else{
            recordsList = [SELECT  Id, Name, RemoveFreightValue__c, ActivePrinciple__c, Multiplicity__c, QuantityUnitOfMeasure, ProductCode, GrossWeightUnity__c,Family__c, Family__r.Id, Family__r.Name, GrossWeight__c, ActivitySector__c 
            FROM Product2 WHERE ActivePrinciple__c != null AND Family__r.Name =: familyName AND IsActive = True AND ActivePrinciple__c LIKE: searchValue LIMIT 10];
        }
        for(Product2 record : recordsList){
            String recordActivePrinciple = record.ActivePrinciple__c;
            if(!productStringList.contains(record.ActivePrinciple__c)){
                productList.add(record); 
                productStringList.add(record.ActivePrinciple__c); 
            }
        }
        return productList;
    }

    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecordPrincipleAndFamilyName(String principle, String family) {

        List<SObject> recordsList = [SELECT  Id, Name, RemoveFreightValue__c, ActivePrinciple__c, Multiplicity__c, QuantityUnitOfMeasure, ProductCode, GrossWeightUnity__c,Family__c, Family__r.Id, Family__r.Name, GrossWeight__c, ActivitySector__c 
        FROM Product2 WHERE ActivePrinciple__c =: principle AND Family__r.Name =: family AND IsActive = True];
        
        return recordsList;
    }

    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecordPrincipleAndFamilyNameWithContract(String principle, String family, List<String> contract) {

        List<SObject> recordsList = [SELECT  Id, Name, RemoveFreightValue__c, ActivePrinciple__c, Multiplicity__c, QuantityUnitOfMeasure, ProductCode, GrossWeightUnity__c,Family__c, Family__r.Id, Family__r.Name, GrossWeight__c, ActivitySector__c 
        FROM Product2 WHERE ActivePrinciple__c =: principle AND Family__r.Name =: family AND IsActive = True AND Id =: contract];
        
        return recordsList;
    }

    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecordTypeIds(String objectApiName, String fieldApiName, String filter, String filterSales) {
        System.debug(objectApiName);

        if(String.isNotBlank(objectApiName)) {

            User currentUser = [SELECT Id, AvaliableNegotiations__c FROM User WHERE Id =: UserInfo.getUserId()];
            String avaliableNegotiations = currentUser.AvaliableNegotiations__c;

            String avaliableNegotiationFilter = '';
            if(avaliableNegotiations == null){
                avaliableNegotiationFilter = ' AND DeveloperName = null';
            }else if (!avaliableNegotiations.contains('All')) {
                
                List<String> availableNegotiationList = avaliableNegotiations.split(';');

                List<String> escapedParameters = new List<String>();
                for(String parameter : availableNegotiationList) {
                    escapedParameters.add('\'' + parameter + '\'');
                }
                avaliableNegotiationFilter = ' AND DeveloperName IN (' + String.join(escapedParameters, ',') + ') ';
            }
            
            if(filterSales == null){
                avaliableNegotiationFilter += ' AND DeveloperName = null ';
            }else{
                
                List<String> availableNegotiationList = (filterSales == 'Sales' ? OrderTypes__c.getAll().get('Tipos de Pedidos').SalesOrders__c.split(';') : OrderTypes__c.getAll().get('Tipos de Pedidos').SalesContracts__c.split(';'));

                List<String> escapedParameters = new List<String>();
                for(String parameter : availableNegotiationList) {
                    escapedParameters.add('\'' + parameter + '\'');
                }
                avaliableNegotiationFilter += ' AND DeveloperName IN ( ' + String.join(escapedParameters, ',') + ' ) ';
            }

            List<SObject> recordsList =
            Database.query(
                'SELECT Id, ' + fieldApiName  +
                ' FROM '      + objectApiName +
                ' WHERE '     + filter +
                avaliableNegotiationFilter + 
                ' ORDER BY Name ASC'
            );

            return recordsList;
        }
        else {
            return NULL;
        }
    }
@AuraEnabled(cacheable=true)
    public static List<SObject> getRecordPrincipleAgregate(String objectApiName, String fieldApiName, String filter, String searchValue) {
        System.debug(objectApiName);
        if(String.isNotBlank(objectApiName)) {
            if(searchValue != null){
                List<SObject> recordsList =
                Database.query(
                    'SELECT ' + fieldApiName  +
                    ' FROM '      + objectApiName +
                    ' WHERE ActivePrinciple__c ' + ' LIKE \'%' + searchValue + '%\'' + ' AND ' + filter 
                ); 
                System.debug('recordsList: ' + recordsList);
                return recordsList;
            }else{
                List<SObject> recordsList =
                Database.query(
                    'SELECT ' + fieldApiName  +
                    ' FROM '      + objectApiName +
                    ' WHERE '  + filter
                );
                return recordsList;
            }
        }
        else {
            return NULL;
        }
    }
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecordSalesTeam(String objectApiName, String fieldApiName, String fieldApiNames, String filter, String searchTerm, String recordId, List<String> salesTeamList, Boolean byFocus) {

        if(byFocus == true) {
            if(!salesTeamList.isEmpty()) {
                System.debug('recordId: ' + salesTeamList);
                
                filter = filter.contains('replace') ? filter.replace('replace', returnListSalesTeam(salesTeamList)) : '';
                System.debug('filter: ' + filter);
                List<String> fieldList = fieldApiName.split(';');
                String query = 'SELECT Id, ' + String.join(fieldList, ', ') + fieldApiNames +
                            ' FROM '    + objectApiName +
                            ' WHERE ';
                List<String> conditions = new List<String>();
                for (String field : fieldList) {
                    conditions.add(' ' + field + ' LIKE \'%' + searchTerm + '%\'');
                }
                query += '(' + String.join(conditions, ' OR ') + ')';
                query += filter + ' LIMIT 10';
            
                List<SObject> recordsList =
                Database.query(query);
                return recordsList;
            }
            else {
                return NULL;
            }
        } else {
            if(!salesTeamList.isEmpty() && String.isNotBlank(searchTerm)) {
                System.debug('recordId: ' + salesTeamList);
                
                filter = filter.contains('replace') ? filter.replace('replace', returnListSalesTeam(salesTeamList)) : '';
                System.debug('filter: ' + filter);                
                List<String> fieldList = fieldApiName.split(';');
                String query = 'SELECT Id, ' + String.join(fieldList, ', ')  + fieldApiNames +
                                ' FROM '    + objectApiName +
                                ' WHERE ';
                List<String> conditions = new List<String>();
                for (String field : fieldList) {
                    conditions.add(' ' + field + ' LIKE \'%' + searchTerm + '%\'');
                }
                query += '(' + String.join(conditions, ' OR ') + ')';
                query += filter + ' LIMIT 10';

                List<SObject> recordsList =
                Database.query(query);
            return recordsList;
            }
            else {
                return NULL;
            }
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecordRtvs(String objectApiName, String fieldSearchNames, String fieldApiName, String filter, String searchTerm, String recordId, List<String> idsRtvs, Boolean byFocus) {
        System.debug('idsRtvs: ' + idsRtvs);
        System.debug('recordId: ' + recordId);
        if(byFocus == true) { 
            if(!idsRtvs.isEmpty() && String.isNotBlank(recordId)) {
                filter = filter.contains('replace') ? filter.replace('replace', returnListSalesTeam(idsRtvs)) : '';
                filter = filter.contains('recordId') ? filter.replace('recordId', recordId) : '';
                System.debug('filter: ' + filter);
                List<SObject> recordsList =
                Database.query(
                    'SELECT Id, ' + fieldSearchNames  + 
                    ' FROM '      + objectApiName +
                    ' WHERE '     + fieldApiName  + ' LIKE \'%' + searchTerm + '%\'' 
                                  + filter        + ' LIMIT 10'
                );
            return recordsList;
            }
            else {
                return NULL;
            }
        }
        else {
            if(!idsRtvs.isEmpty() && String.isNotBlank(searchTerm) && String.isNotBlank(recordId)) {
                filter = filter.contains('replace') ? filter.replace('replace', returnListSalesTeam(idsRtvs)) : '';
                filter = filter.contains('recordId') ? filter.replace('recordId', recordId) : '';
                System.debug('filter: ' + filter);
                List<SObject> recordsList =
                Database.query(
                    'SELECT Id, ' + fieldSearchNames  + 
                    ' FROM '      + objectApiName +
                    ' WHERE '     + fieldApiName  + ' LIKE \'%' + searchTerm + '%\'' 
                                  + filter        + ' LIMIT 10'
                );
            return recordsList;
            }
            else {
                return NULL;
            }
        }
    }

    public static String returnListSalesTeam(List<String> listSalesTeam) {
        String stringRight = '';
        System.debug('listSalesTeam: ' + listSalesTeam);
        for(String s : listSalesTeam) {
            stringRight += '\'' + s + '\',';
        }

        stringRight = stringRight.removeEnd(',');

        return stringRight;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecordsProduct(String objectApiName, String fieldApiName, String fieldApiNames, String filter, String searchTerm, String recordId, String familyId, List<String> idsProducts, String activitySector, Boolean byFocus) {
        System.debug(objectApiName);
        System.debug(fieldApiName);
        System.debug(filter);
        System.debug(searchTerm);
        System.debug(recordId);
        System.debug(fieldApiNames);
        System.debug(familyId);
        System.debug('idsProducts: ' + idsProducts);
        System.debug('activitySector: ' + activitySector);

        List<String> recordActivityChannelList = new List<String>();
        
        filter = activitySector != null && filter.contains('replaceActivitySector') ? filter.replace('replaceActivitySector', activitySector) : filter.replace('ActivitySector__c == \'replaceActivitySector\' OR ', '');
        filter = familyId != null && filter.contains('replaceFamily') ? filter.replace('replaceFamily', familyId) : filter.replace('AND Family__c = \'replaceFamily\'', '');
        filter = idsProducts != null && filter.contains('replaceId') ? filter.replace('replaceId', returnListSalesTeam(idsProducts)) : '';
        System.debug('filter: ' + filter);

        if(byFocus == true) { 
            if(!idsProducts.isEmpty()) {
                    List<SObject> recordsList =
                    Database.query(
                        'SELECT Id, ' + fieldApiName  + fieldApiNames +
                        ' FROM '      + objectApiName +
                        ' WHERE '     + fieldApiName  + ' LIKE \'%' + searchTerm + '%\'' 
                                      + filter        + ' LIMIT 50'
                    );
                    return recordsList;
                } else  {
                    return null;
                }
        } else {
            if(String.isNotBlank(searchTerm) && !idsProducts.isEmpty()) {

                if(searchTerm != '') {
                    List<SObject> recordsList =
                    Database.query(
                        'SELECT Id, ' + fieldApiName  + fieldApiNames +
                        ' FROM '      + objectApiName +
                        ' WHERE '     + fieldApiName  + ' LIKE \'%' + searchTerm + '%\'' 
                                      + filter        + ' LIMIT 50'
                    );
                    return recordsList;
                } else  {
                    return null;
                }
            } else {
                return null;
            }
        }
    }
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecordsProductWithContract(String objectApiName, String fieldApiName, String fieldApiNames, String filter, String searchTerm, String recordId, String familyId, List<String> idsProducts, String activitySector, Boolean byFocus, List<String> contract) {
        System.debug('Contract:' + contract);
        System.debug(objectApiName);
        System.debug(fieldApiName);
        System.debug(filter);
        System.debug(searchTerm);
        System.debug(recordId);
        System.debug(fieldApiNames);
        System.debug(familyId);
        System.debug('idsProducts: ' + idsProducts);
        System.debug('activitySector: ' + activitySector);

        List<String> recordActivityChannelList = new List<String>();
        List<String> newProductsIds = new List<String>();
        if(idsProducts != null){
            for(String product : idsProducts){
                if(contract.contains(product)){
                    newProductsIds.add(product);
                }
            }
        }
        filter = activitySector != null && filter.contains('replaceActivitySector') ? filter.replace('replaceActivitySector', activitySector) : filter.replace('ActivitySector__c == \'replaceActivitySector\' OR ', '');
        filter = familyId != null && filter.contains('replaceFamily') ? filter.replace('replaceFamily', familyId) : filter.replace('AND Family__c = \'replaceFamily\'', '');
        filter = newProductsIds != null && filter.contains('replaceId') ? filter.replace('replaceId', returnListSalesTeam(newProductsIds)) : '';
        System.debug('filter: ' + filter);
        if(byFocus == true) { 
            if(!newProductsIds.isEmpty()) {
                    List<SObject> recordsList =
                    Database.query(
                        'SELECT Id, ' + fieldApiName  + fieldApiNames +
                        ' FROM '      + objectApiName +
                        ' WHERE '  + fieldApiName  + ' LIKE \'%' + searchTerm + '%\'' 
                                      + filter        + ' LIMIT 10'
                    );
                    return recordsList; 
                } else  {
                    return null;
                }
        } else {
            if(String.isNotBlank(searchTerm) && !newProductsIds.isEmpty()) {

                if(searchTerm != '') {
                    List<SObject> recordsList =
                    Database.query(
                        'SELECT Id, ' + fieldApiName  + fieldApiNames +
                        ' FROM '      + objectApiName +
                        ' WHERE '  + fieldApiName  + ' LIKE \'%' + searchTerm + '%\'' 
                                      + filter        + ' LIMIT 10'
                    );
                    return recordsList; 
                } else  {
                    return null;
                }
            } else {
                return null;
            }
        }
    }
    public static String getStringToSend(String recordString) {
        String s = recordString;

        List<String> sList = new List<String>();
        String sList2 = '';
        sList = s.split(';');
        
        for(String str : sList) {
            sList2 += '\'' + str + '\',';
        }

        sList2 = sList2.removeEnd(',');

        return sList2;
    }
}