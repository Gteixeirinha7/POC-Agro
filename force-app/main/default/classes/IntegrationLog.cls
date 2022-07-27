public with sharing class IntegrationLog {
    public static Map<String, ID> logRecordTypeIDMap;
    
    public static void initializeLog(){
        if (logRecordTypeIDMap == null){
            logRecordTypeIDMap = new Map<String, ID>();

            for (RecordType rType : RecordTypeDAO.getRecordTypeBySObjectType(new List<String>{'IntegrationLog__c'}, new Set<String>{'Id, DeveloperName'})){
                logRecordTypeIDMap.put(rType.DeveloperName, rType.ID);
            }
        }
    }

    public static void createIntegrationLog(String integrationName, String recordTypeName, String payloadIN, String payloadOUT, Boolean hasAnyErrors){
        createIntegrationLog(integrationName, recordTypeName, payloadIN, payloadOUT, hasAnyErrors, null);
    }

    public static void createIntegrationLog(String integrationName, String recordTypeName, String payloadIN, String payloadOUT, Boolean hasAnyErrors, String ExternalIds){
        System.debug('ON WS LOG: '+ integrationName);

        initializeLog();
        System.debug('recordTypeName: ' + recordTypeName);
        System.debug('logRecordTypeIDMap: ' + logRecordTypeIDMap);
        System.debug('get do logRecordTypeIdMap: ' + logRecordTypeIDMap.get(recordTypeName));
        Boolean shouldUseAttachmentIN  = (payloadIN.length() > 100000);
        Boolean shouldUseAttachmentOUT = (payloadOUT.length() > 100000);

        Datetime tNow = System.now();

        ID rType;
        if ((rType = logRecordTypeIDMap.get(recordTypeName)) == null){
            System.debug('FAILED TO GET RECORDTYPE FROM LIST');
        }
        IntegrationLog__c log = new IntegrationLog__c(
            RecordTypeId       = rType,
            Integration__c     = integrationName,
            hasAttachment__c   = (shouldUseAttachmentIN || shouldUseAttachmentOUT),
            PayloadIN__c       = (shouldUseAttachmentIN  ? '' : payloadIN),
            PayloadOUT__c      = (shouldUseAttachmentOUT ? '' : payloadOUT),
            Status__c          = (hasAnyErrors ? 'Error' : 'OK'),
            Date__c 		   = tNow,
            ExternalIds__c     = ExternalIds
        );

        try{
            insert log;

            // Maximum Size for a String
            if (shouldUseAttachmentIN){
            	createAttachment(log.Id, integrationName, 'IN', log.Name, String.valueOf(tNow), payloadIN);
            }

            if (shouldUseAttachmentOUT){
            	createAttachment(log.Id, integrationName, 'OUT', log.Name, String.valueOf(tNow), payloadOUT);
            }

            System.debug('NEW LOG CREATED: '+log.Id);
        }catch(Exception e){
            System.debug('EXCEPTION ON LOG - Please review parameters - '+e.getMessage()+' - '+e.getStackTraceString());
        }
    }

    @TestVisible
    private static void createAttachment(String recordId, String integrationName, String inOrOut, String logName, String timeAsString, String payload){
    	Attachment att = new Attachment();
    	att.Name = 'LOG-'+integrationName+'-'+inOrOut+'-'+timeAsString+'.txt';
    	att.Body = Blob.valueOf(payload);
    	att.ParentId = recordId;
    	insert att;
    }
}
