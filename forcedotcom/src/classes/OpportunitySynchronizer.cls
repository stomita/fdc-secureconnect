/**
 * An example client which propagate opportunity information to intranet system via SecureConnect
 */
public class OpportunitySynchronizer {

	public static void propagate(List<Opportunity> opps) {
		List<Id> oppIds = new List<Id>();
		List<Map<String, String>> oppMaps = new List<Map<String, String>>();
		for (Opportunity opp : opps) {
			Map<String, String> oppMap = new Map<String, String>();
			oppIds.add(opp.Id);
			oppMap.put('Id', String.valueOf(opp.Id));
			oppMap.put('ExtId', opp.ExternalSystemId__c); // key value in intranet system
			oppMap.put('Name', opp.Name);
			oppMap.put('Amount', String.valueOf(opp.Amount));
			oppMap.put('CloseDate', String.valueOf(opp.CloseDate));
			oppMaps.add(oppMap);
		}
		String oppsJson = JSON.serialize(oppMaps);
		SecureConnect.request('opps/propagate', oppsJson, new PropagateResponseListener(oppIds));
	}
	
	/**
	 * Callbacked when the response arrived from intranet server
	 */
	public class PropagateResponseListener implements SecureConnect.ResponseListener {
		public List<Id> oppIds { get; set; }

		public PropagateResponseListener(List<Id> oppIds) {
			this.oppIds = oppIds;
		}

    	public Type getClassType() {
    		return PropagateResponseListener.class;
    	}
    	
    	public void onResponse(String responseCode, String responseData) {
    		if (responseCode == 'success') {
    			List<Opportunity> opps = new List<Opportunity>();
    			List<String> extIds = (List<String>) JSON.deserialize(responseData, List<String>.class);
				Integer i = 0;
    			for (String extId : extIds) {
    				if (i >= oppIds.size()) break;
    				if (extId != null) {
    					System.debug('ExtId = '+extId);
						Opportunity opp = new Opportunity(Id=oppIds[i]);
	    				// Register external system id to custom field to synchronize each database
	    				opp.ExternalSystemId__c = extId;
	    				opps.add(opp);
    				}
    				i++;
				}
    			update opps;
    		}
    	}
	}

}