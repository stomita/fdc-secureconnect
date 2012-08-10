/**
 * Example trigger which syncs the status of won opportunity to intranet system (e.g. Accounting)
 */
trigger OppotunitySyncTrigger on Opportunity (after update) {
	List<Opportunity> wonOpps = new List<Opportunity>();
	for (Opportunity opp : Trigger.new) {
		Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
		// Ignore change of external system id
		if (opp.ExternalSystemId__c != oldOpp.ExternalSystemId__c) continue;
		// Propagate opportunity information to extrenal system only in "Won" status
		if (opp.IsWon) wonOpps.add(opp);
	}
	if (wonOpps.size() > 0) {
		OpportunitySynchronizer.propagate(wonOpps);
	}
}