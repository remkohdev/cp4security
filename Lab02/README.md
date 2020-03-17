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

Upon installation, `Ithemes Security` will create the following tables:
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
stix-shifter main.py translate <MODULE NAME> query "<STIX IDENTITY OBJECT>" "<STIX PATTERN>" "<OPTIONS>"
```

For the wp_ithemes connector, to translate a simple query from stix to sql:
```
$ python main.py translate wp_ithemes query "{}" "[id:value = 1]"
=====> query_string:
["SELECT * FROM tableName WHERE Id = '1'"]
{'queries': ["SELECT * FROM tableName WHERE Id = '1'"]}
```

### Transmit


### Execute

```
python main.py transmit wp_ithemes '{}' '{"auth": {"username": "<mysql_username>","password": "<mysql_password>", "hostname": "<mysql_host>", "database": "<mysql_database>" }}' ping
```


The `translate` function

Usage:
```
$ main.py translate [-h] [-x] [-m DATA_MAPPER] module {results,query,parse,supported_attributes} data_source data [options] [recursion_limit]
```

The `transmit` function takes in common arguments: the module name, the connection object, and the configuration object. 
```
$ python main.py transmit $MODULE $CONN $AUTH ping
```

Usage:
```
$ main.py transmit [-h] module connection configuration {ping,query,results,status,delete,is_async}
```



## itsec_logs

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

Add the line `include stix_shifter/stix_translation/src/modules/wp_ithemes/json/*.json` to the `~/MANIFEST.in` file.
Add the module to the array `TRANSLATION_MODULES = []` on line 15 in `include stix_shifter/stix_translation/stix_translation.py`.

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

python main.py translate wp_ithemes query "{}" "[id:value = '1']"
Caught exception: wp_ithemes is an unsupported data source. <class 'stix_shifter.stix_translation.src.utils.exceptions.UnsupportedDataSourceException'>
received exception => UnsupportedDataSourceException: wp_ithemes is an unsupported data source.
{'success': False, 'code': 'not_implemented', 'error': 'unsupported datasource : wp_ithemes is an unsupported data source.'}