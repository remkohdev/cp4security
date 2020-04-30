# Lab02 - Build a Translate Module for wp_ithemes Connector

In this lab you will build a stix-shifter connector to retrieve logs from the iThemes Security plugin for WordPress. This lab is assuming you are using stix-shifter version 2.x from the `v2-master` branch.

```
$ git clone -b v2-master https://github.com/opencybersecurityalliance/stix-shifter.git
$ cd stix-shifter
```

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

Upon installation in WordPress, the `iThemes Security for WordPress` plugin will create the following tables in the WordPress database:
* itsec_distributed_storage
* itsec_fingerprints
* itsec_geolocation_cache
* itsec_lockouts
* itsec_logs
* itsec_opaque_tokens
* itsec_temp

## STIX_SHIFTER Connector

Stix-shifter provides 3 functions: 
1. `translate` converts STIX patterns into data source queries,
2. `transmit` allows stix-shifter to connect with product data, and 
3. `execute` runs the `translate` and `transmit` in sequence.

In v2 of stix-shifter, you have to add 2 modules, 1 module for the `translate` command, and 1 module for the `transmit` command.

### Translate

The `translate` command converts STIX patterns into data source queries and translates data source query results (in JSON format) into STIX observation objects.

The `translate` command can be used with the following methods:
* results
* query
* parse
* supported_attributes

This version of the connector only supports the `query` command.

Usage:
```
$ main.py translate [-h] [-x] [-m DATA_MAPPER] module {results,query,parse,supported_attributes} data_source data [options] [recursion_limit]
```

1. Create a New Folder,

    Create a new folder `stix_shifter/stix_translation/src/modules/wp_ithemes` for the `stix_translation` module,
    ```
    $ mkdir -p stix_shifter/stix_translation/src/modules/wp_ithemes
    ```

1. Create a Python Module for Translate

    To create the translate directory into a Python module, add a `__init__.py` file.
    ```
    $ cd stix_shifter/stix_translation/src/modules/wp_ithemes
    $ touch __init__.py
    ```

1. Add STIX to DataSource Mapping

    To map the STIX patterns to data source queries, you need to create a `json/from_stix_map.json` and a `json/to_stix_map.json` file.

    The format of the `from_stix_map.json` file is as follows,
    ```
    {
        "stix-object": {
            "fields": {
                "stix_object_property": ["DataSourceField", "DataSourceField"],
                "stix_object_property": ["DataSourceField"]
            }
        }
    }
    ```

    Create a new `json/from_stix_map.json` file,
    ```
    $ mkdir json
    $ vi json/from_stix_map.json
    ```

    and add the following mapping to the file,
    ```
    {
        "Id": {
        "fields": {
            "value": ["id"]
        }
        },
        "ParentId": {
        "fields": {
            "value": ["parent_id"]
        }
        },
        "Module": {
        "fields": {
            "value": ["module"]
        }
        },
        "Code": {
        "fields": {
            "value": ["code"]
        }
        },
        "Data": {
        "fields": {
            "value": ["data"]
        }
        },
        "Type": {
        "fields": {
            "value": ["type"]
        }
        },
        "Timestamp": {
        "fields": {
            "value": ["timestamp"]
        }
        },
        "InitTimestamp": {
        "fields": {
            "value": ["init_timestamp"]
        }
        },
        "MemoryCurrent": {
        "fields": {
            "value": ["memory_current"]
        }
        },
        "MemoryPeak": {
        "fields": {
            "value": ["memory_peak"]
        }
        },
        "Url": {
        "fields": {
            "value": ["url"]
        }
        },
        "BlogId": {
        "fields": {
            "value": ["blog_id"]
        }
        },
        "UserId": {
        "fields": {
            "value": ["user_id"]
        }
        },
        "RemoteIp": {
        "fields": {
            "value": ["remote_ip"]
        }
        }
    }
    ```

    The format of the `to_stix_map.json` file is as follows,
    ```
    {
        "DataSourceField": {
            "key": "stix-object.stix_object_property"
        },
        "DataSourceField": {
            "key": "x_custom_object.property",
            "cybox": false
        }
    }
    ```

    Create a new `json/to_stix_map.json` file,
    ```
    $ vi json/to_stix_map.json
    ```

    and add the following mapping to the file,
    ```
    {
        "id": {
        "key": "Id"
        },
        "parent_id": {
        "key": "ParentId"
        },
        "module": {
        "key": "Module"
        },
        "code": {
        "key": "Code"
        },
        "data": {
        "key": "Data"
        },
        "type": {
        "key": "Type"
        },
        "timestamp": {
        "key": "Timestamp"
        },
        "init_timestamp": {
        "key": "InitTimestamp"
        },
        "memory_current": {
        "key": "MemoryCurrent"
        },
        "Memomemory_peakryPeak": {
        "key": "MemoryPeak"
        },
        "url": {
        "key": "Url"
        },
        "blog_id": {
        "key": "BlogId"
        },
        "user_id": {
        "key": "UserId"
        },
        "remote_ip": {
        "key": "RemoteIp"
        }
    }
    ```

