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
            mysql_host = connection.get('host')
            mysql_port = connection.get('port')
            auth = configuration.get('auth')
            mysql_database = auth.get('mysql_database')
            mysql_username = auth.get('mysql_username')
            mysql_password = auth.get('mysql_password')

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

        def run_search(self, query_expression, offset=None, length=None):
            results = self.client.cmd_query(query_expression)
            return {"code": 200, "search_id": query_expression, "results": results }
    ' > mysql_connection_client.py
    ```

    The MySQLConnectionClient implements methods to test the connection to the data source and a method to execute queries, which were translated by the `translate` command.

1. Implement the Ping Connector,

    Now our `Connector` class in `wp_ithemes_connector.py` is initialized and has an instance of the data source connection manager, we can implement the `ping` command. The `ping` function is defined by the `WPiThemesPingConnector` that implements the `BasePing` class.

    Create a new file `wp_ithemes_ping_connector.py` and add the code to create the `WPiThemesPingConnector`,
    ```
    echo `from ..base.base_ping import BasePing
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
                return_obj['success'] = True
                return_obj['response'] = {"code": 200, "results": "Client is Connected to Data Source"}
            else:
                return_obj['success'] = False
                errMessage = 'Error: Client could not connect to Data Source'
                print(errMessage)
                ErrorResponder.fill_error(return_obj, response_dict, [errMessage])

            return return_obj
    ` > wp_ithemes_ping_connector.py
    ```

    The `ping` function calls the `ping_box()` function of the `MySQLConnectionClient` class, which tests the connection to the data source.

4. Implement the Results Connector,

    The last connector to implement is the `WPiThemesResultsConnector` that should handle the `create_results_connection` method. This method executes the query against the data source and returns the result set. 

    Create a new file `wp_ithemes_results_connector.py` and add the following code to implement a `BaseResultsConnector` class,
    ```
    echo `from ..base.base_results_connector import BaseResultsConnector
    from .mysql_connection_client import MySQLConnectionClient
    import json
    from .....utils.error_response import ErrorResponder

    class WPiThemesResultsConnector(BaseResultsConnector):
        def __init__(self, mysql_connection_client):
            self.mysql_connection_client = mysql_connection_client

        def create_results_connection(self, search_id, offset, length):
            # todo: enable offset
            min_range = offset
            max_range = offset + length
            query_expression = search_id

            return_obj = dict()
            try:
                response = self.mysql_connection_client.run_search(query_expression, offset=None, length=None)
                return_obj['success'] = True
                return_obj['response'] = response
            except Exception as err:
                errMessage = 'error when searching datasource {}:'.format(err)
                print(errMessage)
                ErrorResponder.fill_error(return_obj, response_dict, [errMessage])
                return_obj['success'] = False

            return return_obj
    ` > wp_ithemes_results_connector.py
    ```
    
5. Add Error Mapping,

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

    Edit the file `mysql_error_mapper.py` and change the `error_mapping` object to map MySQL error codes to the stix-shifter connector error codes, to the following `error_mapping` object:
    ```
    # See: https://mariadb.com/kb/en/mariadb-error-codes/
    error_mapping = {
        1012: 'Cannot read record in system table'
        1013: 'Cannot get status'
        1032: 'Cannot find record'
        1043: 'Bad handshake'
        1044: 'Access denied for user to database'
        1045: 'Access denied for user (using password)'
        1046: 'No database selected'
        1047: 'Unknown command'
        1051: 'Unknown table'
        1102: 'Unknown database'
        1103: 'Incorrect table name'
        1105: 'Unknown error'
        1109: 'Incorrect parameters in procedure'
        1146: 'Table does not exist'
        1251: ErrorCode.TRANSMISSION_AUTH_SSL
        1342: ErrorCode.TRANSMISSION_QUERY_PARSING_ERROR
        1398: ErrorCode.TRANSMISSION_INVALID_PARAMETER
    }
    ```

6. Register the Transmit Module,

    Edit the file `~/stix_shifter/stix_transmission/stix_transmission.py`, and register the `wp_ithemes` to the `TRANSMISSION_MODULES` array on line 4,
    ```
    TRANSMISSION_MODULES = ['async_dummy', 'synchronous_dummy', 'qradar', 'splunk', 'bigfix', 'csa', 'aws_security_hub', 'carbonblack', 'elastic_ecs', 'proxy', 'stix_bundle', 'msatp', 'security_advisor', 'guardium', 'aws_cloud_watch_logs', 'azure_sentinel', 'wp_ithemes']
    ```

7. Test the Transmit Module,

    The `translate query` command returned a translated native query. Use the native query as input parameter in the transmit command.
    ```
    $ python3 main.py translate wp_ithemes query "{}" "[Module:value = 'brute_force']" '{"tableName": "wp_itsec_logs"}'
    {'queries': ["SELECT * FROM wp_itsec_logs WHERE module = 'brute_force'"]}
    ```

    







### Transmit




[timestamp:value > '2020-03-17']
$ python main.py translate wp_ithemes query "{}" "[timestamp > '2020-03-17']"


# Run @localhost

Use MySQL@localhost via docker to run the connector on localhost out of the Cloud Pak for Security, see https://hub.docker.com/_/mysql

Run the mysql container and the phpmyadmin container,
```
$ docker run -d --name wp-mysql -v /Users/user1/dev/src/stix-shifter/mysql:/var/lib/mysql -p 6603:3306 -e MYSQL_ROOT_PASSWORD=Passw0rd -e MYSQL_DATABASE=wp_itsec_logs mysql:latest
$ docker inspect wp-mysql | grep IPAddress
$ docker run --name phpmyadmin -d --link wp-mysql:db -p 8080:80 phpmyadmin/phpmyadmin 
```

Load the sql from the `~/data` folder with test data.



Use the results from the `translate query` command, to run the transmit query command,
```
$ python main.py translate wp_ithemes query "{}" "[id:value = 1]"
```


Run the `transmit ping` command,
```
$ python main.py transmit wp_ithemes '{"host":"localhost", "port":"6603"}' '{"auth": {"mysql_username": "root","mysql_password": "Passw0rd", "mysql_hostname": "localhost", "mysql_database": "remkoh_dev_2" } }' ping
{'success': True, 'response': {'code': 200, 'results': 'Client is Connected to Data Source'}}
```


Run the `transmit results` command,
```
$ python main.py transmit wp_ithemes '{"host":"localhost", "port":"6603"}' '{"auth": {"mysql_username": "root","mysql_password": "Passw0rd", "mysql_hostname": "localhost", "mysql_database": "remkoh_dev_2" } }' results "SELECT * FROM wp_2d52qn_itsec_logs WHERE Id = '1'" 0 1

