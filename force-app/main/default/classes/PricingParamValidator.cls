public with sharing class PricingParamValidator {
    private SObjectType sobjectType;
    private Boolean     isUpdating;
    private SObject[]   records;

    /*
    private PricingParamValidator(SObjectType sobjectType){
        this.sobjectType = sobjectType;
    }

    public static PricingParamValidator of(SObjectType sobjectType){
        return new PricingParamValidator(sobjectType);
    }
    
    public PricingParamValidator with(SObject[] records){
        this.records = records;
        return this;
    }

    public PricingParamValidator updating(Boolean updating){
        this.isUpdating = updating;
        return this;
    }

    
    public PricingParamValidator validate(){
        this.runValidation();
        return this;
    }
    

    private static Boolean isValidationRunning;

    static {
        isValidationRunning = false;
    }
    
    public static Boolean isValidationRunning(){
        return PricingParamValidator.isValidationRunning;
    }

    
    private void runValidation(){
        if (!this.records.isEmpty()){
            List<SObject> approvedRecords = Collection.of(records)
                                           .filter(
                                               Match.field('Ativo__c')
                                               .equals(true)
                                           ).asList();
            
            validateTransactionRecords(approvedRecords);

            if (!approvedRecords.isEmpty() && !isValidationRunning()){
            
                Map<String, RecordDateInfo> recordsDateResult = mapRecordsDateResult(approvedRecords);
                SObject[] existingRecords = Database.query(
                    buildQueryFromRecords(recordsDateResult.values())
                );
    
                SObject[] existingRecordsAfterValidation = handleExistingRecords(recordsDateResult, existingRecords);

                handleExistingRecordsApproval(existingRecordsAfterValidation);
            }
        }
    }

    private void validateTransactionRecords(SObject[] records){
        Map<String, RecordDateInfo> recordsDateResult = mapRecordsDateResult(records);
        handleExistingRecords(recordsDateResult, records);

        resetValidRecords(recordsDateResult);
    }

    private void resetValidRecords(Map<String, RecordDateInfo> recordsDateResult){
        for(RecordDateInfo recordDateInfo : recordsDateResult.values()){
            SObject recordSObject = recordDateInfo.recordInstance;

            recordSObject.put('dataFim__c', recordDateInfo.endDate);
            recordSObject.put('Ativo__c', true);
        }
    }

    private SObject[] handleExistingRecords(Map<String, RecordDateInfo> recordsDateResult, SObject[] existingRecords){

        System.debug(recordsDateResult.keySet());

        SObject[] recordsToUpdate = new SObject[]{};
        for(SObject existingRecord : existingRecords){
            String existingRecordExternalId = (String) existingRecord.get('ExternalIDIndex__c');
            Date existingRecordStartDate = (Date) existingRecord.get('dataInicio__c');
            Date existingRecordEndDate = (Date) existingRecord.get('dataFim__c');
            
            RecordDateInfo insertedRecordInfo = recordsDateResult.get(existingRecordExternalId);
            
            if (insertedRecordInfo.startDate > existingRecordStartDate){
				existingRecord.put('dataFim__c', insertedRecordInfo.startDate.addDays(-1));
            } else {
				existingRecord.put('Ativo__c', false);
            }
        }

        return existingRecords;
    }

    private Map<String, RecordDateInfo> mapRecordsDateResult(SObject[] records){
        Map<String, RecordDateInfo> result = new Map<String, RecordDateInfo>();
        for(SObject record : records){
            String recordExternalId = (String) record.get('ExternalIDIndex__c');
            result.put(recordExternalId, new RecordDateInfo(record));
        }

        return result;
    }

    private String buildQueryFromRecords(RecordDateInfo[] recordsMapped){
        
        String recordObjectName = this.sobjectType.getDescribe().getName();

        String existingRecordsDynamicQuery =
            ' SELECT Id, ExternalIDIndex__c, Ativo__c, DataFim__c,DataInicio__c                                                           ' +
            ' FROM ' + recordObjectName + '                                                                                                ' +
            ' WHERE (';

        String[] whereClauses = new String[]{};

        for(RecordDateInfo recordDateInfo : recordsMapped){
            
            String whereClause = String.format(
                ' (                                                        ' +
                '     ExternalIDIndex__c = {0}                             ' +
                '     AND (                                                ' +
                '         (dataInicio__c >= {1} AND dataInicio__c <= {2})  ' +
                '         OR (dataFim__c >= {1} AND dataFim__c    <= {2})  ' +
                '         OR (                                             ' +
                '             dataInicio__c <= {1} AND dataFim__c >= {2}   ' +
                '         )                                                ' +
                '     )                                                    ' +
                ' )                                                        '
            , new List<String>{ 
                '\'' + recordDateInfo.key + '\'', 
                String.valueOf(recordDateInfo.startDate),
                String.valueOf(recordDateInfo.endDate)
            });

            whereClauses.add(whereClause);
        }

        String updateClause = this.isUpdating? ' AND id NOT IN :records ' : '';

        existingRecordsDynamicQuery = '' + existingRecordsDynamicQuery + String.join(whereClauses, ' OR ') + ') AND Ativo__c = true ' + updateClause;
        System.debug(existingRecordsDynamicQuery);
        return existingRecordsDynamicQuery;
    }

    private void handleExistingRecordsApproval(SObject[] records){
        Approval.unlock(records);
        
        isValidationRunning = true;
            update records;
        isValidationRunning = false;

        deleteRecordApprovalItems(records);

        Approval.lock(records);
    }

    private List<Approval.ProcessResult> deleteRecordApprovalItems(SObject[] records){
        List<Id> recordIds = Collection.of(records).pluckIds();

        List<ProcessInstanceWorkitem> approvalWorkItems = [
            SELECT 
                id, processInstance.TargetObjectId 
            FROM ProcessInstanceWorkitem 
            WHERE processInstance.status = 'Pending' 
            AND processInstance.targetObjectId IN :recordIds
        ];
        List<Approval.ProcessWorkitemRequest> approvalRequests =  new List<Approval.ProcessWorkitemRequest>();
        for(ProcessInstanceWorkitem workItem : approvalWorkItems){
            Approval.ProcessWorkitemRequest requestItem = new Approval.ProcessWorkitemRequest();
            
            requestItem.setWorkItemId(workItem.Id);
            requestItem.setComments('Removido pelo processo automÃ¡tico na trigger.');
            requestItem.setAction('Removed'); 
            requestItem.setNextApproverIds(new Id[] {UserInfo.getUserId()}); 
            approvalRequests.add(requestItem);
        }

        if(!approvalRequests.isEmpty()){
            return Approval.process(approvalRequests);
        }

        return null;
    }
    */
    public static void assignExternalId(List<SObject> records, Set<String> fields){
        for(SObject record : records){
            List<String> keyParts = new List<String>();
            for(String field : fields){
                Object keyPart = record.get(field) == null? '' : record.get(field);
                keyParts.add(String.valueOf(keyPart));
            }

            record.put('ExternalIDIndex__c', String.join(keyParts, '-'));
        }  
    }

    /*
    public class RecordDateInfo{
        
        public Date startDate;
        public Date endDate;
        public String key; 
        public Id recordId; 
        public SObject recordInstance; 

        public RecordDateInfo(SObject record){
            this.startDate      = (Date) record.get('dataInicio__c');
            this.endDate        = (Date) record.get('dataFim__c');
            this.key            = (String) record.get('ExternalIDIndex__c');
            this.recordId       = record.id;
            this.recordInstance = record;
        }
    }
    */
}
