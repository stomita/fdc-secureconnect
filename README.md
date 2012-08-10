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

- Open {project_root}/forcedotcom/.project in Eclipse with Force.com IDE. 
- Deploy it to your desired Salesforce organization.

### Setup MySQL Database

1. First, please make sure you installed MySQL and mysqld is running
2. Run SQL script to setup demo objects into MySQL database

<pre>
$ cd nodejs/sql
$ mysql test &lt; deptemp.sql
$ mysql test &lt; crbilling.sql
</pre>

### Startup SecureConnect resource server (Node.js) 

1. Please make sure you installed Node.js, npm, and coffee script.

2. Install bundled libraries

	<pre>
$ cd nodejs
$ npm install
</pre>

3. Startup SecureConnect resource server

	<pre>
$ SF_USERNAME=user@example.org \
	SF_PASSWORD=password \
	MYSQL_USER=root \
	MYSQL_PASWORD=pass \
	MYSQL_DATABASE=test \
	coffee server.coffee
</pre>