{'success': True, 'response': {'code': 200, 'search_id': "SELECT * FROM wp_2d52qn_itsec_logs WHERE Id = '1'", 'results': {'columns': [('id', 8, None, None, None, None, 0, 16931), ('parent_id', 8, None, None, None, None, 0, 33), ('module', 253, None, None, None, None, 0, 16393), ('code', 253, None, None, None, None, 0, 16393), ('data', 252, None, None, None, None, 0, 4113), ('type', 253, None, None, None, None, 0, 16393), ('timestamp', 12, None, None, None, None, 0, 16521), ('init_timestamp', 12, None, None, None, None, 0, 129), ('memory_current', 8, None, None, None, None, 0, 33), ('memory_peak', 8, None, None, None, None, 0, 33), ('url', 253, None, None, None, None, 0, 1), ('blog_id', 8, None, None, None, None, 0, 16393), ('user_id', 8, None, None, None, None, 0, 16425), ('remote_ip', 253, None, None, None, None, 0, 1)], 'eof': {'warning_count': 0, 'status_flag': 1}}}}
```

### Execute



## Maps

### itsec_logs

A simple `to_stix_map.json` file would be
```
{
  "Id": {
    "key": "id"
  },
  "ParentId": {
    "key": "parent_id"
  },
  "Module": {
    "key": "module"
  },
  "Code": {
    "key": "code"
  },
  "Data": {
    "key": "data"
  },
  "Type": {
    "key": "type"
  },
  "Timestamp": {
    "key": "timestamp"
  },
  "InitTimestamp": {
    "key": "init_timestamp"
  },
  "MemoryCurrent": {
    "key": "memory_current"
  },
  "MemoryPeak": {
    "key": "memory_peak"
  },
  "Url": {
    "key": "url"
  },
  "BlogId": {
    "key": "blog_id"
  },
  "UserId": {
    "key": "user_id"
  },
  "RemoteIp": {
    "key": "remote_ip"
  }
}
```

A simple `from_stix_map.json` file would be
```
{
  "id": {
    "fields": {
      "value": ["Id"]
    }
  },
  "parent_id": {
    "fields": {
      "value": ["ParentId"]
    }
  },
  "module": {
    "fields": {
      "value": ["Module"]
    }
  },
  "code": {
    "fields": {
      "value": ["Code"]
    }
  },
  "data": {
    "fields": {
      "value": ["Data"]
    }
  },
  "type": {
    "fields": {
      "value": ["Type"]
    }
  },
  "timestamp": {
    "fields": {
      "value": ["Timestamp"]
    }
  },
  "init_timestamp": {
    "fields": {
      "value": ["InitTimestamp"]
    }
  },
  "memory_current": {
    "fields": {
      "value": ["MemoryCurrent"]
    }
  },
  "memory_peak": {
    "fields": {
      "value": ["MemoryPeak"]
    }
  },
  "url": {
    "fields": {
      "value": ["Url"]
    }
  },
  "blog_id": {
    "fields": {
      "value": ["BlogId"]
    }
  },
  "user_id": {
    "fields": {
      "value": ["UserId"]
    }
  },
  "remote_ip": {
    "fields": {
      "value": ["RemoteIp"]
    }
  }
}
```


## Notes



ACTION=<"query" or "result">
PATTERN="[id = 1]"
Define module name, authentication object, and connection object:
```
$ ACTION=query
$ PATTERN="[id = 1]"
$ MODULE=wp_ithemes
$ AUTH='{"auth": {"username": "<mysql_username>","password": "<mysql_password>", "hostname": "<mysql_host>", "database": "<mysql_database>", "table": "wp_itsec_logs" }}'
$ CONN='{"host": "<mysql_host>", "port": <mysql_port>}'

$ python main.py translate $MODULE $ACTION '{}' $PATTERN <options>
```

```
python main.py translate $MODULE $ACTION '{"host": "<mysql_host>", "port": <mysql_port>}'
```


python main.py translate wp_ithemes query "{}" "[id:value = '1']"
