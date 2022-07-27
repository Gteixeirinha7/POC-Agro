public with sharing class OrderPDFController {
    
    public OrderData orderData {get;set;}

    public OrderPDFController() {

        String orderIdPageReference = ApexPages.currentPage().getParameters().get('Id');

        List<Order> orderList = OrderDAO.getOrderById(
            new List<String>{orderIdPageReference}, 
            new Set<String>{
                'Id', 'SalesTeam__r.DisplayName__c', 'SalesTeam__r.Address__c', 'SalesTeam__r.City__r.Name', 'SalesTeam__r.CNPJ__c', 'SalesTeam__r.IE__c',
                'SalesTeam__r.Phone__c', 'SalesTeam__r.PostalCode__c', 'StatusSF__c', 'OrderNumber', 'CreatedDate', 'CreatedDateApp__c', 
                'ExternalIdApp__c', 'PaymentDate__c', 'Crop__r.Name', 'EndDate', 'Currency__c', 'TotalAmountWithFreight__c', 
                'PaymentCondition__r.Name', 'toLabel(PaymentForm__c) paymentForm', 'RTV__r.Name', 'RecordType.Name', 'RecordType.DeveloperName', 
                'Freight__c', 'Account.Name', 'Account.CNPJ__c', 'ShippingAccount__r.Name', 'ShippingAccount__r.CPF__c','ShippingAccount__r.CNPJ__c', 
                'ShippingAccount__r.ShippingStreet', 'ShippingAccount__r.ShippingCity', 'ShippingAccount__r.ShippingState', 
                'ShippingAccount__r.StateRegistration__c', 'Commodity__c', 'DeliveryQuantity__c', 'CommercialMeasureUnit__c'
            }
        );

        List<OrderItem> orderItemList = OrderItemDAO.getOrderItemByOrderId(
            new List<String>{orderIdPageReference}, 
            new Set<String>{
                'Id', 'Product2.Name', 'Product2.ProductCode', 'Quantity__c', 'TotalPrice__c', 'Freight__c'
            }
        );
        
        String orderFreight = 'FOB';
        List<OrderItemData> orderItemDataList = new List<OrderItemData>();
        for (OrderItem orderItem : orderItemList) {
            if (orderItem.Freight__c == 'CIF')
                orderFreight = 'CIF';
            orderItemDataList.add(new OrderItemData(orderItem));
        }

        this.orderData = new OrderData(orderList.get(0), orderFreight, orderItemDataList);

    }

    public class OrderData {
        //order data
        public String id                    {get;set;}
        public String salesTeamName         {get;set;}
        public String salesTeamAddress      {get;set;}
        public String salesTeamCity         {get;set;}
        public String salesTeamCNPJ         {get;set;}
        public String salesTeamIE           {get;set;}
        public String salesTeamPhone        {get;set;}
        public String salesTeamPostalCode   {get;set;}
        public String orderName             {get;set;}
        public String orderNumber           {get;set;}
        public String status                {get;set;}
        public String issueDate             {get;set;}
        public String cropName              {get;set;}
        public String expirationDate        {get;set;}
        public String paymentDate           {get;set;}
        public String coin                  {get;set;}
        public String coinUnit              {get;set;}
        public String totalValue            {get;set;}
        public String paymentConditionName  {get;set;}
        public String paymentForm           {get;set;}
        public String rtvName               {get;set;}
        public String orderTypeName         {get;set;}
        public String commodity             {get;set;}

        //billing data
        public String accountName           {get;set;}
    
        //delivery data
        public String accountIE             {get;set;}
        public String freightModality       {get;set;}
        public String accountRegister       {get;set;}
        public String deliveryAddress       {get;set;}
        public String deliveryCity          {get;set;}
        public String deliveryAccountName   {get;set;}
        public String deliveryState         {get;set;}

        public String hideInfoStyleClass    {get;set;}
        public String borderStyleClass      {get;set;}

        //items data
        public List<OrderItemData> orderItemDataList    {get;set;}

        public OrderData(Order order, String orderFreight, List<OrderItemData> orderItemDataList) {
            this.id                     = order.Id;
            this.salesTeamName          = order.SalesTeam__r.DisplayName__c;
            this.salesTeamAddress       = order.SalesTeam__r.Address__c;
            this.salesTeamCity          = order.SalesTeam__r.City__r?.Name;
            this.salesTeamCNPJ          = order.SalesTeam__r.CNPJ__c;
            this.salesTeamIE            = order.SalesTeam__r.IE__c;
            this.salesTeamPhone         = order.SalesTeam__r.Phone__c;
            this.salesTeamPostalCode    = order.SalesTeam__r.PostalCode__c;
            this.orderNumber            = order.OrderNumber;
            this.orderName              = isContract(order.RecordType.DeveloperName) ? 'Contrato' : 'Pedido';
            this.status                 = order.StatusSF__c;
            this.issueDate              = String.isBlank(order.ExternalIdApp__c) || order.CreatedDateApp__c == null ? order.CreatedDate.format('dd/MM/yyyy') : order.CreatedDateApp__c.format();
            this.cropName               = order.Crop__r.Name;
            this.expirationDate         = order.EndDate?.format();
            this.paymentDate            = order.PaymentDate__c?.format();
            this.coin                   = order.Currency__c == 'BRL' ? 'Real' : order.Currency__c == 'USD' ? 'Dolár' : '';
            this.coinUnit               = order.Currency__c == 'BRL' ? 'R$' : order.Currency__c == 'USD' ? 'US$' : '';
            this.totalValue             = convertToBRL(order.TotalAmountWithFreight__c);
            this.paymentConditionName   = order.PaymentCondition__r.Name;
            this.paymentForm            = String.valueof(order.get('paymentForm'));
            this.rtvName                = order.RTV__r.Name;
            this.orderTypeName          = order.RecordType.Name;
            

            this.accountName            = order.Account.Name;

            this.accountIE              = order.ShippingAccount__r.StateRegistration__c;
            this.freightModality        = orderFreight;
            this.accountRegister        = String.isNotBlank(order.ShippingAccount__r.CPF__c) ?  order.ShippingAccount__r.CPF__c : order.ShippingAccount__r.CNPJ__c;
            this.deliveryAddress        = order.ShippingAccount__r.ShippingStreet;
            this.deliveryCity           = order.ShippingAccount__r.ShippingCity;
            this.deliveryAccountName    = order.ShippingAccount__r.Name;
            this.deliveryState          = order.ShippingAccount__r.ShippingState;

            this.orderItemDataList      = orderItemDataList;
            
            
            if (order.RecordType.DeveloperName == 'BarterSale' ) {
                this.commodity          = order.Commodity__c;
                this.coinUnit           = order.CommercialMeasureUnit__c;
                this.totalValue         = convertQtdToBRL(order.DeliveryQuantity__c);
                this.hideInfoStyleClass = '';
                this.borderStyleClass   = '';
            } else {
                this.commodity          = 'Não atribuído';
                this.coinUnit           = order.Currency__c == 'BRL' ? 'R$' : order.Currency__c == 'USD' ? 'US$' : '';
                this.totalValue         = convertToBRL(order.TotalAmountWithFreight__c);
                this.hideInfoStyleClass = 'hide';
                this.borderStyleClass   = 'no-border';
            }
        }
    }

    public class OrderItemData {
        public String productCode          {get;set;}
        public String productDescription   {get;set;}
        public String quantity             {get;set;}
        public String totalPrice           {get;set;}

        public OrderItemData(OrderItem orderItem) {
            this.productCode        = orderItem.Product2.ProductCode;
            this.productDescription = orderItem.Product2.Name;
            this.quantity           = convertQtdToBRL(orderItem.Quantity__c);
            this.totalPrice         = convertToBRL(orderItem.TotalPrice__c);
        }
    }

    public static Boolean isContract(String orderType) {
        Set<String> contractDeveloperNames = new Set<String>{'ZCCO', 'ZCEF', 'ZCNO', 'BarterSale'};
        return contractDeveloperNames.contains(orderType);
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

    public static String convertQtdToBRL(Decimal num){
        List<String> args = new String[]{'0','number','###.###.##0,000'};
        String numConverted =  String.format(num.setScale(3).format(), args);
        return numConverted;
    } 

    @RemoteAction
    public static void createContentDistribuction(String contentVersionId, String orderId, String fileName) {
        CreateContentDistribution.createContentDistribuction(contentVersionId, orderId, fileName);
    }

    @RemoteAction
    public static String getUserSessionKey() {
        return UserInfo.getSessionId();
    }

}
