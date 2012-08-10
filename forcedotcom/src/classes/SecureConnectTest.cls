/**
 *
 */
public class SecureConnectTest {
	/**
	 *
	 */
    public static void requestTest() {
        SecureConnect.request('capture', null, new TestResponseListener('Hello'));
    }
    
    public class TestResponseListener implements SecureConnect.ResponseListener {
    	public String name { get; set; }
    	
    	public TestResponseListener(String name) {
    		this.name = name;
    	}
    	
    	public Type getClassType() {
    		return TestResponseListener.class;
    	}
    	
    	public void onResponse(String responseCode, String responseData) {
    		System.debug('Response instance name = ' + this.name);
    		System.debug('Response code = ' + responseCode);
    	}
    	
    }
}