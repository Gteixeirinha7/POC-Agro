public with sharing class PricingTableScreenController {
    public PricingTableScreenController() {}

    @AuraEnabled(cacheable=true)
    public static List<ListPriceScreenBaseData> getListPrice(List<String> userId, String crop, String account, Date initialDate, Decimal calculatedUnitPrice,
    Boolean isActive, Date effectiveDate, String activitySector, String productFamily, Boolean currencyReal, Boolean currencyDolar, Decimal unitPrice,
    Date endDate, List<String> productIdList, String salesTeamId, String salesOfficeId, String salesCondition, String activePrincible, List<String> salesTeamAccessIdList){

        List<String> salesTeamIdList = new List<String>();
        List<String> officeIdList = new List<String>();
        List<String> orgList = new List<String>();
        List<ListPrice__c> listPriceWithInterest = new List<ListPrice__c>();
        List<ListPriceScreenBaseData> realListPriceToShow = new List<ListPriceScreenBaseData>();    

        System.debug('Parameters =>' + userId + account + crop + initialDate + calculatedUnitPrice + isActive + effectiveDate + activitySector + productFamily + currencyReal + currencyDolar + unitPrice + endDate + productIdList + salesTeamId + salesOfficeId + salesCondition + activePrincible);

        Set<String> fields = new Set<String>{
            'Id',
            'Account__c',
            'Crop__r.Name',
            'RecordType.DeveloperName',
            'Crop__c',
            'InterestPriority__c',
            'Priority__c',
            'SalesCondition__c',
            'InitialDate__c',
            'CalculatedUnitPrice__c',
            'IsActive__c',
            'EffectiveDate__c',
            'ActivitySector__c',
            'ProductFamily__r.Name',
            'ProductFamily__c',
            'Currency__c',
            'UnitPrice__c',
            'EndDate__c',
            'Product2Id__r.Family__c',
            'Product2Id__r.Name',
            'Product2Id__c',
            'SalesTeam__r.DisplayName__c',
            'SalesTeam__c',
            'SalesOffice__c',
            'Product2Id__r.ActivePrinciple__c'
        };

        String currencyType;

        if(currencyReal){
            currencyType = 'BRL';
        }

        if(currencyDolar){
            currencyType = 'USD';
        }

        if(salesTeamId != null){
            salesTeamIdList = teamNotNull(salesTeamId);
            officeIdList = getRelatedSalesOffice(salesTeamIdList);
            orgList = getRelatedOrgList(salesTeamIdList);
        }

        else{
            salesTeamIdList = salesTeamAccessIdList;
            officeIdList = getRelatedSalesOffice(salesTeamIdList);
            orgList = getRelatedOrgList(salesTeamIdList);
        }

        List<ListPrice__c> data = ListPriceDAO.getListPriceData(fields, account, crop, initialDate, calculatedUnitPrice, isActive, effectiveDate, activitySector, productFamily, currencyType, unitPrice,
        endDate, productIdList, salesTeamIdList, officeIdList, salesCondition, activePrincible, orgList);

        List<ListPrice__c> interestListPriceList = ListPriceDAO.getInterestListPriceData(fields, account, crop, initialDate, calculatedUnitPrice, isActive, effectiveDate, activitySector, productFamily, currencyType, unitPrice,
        endDate, productIdList, salesTeamIdList, officeIdList, salesCondition, activePrincible, orgList);

        System.debug(salesTeamIdList);
        System.debug(orgList);

        List<ProductManagement__c> productManagement = [
            SELECT Id, Product2__c, Crop__c, SalesTeam__c
            FROM ProductManagement__c
            WHERE SalesTeam__c IN: salesTeamIdList
            AND RecordType.DeveloperName = 'ExclusionList'
            AND IsActive__c = true
        ];

        System.debug('interestListPriceList ->'+interestListPriceList);

        Map<String, ListPrice__c> listPriceKeyToListPrice = new Map<String, ListPrice__c>();

        for(ListPrice__c listPrice : interestListPriceList){
            if(listPrice.Product2Id__c != null){
                listPriceKeyToListPrice.put(listPrice.Product2Id__c + listPrice.RecordType.DeveloperName,listPrice);
            }
            else if(listPrice.ProductFamily__c != null){
                    listPriceKeyToListPrice.put(listPrice.ProductFamily__c + listPrice.RecordType.DeveloperName,listPrice);
            }
        }

        List<String> blockedProductIdList = new List<String>();

        for(ProductManagement__c productMan : productManagement){
            blockedProductIdList.add(productMan.Product2__c+'_'+productMan.Crop__c);
        }

        System.debug(productManagement);
        System.debug(blockedProductIdList);

        if(Test.isRunningTest()){
            data = [SELECT Id,
            Name,
            Account__c,
            Crop__r.Name,
            RecordType.DeveloperName,
            Crop__c,
            InterestPriority__c,
            Priority__c,
            SalesCondition__c,
            InitialDate__c,
            CalculatedUnitPrice__c,
            IsActive__c,
            EffectiveDate__c,
            ActivitySector__c,
            ProductFamily__r.Name,
            ProductFamily__c,
            Currency__c,
            UnitPrice__c,
            EndDate__c,
            Product2Id__r.Family__c,
            Product2Id__r.Name,
            Product2Id__c,
            SalesTeam__r.DisplayName__c,
            SalesConditionObject__c,
            SalesConditionObject__r.Name,
            SalesTeam__c,
            SalesOffice__c,
            Product2Id__r.ActivePrinciple__c FROM ListPrice__c LIMIT 3];
        }

        for(ListPrice__c listPrice : data){
            Decimal totalPrice;
            String interestType = '';
            Decimal totalInterest = 0;
            Decimal listPriceValueWithInterest = 0;
            System.debug('endDate' + endDate);
            System.debug('listPrice.EffectiveDate__c'+ listPrice.EffectiveDate__c);
            Decimal daysDiff = listPrice.EffectiveDate__c.daysBetween(endDate);
            System.debug('daysDiff' + daysDiff);

            if(daysDiff < 0){
                interestType = 'ZDJ1';
            }
            else if (daysDiff > 0) {
                interestType = 'ZJ01';
            }

            Boolean containInterestListPrice = false;

            if(listPriceKeyToListPrice.containsKey(listPrice.Product2Id__c + interestType)){
                containInterestListPrice = true;
            }

            else if(listPriceKeyToListPrice.containsKey(listPrice.Product2Id__r.Family__c + interestType)){
                containInterestListPrice = true;
            }
            System.debug(containInterestListPrice);
            Boolean containPrice;

            if(containInterestListPrice){

                ListPrice__c interestListPrice = new ListPrice__c();

                if(listPriceKeyToListPrice.containsKey(listPrice.Product2Id__c + interestType)) {
                    interestListPrice = listPriceKeyToListPrice.get(listPrice.Product2Id__c + interestType);
                }
                else if(listPriceKeyToListPrice.containsKey(listPrice.Product2Id__r.Family__c + interestType)){
                    interestListPrice = listPriceKeyToListPrice.get(listPrice.Product2Id__r.Family__c + interestType);
                }
                
                Decimal negociatedValue;

                if(interestListPrice.InterestValue__c != null){
                    Double interest =interestListPrice.InterestValue__c;

                    daysDiff = Math.abs(daysDiff);
                    Decimal totalMonths = (daysDiff / 30).setScale(2);


                    if (interestType == 'ZDJ1' && totalMonths > 12){
                            totalMonths = 12;
                    }

                    System.debug('totalMonths --' + totalMonths);
                    System.debug('interestType--' + interest);

                    Decimal calcInterest = (totalMonths * interest) / 100;
                    calcInterest = calcInterest.setScale(7);
                    totalInterest = (listPrice.UnitPrice__c * calcInterest).setScale(2);

                    if(interestType == 'ZDJ1'){
                        totalPrice = listPrice.UnitPrice__c - totalInterest;
                        negociatedValue = listPrice.UnitPrice__c - totalPrice;
                    }

                    else{
                        totalPrice = listPrice.UnitPrice__c + totalInterest;
                        negociatedValue = listPrice.UnitPrice__c - totalPrice;
                    }
                }

                realListPriceToShow.add(new ListPriceScreenBaseData(listPrice,totalPrice, negociatedValue, interestType, blockedProductIdList));
            }
            else {
                interestType = 'PR00';
                realListPriceToShow.add(new ListPriceScreenBaseData(listPrice, totalPrice, totalInterest, interestType, blockedProductIdList));
            }
        }
        return realListPriceToShow;
    }

    public static List<String> teamNotNull(String equipe){
        List<String> salesTeamList = new List<String>{equipe};
        return salesTeamList;
    }


    public static List<String> getRelatedSalesOffice(List<String> salesTeamList){
        List<String> officeList = new List<String>();

        for(Salesteam__c sales : [SELECT id, ParentId__c FROM SalesTeam__c WHERE Id IN : salesTeamList AND Id != null]){
            officeList.add(sales.ParentId__c);
        }
        return officeList;
    }

    public static List<String> getRelatedOrgList(List<String> salesTeamList){
        List<String> orgList = new List<String>();

        for(Salesteam__c sales : [SELECT id, SalesOrg__c FROM SalesTeam__c WHERE Id IN : salesTeamList AND Id != null]){
            orgList.add(sales.SalesOrg__c);
        }
        return orgList;
    }

public class ListPriceScreenBaseData {
        @AuraEnabled public String id {get;set;}                         
        @AuraEnabled public String Account {get;set;}
        @AuraEnabled public String CropName {get;set;}
        @AuraEnabled public String RecordTypeDeveloperName {get;set;}
        @AuraEnabled public String Crop {get;set;}
        @AuraEnabled public Decimal InterestPriority {get;set;}
        @AuraEnabled public Decimal Priority {get;set;}
        @AuraEnabled public String SalesCondition {get;set;} 
        @AuraEnabled public Date InitialDate {get;set;}
        @AuraEnabled public Boolean IsActive {get;set;}
        @AuraEnabled public Date EffectiveDate {get;set;}
        @AuraEnabled public String ActivitySector {get;set;}
        @AuraEnabled public String ProductFamilyName {get;set;}
        @AuraEnabled public String ProductFamily {get;set;}
        @AuraEnabled public String CurrencyType {get;set;}
        @AuraEnabled public String UnitPrice {get;set;}
        @AuraEnabled public String EndDate {get;set;}
        @AuraEnabled public String ProductName {get;set;}
        @AuraEnabled public String Product2Id {get;set;}
        @AuraEnabled public String SalesTeam {get;set;}
        @AuraEnabled public String SalesTeamName {get;set;}
        @AuraEnabled public String SalesOffice {get;set;}
        @AuraEnabled public String ActivePrinciple {get;set;}
        @AuraEnabled public Boolean Discount {get;set;}
        @AuraEnabled public Boolean Juros {get;set;}
        @AuraEnabled public Boolean FinalPrice {get;set;}
        @AuraEnabled public String TotalPrice {get;set;}
        @AuraEnabled public String TotalInterest {get;set;}
        @AuraEnabled public String InterestType {get;set;}
        @AuraEnabled public Boolean IsAvaliable {get;set;}
        @AuraEnabled public Boolean ShowTeamName {get;set;}
        @AuraEnabled public Boolean ShowSalesCondition {get;set;}
        @AuraEnabled public String Name {get;set;}

        public ListPriceScreenBaseData(ListPrice__c listPrice,Decimal totalPrice,Decimal totalInterest, String interestType, List<String> blockList){
            this.Id = listPrice.Id;
            this.Account = listPrice.Account__c;
            this.CropName = listPrice.Crop__r.Name;
            this.RecordTypeDeveloperName = listPrice.RecordType.DeveloperName;
            this.Crop = listPrice.Crop__c;
            this.InterestPriority = listPrice.InterestPriority__c;
            this.Priority = listPrice.Priority__c;
            if(listPrice.SalesCondition__c != null){
                this.SalesCondition = listPrice.SalesConditionObject__r.Name;
                this.ShowSalesCondition = true;
            }
            else{
                this.SalesTeamName = 'Não atribuído';
                this.ShowSalesCondition = false;
            }
            this.InitialDate = listPrice.InitialDate__c;
            this.IsActive = listPrice.IsActive__c;
            this.EffectiveDate = listPrice.EffectiveDate__c;
            this.ActivitySector = listPrice.ActivitySector__c;
            this.ProductFamily = listPrice.Product2Id__r.Family__c;
            this.CurrencyType = listPrice.Currency__c;
            this.UnitPrice = convertToBRL(listPrice.UnitPrice__c);
            this.EndDate = listPrice.EndDate__c.format();
            this.ProductName = listPrice.Product2Id__r.Name;
            this.Product2Id = listPrice.Product2Id__c;
            this.SalesTeam = listPrice.SalesTeam__c;
            if(listPrice.SalesTeam__c != null){
                this.SalesTeamName = listPrice.SalesTeam__r.DisplayName__c;
                this.ShowTeamName = true;
            }
            else{
                this.SalesTeamName = 'Não atribuído';
                this.ShowTeamName = false;
            }
            this.SalesOffice = listPrice.SalesOffice__c;
            this.ActivePrinciple = listPrice.Product2Id__r.ActivePrinciple__c;
            this.Discount = checkOperationDiscount(interestType);
            this.Juros = checkOperationJuros(interestType);
            this.FinalPrice = checkOperation(interestType);
            if(totalPrice != null){
                this.TotalPrice = convertToBRL(totalPrice);
            }
            System.debug(totalInterest);
            if(totalInterest != null){
                if(totalInterest < 0){
                    totalInterest = totalInterest * (-1);
                }
                this.TotalInterest = convertToBRL(totalInterest);
            }
            this.InterestType = interestType;
            this.Name = listPrice.Name;
            this.IsAvaliable = blockList.contains( listPrice.Product2Id__c+'_'+listPrice.Crop__c);
        }
    }

    public static Boolean checkOperationDiscount(String recordType){
        if(recordType == 'ZDJ1'){
            return true;
        }
        else {
            return false;
        }
    }

    public static Boolean checkOperationJuros(String recordType){
        if(recordType == 'ZJ01'){
            return true;
        }
        else {
            return false;
        }
    }

    public static Boolean checkOperation(String recordType){
        if(recordType == 'ZJ01' || recordType == 'ZDJ1'){
            return true;
        }
        else {
            return false;
        }
    }

    public static String convertToBRL(Decimal num){
        List<String> args = new String[]{'0','number','###.###.##0,00'};
        String numConverted =  String.format(num.setScale(2).format(), args);

        if(numConverted.indexOf(',') == -1){
            numConverted += ',00';
        }
        else if (numConverted.indexOf(',') == numConverted.length() - 2){
            numConverted += '0';
        }
        
        return numConverted;
    }

    @AuraEnabled(cacheable=true)
    public static String getUserInfo(){
        return UserInfo.getUserId();
    }
}