# Force.com SecureConnect

## Abstract

Force.com (or its application, Salesforce) is a cloud environment which can store various business data or run transactional business logics.

Because the service is located entirely in the "cloud", it is difficult to cooperate with "intranet" systems which are behind the firewall, especially when the trigger occurs in Force.com side.

This project is an attempt to accomplish *cloud-to-intranet* messaging, without breaking firewall policies, by using Force.com Streaming API.


## Architecture

See the slides:

[http://www.slideshare.net/shinichitomita/cloudtointranet-messaging-by-forcecom-streaming-api](http://www.slideshare.net/shinichitomita/cloudtointranet-messaging-by-forcecom-streaming-api)


## Setup

### Deploy Force.com Classes

1. Open ${project_root}/forcedotcom/.project in Eclipse with Force.com IDE. 
1. Deploy it to your desired Salesforce organization.

### Setup MySQL Database

1. First, please make sure you installed MySQL and mysqld is running
1. Run SQL script to setup demo objects into MySQL database

	<pre>
$ cd ${project_root}/nodejs/sql
$ mysql test &lt; deptemp.sql
$ mysql test &lt; crbilling.sql
</pre>

### Startup SecureConnect resource server (Node.js) 

1. Please make sure you installed Node.js, npm, and coffee script.

1. Install bundled libraries

	<pre>
$ cd ${project_root}/nodejs
$ npm install
</pre>

1. Startup SecureConnect resource server

	<pre>
$ SF_USERNAME=user@example.org \
	SF_PASSWORD=password \
	MYSQL_USER=root \
	MYSQL_PASWORD=pass \
	MYSQL_DATABASE=test \
	coffee server.coffee
</pre>


## Demo

### Simple Hello World
1. Log in to Salesforce and access "SC Client" tab.
2. Put your name to first text field and press "Hello" button.
3. It pops up "Hello, &lt;your name&gt;" alert box.
4. Confirm the resource server log that the message is arrived from request client.

### Query to MySQL
1. Log in to Salesforce and access "SC Client" tab.
2. Put a SQL "SELECT * FROM EMP" to the second text field and press "Query" button.
3. After a few seconds, it shows query result in a table in the page.
4. Confirm the data is queried from local MySQL database by checking the resource server log.


### Opportunity Propagation

1. Log in to Salesforce and access to Opportunity tab.
2. Creaate an Opportunity record and save. 
3. Update the opportunity to set *Stage* field value to "Close - Won" (or equivalent). Please also input field values like *Amount* or *Close Date* field.
4. After a few seconds, refresh the page, and check that *External System ID* field has a value. If there's no field entry in the page, please change page layout to include the field.
5. Confirm that MySQL database has a new record in *billing* table, including *sfdc_id*, *name*, *amount*, and *close_date* column data, which is copied from opportunity record in Salesforce.
