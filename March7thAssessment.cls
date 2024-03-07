//Class returning Map of Map<String, List<SObject>>
public with sharing class Mar7SobjectStringMapping {
    public static Map<String, List<SObject>> stringSobjectMap(List<SObject> inputRecords, String fieldApiName) {
        Map<String, List<SObject>> recordMapping = new Map<String, List<SObject>>();
        for (SObject record : inputRecords) {
            Object fieldValue = record.get(fieldApiName);
            if (fieldValue != null) {
                String fieldValueAsString = String.valueOf(fieldValue);
                if (!recordMapping.containsKey(fieldValueAsString)) {
                    recordMapping.put(fieldValueAsString, new List<SObject>());
                }
                recordMapping.get(fieldValueAsString).add(record);
            }
        }
        return recordMapping;
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
public class Mar7UpdateAllOppMonthly implements Schedulable {
    public void execute(SchedulableContext sc) {
        List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE IsClosed=TRUE AND IsWon=TRUE];
        for (Opportunity opp : oppList) {
            opp.Description = opp.Description; // Dummy update
        }
        update oppList;
    }
}
/*
String cronExp = '0 0 10 1 * ?'; // Run on the 1st of every month at 10 AM
Mar7UpdateAllOppMonthly m = new Mar7UpdateAllOppMonthly();
System.schedule('Opportunity Monthly Update', cronExp, m);
*/