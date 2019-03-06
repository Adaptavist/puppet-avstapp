# Avstapp Module
[![Build Status](https://travis-ci.org/Adaptavist/puppet-avstapp.svg?branch=master)](https://travis-ci.org/Adaptavist/puppet-avstapp)

## Overview

The **Avstapp** module handles the following aspects of configuring Atlassian applications.

* Creates default folder structure and makes sure it belongs to avstapp::hosting_user (needs to be created before, see baseusers module)
* Downloads tarball from url or uses one provided
* Extracts tarball into specifified location
* Avstapp application avstapp.conf.sh setup
* Installs package that will configure application
* Configures and starts avst-wizard that will pass the wizard of the atlassian product

Make sure you register repository(puppet-packages_repos module) where avst-app and avst-wizard packages are located.

## Configuration

The Avstapp module is entirely configured in [Hiera](#hiera). Examples of Hiera configuration will be given in [YAML](#yaml), Hiera's primary backend.

The following section will present how to configure each of the module aspects
presented in the section above.

### Application server configuration

Here is a complete YAML snippet for configuring a Crowd server which will be discussed in the following paragraphs:

    # Set users to be used for avstapp instalation
    avstapp::hosting_user: 'hosting'
    avstapp::hosting_group: 'hosting'
    avstapp::java_module_name: 'oracle_java'

    hosts:
      'avst-stg1':
        role: avstapp
        avstapp::conf:
          'crowd-stg1':
            version: '2.6.7'
            context_path: '/'
            application_type: crowd
            custom_service_provider: 'upstart'
            tarball_location_url: 'http://www.atlassian.com/software/crowd/downloads/binary/atlassian-crowd-2.6.7.tar.gz'
            # tarball_location_file: '/etc/puppet/atlassian-crowd-2.6.7.tar.gz'
            connectors:
              - scheme:      'http'
                http_port:   8080
                proxy_name:  "avst-stg1.vagrant"
                proxy_port:  80
              - scheme:      'https'
                http_port:   8081
                proxy_name:  "avst-stg1.vagrant"
                proxy_port:  443
            base_url: "http://avst-stg1.vagrant"
            avst_wizard_properties:
              admin_full_name: "Admin admin"
              admin_email: "admin@admin.com"
              admin_user: "admin"
              admin_pass: "admin"
              database_url: "localhost"
              database_name: "jira"
              database_user: "jirauser"
              database_pass: "jirapass"
              license: |
                8AcSeI+DAsAhRJhI3dyXyrgCc+/LF9LiEqV
                WY+vwIUBIu7WdW2Tqt1OlEe8dAjn4F3vlk=X02dd
              instance_name: "My new Jira"
            java_flags:              
                JVM_MINIMUM_MEMORY:  '512m'
                JVM_MAXIMUM_MEMORY: '1024m'
                JVN_MAX_PERM_SIZE: '256m'
                JAVA_OPTS: '-XOOME=blah'
            limits:
                SERVICE_MAX_OPEN_FILES: '8192'

The application configuration key points to a hash, which will be called the application 
configuration hash hereafter. This hash has the following simple (non-collection) properties.

* `shutport` the tomcat shutdown port for the application.
* `version`  the version of Atlassian application to be installed
* `application_type` type of Atlassian app. e.g. crowd
* `tarball_location_url` in case we can not provide tarball use this option to download it from url
* `tarball_location_file` takes precedence to url, specifies tarball location on local machine
* `context_path` context path for server.xml
* `custom_service_provider` the service manager used by the system (upstart or systemd) if not set upstart will be used for everything except RHEL/CentOS >= 7
* `base_url` base url where the app will be available, defaults to "http://${::fqdn}${context_path}",
* `avst_wizard` if avst_wizard should run, defaults to true

The application configuration hash has the following collection (array/hash) properties.

* `connectors` configuration for tomcat connectors
* `db` database and user configuration for the database management system, required only for Fisheye
* `java_flags` flags passed to startup.conf for java setup
* `crowd_sso` crowd sso options
* `avst_wizard_properties` properties for avst_wizard, depends on the application_type, see avst-wizard-templates for details, or avst-wizard for all configuration options
* `class_dependencies` Puppet classes to require are applied first, e.g. ensure build dependencies and other software is installed before the Bamboo Agent.
* `limits` system limits, currently only supports setting the maximum number of open files (SERVICE_MAX_OPEN_FILES).

These collection properties will be described individually in following sections.

### Database configuration

This part of the avstapp configuration hash is for configuring client side database settings. Configuration is required only for Fisheye as for the rest avst-wizard will initiate databases population.

As mentioned above the database configuration in the `db` key of the application configuration hash.
The database configuration is expressed as a hash with three keys.

Example: All following fields are required!
db:

    DB_PORT:     '3306'
    DB_NAME:     'fisheye_db'
    DB_TYPE:     'mysql'
    DB_DRIVER:   'com.mysql.jdbc.Driver'
    DB_JDBC_URL: 'jdbc:mysql://localhost/fisheye_db?useUnicode=true&amp;characterEncoding=UTF8&amp;sessionVariables=storage_engine=InnoDB'
    DB_MAX_POOL_SIZE: '15'
    DB_USERNAME: 'fisheyeuser'
    DB_PASSWORD: 'fisheyepassword'
    DB_VALIDATION_QUERY: 'select 1'

### Connectors

The tomcat connector configuration is specified in the value of the 'connectors' key of the application
configuration hash. This key points to an array of hashes for each connector. These hashes will be called connector hashes.
Each connector hash has the following properties:

* `scheme`      The URL scheme to use, either http or https
* `http_port`   The port that tomcat will use for this connector
* `proxy_name`  The domain name of the apache vhost that will proxy this connector
* `proxy_port`  The port of the apache vhost that will proxy this connector

### Java flags
Pass following available params as hash 
java_flags:

    JVM_MINIMUM_MEMORY:  '512m'
    JVM_MAXIMUM_MEMORY: '1024m'
    JIRA_MAX_PERM_SIZE: '256m'
    JAVA_OPTS: '-XOOME=blah'

### Syslog
A custom syslog filter can be enabled in order to capture avst-app related syslog traffic, systems running systemd (RHEL/CentOS >= 7) log all console output to syslog.  Currently only creating filters for **rsyslog** is supported

A rsyslog filter is created by default for RHEL/CentOS >= 7 systems to capture anything with an applicaiotn name of "avst-app" and log it into /var/log/avst-app.log instead of the default localtion (/var/log/messages), for any other systems no filter is created unless specifically enabled.  If a filter is created then logrotate is also configured by default to rotate this log every week and keep 4 compressed historic log files. 

The following configuration options are avaliable:

* `avstapp::syslog::enable_syslog` - flag to determine of syslog filters should be used, defaults to **undef**, when not defined the system will only enable the filter for RHEL/CentOS >= 7 systems.
* `avstapp::syslog::syslog_implementation` - the syslog implementation used, defaults to **rsyslog** (the only current supported implementation)
* `avstapp::syslog::syslog_config_file` - the location of the syslog filter file, defaults to **/etc/rsyslog.d/avst-app.conf**
* `avstapp::syslog::syslog_destination` - the syslog destination, defaults to **/var/log/avst-app.log**
* `avstapp::syslog::syslog_filter_value` - the program name to filter on, defaults to **avst-app**
* `avstapp::syslog::enable_logrotate` - flag to determin if logrotate should be used, defaults to **true**  ignored if we are dropping the log messages (with destination ~)
* `avstapp::syslog::logrotate_config_file` - the location of the logrotate config file for the syslog log, defaults to **/etc/logrotate.d/avst-app**
* `avstapp::syslog::logrotate_rotate_period` - the log rotate period, defaults to **weekly**
* `avstapp::syslog::logrotate_keep` - now many logs to keep, defaults to **4**
* `avstapp::syslog::logrorate_compress` - flag to determine if the historic logs should be compressed, defaults to **true**
## Dependencies
The module depends on the following modules:

* Limits
* Java
* packages_repos
* oracle_java

## References

* [**Hiera**](id:hiera) https://github.com/puppetlabs/hiera
* [**YAML**](id:yaml) http://yaml.org/spec/1.1/
