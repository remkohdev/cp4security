# Introduction

Stix-shifter provides 3 functions: 
* `translate`,
* `transmit`, 
* `execute`.

The `translate` command can be used with the following methods:
* results
* query
* parse
* supported_attributes

The `transmit` command can be used with the following methods:
* ping
* query (only for asynchronous)
* results
* status (only for asynchronous)
* delete and
* is_async


## Wordpress iThemes

The [iThemes Security Pro](https://ithemes.com/security/) is a leading Security and Protection plugin for WordPress. It offers the following high level features:
* WordPress Brute Force Protection,
* File Change Detection,
* 404 Detection,
* Strong Password Enforcement,
* Locl Out Bad Users,
* Away Mode,
* Hide Login and Admin,
* Database Backups,
* Email Notifications.

Upon installation, `iThemes Security for WordPress` will create the following tables:
* itsec_distributed_storage
* itsec_fingerprints
* itsec_geolocation_cache
* itsec_lockouts
* itsec_logs
* itsec_opaque_tokens
* itsec_temp

The `wp_itsec_logs` table has the following columns:
* id
* blog_id
* code
* data
* init_timestamp
* memory_current
* memory_peak
* module
* parent_id
* remote_ip
* timestamp
* type
* url
* user_id


The `module` column has the following distinct values:
* brute_force
* file_change
* four_oh_four
* lockout
* notification_center

The `code` column has the following distinct values:
* auto-ban-admin-username
* changes-found
* found_404
* host-lockout

The `type` column has the following distinct values:
* action
* debug
* notice
* process-start
* process-stop
* process-update
* warning


## WordPress iThemes Security Connector

### v0.1.0

The WordPress iThemes Security Connector v0.1.0 implements a connector to the `itsec_logs` table of iThemes Security and the following commands for the stix_shifter connector:
* `translate`,
  * query,
* `transmit`, 
  * ping,
  * results,
* `execute`.


# Playback

Steps:
1. Setup localhost development environment:
   1. MySQL
   2. PHPMyAdmin, localhost:8080
   3. Import `szirinedb_create.sql`
   4. Import `szirinedb_wp_itsec_logs_1.sql`, optionally import *2,3,4,5.
   5. Install dependencies for connector, `pip install -r requirements.txt`
2. Run `transmit ping` command example,

	```
	python main.py transmit wp_ithemes '{"host":"localhost", "port":"6603"}' '{"auth": {"mysql_username": "root","mysql_password": "Passw0rd", "mysql_hostname": "localhost", "mysql_database": "szirine_com" } }' ping
	{'success': True, 'response': {'code': 200, 'results': 'Client is Connected to Data Source'}}
	```

3. Run `translate query` command examples with Stix Patterns,

	Examples:
      * "[module:value = 'brute_force']"
        * $ python main.py translate wp_ithemes query "{}" "[module:value = 'brute_force']"
        * SELECT * FROM wp_itsec_logs WHERE Module = 'brute_force'
      * "[module:value = 'brute_force' AND code:value = 'invalid-login']]"
        * $ python main.py translate wp_ithemes query "{}" "[module:value = 'brute_force' AND code:value = 'invalid-login']"
        * SELECT * FROM wp_itsec_logs WHERE Code = 'invalid-login' AND Module = 'brute_force'
      * "[type:value = 'warning']"
        * $ python main.py translate wp_ithemes query "{}" "[type:value = 'warning']"
        * SELECT * FROM wp_itsec_logs WHERE Type = 'warning'

4. Run `transmit results` command example,
   
	* Using the above queries, get the results data,
    	* $ python main.py transmit wp_ithemes '{"host":"localhost", "port":"6603"}' '{"auth": {"mysql_username": "root","mysql_password": "Passw0rd", "mysql_hostname": "localhost", "mysql_database": "szirine_com" } }' results "SELECT * FROM wp_itsec_logs WHERE Module = 'brute_force'" 0 1
    	* $ python main.py transmit wp_ithemes '{"host":"localhost", "port":"6603"}' '{"auth": {"mysql_username": "root","mysql_password": "Passw0rd", "mysql_hostname": "localhost", "mysql_database": "szirine_com" } }' results "SELECT * FROM wp_itsec_logs WHERE Code = 'invalid-login' AND Module = 'brute_force'" 0 1
        * $ python main.py transmit wp_ithemes '{"host":"localhost", "port":"6603"}' '{"auth": {"mysql_username": "root","mysql_password": "Passw0rd", "mysql_hostname": "localhost", "mysql_database": "szirine_com" } }' results "SELECT * FROM wp_itsec_logs WHERE Type = 'warning'" 0 1

5. Feature requests, bug reports, issues: https://github.com/remkohdev/cp4security#zenhub
   1. CP4S Epic https://github.com/remkohdev/cp4security/issues/1
6. 


Highlights: 

* Created a CP4Security STIX_SHIFTER Connector for WordPress iThemes Security. More than half the world's websites use WordPress to manage content. The most popular security plugin for WordPress is iThemes Security. The Connector implements 2 main commands:
1. translate, using a mapping file the translate command translates incoming and outgoing messages to connect the CP4Security with the iThemes Security data source, into a native data source query,
2. transmit, establishes a connection with the security data source, returns the health status, executes the query and returns the query results,
The connector provides the data for the UDS Dashboard in the CP4Security.
* Playback with IBM Cloud Pak for Security scheduled to showcase progress on CP4Security STIX_SHIFTER Connector for WordPress iThemes Security,
* Started functional description and technical research for CP4Security Apps. The CP4S App is a dashboard widget that visualizes data retrieved from the connectors.
* Set up CP4Security squad organization, box folder, Slack channel #cda-squad-security, public Zenhub board
* Discussed roll-out strategy with the OM team. Phase 1 of the developer enablement content will be rolled out with a preferred partner in collaboration with the OM team. Also coordinating with Ben Peterson, Developer Advocacy and Startup Leader in A/NZ, who has immediate opportunities to roll out the content.
* Several developer teams have shown interest to contribute to the developer content development. To be continued, as I need to setup the proper repository and zenhub board to facilitate.


Next Steps:

* Playback release version 0.1.0 of CP4Security STIX_SHIFTER Connector for WordPress iThemes Security Logs, March 27,
* Create a 6 months roadmap for CP4Security development,
* Create easy to start issues to encourage open source contribution by other developers,
* Plan v0.2.0
* Unit Tests
* Add Asynchronous support,
* Support extended commands and methods,
* Support other tables for iThemes Security,
* Plan v1.0.0 GA, requires a CP4Security Deployment
* Start work on the CP4S App for CP4Security STIX_SHIFTER Connector for WordPress iThemes Security,