global with sharing class TemplateDataIntegrationFields {

    public interface FieldData {
        List<String> getRequiredFields(FieldData obj);
        String getFieldKey();
        String getFieldId();
        SObject serialize(Map<String, Id> lookups);
    }
    
    public interface FieldDataChild {
        List<String> getRequiredFields(FieldDataChild obj);
        String getFieldKey();
        String getFieldExternal();
        SObject serialize(Map<String, String> lookups);
        String getParentKey();
    }

    
    
    //ListPrice input structure -> Implementing FieldData
    global class ListPriceINData implements FieldData{
        
        //JSON fields
        public String       ExternalId;
        public KeyClass     RecordType;
        public String       RecordTypeName;
        public String       Description;
        public KeyClass     SalesOrganization;
        public String       PriceList;
        public String       PriceListName;
        public KeyClass     Crop;
        public KeyClass     Account;
        public String       AccountType;
        public KeyClass     SalesOffice;
        public KeyClass     SalesTeam;
        public String       SalesSection;
        public String       InitialDate;
        public String       EndDate;    
        public String       CurrencyCode;
        public String       Unidade;
        public Decimal      PriceMultiplier;
        public String       EffectiveDate;
        public Boolean      isActive;
        public Decimal      UnitPrice;
        public KeyClass     Product2Id;
        public Decimal      InterestValue;
        public KeyClass     ProductFamily;

        public Boolean      hasError;

        // public ListPriceINData(){

        // }

        public ListPrice__c serialize(Map<String, Id> lookups){



                // Alterar a integração de recebimento de listas de preço
                // do SAP para o Salesforce, aonde será enviada uma nova
                // Lista de preço com o parametro de ZPRS, no parametro
                // da integração: RecordTypeName.

                // Durante a integração de catalogo de preço, IntegrationListPriceIN,
                // verificar se o parametro RecordTypeName é igual a ZPRS, se caso
                // for igual a ZPRS, Não preencher o campo UnitPrice__c, e
                // sim preencher o campo Cost__c, com a seguinte regra:
                // (this.UnitPrice == null ? 1 : this.UnitPrice ) /
                // (this.PriceMultiplier == 0 ||
                // this.PriceMultiplier == null ? 1 : this.PriceMultiplier)

            Decimal toUnitPrice =(this.UnitPrice == null ? 1 : this.UnitPrice ) / (this.PriceMultiplier == 0 || this.PriceMultiplier == null ? 1 : this.PriceMultiplier);
            Decimal toCost =null;
            if (this.RecordType.Name=='ZPRS'){
                toUnitPrice =null;
                toCost =(this.UnitPrice == null ? 1 : this.UnitPrice ) /(this.PriceMultiplier == 0 || this.PriceMultiplier == null ? 1 : this.PriceMultiplier);
            }

            ListPrice__c lists =  new ListPrice__c(
                UnitPrice__c                  = null,
                Cost__c                  = null,
                ExternalId__c            = this.ExternalId,
                ListPriceCode__c         = this.ExternalId?.replaceFirst('^0+',''),
                RecordTypeId             = Schema.SObjectType.ListPrice__c.getRecordTypeInfosByDeveloperName().get(this.RecordTypeName).getRecordTypeId(),
                Description__c           = this.Description,
                SalesOrgName__c          = this.SalesOrganization?.ExternalId,
                SalesOrg__c              = lookups.containsKey('SalesOrg'+this.SalesOrganization?.ExternalId) ? lookups.get('SalesOrg'+this.SalesOrganization?.ExternalId) : null,
                SalesCondition__c        = this.PriceList != null && this.PriceList.contains('ALL') ? 'ALL' : this.PriceList,
                SalesConditionObject__c  = lookups.containsKey('SalesCondition'+this.PriceList) ? lookups.get('SalesCondition'+this.PriceList) : null,
                Crop__c                  = this.Crop == null ? null : lookups.containsKey('Crop'+this.Crop?.ExternalId) ? lookups.get('Crop'+this.Crop?.ExternalId) : null,
                Account__c               = lookups.containsKey('Account'+this.Account?.ExternalId) ? lookups.get('Account'+this.Account?.ExternalId) : null,
                CustomerGroup__c         = this.AccountType,
                SalesOffice__c           = lookups.containsKey('SalesOffice'+this.SalesOffice?.ExternalId) ? lookups.get('SalesOffice'+this.SalesOffice?.ExternalId) : null,
                SalesTeam__c             = lookups.containsKey('SalesTeam'+this.SalesTeam?.ExternalId) ? lookups.get('SalesTeam'+this.SalesTeam?.ExternalId) : null,
                ActivitySector__c        = this.SalesSection,
                InitialDate__c           = !(IntegrationUtils.convertEmptyString(this.InitialDate)) ? Date.ValueOf(this.InitialDate) : null,
                EndDate__c               = !(IntegrationUtils.convertEmptyString(this.EndDate)) ? Date.ValueOf(this.EndDate) : null,
                Currency__c              = this.CurrencyCode?.trim(),
                UnitMeasurement__c       = this.Unidade,
                PriceMultiplier__c       = this.PriceMultiplier,
                EffectiveDate__c         = !(IntegrationUtils.convertEmptyString(this.EffectiveDate)) ? Date.ValueOf(this.EffectiveDate) : null,
                isActive__c              = this.isActive,
                OriginalUnitPrice__c     = this.UnitPrice,
                Product2Id__c            = lookups.containsKey('Product2'+this.Product2Id?.ExternalId) ? lookups.get('Product2'+this.Product2Id?.ExternalId) : null,
                InterestValue__c         = this.InterestValue,
                ProductFamily__c         = lookups.containsKey('ProductFamily'+this.ProductFamily?.ExternalId) ? lookups.get('ProductFamily'+this.ProductFamily?.ExternalId) : null
            );
            if(this.RecordType.Name=='ZPRS'){
                lists.Cost__c                  = toCost;                
            }else{
                lists.UnitPrice__c             = (this.UnitPrice == null ? 1 : this.UnitPrice ) / (this.PriceMultiplier == 0 || this.PriceMultiplier == null ? 1 : this.PriceMultiplier);
            }
            return lists;
        }
        
        //Required fields for integration
        public List<String> getRequiredFields(FieldData obj){
            ListPriceINData nObj = (ListPriceINData)obj;
            //Example
            List<String> reqList = new List<String>{
                'ExternalId__c',
                'RecordTypeId',
                'SalesOrg__c'
            };
            if(nObj.RecordType.Name == 'PR00'){
                reqList.addAll(new List<String>{
                    //'SalesCondition__c',
                    'InitialDate__c',
                    'EndDate__c',
                    'Currency__c',
                    'UnitMeasurement__c',
                    'EffectiveDate__c',
                    'UnitPrice__c',
                    'Product2Id__c'
                });
            }else if(nObj.RecordType.Name != 'ZPRS'){
                reqList.addAll(new List<String>{
                    'InterestValue__c'
                });
            }
            System.debug(reqList);

            return reqList;
        }

        //ExternalId field
        public String getFieldKey(){
            return 'ExternalId__c';
        }
        
        //Id field
        public String getFieldId() {
            return 'Id';
        }
    }

    global class Product2INData implements FieldData{
        
        //JSON fields
        public String   ExternalId;
        public String   ProductCode;
        public String   Name;
        public String   Description;
        public Decimal  Multiplicity;
        public String   ActivitySection;
        public KeyClass SalesOrganization;
        public String   StatusOrganizacaoVendas;
        public String   ActivityChannel;
        public String   ProductType;
        public String   PrincipioAtivo;
        public KeyClass Family;
        public Boolean  isActive;
        public Decimal  GrossWeight;
        public String   GrossWeightUnity;
        public String   QuantityUnitOfMeasure;

        public String   NCM;
        public String   NumeroRegistro;

        public String   Marca;
        public String   Categoria;
        public String   Fornecedor;
        public Boolean   Prescricao;
        public String   CertificadoImagem;
        public String   InstrucaoImagem;
        public String   RotuloImagem;
        public String[]   ImageList;

        public Product2 serialize(Map<String, Id> lookups){

            //Returning Object with Fields.
            return new Product2(
                Brand__c                   = this.Marca,
                ExternalId__c              = this.ExternalId,
                ProductCode                = this.ProductCode,
                Name                       = this.Name,
                Description                = this.Description,
                ActivitySector__c          = this.ActivitySection,
                Multiplicity__c            = this.Multiplicity,
                ActivePrinciple__c         = this.PrincipioAtivo,
                NCM__c                     = this.NCM,
                RegisterNumber__c          = this.NumeroRegistro,
                SalesOrg__c                = lookups.containsKey('SalesOrg'+this.SalesOrganization?.ExternalId) ? lookups.get('SalesOrg'+this.SalesOrganization?.ExternalId) : null,
                SalesOrganizationStatus__c = this.StatusOrganizacaoVendas,
                DistributionChannel__c     = this.ActivityChannel,
                ProductType__c             = this.ProductType,
                Family__c                  = lookups.containsKey('ProductFamily'+this.Family?.ExternalId) ? lookups.get('ProductFamily'+this.Family?.ExternalId) : null,
                isActive                   = this.isActive,
                Manufacturer__c              = this.Fornecedor,
                GrossWeight__c             = (this.QuantityUnitOfMeasure == 'BB' ? 1000 : this.GrossWeight),
                GrossWeightUnity__c        = this.GrossWeightUnity,
                PrescriptionRequired__c    = this.Prescricao,
                CertificateUrl__c          = this.CertificadoImagem,
                InstructionsUrl__c         = this.InstrucaoImagem,
                LabelUrl__c                = this.RotuloImagem,
                QuantityUnitOfMeasure      = this.QuantityUnitOfMeasure
            );
        }
        
        //Required fields for integration
        public List<String> getRequiredFields(FieldData obj){
            return new List<String>{
                'ExternalId__c',
                'ProductCode',
                'Name',
                'Description',
                'Multiplicity__c',
                'GrossWeight__c',
                'SalesOrg__c',
                'GrossWeightUnity__c',
                'QuantityUnitOfMeasure'
            };
        }

        //ExternalId field
        public String getFieldKey(){
            return 'ExternalId__c';
        }
        
        //Id field
        public String getFieldId() {
            return 'Id';
        }
    }
    //Required fields for integration
    global class CustomerPerOrgINData implements FieldDataChild{
    //JSON fields
        public Boolean Blocked;
        public String  relatedAccountId;
        public String  SalesOrgCode;
        public String  SetorAtividade;
        public String  RegiaoVendas;
        public String  CanalDistribuicao;
        public String  GrupoClientes;
        public String  RTVs;

        public CustomerPerOrg__c serialize(Map<String, Id> lookups){
            //Returning Object with Fields.
            return new CustomerPerOrg__c(   
                ExternalId__c           = relatedAccountId +'|'+ SalesOrgCode +'|'+ CanalDistribuicao +'|'+ SetorAtividade,             
                Blocked__c              = (this.Blocked != null) ? this.Blocked : false,
                DistributionChannel__c  = this.CanalDistribuicao,
                Customer__c             = lookups.containsKey('Account'+this.relatedAccountId) ? lookups.get('Account'+this.relatedAccountId) : null,
                ClientGroup__c          = getAccountGroup(this.GrupoClientes, this.SalesOrgCode),
                SalesOrg__c             = lookups.containsKey('SalesOrg'+this.SalesOrgCode) ? lookups.get('SalesOrg'+this.SalesOrgCode) : null,
                ActivitySector__c       = this.SetorAtividade,
                SalesSector__c          = this.RegiaoVendas,
                RTVExternalIds__c       = this.RTVs
            );
        }
        public String getAccountGroup(String groups, String salesOrg){
            if(!IntegrationUtils.convertEmptyString(this.GrupoClientes)) return this.GrupoClientes;

            Map<String, AccountGroupIntegration__c> accGroupMap = AccountGroupIntegration__c.getAll();

            if(accGroupMap.containsKey(salesOrg))
                return accGroupMap.get(salesOrg).ClientGroup__c;
            else
                return 'C2';
        }
        //Required fields for integration
        public List<String> getRequiredFields(FieldDataChild obj){
            //Example
            return new List<String>{
                'ExternalId__c',
                'Customer__c',
                'DistributionChannel__c',
                'ActivitySector__c',
                'SalesSector__c',
                'SalesOrg__c',
                'ClientGroup__c'
            };
        }
        //Key field
        public String getFieldKey(){
            return 'Id';
        }

        //ExternalId field
        public String getFieldExternal(){
            return 'ExternalId__c';
        }
        
        //Parent ExternalId field
        public String getParentKey(){
            return 'Customer__c';
        }
    }
    //Account input structure -> Implementing FieldData
    global class AccountINData implements FieldData{
        
        //JSON fields
        public String       CodigoSAP;
        public String       RecordType;
        public String       Nome;
        public String       Sobrenome;
        public String       NomePropriedade;
        public String       ShippingStreet;
        public String       ShippingCity;
        public String       ShippingState;
        public String       ShippingCountry;
        public String       ShippingPostalCode;
        public String       BillingStreet;
        public String       BillingCity;
        public String       BillingState;
        public String       BillingCountry;
        public String       BillingPostalCode;
        public String       ParentId;
        public String       CNPJ;
        public String       CPF;
        public String       InscricaoMunicipal;
        public String       InscricaoEstadual;
        public Boolean      Blocked;
        public String       GrupoClientes;
        public String       Email;
        public String       Phone;
        public String       RegiaoVendas;
        public String       CertidaoDebito;
        public String       DataCertidao;
        public String       Status;
        public String       OrganizacaoVendas;
        public String       StatusOrganizacaoVendas;
        //public String       EscritorioVendas;
        //public String       EquipeVendas;
        public String       SetorAtividade;
        public String       CanalDistribuicao;
        public String       DomicilioFiscal;
        public List<TemplateDataIntegrationFields.AccountTeamMemberINData> RTVs = new List<TemplateDataIntegrationFields.AccountTeamMemberINData>();
        public List<TemplateDataIntegrationFields.RatingCreditINData> RatingList = new List<TemplateDataIntegrationFields.RatingCreditINData>();

        public Account serialize(Map<String, Id> lookups){

            String names = !(IntegrationUtils.convertEmptyString(this.NomePropriedade)) ? this.Nome +' '+ this.Sobrenome +' '+ this.NomePropriedade : this.Nome +' '+ this.Sobrenome;
            string recordTypeString = ' - ' + this.RecordType;

            Integer recordTypeMax = (255-recordTypeString.length());

            //Returning Object with Fields.
            return new Account(
                Id                       = lookups.containsKey('Account'+this.CodigoSAP) ? lookups.get('Account'+this.CodigoSAP) : null,
                RecordTypeId             = lookups.containsKey('RecordType'+this.RecordType) ? lookups.get('RecordType'+this.RecordType) : null,
                ExternalId__c            = this.CodigoSAP,
                Name                     = names.substring(0, names.length() > recordTypeMax ? recordTypeMax : names.length()) + recordTypeString,
                Surname__c               = this.Sobrenome,
                ShippingStreet           = this.ShippingStreet,
                ShippingCity             = this.ShippingCity,
                ShippingState            = this.ShippingState,
                ShippingCountry          = this.ShippingCountry,
                ShippingPostalCode       = this.ShippingPostalCode,
                BillingStreet            = this.BillingStreet,
                BillingCity              = this.BillingCity,
                BillingState             = this.BillingState,
                BillingCountry           = this.BillingCountry,
                BillingPostalCode        = this.BillingPostalCode,
                ParentId                 = lookups.containsKey('Account'+this.ParentId) ? lookups.get('Account'+this.ParentId) : null,
                CNPJ__c                  = this.CNPJ,
                CPF__c                   = this.CPF,
                MunicipalRegistration__c = this.InscricaoMunicipal,
                StateRegistration__c     = this.InscricaoEstadual,
                Blocked__c               = (this.Status == 'Bloqueado'),
                //CustomerGroup__c         = this.GrupoClientes,
                Email__c                 = this.Email,
                Phone__c                 = this.Phone,
                //SalesSector__c           = this.RegiaoVendas,
                NCD__c                   = this.CertidaoDebito,
                NCDDate__c               = !(IntegrationUtils.convertEmptyString(this.DataCertidao)) ? Date.ValueOf(this.DataCertidao) : null,
                Status__c                = this.Status,
                //SalesOrg__c              = lookups.containsKey('SalesOrg'+this.OrganizacaoVendas) ? lookups.get('SalesOrg'+this.OrganizacaoVendas) : null,
                //StatusSalesOrg__c        = this.StatusOrganizacaoVendas,
                //SalesOffice__c           = lookups.containsKey('SalesOffice'+this.EscritorioVendas) ? lookups.get('SalesOffice'+this.EscritorioVendas) : null,
                //SalesTeam__c             = lookups.containsKey('SalesTeam'+this.EquipeVendas) ? lookups.get('SalesTeam'+this.EquipeVendas) : null,
                //ActivitySector__c        = this.SetorAtividade,
                //DistributionChannel__c   = this.CanalDistribuicao,
                FiscalDomicile__c        = this.DomicilioFiscal,
                InternShippingCity__c    = lookups.containsKey('City'+this.DomicilioFiscal) ? lookups.get('City'+this.DomicilioFiscal) : null
            );
        }
        
        //Required fields for integration
        public List<String> getRequiredFields(FieldData obj){
            //Example
            return new List<String>{
                'RecordTypeId',
                'ExternalId__c',
                'Name',
                //'Surname__c',
                'ShippingStreet',
                'ShippingCity',
                'ShippingState',
                'ShippingCountry',
                'ShippingPostalCode',
                'BillingStreet',
                'BillingCity',
                'BillingState',
                'BillingCountry',
                'BillingPostalCode',
                //'StateRegistration__c',
                //'Email__c',
                //'Phone__c',
                //'SalesSector__c',
                //'NCD__c',
                //'NCDDate__c',
                //'SalesOrg__c',
                //'SalesOffice__c',
                //'SalesTeam__c',
                //'ActivitySector__c',
                'FiscalDomicile__c'
                //'DistributionChannel__c'
            };
        }

        //ExternalId field
        public String getFieldKey(){
            return 'ExternalId__c';
        }
        
        //Id field
        public String getFieldId() {
            return 'Id';
        }
    }

    //RatingCredit__c input structure -> Implementing FieldDataChild
    global class RatingCreditINData implements FieldData{
        
        //JSON fields
        public String  Crop;
        public String  AccountId;
        public String  Rating;
        public String  RatingSAP;
        public Decimal  Value;

        public RatingCredit__c serialize(Map<String, Id> lookups){
            //Returning Object with Fields.
            return new RatingCredit__c(                
                // Crop__c        = lookups.containsKey('Crop'+this.Crop) ? lookups.get('Crop'+this.Crop) : null,
                Account__c     = lookups.containsKey('Account'+this.AccountId) ? lookups.get('Account'+this.AccountId) : null,
                Rating__c      = this.Rating,
                RatingSAP__c   = this.getRatingSAP(),
                // Value__c       = this.Value,
                ExternalId__c  = this.AccountId
            );
        }

        public String getRatingSAP(){
            Map<String, String> ratingMap = new Map<String, String>{
                '++' => 'AA',
                'AA' => 'AA',
                'muito positivo' => 'AA',
                '+' => 'A',
                'A' => 'A',
                'positivo' => 'A',
                '--' => 'D',
                'D' => 'D',
                'muito negativo' => 'D',
                '-' => 'C',
                'C' => 'C',
                'negativo' => 'C',
                'O' => 'B',
                'B' => 'B',
                'invariável' => 'B'
            };

            return ratingMap.get(this.RatingSAP);
        }
        //Required fields for integration
        public List<String> getRequiredFields(FieldData obj){
            //Example
            return new List<String>();
        }

        //Key field
        public String getFieldKey(){
            return 'Id';
        }

        //Parent ExternalId field
        public String getFieldId(){
            return 'Id';
        }
    }

    //AccountTeamMember input structure -> Implementing FieldDataChild
    global class AccountTeamMemberINData implements FieldDataChild{
        
        //JSON fields
        public String  CodigoRTVSAP;
        public String  relatedAccountId;

        public AccountTeamMember serialize(Map<String, Id> lookups){
            //Returning Object with Fields.
            return new AccountTeamMember(                
                UserId                 = lookups.containsKey('User'+this.CodigoRTVSAP) ? lookups.get('User'+this.CodigoRTVSAP) : null,
                AccountId              = this.relatedAccountId,
                TeamMemberRole         = 'Sales Rep',
                AccountAccessLevel     = 'Read',
                CaseAccessLevel        = 'None',
                ContactAccessLevel     = 'None',
                OpportunityAccessLevel = 'None'
            );
        }
        
        //Required fields for integration
        public List<String> getRequiredFields(FieldDataChild obj){
            //Example
            return new List<String>{
                'UserId'
            };
        }

        //Key field
        public String getFieldKey(){
            return 'Id';
        }

        //ExternalId field
        public String getFieldExternal(){
            return 'UserId';
        }
        
        //Parent ExternalId field
        public String getParentKey(){
            return 'AccountId';
        }
    }

    //Order input structure -> Implementing FieldData
    global class OrderINData implements FieldData{
        
        
        //JSON fields
        public String       CodigoSAP;
        public String       CodigoSAPInterno;
        public String       CodigoSalesforce;
        public String       DataPagamento;
        public String       TipoDocumento;
        public String       TipoPedido;
        public String       Safra;
        public String       CondicaoPagamento;
        public String       FormaPagamento;
        public String       DataVencimento;
        public String       Status;
        public String       NumeroPedidoCliente;
        public String       MotivoOrdem;
        public Decimal      ValorFrete;
        public Decimal      PrecoTotal;
        public Decimal      PrecoTotalSemFrete;
        public String       PedidoPai;
        public String       TipoReferenciaPedidoPai;
        public String       OrganizacaoVendas;
        public String       CanalDistribuicao;
        public String       SetorAtividade;
        public String       EscritorioVendas;
        public String       EquipeVendas;
        public String       ModalidadeFrete;
        public String       DataPedido; //
        public String       Incoterms1;
        public String       Incoterms2;
        public List<TemplateDataIntegrationFields.TextAreaINData>  Textos    = new List<TemplateDataIntegrationFields.TextAreaINData>();
        public List<TemplateDataIntegrationFields.OrderItemINData> Itens     = new List<TemplateDataIntegrationFields.OrderItemINData>();
        public List<TemplateDataIntegrationFields.PartnerINData>   Parceiros = new List<TemplateDataIntegrationFields.PartnerINData>();

        //Control Fields
        public String       AllTextos;
        public String       EffectiveDate;
        public String       Moeda;
        public String       CodigoSAPAG;
        public String       CodigoSAPWE;
        public String       CodigoSAPZV;

        public Order serialize(Map<String, Id> lookups){
            //Adding Texts & Partner Information to new Order
            /////////////////////////////

            Order ord= new Order(
                Id                          = lookups.containsKey('Order'+this.CodigoSalesforce) ? lookups.get('Order'+this.CodigoSalesforce) : null,
                //RecordTypeId                = lookups.containsKey('RecordType'+this.TipoDocumento) ? lookups.get('RecordType'+this.TipoDocumento) : null,
                //OrderNumber                 = this.CodigoSalesforce,
                PaymentDate__c              = !(IntegrationUtils.convertEmptyString(this.DataPagamento)) ? Date.ValueOf(this.DataPagamento) : null,
                Crop__c                     = lookups.containsKey('Crop'+this.Safra) ? lookups.get('Crop'+this.Safra) : null,
                PaymentCondition__c         = lookups.containsKey('PaymentCondition'+this.CondicaoPagamento) ? lookups.get('PaymentCondition'+this.CondicaoPagamento) : null,
                //PaymentForm__c              = this.FormaPagamento,
                EffectiveDate               = !(IntegrationUtils.convertEmptyString(this.EffectiveDate)) ? Date.valueOf(this.EffectiveDate) : Date.Today(),
                // EndDate                     = !(IntegrationUtils.convertEmptyString(this.DataVencimento)) ? Date.ValueOf(this.DataVencimento) : null,
                Status                      = 'Draft',
                // type                        = this.TipoPedido,
                StatusSF__c                 = 'Integrado',
                StatusSAP__c                = this.Status,
                CustomerOrderNumber__c      = this.NumeroPedidoCliente,
                OrderMotive__c              = this.MotivoOrdem,
                //TotalFreightValue__c        = this.ValorFrete,
                //TotalAmount                 = this.PrecoTotalSemFrete,
                //TotalAmountWithFreight__c   = this.PrecoTotal,
                ParentOrderReferenceType__c = this.TipoReferenciaPedidoPai,
                SalesOrg__c                 = lookups.containsKey('SalesOrg'+this.OrganizacaoVendas) ? lookups.get('SalesOrg'+this.OrganizacaoVendas) : null,
                DistributionChannel__c      = this.CanalDistribuicao,
                ActivitySector__c           = this.SetorAtividade,
                SalesOffice__c              = lookups.containsKey('SalesOffice'+this.EscritorioVendas) ? lookups.get('SalesOffice'+this.EscritorioVendas) : null,
                SalesTeam__c                = lookups.containsKey('SalesTeam'+this.EquipeVendas) ? lookups.get('SalesTeam'+this.EquipeVendas) : null,
                Freight__c                  = this.ModalidadeFrete,
                Currency__c                 = this.Moeda,
                Pricebook2Id                = lookups.containsKey('StandardPricebook2') ? lookups.get('StandardPricebook2') : null,
                AccountId                   = lookups.containsKey('Account'+this.CodigoSAPAG) ? lookups.get('Account'+this.CodigoSAPAG) : null,
                BillingAccount__c           = lookups.containsKey('Account'+this.CodigoSAPAG) ? lookups.get('Account'+this.CodigoSAPAG) : null,
                ShippingAccount__c          = lookups.containsKey('ShippingAccount'+this.CodigoSAPWE) ? lookups.get('ShippingAccount'+this.CodigoSAPWE) : null, 
                RTV__c                      = lookups.containsKey('RTV'+this.CodigoSAPZV) ? lookups.get('RTV'+this.CodigoSAPZV) : null 
            );

            if(this.AllTextos != null){
                ord.Description = this.AllTextos;
            }
            if(this.PedidoPai != null){
                ord.OriginalOrder__c= lookups.containsKey('Order'+this.PedidoPai) ? lookups.get('Order'+this.PedidoPai) : null;
            }

            if(ord.Id == null){
                ord.RecordTypeId = lookups.containsKey('RecordType'+this.TipoDocumento) ? lookups.get('RecordType'+this.TipoDocumento) : null;
            }
            if(!lookups.containsKey('OrderExternal'+this.CodigoSalesforce)){
                ord.ExternalId__c =  this.CodigoSAP;
            }else if(this.CodigoSAPInterno != null){
                ord.ExternalId__c = this.CodigoSAPInterno;
            }
            return ord;
            //Returning Object with Fields.
        }
        
        public List<String> getRequiredFields(FieldData obj){
            //Example
            return new List<String>{
                // 'ExternalId__c',
                'Freight__c',
                //'CreatedDate',
                'AccountId',
                'BillingAccount__c',
                'ShippingAccount__c',
                'RTV__c'
            };
        }

        //ExternalId field
        public String getFieldKey(){
            return 'ExternalId__c';
        }
        
        //Id field
        public String getFieldId() {
            return 'Id';
        }
    }

    //TextArea input structure
    global class TextAreaINData{
        
        //JSON fields
        public String  TextoId;
        public String  Texto;
    }

    //Partner input structure
    global class PartnerINData{
        
        //JSON fields
        public String  TipoParceiro;
        public String  CodigoSAP;
    }

    //OrderItem input structure -> Implementing FieldDataChild
    global class OrderItemINData implements FieldDataChild{
        
        //JSON fields
        public String       NoItemPedidoCliente;
        public Decimal      Quantidade;
        public String       Centro;
        public Decimal      QuantidadeFaturada;
        public String       Material;
        public String       IDCultura;
        public String       ModalidadeFrete;
        public String       Status;
        public String       UnidadeMedida;
        public String       ListaPreco;
        public String       MotivoRecusa;
        public String       Incoterms1;
        public String       Incoterms2;
        public List<TemplateDataIntegrationFields.ItemValueINData>        ValoresItem    = new List<TemplateDataIntegrationFields.ItemValueINData>();
        public List<TemplateDataIntegrationFields.ShippingDivisionINData> DivisaoRemessa = new List<TemplateDataIntegrationFields.ShippingDivisionINData>();

        //OrderId
        public String       RelatedOrderId;

        //Value Fields
        public Decimal      PrecoUnitario;
        public Decimal      PrecoLista;
        public Decimal      Desconto;
        public Decimal      DescontoOferta;
        public Decimal      ValorFrete;

        public Boolean      IsInsertSAP;

        public OrderItem serialize(Map<String, Id> lookups){
            //Returning Object with Fields.
            //Id ordId = lookups.containsKey('Order'+this.RelatedOrderExternalId) ? lookups.get('Order'+this.RelatedOrderExternalId) : null;
            OrderItem ordItem = new OrderItem(                
                Id                          = lookups.containsKey('OrderItem'+ this.RelatedOrderId + '|' + this.NoItemPedidoCliente) ? lookups.get('OrderItem'+ this.RelatedOrderId + '|' + this.NoItemPedidoCliente) : null,    
                ExternalId__c               = this.RelatedOrderId + '|' + this.NoItemPedidoCliente,
                SAPNumber__c                = this.NoItemPedidoCliente,
                OrderId                     = this.RelatedOrderId,
                Quantity                    = this.Quantidade,
                Quantity__c                 = this.Quantidade,
                Center__c                   = lookups.containsKey('DistributionCenter'+this.Centro) ? lookups.get('DistributionCenter'+this.Centro) : null,
                BilledQuantity__c           = !(IntegrationUtils.convertEmptyString(String.ValueOf(this.QuantidadeFaturada))) ? this.QuantidadeFaturada : 0,
                Product2Id                  = lookups.containsKey('Product2'+this.Material) ? lookups.get('Product2'+this.Material) : null,
                Culture__c                  = lookups.containsKey('Culture'+this.IDCultura) ? lookups.get('Culture'+this.IDCultura) : null,
                Freight__c                  = this.Incoterms1,
                Status__c                   = this.Status,
                UnitMeasure__c              = this.UnidadeMedida,
                RefuseReason__c             = this.MotivoRecusa,
                PricebookEntryId            = lookups.containsKey('PricebookEntry'+this.Material) ? lookups.get('PricebookEntry'+this.Material) : null,
                //ListPriceWithoutInterest__c = this.PrecoUnitario, // o SAP não envia preço de lista, apenas valor unitário
                //UnitPrice                   = this.PrecoUnitario,
                //CustomListPrice__c          = this.PrecoLista,
                OfferDiscount__c            = this.DescontoOferta,
                FreightValue__c             = this.ValorFrete,
                Incoterms1__c               = this.Incoterms1,
                Incoterms2__c               = this.Incoterms2
            );
            if(this.IsInsertSAP && lookups.containsKey('PriceList'+this.ListaPreco)){
                ordItem.ListPrice__c = lookups.get('PriceList'+this.ListaPreco);
            }
            if(this.IsInsertSAP){
                ordItem.UnitPrice = this.PrecoUnitario != null ? this.PrecoUnitario : 0;
                //CustomListPrice__c = this.PrecoLista;
            }
            
            Map<String,Integration__c> integrations = Integration__c.getAll();
            Id userRtvId = lookups.containsKey('OrderRTV'+ this.RelatedOrderId) ? lookups.get('OrderRTV'+ this.RelatedOrderId) : null;
		    if(integrations.containsKey('RecalcProcess')  && 
                (!integrations.get('RecalcProcess').Inactive__c || integrations.get('RecalcProcess').UserName__c?.contains(String.valueOf(userRtvId)))
               ){
                Map<String, Decimal> mapStringToDecimal = new Map<String,Decimal>();
                Map<String, Decimal> mapStringToDecimalValue = new Map<String,Decimal>();
                for(TemplateDataIntegrationFields.ItemValueINData value : ValoresItem){
                    mapStringToDecimal.put(value.TipoCondicao, value.ValorCondicao != null ? value.ValorCondicao : 0);
                    mapStringToDecimalValue.put(value.TipoCondicao, value.ValorMonetario != null ? value.ValorMonetario : 0);
                }

                ordItem.UnitPrice                      = mapStringToDecimal.containsKey('ICMI') ? mapStringToDecimal.get('ICMI') : 0;
                // ordItem.CustomListPrice__c             = mapStringToDecimal.containsKey('ZPR0') ? mapStringToDecimal.get('ZPR0') : 0;
                // ordItem.OriginalListPrice__c           = mapStringToDecimal.containsKey('ZPR0') ? mapStringToDecimal.get('ZPR0') : 0;
                // ordItem.ListPriceWithoutInterest__c    = mapStringToDecimal.containsKey('ZPR0') ? mapStringToDecimal.get('ZPR0') : 0;
                ordItem.InterestValuePercent__c        = mapStringToDecimal.containsKey('ZDJ1') ? mapStringToDecimal.get('ZDJ1')*100 : 0;
                ordItem.InterestValue__c               = mapStringToDecimalValue.containsKey('ZJ00') ? mapStringToDecimalValue.get('ZJ00') : 0;

                ordItem.AnticipationDiscountPercent__c = mapStringToDecimal.containsKey('ZDJ1') ? Math.abs(mapStringToDecimal.get('ZDJ1')*100) : 0;
                ordItem.AnticipationDiscount__c        = mapStringToDecimalValue.containsKey('ZDJ0') ? Math.abs(mapStringToDecimalValue.get('ZDJ0')) : 0;

                ordItem.DiscountPercent__c             = mapStringToDecimal.containsKey('ZK07') ? (mapStringToDecimal.get('ZK07') < 0 ? Math.abs(mapStringToDecimal.get('ZK07')*100) : 0) : 0;    
                ordItem.DiscountAmount__c              = mapStringToDecimalValue.containsKey('ZK07') ? (mapStringToDecimalValue.get('ZK07') < 0 ? Math.abs(mapStringToDecimalValue.get('ZK07')) : 0) : 0;

                ordItem.AdditionPercent__c             = mapStringToDecimal.containsKey('ZK07') ? (mapStringToDecimal.get('ZK07') > 0 ? mapStringToDecimal.get('ZK07')*100 : 0) : 0;
                ordItem.AdditionAmount__c              = mapStringToDecimalValue.containsKey('ZK07') ? (mapStringToDecimalValue.get('ZK07') > 0 ? mapStringToDecimalValue.get('ZK07') : 0) : 0;

                ordItem.FreightValue__c                = mapStringToDecimalValue.containsKey('ZF00') ? mapStringToDecimalValue.get('ZF00') : 0;
            }else {
                if (this.Desconto < 0) {
                    ordItem.DiscountPercent__c = this.Desconto * -1;
                } else {
                    ordItem.AdditionPercent__c = this.Desconto;
                    if(this.Desconto == null) ordItem.AdditionPercent__c = 0;
                }
                // ordItem.CustomListPrice__c          = this.PrecoLista;
                ordItem.FreightValue__c             = this.ValorFrete;
            }
            return ordItem;
        }
        
        //Required fields for integration
        public List<String> getRequiredFields(FieldDataChild obj){
            //Example
            return new List<String>{
                'ExternalId__c',
                'OrderId',
                'Quantity',
                //'BilledQuantity__c',
                'Product2Id',
                'Culture__c',
                'Freight__c',
                //'Status__c',
                'UnitMeasure__c'
                // 'UnitPrice',
                //'ListPriceWithoutInterest__c'
            };
        }

        //Key field
        public String getFieldKey(){
            return 'Id';
        }

        //ExternalId field
        public String getFieldExternal(){
            return 'ExternalId__c';
        }
        
        //Parent ExternalId field
        public String getParentKey(){
            return 'OrderId';
        }
    }

    //ItemValue input structure
    global class ItemValueINData{
        
        //JSON fields
        public String  TipoCondicao;
        public Decimal ValorCondicao;
        public Decimal ValorMonetario;
        public String  Moeda;
    }

    //ShippingDivision input structure
    global class ShippingDivisionINData implements FieldDataChild{
        
        //JSON fields
        public String  NumeroDivisao;
        public String  DataDivisao;
        public Decimal Quantidade;
        public Decimal QuantidadeConfirmada;
        public String  MotivoRecusa;

        //OrderItemExternalId
        public String  RelatedOrderItemId;
        public String  RelatedOrderItemExternalId;

        public ShippingDivisionINData(){}

        public ShippingDivisionINData(Decimal qtd, OrderItemINData ordItem){
            this.NumeroDivisao = '1001';
            this.DataDivisao = Date.today().year()+'-'+Date.today().month()+'-'+Date.today().day();
            this.Quantidade = qtd;
            this.QuantidadeConfirmada = 0;
            this.MotivoRecusa = ordItem.MotivoRecusa;

            this.RelatedOrderItemId = '';
            this.RelatedOrderItemExternalId = ordItem.NoItemPedidoCliente;
        }

        public ShippingDivision__c serialize(Map<String, Id> lookups){
            //Returning Object with Fields.
            return new ShippingDivision__c(                
                Id                     = lookups.containsKey('ShippingDivision'+ RelatedOrderItemId + '|' + this.NumeroDivisao) ? lookups.get('ShippingDivision'+ RelatedOrderItemId + '|' + this.NumeroDivisao) : null,    
                Name                   = this.RelatedOrderItemExternalId + '|' + this.NumeroDivisao,
                SAPNumber__c           = this.NumeroDivisao,
                ExternalId__c          = RelatedOrderItemId + '|' + this.NumeroDivisao,
                OrderItem__c           = RelatedOrderItemId ,
                DeliveryDate__c        = !(IntegrationUtils.convertEmptyString(this.DataDivisao)) ? Date.ValueOf(this.DataDivisao) : null,
                Quantity__c            = this.Quantidade,
                ConfirmedQuantity__c   = this.QuantidadeConfirmada,
                RefuseReason__c        = this.MotivoRecusa
            );
        }
        
        //Required fields for integration
        public List<String> getRequiredFields(FieldDataChild obj){
            //Example
            return new List<String>{
                'ExternalId__c',
                'DeliveryDate__c',
                'OrderItem__c',
                'Quantity__c'
            };
        }

        //Key field
        public String getFieldKey(){
            return 'Id';
        }

        //ExternalId field
        public String getFieldExternal(){
            return 'ExternalId__c';
        }
        
        //Parent ExternalId field
        public String getParentKey(){
            return 'OrderItem__c';
        }
    }

    global class ProductManagementINData implements FieldData{
    
        public String       RecordTypeName;
        public KeyClass     Crop;
        public KeyClass     SalesTeam;
        public String       InitialDate;
        public String       EndDate;    
        public Boolean      IsActive;
        public KeyClass     Product2Id;

        public ProductManagement__c serialize(Map<String, Id> lookups){

            return new ProductManagement__c(
                Crop__c         = lookups.containsKey('Crop'+this.Crop?.ExternalId) ? lookups.get('Crop'+this.Crop?.ExternalId) : null,
                InitialDate__c  = !(IntegrationUtils.convertEmptyString(this.InitialDate)) ? Date.ValueOf(this.InitialDate) : null,
                EndDate__c      = !(IntegrationUtils.convertEmptyString(this.EndDate)) ? Date.ValueOf(this.EndDate) : null,
                IsActive__c     = this.IsActive,
                Product2__c     = lookups.containsKey('Product2'+this.Product2Id?.ExternalId) ? lookups.get('Product2'+this.Product2Id?.ExternalId) : null,
                SalesTeam__c    = lookups.containsKey('SalesTeam'+this.SalesTeam?.ExternalId) ? lookups.get('SalesTeam'+this.SalesTeam?.ExternalId) : null,
                SalesOrgName__c = lookups.containsKey('SalesTeam'+this.SalesTeam?.ExternalId) ? lookups.get('SalesTeam'+this.SalesTeam?.ExternalId) : null,
                ExternalId__c   = this.Product2Id?.ExternalId           + '-' + 
                                  this.SalesTeam?.ExternalId            + '-' + 
                                  this.Crop?.ExternalId,
                RecordTypeId    = Schema.SObjectType.ProductManagement__c.getRecordTypeInfosByDeveloperName().get(RecordTypeName).getRecordTypeId()
            );
        }
        
        public List<String> getRequiredFields(FieldData obj){
            ProductManagementINData nObj = (ProductManagementINData)obj;

            List<String> reqList = new List<String>{
                'Product2__c',
                'SalesTeam__c'
            };
            
            if (nObj.RecordTypeName == 'ExclusionList') {
                reqList.addAll(new List<String>{
                    'Crop__c',
                    'IsActive__c'
                });
            }

            return reqList;
        }

        //ExternalId field
        public String getFieldKey(){
            return 'ExternalId__c';
        }
        
        //Id field
        public String getFieldId() {
            return 'Id';
        }
    }

    global class KeyClass{
        public String Name {get;set;}
        public String ExternalId {get;set;}
    }

    //Response structure
    global virtual class Response {
        public String        idSalesforce;
        public String        externalId;
        public List<String>  errorMessage = new List<String>();
        public Boolean       status;
        public String        sObjectType;

        public void success(String idSalesforce, String externalId, String sObjectType){
            this.idSalesforce = idSalesforce;
            this.externalId   = externalId;
            this.status       = true;
            this.SObjectType  = sObjectType;
        }
        
        public void error(String externalId, String errorMessage, String sObjectType){
            this.externalId   = externalId;
            this.status       = false;
            this.errorMessage.add(errorMessage);
            this.SObjectType  = sObjectType;
        }

        public void error(String idSalesforce, String externalId, String errorMessage, String sObjectType){
            this.idSalesforce = idSalesforce;
            this.externalId   = externalId;
            this.status       = false;
            this.errorMessage.add(errorMessage);
            this.SObjectType  = sObjectType;
        }
    }
    
    //Response structure for integration of parent and child objects
    global class ResponseParent extends Response {
        public List<TemplateDataIntegrationFields.Response> items;
        public ResponseParent(){}

        public ResponseParent(String msg, string extId){
            this.items = new List<TemplateDataIntegrationFields.Response>();
            TemplateDataIntegrationFields.Response resp = new TemplateDataIntegrationFields.Response();
            resp.error(extId, msg, 'Order');
            this.items.add(resp);
        }
    }

}