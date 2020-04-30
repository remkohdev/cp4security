# Lab03 - Build a Transmit Module for wp_ithemes Connector

In this lab you will build the `transmit` module for the stix-shifter connector to connect to and retrieve logs from the iThemes Security plugin for WordPress. 

This lab is assuming you are using stix-shifter version 2.x from the `v2-master` branch,
```
$ git clone -b v2-master https://github.com/opencybersecurityalliance/stix-shifter.git
$ cd stix-shifter
```

and that you completed [Lab02](../Lab02/README.md) and have a `translate` module.

## Transmit

The `transmit` command connects stix-shifter to the cybersecurity data source using connection and authentication credentials. The `transmit` command takes in common arguments: the module name, the connection object, and the configuration or authentication object. 

Usage:
```
$ main.py transmit [-h] module connection configuration {ping,query,results,status,delete,is_async}
```

Or 
```
$ python3 main.py transmit $MODULE $CONN $AUTH ping
```

The `transmit` command can be used with the following methods:
* ping
* query (only for asynchronous)
* results
* status (only for asynchronous)
* delete and
* is_async

### Create the Translate Module

1. Create a New Folder,

    Create a new folder `stix_shifter/stix_transmission/src/modules/wp_ithemes` for the `stix_transmission` module,
    ```
    $ mkdir -p stix_shifter/stix_transmission/src/modules/wp_ithemes
    ```

1. Create a Python Module for Transmit

    To create the transmit directory into a Python module, add a `__init__.py` file.
    ```
    $ cd stix_shifter/stix_transmission/src/modules/wp_ithemes
    $ touch __init__.py
    ```

1. Add a Connector Class

    Create a new file `wp_ithemes_connector.py`,
    ```
    $ echo 'from ..base.base_connector import BaseConnector
    from .....utils.error_response import ErrorResponder
    from .mysql_connection_client import MySQLConnectionClient
    from .mysql_error_mapper import ErrorMapper
    from .wp_ithemes_ping_connector import WPiThemesPingConnector
    from .wp_ithemes_results_connector import WPiThemesResultsConnector
    import json

    class UnexpectedResponseException(Exception): pass

    class Connector(BaseConnector):
        def __init__(self, connection, configuration):
            self.mysql_connection_client = MySQLConnectionClient(connection, configuration)
            self.is_async = False
            self.ping_connector = WPiThemesPingConnector(self.mysql_connection_client)
            self.results_connector = WPiThemesResultsConnector(self.mysql_connection_client)
            self.status_connector = self
            self.query_connector = self

        def create_query_connection(self, query):
            return {"success": True, "search_id": query}

        def create_status_connection(self, search_id):
            return {"success": True, "status": "COMPLETED", "progress": 100}
    ' > wp_ithemes_connector.py
    ```

    The `Connector` class initializes a `MySQLConnectionClient`, and implements the `ping`, `results`, `status`, and `query` methods. 
    The `Connector` class also loads an `ErrorMapper` class, that maps MySQL and MariaDB error codes to custom messages.

1. Create the MySQLConnectionClient,

    Create a new file `mysql_connection_client.py` and add the following code,
    ```
    $ echo 'import mysql.connector

    class MySQLConnectionClient():

        def __init__(self, connection, configuration):
            # https://dev.mysql.com/doc/connector-python/en/connector-python-connectargs.html
            mysql_host = connection.get("host")
            mysql_port = connection.get("port")
            auth = configuration.get("auth")
            mysql_database = auth.get("mysql_database")
            mysql_username = auth.get("mysql_username")
            mysql_password = auth.get("mysql_password")

            # See https://dev.mysql.com/downloads/connector/python/
            self.client = mysql.connector.MySQLConnection(
                host=mysql_host,
                port=mysql_port,
                database=mysql_database,
                user=mysql_username,
                password=mysql_password
                )

        def ping_box(self):
            # See: https://dev.mysql.com/doc/connector-python/en/connector-python-api-mysqlconnection-is-connected.html
            return self.client.is_connected() 

        def run_search(self, query_expression, offset, length):
            query = "{} limit {} offset {}".format(query_expression, length, offset)

            cursor = self.client.cursor()
            cursor.execute(query)
            results = cursor.fetchall()

            return {"code": 200, "search_id": query, "results": results }
    ' > mysql_connection_client.py
    ```
    Correct indentation from copy-pasting where necessary.

    The MySQLConnectionClient implements methods to test the connection to the data source and a method to execute queries, which were translated by the `translate` command.

