# Lab02 - Build a STIX_SHIFTER Connector for wp_ithemes logs

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

## STIX_SHIFTER Connector

Stix-shifter provides 3 functions: `translate` and `transmit` are the primary functions, `execute` tests the complete stix-shifter flow.

### Translate

The `translate` command converts STIX patterns into data source queries and translates data source query results (in JSON format) into STIX observation objects.

Usage:
```
$ main.py translate [-h] [-x] [-m DATA_MAPPER] module {results,query,parse,supported_attributes} data_source data [options] [recursion_limit]
```

The `translate` command can be used with the following methods:
* results
* query
* parse
* supported_attributes


A STIX Pattern like,
```
"[id:value = 1]"
```
Would be translated to a SQL Query:
```
"SELECT * FROM tableName WHERE (id = 1)
```

Translation of a query is called in the format of:
```
stix-shifter translate <MODULE NAME> query "<STIX IDENTITY OBJECT>" "<STIX PATTERN>" "<OPTIONS>"
```

Or from source,
```
python main.py translate <MODULE NAME> query "<STIX IDENTITY OBJECT>" "<STIX PATTERN>" "<OPTIONS>"
```

For the wp_ithemes connector, to translate a simple query from stix to the native query language of the data source, i.e. sql:
```
$ python main.py translate wp_ithemes query "{}" "[id:value = 1]"
=====> query_string:
["SELECT * FROM tableName WHERE Id = '1'"]
{'queries': ["SELECT * FROM tableName WHERE Id = '1'"]}
```

The translated native query can be used as an input parameter in the transmit command.


#### Stix Patterns

[timestamp:value > '2020-03-17']
$ python main.py translate wp_ithemes query "{}" "[timestamp > '2020-03-17']"

### Transmit

The `transmit` function takes in common arguments: the module name, the connection object, and the configuration or authentication object. 
```
$ python main.py transmit $MODULE $CONN $AUTH ping
```

Usage:
```
$ main.py transmit [-h] module connection configuration {ping,query,results,status,delete,is_async}
```

The `transmit` command can be used with the following methods:
* ping
* query (only for asynchronous)
* results
* status (only for asynchronous)
* delete and
* is_async


## Configure stix_shifter to add connector

Add the line `include stix_shifter/stix_translation/src/modules/wp_ithemes/json/*.json` to the `~/MANIFEST.in` file.
Add the module to the array `TRANSLATION_MODULES = []` on line 15 in `include stix_shifter/stix_translation/stix_translation.py`.

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
$ $ python main.py transmit wp_ithemes '{"host":"localhost", "port":"6603"}' '{"auth": {"mysql_username": "root","mysql_password": "Passw0rd", "mysql_hostname": "localhost", "mysql_database": "remkoh_dev_2" } }' results "SELECT * FROM wp_2d52qn_itsec_logs WHERE Id = '1'" 0 1

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
