//Class returning Map of Map<String, List<SObject>>
public with sharing class Mar7SobjectStringMapping {
    public static Map<String, List<sObject>> stringSobjectMap(List<sObject> sObjectList, String fieldApiName) {
        Map<String, List<sObject>> groupedMap = new Map<String, List<sObject>>();
        if (sObjectList.isEmpty()) {
            return groupedMap;
        }
        sObject genericSObject = sObjectList[0];
        Schema.DescribeSObjectResult sObjectDescribe = genericSObject.getSObjectType().getDescribe();
    
        if (!sObjectDescribe.fields.getMap().containsKey(fieldApiName)) {
            throw new IllegalArgumentException('Invalid field API name: ' + fieldApiName);
        }
        for (sObject obj : sObjectList) {
            String fieldValue = String.valueOf(obj.get(fieldApiName));
            if (!groupedMap.containsKey(fieldValue)) {
                groupedMap.put(fieldValue, new List<sObject>()); 
            } 
            groupedMap.get(fieldValue).add(obj);
        }
        return groupedMap;
    }    
}


*******************************************************************************************************************
//Trigger on Opportunity after Update
trigger Mar7OpportunityRecType on Opportunity (after update) {
    List<Opportunity> newServicingOpps = new List<Opportunity>();
    List<Opportunity> newDealOpp = new List<Opportunity>();
    for (Opportunity oldOpp : Trigger.old) {
        if (oldOpp.IsClosed && oldOpp.IsWon){
            oldOpp.RecordTypeId = '0125h000002FDu1AAG';//"New Deal" RecordType Id from table RecordType
            newDealOpp.add(oldOpp);
            if(oldOpp.CloseDate == Date.today().addMonths(-6)) {
                Opportunity newOpp = oldOpp.clone();
                newOpp.Name = newOpp.Name + ' - Servicing';//"- Servicing" added to name to create
                newOpp.RecordTypeId = '0125h000002FDu6AAG';//"Servicing" RecordType Id from table RecordType
                newOpp.CloseDate = Date.today().addDays(30);
                newServicingOpps.add(newOpp);
            }
        }
    }
    update newDealOpp;
    insert newServicingOpps;
}
************************************************************************************************************************
//Dummy update every month
public class Mar7UpdateAllOppMonthly implements Database.Batchable<sObject>, Schedulable {
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT Id FROM Opportunity'); 
    }
    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Opportunity> oppsToUpdate = (List<Opportunity>) scope;
        for (Opportunity opp : oppsToUpdate) {
            opp.Description = 'Updated by batch job'; 
        }
        update oppsToUpdate; 
    }
    public void finish(Database.BatchableContext BC) {
        
    }
    public void execute(SchedulableContext sc) {
        Database.executeBatch(this, 200);
    }
}
/*
String cronExp = '0 0 10 1 * ?'; // Run on the 1st of every month at 10 AM
Mar7UpdateAllOppMonthly m = new Mar7UpdateAllOppMonthly();
System.schedule('Opportunity Monthly Update', cronExp, m);
*/