1. Implement the Ping Connector,

    Now our `Connector` class in `wp_ithemes_connector.py` is initialized and has an instance of the data source connection manager, we can implement the `ping` command. The `ping` function is defined by the `WPiThemesPingConnector` that implements the `BasePing` class.

    Create a new file `wp_ithemes_ping_connector.py` and add the code to create the `WPiThemesPingConnector`,
    ```
    $ echo 'from ..base.base_ping import BasePing
    from .mysql_connection_client import MySQLConnectionClient
    import json
    from .....utils.error_response import ErrorResponder

    class WPiThemesPingConnector(BasePing):
        def __init__(self, mysql_connection_client):
            self.mysql_connection_client = mysql_connection_client

        def ping(self):
            return_obj = dict()

            isConnected = self.mysql_connection_client.ping_box()

            if isConnected:
                return_obj["success"] = True
                return_obj["response"] = {"code": 200, "results": "Client is Connected to Data Source"}
            else:
                return_obj["success"] = False
                errMessage = "Error: Client could not connect to Data Source"
                print(errMessage)
                ErrorResponder.fill_error(return_obj, response_dict, [errMessage])

            return return_obj
    ' > wp_ithemes_ping_connector.py
    ```

    The `ping` function calls the `ping_box()` function of the `MySQLConnectionClient` class, which tests the connection to the data source.

1. Implement the Results Connector,

    The last connector to implement is the `WPiThemesResultsConnector` that should handle the `create_results_connection` method. This method executes the query against the data source and returns the result set. 

    Create a new file `wp_ithemes_results_connector.py` and add the following code to implement a `BaseResultsConnector` class,
    ```
    $ echo 'from ..base.base_results_connector import BaseResultsConnector
    from .mysql_connection_client import MySQLConnectionClient
    import json
    from .....utils.error_response import ErrorResponder

    class WPiThemesResultsConnector(BaseResultsConnector):
        def __init__(self, mysql_connection_client):
            self.mysql_connection_client = mysql_connection_client

        def create_results_connection(self, search_id, offset, length):
            query_expression = search_id

            return_obj = dict()
            try:
                response = self.mysql_connection_client.run_search(query_expression, offset=offset, length=length)
                return_obj["success"] = True
                return_obj["response"] = response
            except Exception as err:
                errMessage = "Error searching datasource {}:".format(err)
                print(errMessage)
                ErrorResponder.fill_error(return_obj, response_dict, [errMessage])
                return_obj["success"] = False

            return return_obj
    ' > wp_ithemes_results_connector.py
    ```
    
