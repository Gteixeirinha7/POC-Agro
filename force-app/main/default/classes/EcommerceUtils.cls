public class EcommerceUtils {
    public static String SALES_TEAM_RECORDTYPE {get;set;}
    public static String PRICEBOOK_RECORDTYPE {get;set;}
    public static String PRODUCT_RECORDTYPE {get;set;}
    public static String ACCOUNT_JURIDIC_RECORDTYPE {get;set;}
    public static Boolean isActive {get;set;}
    private static Boolean runTriggerListPrice;
    static{
        SALES_TEAM_RECORDTYPE = 'Seller';
        PRICEBOOK_RECORDTYPE = 'CustomerGroupPriceBook';
        PRODUCT_RECORDTYPE = 'SellerImported';
        ACCOUNT_JURIDIC_RECORDTYPE = 'LegalEntity';
        isActive = true;
        runTriggerListPrice = true;
    }

    public static Boolean isTriggerListPriceEnabled(){
        return runTriggerListPrice;
    }

    public static Boolean enableListPriceTrigger(){
        return runTriggerListPrice = true;
    }

    public static Boolean disableListPriceTrigger(){
        return runTriggerListPrice = false;
    }
    public static void checkSalesTeam(SalesTeam__c[] context, Boolean p_isActive) {
        if(checkPermission()) return;
        /*isActive = p_isActive;
        insertSeller(context);
        insertInventory(context);*/
    }

    public static void checkAccount(Account[] context, Boolean p_isActive){
        if(checkPermission()) return;
        /*isActive = p_isActive;
        insertAccount(context);*/
    }

    public static void checkProduct2(Product2[] context, Boolean p_isActive){
        if(checkPermission()) return;
        /*isActive = p_isActive;
        insertCategory(context);
        insertManufacturer(context);
        insertProductMatched(context);
        insertProductVariantMatched(context);*/
    }

    public static void checkListPrice(ListPrice__c[] context, Boolean p_isActive){
        if(checkPermission()) return;
        /*isActive = p_isActive;
        Map<String, ListPriceProductData> priceData = normalizeListPrice(context);

        if(priceData.isEmpty()) return;
        
        try{insertCrop(context);              }catch(Exception ex){ System.debug(ex.getMessage()+ex.getStackTraceString()+ex.getLineNumber());}
        try{insertPricebook(context);         }catch(Exception ex){ System.debug(ex.getMessage()+ex.getStackTraceString()+ex.getLineNumber());}
        try{insertProduct(priceData);         }catch(Exception ex){ System.debug(ex.getMessage()+ex.getStackTraceString()+ex.getLineNumber());}
        try{insertProductVariant(priceData);  }catch(Exception ex){ System.debug(ex.getMessage()+ex.getStackTraceString()+ex.getLineNumber());}
        try{insertInventoryRecord(priceData); }catch(Exception ex){ System.debug(ex.getMessage()+ex.getStackTraceString()+ex.getLineNumber());}
        try{insertPricebookEntry(context);    }catch(Exception ex){ System.debug(ex.getMessage()+ex.getStackTraceString()+ex.getLineNumber());}
        try{insertImage(context);             }catch(Exception ex){ System.debug(ex.getMessage()+ex.getStackTraceString()+ex.getLineNumber());}*/
    }

    public static Boolean checkPermission(){
        Profile profs = [SELECT id, Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
        return (profs.Name != 'Administrador do sistema' && profs.Name != 'System administrator');
    }

    //Seller Trigger
    /*public static void insertSeller(SalesTeam__c[] context){
        Map<String, Atonit_Mktplace__Seller__c> salesMap = new Map<String, Atonit_Mktplace__Seller__c>();
        for(SalesTeam__c slTeam : context){
            salesMap.put(slTeam.ExternalId__c, getSeller(slTeam));
        }
        if(!salesMap.isEmpty())
            Database.upsert(salesMap.values(), Atonit_Mktplace__Seller__c.SalesforceCoreExternalId__c, true);

        for(SalesTeam__c slTeam : context){
            slTeam.AtonitSeller__c = salesMap.get(slTeam.ExternalId__c).id;
        }
    }
    public static void insertInventory(SalesTeam__c[] context){
        Map<String, Atonit_Mktplace__Inventory__c> inventoryMap = new Map<String, Atonit_Mktplace__Inventory__c>();
        for(SalesTeam__c slTeam : context){
            if(slTeam.AtonitSeller__c != null)
                inventoryMap.put(slTeam.ExternalId__c, getInventory(slTeam));
        }
        if(!inventoryMap.isEmpty())
            Database.upsert(inventoryMap.values(), Atonit_Mktplace__Inventory__c.Atonit_Mktplace__External_Id__c, true);
            
        for(SalesTeam__c slTeam : context){
            slTeam.AtonitInventory__c = inventoryMap.get(slTeam.ExternalId__c).id;
        }
    }
    public static void insertPricebook(ListPrice__c[] context){
        List<ListPrice__c> filteredList = new List<ListPrice__c>();
        Set<String> salesOfficeIdSet = new Set<String>();
        for(ListPrice__c price : context){
            if(checkValidPrice(price) && price.Crop__c != null){
                filteredList.add(price);
                if(price.SalesOffice__c != null){
                    salesOfficeIdSet.add(price.SalesOffice__c);
                }
            }
        }

        if(filteredList.isEmpty()) return;

        Set<Id> listPriceSalesSet = new Set<Id>();
        Map<Id, Set<Id>> salesMap = new Map<Id, Set<Id>>();
        Map<Id, String> salesNameMap = new Map<Id, String>();
        
        for(SalesTeam__c sales : [SELECT atonitSeller__c, ParentId__c, DisplayName__c, Name FROM SalesTeam__c]){
            if(!salesMap.containsKey(sales.ParentId__c))    
                salesMap.put(sales.ParentId__c, new Set<Id>());
            salesMap.get(sales.ParentId__c).add(sales.atonitSeller__c);

            salesNameMap.put(sales.Id, (sales.DisplayName__c != null ? sales.DisplayName__c : sales.Name));
            salesNameMap.put(sales.atonitSeller__c, (sales.DisplayName__c != null ? sales.DisplayName__c : sales.Name));
        }

        if(!salesOfficeIdSet.isEmpty()){
            for(ListPrice__c sales : [SELECT id, SalesTeam__c FROM ListPrice__c WHERE SalesTeam__r.ParentId__c IN :salesOfficeIdSet AND SalesCondition__c = '18' AND RecordType.DeveloperName = 'PR00']){
                listPriceSalesSet.add(sales.SalesTeam__c);
            }
        }

        Map<String, Atonit_Mktplace__PriceBook__c> priceBookMap = new Map<String, Atonit_Mktplace__PriceBook__c>();
        Set<String> cropIdSet = new Set<String>();
        for(ListPrice__c pricess : filteredList){

            cropIdSet.add(pricess.CropExternalId__c);

            if(pricess.SalesOffice__c != null && salesMap.containsKey(pricess.SalesOffice__c) && !priceBookMap.containsKey( pricess.AtonnitSeller__c+'_'+pricess.CropExternalId__c)){
                for(Id salesId : salesMap.get(pricess.SalesOffice__c)){
                    
                    if(listPriceSalesSet.contains(salesId)) continue;

                    Atonit_Mktplace__PriceBook__c prices = getPriceBook(pricess, pricess.CropExternalId__c, salesId, salesNameMap.get(salesId));
                    priceBookMap.put(prices.Atonit_Mktplace__External_Id__c, prices);
                }
            }
            if(pricess.AtonnitSeller__c != null){
                Atonit_Mktplace__PriceBook__c prices = getPriceBook(pricess, pricess.CropExternalId__c, pricess.AtonnitSeller__c, salesNameMap.get(pricess.AtonnitSeller__c));
                priceBookMap.put(prices.Atonit_Mktplace__External_Id__c, prices);
            }
        }
        if(!priceBookMap.isEmpty())
            Database.upsert(priceBookMap.values(), Atonit_Mktplace__PriceBook__c.Atonit_Mktplace__External_Id__c, true);
        
        insertCropPriceBook(priceBookMap.values(), cropIdSet);
    }
    public static void insertCrop(ListPrice__c[] context){
        Map<String, Atonit_Mktplace__Customer_Group__c> cropMap = new Map<String, Atonit_Mktplace__Customer_Group__c>();
        for(ListPrice__c price : context){
            if(price.crop__c == null) continue;
            Atonit_Mktplace__Customer_Group__c crop = getCrop(price);
            cropMap.put(crop.Atonit_Mktplace__Marketplace_Id__c, crop);
        }
        if(!cropMap.isEmpty())
            Database.upsert(cropMap.values(), Atonit_Mktplace__Customer_Group__c.Atonit_Mktplace__Marketplace_Id__c, true);
        
    }
    public static void insertCropPriceBook(Atonit_Mktplace__PriceBook__c[] context, Set<String> cropIdSet){
        Map<String, Atonit_Mktplace__Customer_Group__c> customerMap = getCustomerMap(cropIdSet); 
        Map<String, Atonit_Mktplace__PriceBook_CustomerGroup_Association__c> priceBookMap = new Map<String, Atonit_Mktplace__PriceBook_CustomerGroup_Association__c>();
        for(Atonit_Mktplace__PriceBook__c prices : context){
            String pricesCropId = prices.Atonit_Mktplace__External_Id__c.split('_')[1];
            if(customerMap.containsKey(pricesCropId)){
                Atonit_Mktplace__PriceBook_CustomerGroup_Association__c priceCustomer = getCropPriceBook(prices, customerMap.get(pricesCropId).id);
                priceBookMap.put(priceCustomer.Atonit_Mktplace__External_Id__c, priceCustomer);
            }
        }
        if(!priceBookMap.isEmpty())
            Database.upsert(priceBookMap.values(), Atonit_Mktplace__PriceBook_CustomerGroup_Association__c.Atonit_Mktplace__External_Id__c, true);   
    }

    //Account Trigger
    public static void insertAccount(Account[] context){
        /*Map<String, Atonit_Mktplace__Customer__c> accMap = new Map<String, Atonit_Mktplace__Customer__c>();
        for(Account acc : context){
            if(!acc.Blocked__c && acc.RecordTypeId != Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Property').getRecordTypeId())
                accMap.put(acc.ExternalId__c, null);
        }

        Map<String, CustomerPerOrg__c[]> customerMap = new Map<String, CustomerPerOrg__c[]>();
        for(CustomerPerOrg__c customer : [SELECT ActivitySector__c, Customer__r.ExternalId__c, DistributionChannel__c 
                                        FROM CustomerPerOrg__c
                                        WHERE Customer__r.ExternalId__c IN :accMap.keySet()]){
            if(!customerMap.containsKey(customer.Customer__r.ExternalId__c))
                customerMap.put(customer.Customer__r.ExternalId__c, new List<CustomerPerOrg__c>());
            customerMap.get(customer.Customer__r.ExternalId__c).add(customer);
        }

        for(Account acc : context){
            if(!acc.Blocked__c && acc.ExternalId__c != null && accMap.containsKey(acc.ExternalId__c))
                accMap.put(acc.ExternalId__c, getAccount(acc, customerMap.get(acc.ExternalId__c)));
        }

        if(!accMap.isEmpty())
            Database.upsert(accMap.values(), Atonit_Mktplace__Customer__c.Atonit_SAPExternalID__c, true);

        Map<String, Atonit_Customer_Address__c> accAddressMap = new Map<String, Atonit_Customer_Address__c>();
        for(Account acc : context){
            if(acc.Blocked__c) continue;
            
            if(accMap.containsKey(acc.ExternalId__c) && isActive)
                acc.AtonnitAccount__c =  accMap.get(acc.ExternalId__c).id;
            else if(isActive)
                acc.AtonnitParentAccount__c = acc.AtonitParentId__c;
            
            Id accId = acc.AtonnitAccount__c != null ? acc.AtonnitAccount__c : acc.AtonnitParentAccount__c;

            if(accId != null && acc.ShippingStreet != null && acc.ShippingCity != null && acc.ShippingState != null)
                accAddressMap.put(acc.ExternalId__c, getAddress(acc, accId));
        }
        //Alinhamento
        if(!accAddressMap.isEmpty())
            Database.upsert(accAddressMap.values(), Atonit_Customer_Address__c.Atonit_ExternalId__c, true);
            // Database.insert(accAddressMap.values(), true);
        for(Account acc : context){
            if(accAddressMap.containsKey(acc.ExternalId__c) && isActive)
                acc.AtonnitAddress__c = accAddressMap.get(acc.ExternalId__c).Id;
        }*-/
    }

    //Product2 Trigger
    public static void insertCategory(Product2[] context){
        Map<String, Atonit_Mktplace__Category__c > catMap = new Map<String, Atonit_Mktplace__Category__c >();
        for(Product2 prod : context){
            if(prod.Category__c != null)
                catMap.put(prod.Category__c, null);
        }
        for(Atonit_Mktplace__Category__c cat : [SELECT id, Atonit_Mktplace__Marketplace_Id__c FROM Atonit_Mktplace__Category__c WHERE Atonit_Mktplace__Marketplace_Id__c IN :catMap.keySet()]){
            catMap.put(cat.Atonit_Mktplace__Marketplace_Id__c, cat);
        }
        for(Product2 prod : context){
            if(catMap.containsKey(prod.Category__c))
                prod.AtonnitCategory__c = catMap.get(prod.Category__c)?.id;
        }

        Map<String, Atonit_Mktplace__Product_to_Related_Category__c > catProdMap = new Map<String, Atonit_Mktplace__Product_to_Related_Category__c >();
        for(Product2 prod : context){
            if(prod.AtonnitCategory__c != null && prod.AtonnitProduct__c != null){
                Atonit_Mktplace__Product_to_Related_Category__c cats = getCategoryProduct(prod);
                catProdMap.put(cats.Atonit_Mktplace__External_Id__c, cats);
            }
        }
        if(!catProdMap.isEmpty())
            Database.upsert(catProdMap.values(), Atonit_Mktplace__Product_to_Related_Category__c.Atonit_Mktplace__External_Id__c, true);
    }
    public static void insertManufacturer(Product2[] context){
        Map<String, Atonit_Mktplace__Manufacturer__c> manuMap = new Map<String, Atonit_Mktplace__Manufacturer__c>();
        for(Product2 prod : context){
            if(prod.Manufacturer__c != null)
                manuMap.put(prod.Manufacturer__c, getManufacturer(prod));
        }
        if(!manuMap.isEmpty())
            Database.upsert(manuMap.values(), Atonit_Mktplace__Manufacturer__c.Atonit_Mktplace__Marketplace_Id__c, true);
            
        for(Product2 prod : context){
            if(manuMap.containsKey(prod.Manufacturer__c))
                prod.AtonnitManufacturer__c = manuMap.get(prod.Manufacturer__c).id;
        }
    }
    public static void insertProductMatched(Product2[] context){
        Map<String, Atonit_Mktplace__Product__c> prodMap = new Map<String, Atonit_Mktplace__Product__c>();
        for(Product2 prod : context){
            prodMap.put(prod.ExternalId__c, getProduct(prod));
        }
        if(!prodMap.isEmpty())
            Database.upsert(prodMap.values(), Atonit_Mktplace__Product__c.Atonit_Mktplace__External_Id__c, true);

        for(Product2 prod : context){
            prod.AtonnitProduct__c = prodMap.get(prod.ExternalId__c).id;
        }
    }
    public static void insertProductVariantMatched(Product2[] context){
        Map<String, Atonit_Mktplace__Product_Variant__c> prodMap = new Map<String, Atonit_Mktplace__Product_Variant__c>();
        
        Map<Id, RangeDiscount__c> famIdMap = new Map<Id, RangeDiscount__c>();

        Map<Id, String[]> listPriceMap = new Map<Id, String[]>();
        Map<String, String[]> listPriceInterestMap = new Map<String, String[]>();
        Map<String, String[]> listPriceAntecipationMap = new Map<String, String[]>();
        Set<String> invalidProductsSet = new Set<String>();
        Set<String> familyIdSet = new Set<String>();
        Set<String> salesOrgNameSet = new Set<String>();
        for(Product2 prod : context){
            famIdMap.put(prod.Family__c, new RangeDiscount__c(MinimumPercentage__c=0));

            if(prod.Id != null && !listPriceMap.containsKey(prod.Id)){
                listPriceMap.put(prod.Id, new List<String>());
            }
            if(prod.Family__c != null && !listPriceInterestMap.containsKey(prod.Family__c )){
                listPriceInterestMap.put(prod.Family__c, new List<String>());
                listPriceAntecipationMap.put(prod.Family__c, new List<String>());
                familyIdSet.add(prod.Family__c);
            }
        }

        getRangeDiscount(famIdMap, new Set<Id>());

        getListPrice(invalidProductsSet, listPriceMap, listPriceInterestMap, listPriceAntecipationMap, new Set<Id>(), new Set<Id>(), familyIdSet, salesOrgNameSet);

        for(Product2 prod : context){
            String EffectiveDate      = getJSONCrop(prod.id, listPriceMap);
            String taxAfterEffective  = getJSONCrop(prod.Family__c, listPriceInterestMap);
            String taxBeforeEffective = getJSONCrop(prod.Family__c, listPriceAntecipationMap);
            prodMap.put(prod.ExternalId__c, getProductVariant(false, prod, famIdMap.get(prod.Family__c), EffectiveDate, taxAfterEffective, taxBeforeEffective));
        }
        if(!prodMap.isEmpty())
            Database.upsert(prodMap.values(), Atonit_Mktplace__Product_Variant__c.Atonit_Mktplace__External_Id__c, true);

        for(Product2 prod : context){
            prod.AtonnitProductVariant__c = prodMap.get(prod.ExternalId__c).id;
        }
    }

    //ListPrice Trigger
    public static Map<String, ListPriceProductData> normalizeListPrice(ListPrice__c[] context){
        Map<String, Atonit_Mktplace__Product__c> prodMap = new Map<String, Atonit_Mktplace__Product__c>();
        
        Map<Id, Set<Id>> slMap = new Map<Id, Set<Id>>();
        for(SalesTeam__c sl : [SELECT id, ParentId__c, AtonitSeller__c FROM SalesTeam__C WHERE ParentId__c IN : Collection.of(context).pluckIds(ListPrice__c.SalesOffice__c) AND ParentId__c != null]){
            if(!slMap.containsKey(sl.ParentId__c))
                slMap.put(sl.ParentId__c, new Set<Id>());
            slMap.get(sl.ParentId__c).add(sl.AtonitSeller__c);
        }

        Map<String, ListPriceProductData> priceDataMap = new Map<String, ListPriceProductData>();
        for(ListPrice__c price : context){
            
            if(!checkValidPrice(price)) continue;

            String key = price.AtonnitProductMatched__c+'_';

            if(price.AtonnitSeller__c != null){
                key += price.AtonnitSeller__c;
                priceDataMap.put(key, new ListPriceProductData(price.AtonnitSeller__c, price));
            }else if(slMap.containsKey(price.SalesOffice__c)){
                for(Id slId : slMap.get(price.SalesOffice__c)){
                    key += slId;
                    priceDataMap.put(key, new ListPriceProductData((String)slId, price));
                }
            }
        }
        return priceDataMap;
    }
    public static void insertProduct(Map<String, ListPriceProductData> context){
         Map<Id, Atonit_Mktplace__Product__c> productMap = getProductMap(getProductIdSet(context));

        Map<String, Atonit_Mktplace__Product__c> prodMap = new Map<String, Atonit_Mktplace__Product__c>();
        for(ListPriceProductData priceData : context.values()){
            Atonit_Mktplace__Product__c atonitProduct = getProduct(priceData, productMap);
            prodMap.put(atonitProduct.Atonit_Mktplace__External_Id__c, atonitProduct);            
        }
        if(!prodMap.isEmpty())
            Database.upsert(prodMap.values(), Atonit_Mktplace__Product__c.Atonit_Mktplace__External_Id__c, true);
    }
    public static void insertProductVariant(Map<String, ListPriceProductData> context){
        Map<Id, Atonit_Mktplace__Product_Variant__c> variantMap = getProductVariantMap(getVariantIdSet(context));
        Map<String, Atonit_Mktplace__Product_Variant__c> prodMap = new Map<String, Atonit_Mktplace__Product_Variant__c>();
        
        Map<Id, RangeDiscount__c> famIdMap = new Map<Id, RangeDiscount__c>();

        Map<Id, String[]> listPriceMap = new Map<Id, String[]>();
        Map<String, String[]> listPriceInterestMap = new Map<String, String[]>();
        Map<String, String[]> listPriceAntecipationMap = new Map<String, String[]>();
        Set<String> invalidProductsSet = new Set<String>();
        Set<String> familyIdSet = new Set<String>();
        Set<String> salesOrgNameSet = new Set<String>();

        Set<String> prodKeyStringSet = new Set<String>();
        for(ListPriceProductData priceData : context.values()){
            prodKeyStringSet.add(priceData.prodCode+'_'+priceData.salesId);
            ListPrice__c prod = priceData.priceList;
            famIdMap.put(prod.ProductFamilyId__c, new RangeDiscount__c(MinimumPercentage__c=0));

            if(prod.Id != null && !listPriceMap.containsKey(prod.Id)){
                listPriceMap.put(prod.Product2Id__c, new List<String>());
            }
            if(prod.ProductFamilyId__c != null && !listPriceInterestMap.containsKey(prod.ProductFamilyId__c+'_'+prod.SalesOrgName__c )){
                listPriceInterestMap.put(prod.ProductFamilyId__c+'_'+prod.SalesOrgName__c, new List<String>());
                listPriceAntecipationMap.put(prod.ProductFamilyId__c+'_'+prod.SalesOrgName__c, new List<String>());
                familyIdSet.add(prod.ProductFamilyId__c);
                salesOrgNameSet.add(prod.SalesOrgName__c);
            }
        }

        getRangeDiscount(famIdMap, new Set<Id>());

        getListPrice(invalidProductsSet, listPriceMap, listPriceInterestMap, listPriceAntecipationMap, new Set<Id>(), new Set<Id>(), familyIdSet, salesOrgNameSet);

        System.debug(listPriceMap);
        
        Map<String, String> prodCoMap = new Map<String, String>();
        for(Atonit_Mktplace__Product__c vari : [SELECT id, Atonit_Mktplace__External_Id__c FROM Atonit_Mktplace__Product__c WHERE Atonit_Mktplace__External_Id__c IN :prodKeyStringSet]){
            prodCoMap.put(vari.Atonit_Mktplace__External_Id__c, vari.id);
        }
        System.debug(prodCoMap);


        for(ListPriceProductData priceData : context.values()){
            ListPrice__c prod = priceData.priceList;
            String key = priceData.prodCode+'_'+priceData.salesId;
            String EffectiveDate      = getJSONCrop(prod.Product2Id__c, listPriceMap);
            String taxAfterEffective  = getJSONCrop(prod.ProductFamilyId__c+'_'+prod.SalesOrgName__c, listPriceInterestMap);
            String taxBeforeEffective = getJSONCrop(prod.ProductFamilyId__c+'_'+prod.SalesOrgName__c, listPriceAntecipationMap);
            System.debug(EffectiveDate);
            string prodId = prodCoMap.get(key);

            Decimal prices = (prod.UnitPrice__c / prod.PriceMultiplier__c) * prod.ProductMultiplier__c;
            Boolean isInvalid = invalidProductsSet.contains(key+'_'+prod.Crop__c) || invalidProductsSet.contains(key+'_null') || prices == 0;

            Atonit_Mktplace__Product_Variant__c atonitProduct = getProductVariant(isInvalid, priceData, variantMap, famIdMap.get(prod.ProductFamilyId__c), EffectiveDate, taxAfterEffective, taxBeforeEffective, prodId);
            prodMap.put(atonitProduct.Atonit_Mktplace__External_Id__c, atonitProduct);
        }
        if(!prodMap.isEmpty())
            Database.upsert(prodMap.values(), Atonit_Mktplace__Product_Variant__c.Atonit_Mktplace__External_Id__c, true);
    }
    public static void insertInventoryRecord(Map<String, ListPriceProductData> context){
        Map<String, Atonit_Mktplace__Inventory_Record__c> invenMap = new Map<String, Atonit_Mktplace__Inventory_Record__c>();

        Set<Id> sellerIdSet = new Set<Id>();
        Set<Id> productIdSet = new Set<Id>();
        Set<Id> salesIdSet = new Set<Id>();
        Set<String> prodKeyStringSet = new Set<String>();
        Set<String> invalidProductsSet = new Set<String>();
        for(ListPriceProductData prices : context.values()){
            sellerIdSet.add(prices.salesId);
            productIdSet.add(prices.priceList.Product2Id__c);
            prodKeyStringSet.add(prices.prodCode+'_'+prices.salesId);
        }
        
        Map<Id, Id> inventoryMap = new Map<Id, Id>();
        for(Atonit_Mktplace__Inventory__c inven : [SELECT id, Atonit_Mktplace__Seller__c FROM Atonit_Mktplace__Inventory__c WHERE Atonit_Mktplace__Seller__c IN :sellerIdSet]){
            inventoryMap.put(inven.Atonit_Mktplace__Seller__c, inven.id);
        }
        
        Map<String, String> variantMap = new Map<String, String>();
        for(Atonit_Mktplace__Product_Variant__c vari : [SELECT id, Atonit_Mktplace__External_Id__c FROM Atonit_Mktplace__Product_Variant__c WHERE Atonit_Mktplace__External_Id__c IN :prodKeyStringSet]){
            variantMap.put(vari.Atonit_Mktplace__External_Id__c, vari.id);
        }
        System.debug(variantMap);

        invalidProductsSet.addAll(getListPriceInactive(context.values()));

        for(ListPriceProductData prices : context.values()){
            String key = prices.prodCode+'_'+prices.salesId;
            string prodId = variantMap.get(key);
            System.debug(key);
            invenMap.put(key, getInventoryRecord(prices, inventoryMap, prodId, key, invalidProductsSet));
        }
        
        if(!invenMap.isEmpty()){
            Database.upsert(invenMap.values(), Atonit_Mktplace__Inventory_Record__c.Atonit_Mktplace__External_Id__c, true);
        }
    }
    public static void insertPricebookEntry(ListPrice__c[] context){
        List<ListPrice__c> filteredList = new List<ListPrice__c>();
        Set<String> productIdSet = new Set<String>();
        Set<String> cropIdSet = new Set<String>();
        Set<String> prodFullSet = new Set<String>();
        Set<String> existPriceIdSet = new Set<String>();

        
        List<ListPrice__c> filteredOrgList = new List<ListPrice__c>();
        List<ListPrice__c> filteredOfficeList = new List<ListPrice__c>();
        List<ListPrice__c> filteredSalesList = new List<ListPrice__c>();
        for(ListPrice__c price : context){
            if(checkValidPrice(price)){
                cropIdSet.add(price.Crop__c);
                productIdSet.add(price.ProductCode__c);

                filteredList.add(price);
                if(price.SalesTeam__c == null && price.SalesOffice__c == null){
                    filteredOrgList.add(price);
                }else if(price.SalesTeam__c == null){
                    filteredOfficeList.add(price);
                }else{
                    filteredSalesList.add(price);
                }
            }
        }

        if(filteredList.isEmpty()) return;

        Map<Id, Set<Id>> salesMap = new Map<Id, Set<Id>>();
        Map<Id, Id> salesIdMap = new Map<Id, Id>();

        Set<String> prodKeyStringSet = new Set<String>();
        Map<Id, Id[]> salesOrgIdMap = new Map<Id, Id[]>();

        for(SalesTeam__c sales : [SELECT id, ParentId__c, AtonitSeller__c, SalesOrg__c FROM SalesTeam__c]){
            salesIdMap.put(sales.Id, sales.AtonitSeller__c);
            
            if(!salesMap.containsKey(sales.ParentId__c))    
                salesMap.put(sales.ParentId__c, new Set<Id>());
            salesMap.get(sales.ParentId__c).add(sales.Id);

            if(!salesOrgIdMap.containsKey(sales.SalesOrg__c))
                salesOrgIdMap.put(sales.SalesOrg__c, new List<Id>());
            salesOrgIdMap.get(sales.SalesOrg__c).add(sales.AtonitSeller__c);

            for(String prodId : productIdSet){
                prodKeyStringSet.add(prodid+'_'+sales.AtonitSeller__c);
            }
        }

        for(ListPrice__c sales : [SELECT id, SalesTeam__c, ProductCode__c, SalesOffice__c 
                                FROM ListPrice__c 
                                WHERE ProductCode__c IN :productIdSet 
                                AND SalesCondition__c = '18' AND RecordType.DeveloperName = 'PR00'
                                AND (SalesTeam__c != null OR SalesOffice__c != null)]){
            existPriceIdSet.add(sales.SalesTeam__c+'_'+sales.ProductCode__c);
        }

        Map<String, Atonit_Mktplace__PriceBook__c[]> salesPriceMap = new Map<String, Atonit_Mktplace__PriceBook__c[]>();
        for(Atonit_Mktplace__PriceBook__c price : [SELECT id, Atonit_Mktplace__Seller__c, AtonitCrop__c FROM Atonit_Mktplace__PriceBook__c]){
            Id salesId = price.Atonit_Mktplace__Seller__c;
            Id cropId = price.AtonitCrop__c;

            if(!salesPriceMap.containsKey(cropId+'_'+salesId))
                salesPriceMap.put(cropId+'_'+salesId, new List<Atonit_Mktplace__PriceBook__c>());
            salesPriceMap.get(cropId+'_'+salesId).add(price);

            if(!salesPriceMap.containsKey('null_'+salesId))
                salesPriceMap.put('null_'+salesId, new List<Atonit_Mktplace__PriceBook__c>());
            salesPriceMap.get('null_'+salesId).add(price);
        }

        Map<String, String> variantMap = new Map<String, String>();
        for(Atonit_Mktplace__Product_Variant__c vari : [SELECT id, Atonit_Mktplace__External_Id__c 
                                                        FROM Atonit_Mktplace__Product_Variant__c 
                                                        WHERE Atonit_Mktplace__External_Id__c IN :prodKeyStringSet 
                                                        OR Atonit_Mktplace__Main_Product__r.Atonit_ProductCode__c IN :productIdSet]){
            variantMap.put(vari.Atonit_Mktplace__External_Id__c, vari.id);
        }

        Map<String, Atonit_Mktplace__Price_Book_Entry__c> priceEntryMap = new Map<String, Atonit_Mktplace__Price_Book_Entry__c>();
       
        for(ListPrice__c listPrices : filteredList){
            if(salesOrgIdMap.containsKey(listPrices.SalesOrg__c)){
                for(Id salesId : salesOrgIdMap.get(listPrices.SalesOrg__c)){ 

                    if(existPriceIdSet.contains(salesId+'_'+listPrices.ProductCode__c)) continue;

                    getPricebookEntryBySeller(salesId, listPrices, salesPriceMap, variantMap, salesIdMap, priceEntryMap);
                }
            }
        }
        for(ListPrice__c listPrices : filteredOfficeList){
            if(salesMap.containsKey(listPrices.SalesOffice__c)){
                for(Id salesId : salesMap.get(listPrices.SalesOffice__c)){

                    if(existPriceIdSet.contains(salesId+'_'+listPrices.ProductCode__c)) continue;

                    getPricebookEntryBySeller(salesId, listPrices, salesPriceMap, variantMap, salesIdMap, priceEntryMap);
                }
            }
        }
        for(ListPrice__c listPrices : filteredSalesList){
            getPricebookEntryBySeller(listPrices.SalesTeam__c, listPrices, salesPriceMap, variantMap, salesIdMap, priceEntryMap);
        }
         if(!priceEntryMap.isEmpty())
            Database.upsert(priceEntryMap.values(), Atonit_Mktplace__Price_Book_Entry__c.Atonit_Mktplace__External_Id__c, true);
    }
    public static void getPricebookEntryBySeller(Id slId, ListPrice__c listPrices, Map<String, Atonit_Mktplace__PriceBook__c[]> salesPriceMap ,  Map<String, String> variantMap, Map<Id, Id> salesIdMap , Map<String, Atonit_Mktplace__Price_Book_Entry__c> priceEntryMap ){        
        String key = listprices.crop__c+'_'+salesIdMap.get(slId);
        String keyVariant = listPrices.ProductCode__c+'_'+salesIdMap.get(slId);

        if(!variantMap.containsKey(keyVariant)) return; 

        if(!salesPriceMap.containsKey(key)) return;

        for(Atonit_Mktplace__PriceBook__c price : salesPriceMap.get(key)){
            String prodId = variantMap.get(keyVariant);

            String keyInsert = price.Id+'_'+prodId;

            priceEntryMap.put(keyInsert, getPriceBookEntry(keyInsert, listPrices, price.Id, prodId));
        }
    }
    public static void insertImage(ListPrice__c[] context){
        Set<String> prodIdSet = new Set<String>();
        for(ListPrice__c price : context){
            prodIdSet.add(price.AtonnitProductMatched__c);
        }

        Map<String, TemplateDataIntegrationFields.Product2INData> prodMap = new Map<String, TemplateDataIntegrationFields.Product2INData>();
        for(Atonit_Mktplace__Image__c imgs : [SELECT id,Atonit_Mktplace__URL__c, Atonit_Mktplace__Product__r.Atonit_ProductCode__c FROM Atonit_Mktplace__Image__c WHERE Atonit_Mktplace__Product__c IN :prodIdSet]){
            TemplateDataIntegrationFields.Product2INData prods = prodMap.containsKey(imgs.Atonit_Mktplace__Product__r.Atonit_ProductCode__c) ? prodMap.get(imgs.Atonit_Mktplace__Product__r.Atonit_ProductCode__c) : new TemplateDataIntegrationFields.Product2INData();
            prods.ExternalId = imgs.Atonit_Mktplace__Product__r.Atonit_ProductCode__c;
            prods.ImageList = prods.ImageList == null ? new List<String>() : prods.ImageList;
            prods.ImageList.add(imgs.Atonit_Mktplace__URL__c);
            prodMap.put(prods.ExternalId, prods);
        }
        setImageProduct(prodMap.values());
    }


    //Object Definition
    public static Atonit_Mktplace__Image__c getImage(String prodURL, Atonit_Mktplace__Product__c prod, Integer i){
        return new Atonit_Mktplace__Image__c(
            Atonit_Mktplace__URL__c = prodURL,
            Atonit_Mktplace__Update_Timestamp__c = Datetime.now(),
            Atonit_Mktplace__Status__c = 'Approved',
            Atonit_Mktplace__Product__c = prod.id,
            Atonit_Mktplace__Order__c = i,
            Atonit_Mktplace__External_Id__c = prod.id+'_'+i
        );
    }
    public static Atonit_Mktplace__Seller__c getSeller(SalesTeam__c slTeam){
        return new Atonit_Mktplace__Seller__c(
            Atonit_Mktplace__Display_Name__c = slTeam.DisplayName__c != null ? slTeam.DisplayName__c : slTeam.Name,
            Atonit_Mktplace__Slug__c = slTeam.ExternalId__c,
            Atonit_SalesOrg__c = slTeam.SalesOrgExternalId__c,
            Atonit_SalesOffice__c = slTeam.SalesOfficeExternalId__c,
            SalesforceCoreExternalId__c = slTeam.ExternalId__c,
            Atonit_Mktplace__Status__c = 'Approved',
            RecordTypeId = Schema.SObjectType.Atonit_Mktplace__Seller__c.getRecordTypeInfosByDeveloperName().get(SALES_TEAM_RECORDTYPE).getRecordTypeId()
        );
    }
    public static Atonit_Mktplace__Inventory__c getInventory(SalesTeam__c slTeam){
        return new Atonit_Mktplace__Inventory__c(
            Atonit_Mktplace__Active__c = isActive, 
            Atonit_Mktplace__Name__c = 'Inventário '+(slTeam.DisplayName__c == null ? slTeam.Name : slTeam.DisplayName__c),
            Atonit_Mktplace__External_Id__c  = slTeam.ExternalId__c,
            Atonit_Mktplace__Status__c = 'Approved',
            Atonit_Mktplace__Seller__c = slTeam.AtonitSeller__c
        );
    }
    public static Atonit_Mktplace__PriceBook__c getPriceBook(ListPrice__c pricess, String crops, String sellerId, String sellerName){
        return new Atonit_Mktplace__PriceBook__c(
            Atonit_Mktplace__Active__c = isActive, 
            Atonit_Mktplace__Currency__c = 'BRL',
            Atonit_Mktplace__Name__c = 'Catálogo '+sellerName+' referente a Safra: '+crops,
            Atonit_Mktplace__External_Id__c = sellerId+'_'+crops,
            Atonit_Mktplace__Seller__c = sellerId,
            AtonitCrop__c = pricess.Crop__c,
            Atonit_Mktplace__Status__c = 'Approved',
            RecordTypeId = Schema.SObjectType.Atonit_Mktplace__PriceBook__c.getRecordTypeInfosByDeveloperName().get(PRICEBOOK_RECORDTYPE).getRecordTypeId()
        );
    }
    public static Atonit_Mktplace__Customer_Group__c getCrop(ListPrice__c pricess){
        return new Atonit_Mktplace__Customer_Group__c (
            Atonit_Mktplace__Description__c = 'Safra '+pricess.CropExternalId__c, 
            Atonit_Mktplace__Marketplace_Id__c = pricess.CropExternalId__c,
            Name = 'Safra '+pricess.CropExternalId__c
        );
    }
    public static Atonit_Mktplace__PriceBook_CustomerGroup_Association__c getCropPriceBook(Atonit_Mktplace__PriceBook__c pricess, Id customerId){
        return new Atonit_Mktplace__PriceBook_CustomerGroup_Association__c(
            Atonit_Mktplace__Customer_Group__c = customerId, 
            Atonit_Mktplace__Price_Book__c = pricess.id,
            Atonit_Mktplace__External_Id__c = pricess.id+'_'+customerId
        );
    }
    public static Atonit_Mktplace__Category__c getCategory(Product2 prod){
        return new Atonit_Mktplace__Category__c(
            Atonit_Mktplace__Description__c = prod.Category__c,
            Atonit_Mktplace__External_Id__c = prod.Category__c,
            Atonit_Mktplace__Full_Path__c = prod.Category__c,
            Atonit_Mktplace__Is_Deleted__c = isActive,
            Atonit_Mktplace__Update_Timestamp__c = DateTime.now(),
            Name = prod.Category__c
        );  
    }
    public static Atonit_Mktplace__Manufacturer__c getManufacturer(Product2 prod){
        return new Atonit_Mktplace__Manufacturer__c(
            Atonit_Mktplace__Description__c = prod.Manufacturer__c,
            Name = prod.Manufacturer__c,
            Atonit_Mktplace__Marketplace_Id__c = prod.Manufacturer__c
        );  
    }
    public static Atonit_Mktplace__Product_Variant__c getProductVariant(Boolean isinvalid, Product2 prod, RangeDiscount__c range, String EffectiveDate, String taxAfterEffective, String taxBeforeEffective){
        return new Atonit_Mktplace__Product_Variant__c(
            Atonit_Mktplace__Depth__c = 0,
            Atonit_Mktplace__Height__c = 0,
            Atonit_Mktplace__Width__c = 0,
            Atonit_Mktplace__EAN__c = null,
            Atonit_Mktplace__Display_Name__c = prod.name,
            // Atonit_Mktplace__EAN__c
            Atonit_Mktplace__External_Id__c = prod.ExternalId__c,
            Atonit_Mktplace__Full_Description__c = prod.Description,
            Atonit_Mktplace__Image_Link__c = prod.LabelUrl__c,
            Atonit_Mktplace__Is_Deleted__c = !isActive,
            Atonit_Mktplace__Weight__c = prod.GrossWeight__c,
            Atonit_Mktplace__Main_Product__c = prod.AtonnitProduct__c,
            Atonit_Mktplace__Status__c = isinvalid ? 'Pending' : 'Approved',
            Atonit_Mktplace__Update_Timestamp__c = Datetime.now(),
            Name = prod.name,
            Atonit_CropsEffectiveDate__c     = EffectiveDate,
            Atonit_MaxRtvDiscount__c         = range.MinimumPercentage__c,
            Atonit_TaxAfterEffectiveDate__c  = taxAfterEffective,
            Atonit_TaxBeforeEffectiveDate__c = taxBeforeEffective
        );
    }
    public static Atonit_Mktplace__Product_Variant__c getProductVariant(Boolean isinvalid, ListPriceProductData context, Map<Id, Atonit_Mktplace__Product_Variant__c> productMap , RangeDiscount__c range, String EffectiveDate, String taxAfterEffective, String taxBeforeEffective, String prodId){
        
        Decimal prices = (context.priceList.UnitPrice__c / context.priceList.PriceMultiplier__c) * context.priceList.ProductMultiplier__c;

        Atonit_Mktplace__Product_Variant__c prodsOld = productMap.get(context.prodVariantId);
        
        Atonit_Mktplace__Product_Variant__c prods = prodsOld.clone(false, false, false, false);
        prods.Atonit_Mktplace__Is_Deleted__c = !isActive;
        prods.ListPrice__c = context.priceList.Id;
        prods.Atonit_Mktplace__Status__c = prices == 0 ? 'Pending': 'Approved' ;
        prods.Atonit_Mktplace__Matched_Variant__c = context.prodVariantId;
        prods.Atonit_Mktplace__Main_Product__c = prodId;
        prods.Atonit_Mktplace__External_Id__c += '_'+context.salesId;
        prods.Atonit_Seller__c = context.salesId;
        prods.Atonit_CropsEffectiveDate__c     = EffectiveDate;
        prods.Atonit_MaxRtvDiscount__c         = range.MinimumPercentage__c;
        prods.Atonit_TaxAfterEffectiveDate__c  = taxAfterEffective;
        prods.Atonit_TaxBeforeEffectiveDate__c = taxBeforeEffective;
        return prods;
    }
    public static Atonit_Mktplace__Product_to_Related_Category__c getCategoryProduct(Product2 prod){
        return new Atonit_Mktplace__Product_to_Related_Category__c(
            Atonit_Mktplace__Product__c = prod.AtonnitProduct__c,
            Atonit_Mktplace__Category__c = prod.AtonnitCategory__c,
            Atonit_Mktplace__External_Id__c = prod.AtonnitProduct__c+'_'+prod.AtonnitCategory__c,
            Atonit_Mktplace__Status__c = 'Approved',
            Atonit_Mktplace__Update_Timestamp__c = DateTime.now()
        );
    }
    public static Atonit_Mktplace__Product__c getProduct(Product2 prod){
        return new Atonit_Mktplace__Product__c(
            /*Atonit_TaxBeforeEffectiveDate__c
            Atonit_TaxAfterEffectiveDate__c
            Atonit_CropsEffectiveDate__c
            Atonit_MaxRtvDiscount__c

            Atonit_Mktplace__Marketplace_Catalog__c
            Atonit_Mktplace__Matched_Product__c
            Atonit_Mktplace__Brand__c*-/
            // Atonit_NCM__c = prod.NCM__c, 
            // Atonit_grossWeight__c = prod.GrossWeight__c, 
            // Atonit_registerNumber__c = prod.RegisterNumber__c, 
            ActivePrinciple__c = prod.ActivePrinciple__c,  
            Atonit_Mktplace__Brand__c = prod.Brand__c,
            Atonit_Mktplace__Main_Category__c = prod.AtonnitCategory__c,
            Atonit_Mktplace__Image_URL__c =  prod.LabelUrl__c,
            Atonit_CertificateUrl__c = prod.CertificateUrl__c,
            Atonit_InstructionsUrl__c = prod.InstructionsUrl__c,
            Atonit_LabelUrl__c = prod.LabelUrl__c,
            Atonit_ProductCode__c = prod.ExternalId__c,
            Atonit_ActivitySection__c = prod.ActivitySector__c,
            Atonit_ActivityChannel__c = prod.DistributionChannel__c,
            Atonit_PesoBruto__c = prod.GrossWeight__c,
            Atonit_UnidadeMedida__c = (Test.isRunningTest() ? 'KG' : prod.QuantityUnitOfMeasure),
            Atonit_Unidade_Medida_PesoBruto__c = prod.GrossWeightUnity__c,
            Atonit_PrescriptionRequired__c = prod.PrescriptionRequired__c,
            Atonit_ProductFamily__c = prod.FamilyName__c,
            Atonit_Mktplace__External_Id__c = prod.ExternalId__c,
            Atonit_Mktplace__Full_description__c = prod.Description,
            Atonit_Mktplace__Is_Deleted__c = !isActive,
            Atonit_isActive__c = prod.isActive,
            Atonit_Mktplace__Manufacturer__c = prod.AtonnitManufacturer__c,
            Atonit_Mktplace__Name__c = prod.name,
            Atonit_Mktplace__Product_type__c = 'Simple',//  'Grouped'
            Atonit_Mktplace__Seller_Product__c = true,
            Atonit_Mktplace__Short_description__c = (prod.Description != null && prod.Description.length() > 255 ? prod.Description?.subString(0,255) : prod.Description),
            Atonit_Mktplace__Status__c = 'Approved',
            Atonit_Mktplace__Update_Timestamp__c = DateTime.now(),
            RecordTypeId = Schema.SObjectType.Atonit_Mktplace__Product__c.getRecordTypeInfosByDeveloperName().get(PRODUCT_RECORDTYPE).getRecordTypeId()
        );  
    }
    public static Atonit_Mktplace__Product__c getProduct(ListPriceProductData context, Map<Id, Atonit_Mktplace__Product__c> productMap ){
        Atonit_Mktplace__Product__c prodsOld = productMap.get(context.prodId);
        
        Atonit_Mktplace__Product__c prods = prodsOld == null ? new Atonit_Mktplace__Product__c() : prodsOld.clone(false, false, false, false);
        prods.Atonit_isActive__c = isActive;
        prods.ListPrice__c = context.priceList.Id;
        prods.Atonit_Mktplace__Matched_Product__c = context.prodId;
        prods.Atonit_Mktplace__External_Id__c = prodsOld?.Atonit_Mktplace__External_Id__c+'_'+context.salesId;
        prods.Atonit_Seller__c = context.salesId;
        return prods;
    }
    public static Atonit_Mktplace__Customer__c getAccount(Account acc, CustomerPerOrg__c[] customerList){
        String[] lastNameSet = acc.name.split(' - ')[0].split(' ');
        lastNameSet.remove(0);

        String distriChannel = '';
        Set<String> activySet = new Set<String>();
        if(customerList != null && !customerList.isEmpty()){
            for(CustomerPerOrg__c cust : customerList){
                activySet.add(cust.ActivitySector__c);
                distriChannel = cust.DistributionChannel__c;
            }
        }
        return new Atonit_Mktplace__Customer__c(
            Atonit_Mktplace__Email__c       = acc.Email__c,
            Atonit_Mktplace__Name__c        = acc.name,
            Atonit_Mktplace__Phone__c       = acc.Phone__c,
            Name                            = acc.name.length() > 80 ? acc.name?.left(80) : acc.name,
            Atonit_LastName__c              = String.join(lastNameSet, ' '),
            Atonit_BillingStreet__c         = acc.BillingStreet,
            Atonit_BillingCity__c           = acc.BillingCity,
            Atonit_BillingState__c          = (Test.isRunningTest() ? 'SP' : acc.BillingState),
            Atonit_BillingCountry__c        = 'Brasil',
            Atonit_BillingPostalCode__c     = acc.BillingPostalCode,
            Atonit_CNPJ__c                  = acc.CNPJ__c,
            Atonit_CPF__c                   = acc.CPF__c,
            Atonit_MunicipalRegistration__c = acc.MunicipalRegistration__c,
            Atonit_StateRegistration__c     = acc.StateRegistration__c == null ? acc.ExternalId__c : acc.StateRegistration__c,
            // Atonit_Phone__c                 = acc.Phone__c,
            // Atonit_isActive__c              = isActive,
            Atonit_SAPExternalID__c         = acc.ExternalId__c,
            Atonit_DistributionChannel__c   = distriChannel,
            Atonit_NCD__c                   = acc.NCD__c,
            Atonit_NCDDate__c               = acc.NCDDate__c,
            ActivitySector__c               = String.join(new List<String>(activySet), ';')
            // Atonit_Blocked__c               = acc.Blocked__c,
            // Atonit_FiscalDomicile__c        = acc.FiscalDomicile__c
        );
    }
    public static Atonit_Customer_Address__c getAddress(Account acc, Id accId){
        return new Atonit_Customer_Address__c(
            Atonit_Customer__c   = accId,
            Atonit_ExternalId__c = acc.ExternalId__c,
            Name                 = acc.ShippingStreet,
            Atonit_Street__c     = acc.ShippingStreet,
            Atonit_City__c       = acc.ShippingCity,
            Atonit_State__c      = (Test.isRunningTest() ? 'SP' : acc.ShippingState),
            Atonit_Country__c    = 'Brasil',
            Atonit_PostalCode__c = acc.ShippingPostalCode,
            Atonit_Phone__c      = acc.Phone__c == null ? '-' : acc.Phone__c,
            Atonit_IsCompany__c  = acc.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(ACCOUNT_JURIDIC_RECORDTYPE).getRecordTypeId()
        );
    }
    public static Atonit_Mktplace__Inventory_Record__c getInventoryRecord(String key, InventoryRelatedRecord prod, InventoryRelatedRecord sales){
        return new Atonit_Mktplace__Inventory_Record__c(
            Atonit_Mktplace__External_Id__c = key,
            Atonit_Mktplace__Inventory__c = sales.idRecord,
            Atonit_Mktplace__Is_Deleted__c = !prod.isActive,
            Atonit_Mktplace__Product_Variant__c = prod.idRecord,
            Atonit_Mktplace__Quantity__c = prod.isActive ? 999999999 : 0,
            Atonit_Mktplace__Status__c = 'Approved',
            Atonit_Mktplace__Update_Timestamp__c = Datetime.now()
        );
    }
    public static Atonit_Mktplace__Inventory_Record__c getInventoryRecord(ListPriceProductData prices, Map<Id, Id> inventoryMap, String prodId, String key, Set<String> invalidPriceSet){
        Boolean invalidQuantity = !prices.priceList.isActive__c  || invalidPriceSet.contains(key+'_null') || invalidPriceSet.contains(key+'_'+prices.priceList.Crop__c);
        return new Atonit_Mktplace__Inventory_Record__c(
            Atonit_Mktplace__External_Id__c = key,
            Atonit_Mktplace__Inventory__c = inventoryMap.get(prices.salesId),
            Atonit_Mktplace__Is_Deleted__c = !prices.priceList.isActive__c ,
            Atonit_Mktplace__Product_Variant__c = prodId,
            Atonit_Mktplace__Quantity__c = !invalidQuantity ? 999999999 : 0,
            Atonit_Mktplace__Status__c = 'Approved',
            Atonit_Mktplace__Update_Timestamp__c = Datetime.now()
        );
    }
    public static Atonit_Mktplace__Price_Book_Entry__c getPriceBookEntry(String key, ListPrice__c price, Id salesId, Id prodId){
        Decimal prices = (price.UnitPrice__c / price.PriceMultiplier__c) * price.ProductMultiplier__c;
        return new Atonit_Mktplace__Price_Book_Entry__c(
            Atonit_Mktplace__External_Id__c = key,
            Atonit_Mktplace__Is_Deleted__c = isActive ? price.isActive__c :  isActive,
            Atonit_Mktplace__Price__c = prices,
            Atonit_Mktplace__Price_Book__c = salesId,
            Atonit_Mktplace__Product_Variant__c = prodId, 
            Atonit_Mktplace__Quantity__c = 1,
            Atonit_Mktplace__Status__c = (prices == 0 ? 'Pending' : 'Approved'),
            Atonit_Mktplace__Update_Timestamp__c = Datetime.now()
        );
    }

    //Utils
    public static Boolean checkValidPrice(ListPrice__c price){
        return 
            (price.Currency__c == 'BRL' && price.SalesCondition__c == '18' && price.RecordTypeId == Schema.SObjectType.ListPrice__c.getRecordTypeInfosByDeveloperName().get('PR00').getRecordTypeId());
    }
    public static void getRangeDiscount(Map<Id, RangeDiscount__c> famIdMap, Set<Id> officeIdSet){
        for(RangeDiscount__c range : [SELECT CustomerCategory__c, Family__c, Family__r.name,  MinimumPercentage__c, PaymentType__c, SalesOffice__r.name, SalesOffice__c
                                        FROM RangeDiscount__c 
                                        WHERE ApprovingAuthority__c = 'Manager' 
                                        AND InitialDate__c <= TODAY AND FinalDate__c >= TODAY 
                                        AND Status__c = 'Aprovado' 
                                        AND Family__c IN :famIdMap.keySet()
                                        ORDER BY Family__c]){
            if(officeIdSet.isEmpty() || officeIdSet.contains(range.SalesOffice__c))
                famIdMap.put(range.Family__c, range);
        }
    }
    public static Set<String> getListPriceInactive(ListPriceProductData[] prices ){
        Set<String> prodIdSet = new Set<String>();
        Set<String> salesIdSet = new Set<String>();
        for(ListPriceProductData pri : prices){
            prodIdSet.add(pri.prodCode);
            salesIdSet.add(pri.salesId);
        }
        Set<String> invalidProductsSet = new Set<String>();
        for(ProductManagement__c price : [SELECT Id, Name, SalesTeam__r.AtonitSeller__c, Product2__r.ExternalId__c, SalesTeam__c, Crop__c, InitialDate__c, EndDate__c, IsActive__c, ExternalId__c 
                                        FROM ProductManagement__c
                                        WHERE EndDate__c >= TODAY AND InitialDate__c <= TODAY 
                                        AND IsActive__c = true 
                                        AND SalesTeam__r.AtonitSeller__c IN: salesIdSet]){
            invalidProductsSet.add(price.Product2__r.ExternalId__c+'_'+price.SalesTeam__r.AtonitSeller__c+'_'+price.Crop__c);
        } 
        return invalidProductsSet;
    }
    public static Set<String> getListPriceInactive(Set<Id> salesIdSet, Set<Id> prodIdSet){
        Set<String> invalidProductsSet = new Set<String>();
        for(ProductManagement__c price : [SELECT Id, Name, SalesTeam__r.AtonitSeller__c, Product2__r.ExternalId__c, SalesTeam__c, Crop__c, InitialDate__c, EndDate__c, IsActive__c, ExternalId__c 
                                        FROM ProductManagement__c
                                        WHERE EndDate__c >= TODAY AND InitialDate__c <= TODAY 
                                        AND IsActive__c = true 
                                        AND SalesTeam__c IN: salesIdSet]){
            invalidProductsSet.add(price.Product2__r.ExternalId__c+'_'+price.SalesTeam__r.AtonitSeller__c+'_'+price.Crop__c);
        } 
        return invalidProductsSet;
    }
    public static void getListPrice(Set<String> invalidProductsSet,  Map<Id, String[]> listPriceMap, Map<String, String[]> listPriceInterestMap, Map<String, String[]> listPriceAntecipationMap, Set<Id> salesIdSet, Set<Id> officeIdSet, Set<String> familyIdSet, Set<String> salesOrgNameSet){        
        //Account__c, SalesOffice__c, SalesTeam__c
        Map<String, ListPriceData> listPriceDataMap             =  new Map<String, ListPriceData>();
        Map<String, ListPriceData> listPriceDataInterestMap     =  new Map<String, ListPriceData>();
        Map<String, ListPriceData> listPriceDataAntecipationMap = new Map<String, ListPriceData>();
        for(ListPrice__c price : [SELECT RecordType.DeveloperName, SalesOrgName__c, InterestValue__c, Crop__r.ExternalId__c, ProductFamily__c, EffectiveDate__c, Product2Id__c, SalesCondition__c, Account__c, SalesOffice__c, SalesTeam__c 
                                      FROM ListPrice__c 
                                      WHERE EndDate__c >= TODAY AND InitialDate__c <= TODAY 
                                      AND IsActive__c = true 
                                      AND SalesOrgName__c IN :salesOrgNameSet
                                      AND ((RecordType.DeveloperName = 'PR00' AND Currency__c = 'BRL'  AND SalesCondition__c = '18' ) OR RecordType.DeveloperName != 'PR00' ) 
                                      AND ((RecordType.DeveloperName = 'PR00' AND Product2Id__c IN :listPriceMap.keySet()  AND SalesCondition__c = '18' ) OR (RecordType.DeveloperName != 'PR00' AND ProductFamily__c IN :familyIdSet) ) 
                                      ORDER BY Priority__c ASC, InterestPriority__c ASC]){
            
            if(salesIdSet.isEmpty() || salesIdSet.contains(price.SalesTeam__c)){
                if(officeIdSet.isEmpty() || officeIdSet.contains(price.SalesOffice__c)){
                
                    if(price.RecordType.DeveloperName == 'PR00')
                        listPriceDataMap.put(price.Product2Id__c+'_'+price.Crop__r.ExternalId__c, new ListPriceData(price.Crop__r.ExternalId__c, price.EffectiveDate__c));
                    else if(price.RecordType.DeveloperName == 'ZJ01')
                        listPriceDataInterestMap.put(price.ProductFamily__c+'_'+price.Crop__r.ExternalId__c+'_'+price.SalesOrgName__c, new ListPriceData(price.Crop__r.ExternalId__c, price.InterestValue__c));                      
                    else
                        listPriceDataAntecipationMap.put(price.ProductFamily__c+'_'+price.Crop__r.ExternalId__c+'_'+price.SalesOrgName__c, new ListPriceData(price.Crop__r.ExternalId__c, price.InterestValue__c));
                }
            }
        }

        invalidProductsSet.addAll(getListPriceInactive(salesIdSet, listPriceMap.keySet()));

        System.debug(listPriceDataMap);
        System.debug(listPriceDataInterestMap);
        System.debug(listPriceDataAntecipationMap);
        for(String priceDataString : listPriceDataMap.keySet()){
            listPriceMap.get(priceDataString.split('_')[0]).add(listPriceDataMap.get(priceDataString).getDataString());
        }
        for(String priceDataString : listPriceDataInterestMap.keySet()){
            inputMap(priceDataString, listPriceInterestMap, listPriceDataInterestMap);
        }
        for(String priceDataString : listPriceDataAntecipationMap.keySet()){
            inputMap(priceDataString, listPriceAntecipationMap, listPriceDataAntecipationMap);
        }
        System.debug(listPriceMap);
        System.debug(listPriceInterestMap);
        System.debug(listPriceAntecipationMap);
    }
    public static void inputMap(String priceDataString, Map<String, String[]> returnPriceMap, Map<String, ListPriceData> listPriceMap ){
        String famId = priceDataString.split('_')[0];
        String orgId = priceDataString.split('_')[2];
        if(returnPriceMap.containsKey(famId))
            returnPriceMap.get(famId).add(listPriceMap.get(priceDataString).getDataString());
        else if(returnPriceMap.containsKey(famId+'_'+orgId))
            returnPriceMap.get(famId+'_'+orgId).add(listPriceMap.get(priceDataString).getDataString());
    }*/
    public static void setImageProduct(List<TemplateDataIntegrationFields.Product2INData> request){
        Set<String> prodCodeSet = new Set<String>();
        /*for(TemplateDataIntegrationFields.Product2INData prod : request){
            prodCodeSet.add(prod.ExternalId);
        }

        system.debug(prodCodeSet);
        Map<String, Atonit_Mktplace__Product__c[]> prodMap = new Map<String, Atonit_Mktplace__Product__c[]>();
        Map<Id, Atonit_Mktplace__Product__c> prodInsertedMap = new Map<Id, Atonit_Mktplace__Product__c>([SELECT id, Atonit_ProductCode__c FROM Atonit_Mktplace__Product__c WHERE Atonit_ProductCode__c IN :prodCodeSet]);
        for(Atonit_Mktplace__Product__c prod : prodInsertedMap.values()){
            if(!prodMap.containsKey(prod.Atonit_ProductCode__c))
                prodMap.put(prod.Atonit_ProductCode__c, new List<Atonit_Mktplace__Product__c>());
            prodMap.get(prod.Atonit_ProductCode__c).add(prod);
        }
        system.debug(prodMap);

        List<Atonit_Mktplace__Image__c> imageList = new List<Atonit_Mktplace__Image__c>();
        for(Atonit_Mktplace__Image__c imgs : [SELECT id FROM Atonit_Mktplace__Image__c WHERE Atonit_Mktplace__Product__c IN :prodInsertedMap.keySet()]){
            imageList.add(imgs);
        }
        
        system.debug(imageList);
        if(!imageList.isEmpty())
            Database.delete(imageList, true);

        system.debug(prodMap);
        Map<String, Atonit_Mktplace__Image__c> imageMap = new Map<String, Atonit_Mktplace__Image__c>();
                System.debug(request);
        for(TemplateDataIntegrationFields.Product2INData prod : request){
            if(!prodMap.containsKey(prod.ExternalId)) continue;

            for(Atonit_Mktplace__Product__c prodMkt : prodMap.get(prod.ExternalId)){
                Integer i = 0;
                System.debug( prod.ImageList);
                System.debug(i);
                if(prod.ImageList == null || prod.ImageList.isEmpty()) continue; 
                for(String prodURL : prod.ImageList){
                    system.debug(prodURL);
                    String extId = prodMkt.Id+'_'+i;
                    imageMap.put(extId, getImage(prodURL, prodMkt, i));
                    i++;
                }
            }
        }
        system.debug(imageMap);
        if(!imageMap.isEmpty())
            Database.upsert(imageMap.values(), Atonit_Mktplace__Image__c.Atonit_Mktplace__External_Id__c, true);
        */
    }
    /*
    public static String getJSONCrop(Id prodId, Map<Id, String[]> listPriceMap){
        return '{ '+((prodId == null || !listPriceMap.containsKey(prodId)) ? '' : String.join(listPriceMap.get(prodId), ', '))+' } ';
    }
    public static String getJSONCrop(string prodId, Map<String, String[]> listPriceMap){
        return '{ '+((prodId == null || !listPriceMap.containsKey(prodId)) ? '' : String.join(listPriceMap.get(prodId), ', '))+' } ';
    }
    public static Set<Id> getVariantIdSet(Map<String, ListPriceProductData> priceDataMap){
        Set<Id> idSet= new Set<Id>();
        for(ListPriceProductData price : priceDataMap.values()){
            idSet.add(price.prodVariantId);
        }
        return idSet;
    }
    public static Set<Id> getProductIdSet(Map<String, ListPriceProductData> priceDataMap){
        Set<Id> idSet= new Set<Id>();
        for(ListPriceProductData price : priceDataMap.values()){
            idSet.add(price.prodId);
        }
        return idSet;
    }
    public static Map<String, Atonit_Mktplace__Customer_Group__c> getCustomerMap(Set<String> cropIdSet){
        Map<String, Atonit_Mktplace__Customer_Group__c> returnMap = new Map<String, Atonit_Mktplace__Customer_Group__c>();
        for(Atonit_Mktplace__Customer_Group__c crops : [SELECT id, Atonit_Mktplace__Marketplace_Id__c FROM Atonit_Mktplace__Customer_Group__c WHERE Atonit_Mktplace__Marketplace_Id__c IN :cropIdSet]){
            returnMap.put(crops.Atonit_Mktplace__Marketplace_Id__c, crops);
        }
        return returnMap;
    }
    @future
    public static void upsertInventoryEntry(String dataList){
        Database.upsert((List<Atonit_Mktplace__Inventory_Record__c>)JSON.deserialize(dataList, List<Atonit_Mktplace__Inventory_Record__c>.class), Atonit_Mktplace__Inventory_Record__c.Atonit_Mktplace__External_Id__c, true);
    }
    public static Map<Id, Atonit_Mktplace__Product__c> getProductMap(Set<Id> prodIdSet){
        return new Map<Id, Atonit_Mktplace__Product__c>([SELECT id, Atonit_Mktplace__Main_Category__c, Atonit_Mktplace__Image_URL__c, Atonit_CertificateUrl__c, Atonit_InstructionsUrl__c, Atonit_LabelUrl__c, Atonit_ProductCode__c, Atonit_ActivitySection__c, Atonit_ActivityChannel__c, Atonit_PesoBruto__c, Atonit_UnidadeMedida__c, Atonit_Unidade_Medida_PesoBruto__c, Atonit_PrescriptionRequired__c, Atonit_ProductFamily__c, Atonit_Mktplace__External_Id__c, Atonit_Mktplace__Full_description__c, Atonit_Mktplace__Is_Deleted__c, Atonit_isActive__c, Atonit_Mktplace__Manufacturer__c, Atonit_Mktplace__Name__c, Atonit_Mktplace__Product_type__c, Atonit_Mktplace__Seller_Product__c, Atonit_Mktplace__Short_description__c, Atonit_Mktplace__Status__c, Atonit_Mktplace__Update_Timestamp__c, RecordTypeId
                                                        FROM Atonit_Mktplace__Product__c WHERE Id IN :prodIdSet ]);
    }
    public static Map<Id, Atonit_Mktplace__Seller__c> getSellerMap(Set<Id> prodIdSet){
        return new Map<Id, Atonit_Mktplace__Seller__c>([SELECT id, Atonit_Mktplace__Display_Name__c, Atonit_Mktplace__Slug__c, SalesforceCoreExternalId__c, Atonit_Mktplace__Status__c, RecordTypeId
                                                        FROM Atonit_Mktplace__Seller__c WHERE Id IN :prodIdSet ]);
    }
    public static Map<Id, Atonit_Mktplace__Product_Variant__c> getProductVariantMap(Set<Id> prodIdSet){
        return new Map<Id, Atonit_Mktplace__Product_Variant__c>([SELECT Id, Atonit_Mktplace__Display_Name__c, Atonit_Mktplace__External_Id__c, Atonit_Mktplace__Full_Description__c, Atonit_Mktplace__Image_Link__c, Atonit_Mktplace__Is_Deleted__c, Atonit_Mktplace__Weight__c, Atonit_Mktplace__Main_Product__c, Atonit_Mktplace__Status__c, Atonit_Mktplace__Update_Timestamp__c, Name, Atonit_CropsEffectiveDate__c, Atonit_MaxRtvDiscount__c, Atonit_TaxAfterEffectiveDate__c, Atonit_TaxBeforeEffectiveDate__c
                                                        FROM Atonit_Mktplace__Product_Variant__c WHERE Id IN :prodIdSet ]);
    }

    //Class
    public class InventoryRelatedRecord{
        public Id idRecord {get;set;}
        public Boolean isActive {get;set;}
        public InventoryRelatedRecord(Id objId){
            this.idRecord = objId;
            this.isActive = isActive;
        }
    }

    public class ListPriceProductData{
        public String prodCode {get;set;}
        public String prodId {get;set;}
        public String prodVariantId {get;set;}
        public String salesId {get;set;}
        public ListPrice__c priceList  {get;set;}
        public ListPriceProductData(String salesId, ListPrice__c priceList){
            this.salesId = salesId;
            this.prodId = priceList.AtonnitProductMatched__c;
            this.prodCode = priceList.ProductCode__c;
            this.prodVariantId = priceList.AtonnitProductVariantMatched__c;
            this.priceList = priceList;
        }
    }

    public class ListPriceData{
        public String key {get;set;}
        public Decimal value {get;set;}
        public Date valueString {get;set;}
        public ListPriceData(String key, Decimal value){
            this.key = key;
            this.value = value;
            this.valueString = null;
        }
        public ListPriceData(String key, Date valueString){
            this.key = key;
            this.value = null;
            this.valueString = valueString;
        }
        public String getDataString(){
            return ' \"'+key+'\" : '+(this.value == null ? '\"'+String.valueOf(this.valueString)+'\"': String.valueOf(this.value)); 
        }
    }*/

}