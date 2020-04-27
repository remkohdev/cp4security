# Lab01 - Developer Environment Setup

## Prerequisites

The [Developer Guide](https://github.com/opencybersecurityalliance/stix-shifter/blob/master/adapter-guide/develop-stix-adapter.md) lists the prerequisites. 

Check the Python version (dd. version 3.6) and understand the following concepts:
- Observable objects. See [STIX Version 2.0. Part 4: Cyber Observable Objects](http://docs.oasis-open.org/cti/stix/v2.0/stix-v2.0-part4-cyber-observable-objects.html)
- Stix patterning. See [STIX Version 2.0. Part 5: STIX Patterning](https://docs.oasis-open.org/cti/stix/v2.0/stix-v2.0-part5-stix-patterning.html)

## STIX_SHIFTER Connectors

### Setup

Get the source code for stix-shifter. This version supports stix-shifter branch `v2-master`.

```
$ git clone -b v2-master https://github.com/remkohdev/stix-shifter.git
$ cd stix-shifter
```

Setup the environment requirements, using `pyenv` and `pyenv-virtualenv` to activate the virtual environment with python version `3.7.0`. Note that stix-shifter requires Python >= 3.6. At the time of writing this tutorial (April 2020) Python 3.8 failed because of Python wheels and pyarraw version conflicts.

```
$ brew install pyenv
$ brew install pyenv-virtualenv
$ eval "$(pyenv init -)"
$ eval "$(pyenv virtualenv-init -)"
$ pyenv install --list | grep " 3\.[678]"
$ pyenv install -v 3.7.0
$ pyenv versions
  * system
    3.7.0
    venv-3.7.0
$ pyenv virtualenv 3.7.0 venv-3.7.0
$ pyenv virtualenvs
    3.7.0/envs/venv-3.7.0 (created from /Users/user1/.pyenv/versions/3.7.0)
    venv-3.7.0 (created from /Users/user1/.pyenv/versions/3.7.0)
$ pyenv activate venv-3.7.0
    pyenv-virtualenv: prompt changing will be removed from future release. configure `export PYENV_VIRTUALENV_DISABLE_PROMPT=1' to simulate the behavior.
$ python3 -V
    Python 3.7.0
```

### Dependencies 

On your localhost, the requirements-dev.txt defines the dependencies,

Install all dependencies,
```
$ touch requirements.txt
$ python install -r requirements-dev.txt
```

One of the stix-shifter dependencies is not published in pypi. Install `stix2-matcher`,

```
pip install git+git://github.com/oasis-open/cti-pattern-matcher.git@b265862971eb63c04a8a054a2adb13860edf7846#egg=stix2-matcher
```

You might get an incompatible version warning,
``
ERROR: stix-shifter 2.10.1 has requirement antlr4-python3-runtime==4.7, but you'll have antlr4-python3-runtime 4.8 which is incompatible.
```

To fix it, e.g. uninstall the existing version and install the required version instead,
```
pip uninstall antlr4-python3-runtime
pip uninstall stix2-patterns
pip install "antlr4-python3-runtime==4.7"
pip install "stix2-patterns==1.2.0"
```

Install stix_shifter,
```
$ pip install stix-shifter
```

## MySQL

```
docker run -d --name wp-mysql -v mysql:/var/lib/mysql -p 6603:3306 -e MYSQL_ROOT_PASSWORD=Passw0rd -e MYSQL_DATABASE=wp_itsec_logs mysql:latest
$ docker inspect wp-mysql | grep IPAddress
$ docker run --name phpmyadmin -d --link wp-mysql:db -p 8080:80 phpmyadmin/phpmyadmin
```

Open phpmyadmin at http://localhost:8080/ and log in with `root:Passw0rd`,

If the database `wp_ithemes_testdb` does not exist or is empty, run the SQL files `szirinedb_wp_itsec_logs_1.sql` to `szirinedb_wp_itsec_logs_5.sql` in the `mysql` folder.