1. Add Error Mapping,

    First copy the `ErrorMapper` and Error Mapping from the `synchronous_dummy` module,
    ```
    $ cp ../synchronous_dummy/synchronous_dummy_error_mapper.py mysql_error_mapper.py
    ```

    The `Connector` class in `wp_ithemes_connector.py` loads the custom error mapping from the `mysql_error_mapper.py` file, you just copied from the `synchronous_dummy` module.

    The `~/utils/error_response.py` file defines the following enumeration of error codes,
    ```
    class ErrorCode(Enum):
        TRANSLATION_NOTIMPLEMENTED_MODE = 'not_implemented'
        TRANSLATION_MODULE_DEFAULT_ERROR =  'invalid_parameter'
        TRANSLATION_MAPPING_ERROR = 'mapping_error'
        TRANSLATION_STIX_VALIDATION = 'invalid_parameter'
        TRANSLATION_NOTSUPPORTED = 'invalid_parameter'
        TRANSLATION_RESULT = 'mapping_error'

        TRANSMISSION_UNKNOWN = 'unknown'
        TRANSMISSION_CONNECT = 'service_unavailable'
        TRANSMISSION_AUTH_SSL = 'authentication_fail'
        TRANSMISSION_AUTH_CREDENTIALS = 'authentication_fail'
        TRANSMISSION_MODULE_DEFAULT_ERROR = 'unknown'
        TRANSMISSION_QUERY_PARSING_ERROR = 'invalid_query'
        TRANSMISSION_QUERY_LOGICAL_ERROR = 'invalid_query'
        TRANSMISSION_RESPONSE_EMPTY_RESULT = 'no_results'
        TRANSMISSION_SEARCH_DOES_NOT_EXISTS = 'no_results'
        TRANSMISSION_INVALID_PARAMETER = 'invalid_parameter'
        TRANSMISSION_REMOTE_SYSTEM_IS_UNAVAILABLE = 'service_unavailable'
    ```

    Edit the file `mysql_error_mapper.py` and change the `error_mapping` object on line 4 to map MySQL error codes to the stix-shifter connector error codes, to the following `error_mapping` object:
    ```
    # See: https://mariadb.com/kb/en/mariadb-error-codes/
    error_mapping = {
        1012: 'Cannot read record in system table',
        1013: 'Cannot get status',
        1032: 'Cannot find record',
        1043: 'Bad handshake',
        1044: 'Access denied for user to database',
        1045: 'Access denied for user (using password)',
        1046: 'No database selected',
        1047: 'Unknown command',
        1051: 'Unknown table',
        1102: 'Unknown database',
        1103: 'Incorrect table name',
        1105: 'Unknown error',
        1109: 'Incorrect parameters in procedure',
        1146: 'Table does not exist',
        1251: ErrorCode.TRANSMISSION_AUTH_SSL,
        1342: ErrorCode.TRANSMISSION_QUERY_PARSING_ERROR,
        1398: ErrorCode.TRANSMISSION_INVALID_PARAMETER
    }
    ```

1. Register the Transmit Module,

    Edit the file `~/stix_shifter/stix_transmission/stix_transmission.py`, and register the `wp_ithemes` to the `TRANSMISSION_MODULES` array on line 4,
    ```
    TRANSMISSION_MODULES = ['async_dummy', 'synchronous_dummy', 'qradar',
    'splunk', 'bigfix', 'csa', 'aws_security_hub', 'carbonblack',
    'elastic_ecs', 'proxy', 'stix_bundle', 'msatp', 'security_advisor',
    'guardium', 'aws_cloud_watch_logs', 'azure_sentinel', 'wp_ithemes']
    ```

1. Install dependencies

    Add `mysql-connector-python>=8.0.19` to the `requirements.txt` dependencies for Python. 
    ```
    $ pip3 install -r requirements-dev.txt
    ...
    Installing collected packages: dnspython, protobuf, mysql-connector-python
    Successfully installed dnspython-1.16.0 mysql-connector-python-8.0.19 protobuf-3.6.1
    ```