1. Add a Translator Class

    Create a new file `wp_ithemes_translator.py`,
    ```
    $ vi wp_ithemes_translator.py
    ```

    And add the following code,
    ```
    from ..base.base_translator import BaseTranslator
    from .stix_to_query import StixToQuery
    from ...json_to_stix.json_to_stix import JSONToStix
    from os import path

    class Translator(BaseTranslator):

        def __init__(self):
            basepath = path.dirname(__file__)
            filepath = path.abspath(
                path.join(basepath, "json", "to_stix_map.json"))
            self.mapping_filepath = filepath
            self.result_translator = JSONToStix(filepath)
            self.query_translator = StixToQuery()
    ```

    Copy the following files from the `dummy` module,
    ```
    $ cp ../dummy/data_mapping.py .
    $ cp ../dummy/query_constructor.py .
    $ cp ../dummy/stix_to_query.py .
    ```

1. Edit the Query Constructor,

    Edit the file `query_constructor.py` and scroll all the way to the bottom, replace the `translate_pattern` function by the following code,

    ```
    def translate_pattern(pattern: Pattern, data_model_mapping, options):
        
        query = QueryStringPatternTranslator(pattern, data_model_mapping).translated

        query = re.sub("START", "START ", query)
        query = re.sub("STOP", " STOP ", query)

        tableName = options['tableName']

        logMsg = "Convert STIX2 Pattern to data source query for table {}".format(tableName)
        logger.info(logMsg)

        return ["SELECT * FROM {} WHERE {}".format(tableName, query)]
    ```

1. Register the translation module,

    Edit the file `~/stix_shifter/stix_translation/stix_translation.py`, and register the `wp_ithemes` to the `TRANSLATION_MODULES` array on line 15,
    ```
    TRANSLATION_MODULES = ['qradar', 'qradar:events:flows', 'dummy', 'car', 'cim', 'splunk', 'elastic', 'bigfix', 'csa', 'csa:at:nf', 'aws_security_hub', 'carbonblack', 'elastic_ecs', 'proxy', 'stix_bundle', 'msatp', 'security_advisor', 'guardium', 'aws_cloud_watch_logs', 'aws_cloud_watch_logs:guardduty:vpcflow', 'azure_sentinel', 'wp_ithemes']
    ```

    Add the line `include stix_shifter/stix_translation/src/modules/wp_ithemes/json/*.json` to the `~/MANIFEST.in` file.

1. Install the Dependencies,

    Edit the file `requirements.txt` and uncomment line 12,

    ```
    git+git://github.com/oasis-open/cti-pattern-matcher.git@b265862971eb63c04a8a054a2adb13860edf7846#egg=stix2-matcher #uncomment when running locally
    ```

    Run the `pip3 install` command,
    ```
    pip3 install -r requirements-dev.txt
    ```

1. Test the Translate Module,

    For the wp_ithemes connector, to translate a simple query from stix to the native query language of the data source, i.e. sql:
    ```
    $ python3 main.py translate wp_ithemes query "{}" "[Module:value = 'brute_force']" '{"tableName": "wp_itsec_logs"}'
    {'queries': ["SELECT * FROM wp_itsec_logs WHERE module = 'brute_force'"]}
    ```

    The translated native query can be used as an input parameter in the transmit command.