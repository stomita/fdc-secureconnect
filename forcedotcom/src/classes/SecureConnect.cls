/**
 * SecureConnect is a class which enables callout from Force.com cloud to Firewall-protected internal resources.
 */
global class SecureConnect {
  /**
   * Setup PushTopics channels for both stream (request and response)
   */
  global static void globalInit() {
  	PushTopic[] topics = [SELECT Id FROM PushTopic WHERE Name IN ('SecureConnectRequest', 'SecureConnectResponse') LIMIT 2];
  	if (topics.size() > 0) {
  		delete topics;
  	}
  	topics = new PushTopic[2];
  	topics[0] = new PushTopic(ApiVersion = 24.0, Name = 'SecureConnectRequest');
    topics[0].Query = 'SELECT Id, RequestType__c, Status__c FROM SecureConnect__c WHERE Status__c IN ( \'REQUEST\', \'REQUEST_WITH_DATA\' )';
    topics[1] = new PushTopic(ApiVersion = 24.0, Name = 'SecureConnectResponse');
    topics[1].Query = 'SELECT Id, ResponseCode__c, Status__c FROM SecureConnect__c WHERE Status__c IN ( \'RESPONSE\', \'RESPONSE_WITH_DATA\', \'ERROR\', \'TIMEOUT\' )';
    insert topics;
    
  }

  /**
   * To handle server's response in Apex, create class which implements ResponseListener interface.
   */
  public interface ResponseListener {
  	Type getClassType();
    void onResponse(String responseCode, String responseData);
  }
  
  /**
   * Callout request from Apex using Streaming API.
   */
  public static Id request(String requestType, String requestData, ResponseListener listener) {
  	SecureConnect__c rec = new SecureConnect__c();
  	rec.RequestType__c=requestType;
  	if (requestData != null && !requestData.equals('')) {
  	  rec.RequestData__c = requestData;
  	  rec.Status__c = 'REQUEST_WITH_DATA';	
  	} else {
  	  rec.Status__c = 'REQUEST';
  	}
  	if (listener != null) {
      rec.ResponseListenerType__c = listener.getClassType().getName();
  	  rec.ResponseListenerData__c = JSON.serialize(listener);
  	}
  	insert rec;
  	return rec.Id;
  }

}