1. Test the Transmit Module,

    Test the data source connection using the `transmit ping` command,
    ```
    $ python3 main.py transmit wp_ithemes '{"host":"123.45.123.123", "port":"30306"}' '{"auth": {"mysql_username": "user1","mysql_password": "Passw0rd", "mysql_hostname": "123.45.123.123", "mysql_database": "wp_test_db" } }' ping

    {'success': True, 'response': {'code': 200, 'results': 'Client is Connected to Data Source'}}
    ```

    The `translate query` command returned a translated native query. Use the translated native query as input parameter in the `transmit results` command, using `offset=0` and `length=1`.
    ```
    $ python3 main.py transmit wp_ithemes '{"host":"123.45.123.123", "port":"30306"}' '{"auth": {"mysql_username": "user1","mysql_password": "Passw0rd", "mysql_hostname": "123.45.123.123", "mysql_database": "wp_test_db" } }' results "SELECT * FROM wp_itsec_logs WHERE Module = 'brute_force'" 0 1

    {'success': True, 'response': {'code': 200, 'search_id': "SELECT * FROM wp_itsec_logs WHERE Module = 'brute_force' limit 1 offset 0", 'results': [(30148, 0, 'brute_force', 'invalid-login::username-szirine.com', 'a:5:{s:7:"details";a:2:{s:6:"source";s:6:"xmlrpc";s:20:"authentication_types";a:1:{i:0;s:21:"username_and_password";}}s:4:"user";O:8:"WP_Error":2:{s:6:"errors";a:1:{s:16:"invalid_username";a:1:{i:0;s:56:"Unknown username. Check again or try your email address.";}}s:10:"error_data";a:0:{}}s:8:"username";s:11:"szirine.com";s:7:"user_id";i:0;s:6:"SERVER";a:37:{s:15:"SERVER_SOFTWARE";s:6:"Apache";s:11:"REQUEST_URI";s:11:"/xmlrpc.php";s:4:"PATH";s:60:"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin";s:11:"SCRIPT_NAME";s:11:"/xmlrpc.php";s:12:"QUERY_STRING";s:0:"";s:14:"REQUEST_METHOD";s:4:"POST";s:15:"SERVER_PROTOCOL";s:8:"HTTP/1.1";s:17:"GATEWAY_INTERFACE";s:7:"CGI/1.1";s:11:"REMOTE_PORT";s:5:"38018";s:15:"SCRIPT_FILENAME";s:38:"/home/dh_23wzed/szirine.com/xmlrpc.php";s:12:"SERVER_ADMIN";s:21:"webmaster@szirine.com";s:21:"CONTEXT_DOCUMENT_ROOT";s:27:"/home/dh_23wzed/szirine.com";s:14:"CONTEXT_PREFIX";s:0:"";s:14:"REQUEST_SCHEME";s:4:"http";s:13:"DOCUMENT_ROOT";s:27:"/home/dh_23wzed/szirine.com";s:11:"REMOTE_ADDR";s:14:"64.202.188.205";s:11:"SERVER_PORT";s:2:"80";s:11:"SERVER_ADDR";s:14:"173.236.188.87";s:11:"SERVER_NAME";s:11:"szirine.com";s:16:"SERVER_SIGNATURE";s:0:"";s:12:"CONTENT_TYPE";s:8:"text/xml";s:9:"HTTP_HOST";s:11:"szirine.com";s:15:"HTTP_USER_AGENT";s:90:"Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.0.1) Gecko/2008070208 Firefox/3.0.1";s:11:"HTTP_ACCEPT";s:74:"text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8";s:15:"HTTP_CONNECTION";s:5:"close";s:20:"HTTP_ACCEPT_ENCODING";s:23:"identity, gzip, deflate";s:14:"CONTENT_LENGTH";s:3:"252";s:7:"DH_USER";s:9:"dh_23wzed";s:14:"ds_id_40644047";s:0:"";s:4:"dsid";s:8:"40644047";s:10:"SCRIPT_URI";s:29:"http://szirine.com/xmlrpc.php";s:10:"SCRIPT_URL";s:11:"/xmlrpc.php";s:9:"UNIQUE_ID";s:27:"XmvmbztjbkBzgs0Jzi2SmAAAAAk";s:9:"FCGI_ROLE";s:9:"RESPONDER";s:8:"PHP_SELF";s:11:"/xmlrpc.php";s:18:"REQUEST_TIME_FLOAT";s:15:"1584129647.1169";s:12:"REQUEST_TIME";s:10:"1584129647";}}', 'notice', datetime.datetime(2020, 3, 13, 20, 0, 47), datetime.datetime(2020, 3, 13, 20, 0, 47), 45156968, 45350320, 'http://szirine.com/xmlrpc.php', 1, 0, '64.202.188.205')]}}
    ```

    To return more results change the `length`, to change the position of the cursor, change the `offset` command. For example to return the 2nd and 3rd result from the query, use `offset=1` and `length=2`,
    ```
    $ python3 main.py transmit wp_ithemes '{"host":"123.45.123.123", "port":"30306"}' '{"auth": {"mysql_username": "user1","mysql_password": "Passw0rd", "mysql_hostname": "123.45.123.123", "mysql_database": "wp_test_db" } }' results "SELECT * FROM wp_itsec_logs WHERE Module = 'brute_force'" 1 2

    ```
