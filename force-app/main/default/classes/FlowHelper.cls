global class FlowHelper {
    
    @InvocableMethod(label='Get type of object' description='Get SObject type name by ID' category = 'Apex To Flow')
    public static List<String> getObjectTypeById(List<String> listOrderId){
        List<String> sObjName = new List<String>();
        try{
            system.debug('ID é : ' + listOrderId[0]);
            Id myId = listOrderId[0];  
            sObjName.add(myId.getSObjectType().getDescribe().getName());  
            system.debug('Nome do objeto é : ' + sObjName[0]);
            
        } catch(Exception e){
            system.debug('Error: ' + e);
        }
        return sObjName;
    }

}