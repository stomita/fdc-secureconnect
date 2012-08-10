/**
 * A trigger which calls registered response listener when received response data
 */
trigger SecureConnectTrigger on SecureConnect__c (before insert, before update) {
	for (SecureConnect__c rec : Trigger.new) {
		String listenerData = rec.ResponseListenerData__c;
		String listenerType = rec.ResponseListenerType__c;
		String responseCode = rec.ResponseCode__c;
		String responseData = rec.ResponseData__c;
		String status = rec.Status__c;
		if ((status == 'RESPONSE' || status == 'RESPONSE_WITH_DATA') &&
			listenerType != null && !listenerType.equals('') ) {
			try {
				SecureConnect.ResponseListener listener = 
					(SecureConnect.ResponseListener) JSON.deserialize(listenerData, Type.forName(listenerType));
				listener.onResponse(responseCode, responseData);
				rec.Status__c = 'COMPLETE';
			} catch (Exception e) {
				System.debug(e);
			}
		}
	}	
}