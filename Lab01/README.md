# Lab01 - Developer Environment Setup

## STIX_SHIFTER Connectors

Setup the environment requirements, using `pyenv` and `pyenv-virtualenv`:

```
$ brew install pyenv
$ brew install pyenv-virtualenv
$ eval "$(pyenv init -)"
$ eval "$(pyenv virtualenv-init -)"
$ pyenv install --list | grep " 3\.[678]"
$ pyenv install -v 3.8.2
$ pyenv versions
$ pyenv virtualenv 3.8.2 venv-3.8.2
$ pyenv virtualenvs
$ pyenv activate venv-3.8.2
$ python -V
Python 3.8.2
```

On your localhost, edit the requirements.txt and uncomment the `git+git://github.com/oasis-open/cti-pattern-matcher.git@v0.1.0#egg=stix2-matcher` 

Install all dependencies,
```
$ python install -r requirements.txt
```

Install stix_shifter,
```
$ pip install stix-shifter
```

## CarbonDesignSystem Widgets

