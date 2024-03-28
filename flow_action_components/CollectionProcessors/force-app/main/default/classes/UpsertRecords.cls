public with sharing class UpsertRecords {
  
        @InvocableMethod(label='Upsert Records [USF Collection Processor]' category='Util' iconName='resource:CollectionProcessorsSVG:colproc')
        public static List<Results> execute (List<Request> requestList) {

        Map<Schema.SObjectField,List<SObject>> recordsByExternalIdField = new Map<Schema.SObjectField,List<SObject>>();

        // we'll assume all requests have the same allOrNone value
        // if they don't, we'll throw an exception
        // this could be a breaking change for existing implementations 
        // but you'd have to be a real mad lad to do that
        Boolean allOrNone = requestList[0].allOrNone ?? true;

        List<Results> responseWrapper = new List<Results>();
        for (Request curRequest : requestList) {
            List<SObject> inputCollection = curRequest.inputCollection ?? new List<SObject>();
            SObject inputRecord = curRequest.inputRecord;
            
            if (String.isNotEmpty(curRequest.serializedRecordData) && String.isNotEmpty(curRequest.objectName)){
                inputCollection = (List<SObject>)JSON.deserialize(curRequest.serializedRecordData,  List<SObject>.class);
                inputRecord = null;
            }

            if (inputCollection == null && inputRecord == null) {
                throw new InvocableActionException('You must pass in either an inputCollection or an inputRecord to the Upsert Records Action');
            }

            if (currRequest.allOrNone != null && currRequest.allOrNone != allOrNone) {
                throw new InvocableActionException('The allOrNone parameter must be the same for all requests');
            }
            
            Schema.SObjectField externalIdField;

            if (curRequest.externalIdFieldName == null) {
                externalIdField = null;
            } else {
                List<String> parts = curRequest.externalIdFieldName.split('\\.');
                String externalIdObjectName = parts[0]?.toLowerCase();
                String externalIdFieldName = parts[1]?.toLowerCase();
                Map<String, SObjectField> fieldsMapByName = Schema.describeSObjects(new String[]{externalIdObjectName}).getDescribe().fields.getMap();
                externalIdField = fieldsMapByName.get(externalIdFieldName);
            }

            if (recordsByExternalIdField.containsKey(externalIdField)) {
                recordsByExternalIdField.get(externalIdField).addAll(inputCollection);
            } else {
                recordsByExternalIdField.put(externalIdField, inputCollection);
            }
            
            //add the inputRecord to inputCollection so we can just handle inputCollection
            //note that cpe's will be able to ensure these are the same type
            if ( inputRecord != null) {
                inputCollection.add(inputRecord);
            }

            if (externalIdField != null) {
                Database.upsert(inputCollection,externalIdField,allOrNone);    
            } else {
                Database.upsert(inputCollection,allOrNone);   
            }

            //Create a Results object to hold the return values
            Results response = new Results();

            responseWrapper.add(response);
        }  
        
        for (Schema.SObjectField externalIdField : recordsByExternalIdField.keySet()) {
            List<SObject> records = recordsByExternalIdField.get(field);
            if (field == null) {
                Database.upsert(records,allOrNone);
            } else {
                Database.upsert(records,externalIdField,allOrNone);
            }
        }
        
        return responseWrapper;
    
    }

    public class Request {
        @InvocableVariable
        public List<SObject> inputCollection;

        @InvocableVariable
        public SObject inputRecord;

        @InvocableVariable
        public String serializedRecordData;

        @InvocableVariable
        public String objectName;

        @InvocableVariable
        public String externalIdFieldName;

        @InvocableVariable
        public Boolean allOrNone;
        
    }
    
    public class Results {
        @InvocableVariable
        public String placeholder; //don't ask


    }

    public class InvocableActionException extends Exception {}
}