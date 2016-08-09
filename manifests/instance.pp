# Sets up default folder structure and creates config file for avstapp application
#
# Application type 'bamboo_agent' requires ONLY the $bamboo_server_url parameter and optionally $capabilities.
#
#
# Example usage:
# avstapp::hosting_user: 'hosting'
# avstapp::hosting_group: 'hosting'
#
# hosts:
#     'jira-stg1':
#         role: avstapp
#         avstapp::conf:
#           'jira-crowd-stg1':
#             version: '2.6.7'
#             context_path: '/'
#             application_type: crowd
#             custom_service_provider: 'upstart'
#             tarball_location_url: 'http://www.atlassian.com/software/crowd/downloads/binary/atlassian-crowd-2.6.7.tar.gz'
#             # tarball_location_file: '/etc/puppet/atlassian-crowd-2.6.7.tar.gz'
#             connectors:
#               - scheme:      'http'
#                 http_port:   8080
#                 proxy_name:  "jira-stg1.jira.vagrant"
#                 proxy_port:  80
#               - scheme:      'https'
#                 http_port:   8081
#                 proxy_name:  "jira-stg1.jira.vagrant"
#                 proxy_port:  443
#             db:
#               DB_PORT:     '3306'
#               DB_NAME:     'jira_db'
#               DB_TYPE:     'mysql'
#               DB_DRIVER:   'com.mysql.jdbc.Driver'
#               DB_JDBC_URL: 'jdbc:mysql://localhost/jira_db?useUnicode=true&amp;characterEncoding=UTF8&amp;sessionVariables=storage_engine=InnoDB'
#               DB_MAX_POOL_SIZE: '15'
#               DB_USERNAME: 'jirauser'
#               DB_PASSWORD: 'jirapassword'
#               DB_VALIDATION_QUERY: 'select 1'
#             java_flags:
#                 JVM_MINIMUM_MEMORY:  '512m'
#                 JVM_MAXIMUM_MEMORY: '1024m'
#                 JIRA_MAX_PERM_SIZE: '256m'
#                 JAVA_OPTS: '-XOOME=blah'
#              drivers:
#                location_url:
#                  - url_to_driver_to_download_and_include
#                location_path:
#                  - path_to_driver_to_include
#              custom: #additional properties to be exported
#                CROWD_SERVER_URL: 'url'
#                CROWD_APP_LOGIN_URL: 'url'
#                CROWD_APP_PASSWORD: 'pass'
#
# To restore system from backup passed following parameters to instance hash:
#             restore: true
#             #path to BASE_DIR that contains INSTANCE_DIR
#             restore_system_path: '/etc/puppet'
#             restore_databases:
#               - backup_database_resource: '/etc/puppet/confluence.sql.gz'
#                 backup_database_name: 'confluence'
#                 backup_database_user: 'jirauser'
#                 backup_database_password: 'jirapass'
#
# See README for more details.
#
define avstapp::instance(
    $application_type             = 'jira',
    $version                      = undef,
    $tarball_location_url         = undef,
    $tarball_location_file        = undef,
    $bamboo_server_url            = undef,
    $shutport                     = '8008',
    $context_path                 = '/',
    $connectors                   = [],
    $restore                      = undef,
    $restore_system_path          = undef,
    $restore_databases            = [],
    $custom_downoad_system_backup = undef,
    $java_flags                   = {},
    $db                           = {},
    $crowd_sso                    = {},
    $drivers                      = {},
    $custom                       = {},
    $capabilities                 = {},
    $work_dir                     = '/tmp/avstapp_resources',
    $clean_tarballs               = true, #in caes there are multiple instances of the same app type disable this
    $license                      = undef,
    $serverID                     = undef,
    $early_access                 = false,
    $clustered                    = undef, # set to 1 if clustered
    $shared_dir                   = undef, # must be set if clustered
    $is_master                    = undef, # set to 1 in case instance is master, slave set to undef or 0
    $manual_service_script        = false,
    $manual_upstart_script        = false, # backwards compatibility only, will be removed soon, use manual_service_script instead
    $class_dependencies           = [],
    $custom_service_provider      = undef,
    $avst_wizard                  = true,
    $package_source_repo          = 'https://rubygems.org',
    $avst_wizard_command_prefix   = 'bash --login -c', #ensures that rvm is loaded so ruby and installed gems are available
    $base_url                     = "http://${::fqdn}${context_path}",
    $avst_wizard_properties       = {},
    $is_mirror                    = false,
    $limits                       = { 'SERVICE_MAX_OPEN_FILES' => '8196'},
) {


    unless empty($class_dependencies) {
        require $class_dependencies
    }
    include avstapp

    notify { $name :
        message => "Installing instance: ${name}",
    }

    $instance_dir = "${avstapp::base_directory}/${name}"
    notify { $instance_dir :
        message => "Creating folder: ${instance_dir}",
    }
    # Create base directory
    file { $instance_dir :
        ensure  => directory,
        owner   => $avstapp::hosting_user,
        group   => $avstapp::hosting_group,
        require => [ User[$avstapp::hosting_user], Group[$avstapp::hosting_group]],
    }

    if (!str2bool($is_mirror)) {

        $is_bamboo_agent = ( $application_type == 'bamboo_agent' )

        if ( $is_bamboo_agent ) {
            unless ( $bamboo_server_url ) {
                fail('You must provide a Bamboo server URL for bamboo-agent application type')
            }
            $product_source = $bamboo_server_url
        } elsif ( $tarball_location_file ) {
            $product_source = $tarball_location_file
        } elsif ( $tarball_location_url ) {
            # in case url provided for product tar download it and place to /tmp
            $tarball_location_splitted = split($tarball_location_url, '/')
            $tarball_file_name = $tarball_location_splitted[-1]
            # ensure folder in workdir for installation tarball is present
            if (!defined(File[$work_dir])) {
                file { $work_dir :
                    ensure  => directory,
                    owner   => $avstapp::hosting_user,
                    group   => $avstapp::hosting_group,
                    require => [ User[$avstapp::hosting_user], Group[$avstapp::hosting_group]],
                }
            }
            if (str2bool($clean_tarballs)){
                # clean all other tarballs in the folder
                exec { "remove_tarballs_from_work_dir_${name}":
                        command   => "rm `find . -type f | grep -v '${tarball_file_name}' | grep '${application_type}'`",
                        logoutput => on_failure,
                        cwd       => $work_dir,
                        onlyif    => "find . -type f | grep -v '${tarball_file_name}' | grep '${application_type}'",
                        require   => [Exec["install_application_with_avstapp_${name}"] , File[$work_dir] ] ,
                }
            }

            $product_source = "${$work_dir}/${tarball_file_name}"
            if ( !defined(Avstapp::Download_tar_file[$tarball_location_url]) ) {
                avstapp::download_tar_file{ $tarball_location_url :
                    work_dir  => $work_dir,
                    file_path => $product_source,
                    before    => File["${instance_dir}/avst-app.cfg.sh"],
                }
            }
        } else {
            fail('You must provide tarball_location_file or tarball_location_url or bamboo_server_url')
        }

        # in case url provided for drivers download it
        if ( $drivers ) {
            if ( $drivers["location_url"] ) {
                if ( !defined(Avstapp::Download_tar_file[$drivers['location_url']]) ) {
                    avstapp::download_tar_file { $drivers["location_url"] :
                        work_dir => $work_dir,
                        before   => File["${instance_dir}/avst-app.cfg.sh"],
                    }
                }
            }
        }

        # Prepare config for avstapp application
        file { "${instance_dir}/avst-app.cfg.sh" :
            ensure  => file,
            content => template("${module_name}/avst-app.cfg.sh.erb"),
            owner   => $avstapp::hosting_user,
            group   => $avstapp::hosting_group,
            mode    => '0644',
            require => File[$instance_dir],
            notify  => Exec["modify_application_with_avstapp_${name}"],
        }

        # Prepare Bamboo Agent capabilities
        if ( $is_bamboo_agent ) {
            file { "${instance_dir}/bamboo-capabilities.properties":
                ensure  => file,
                content => template("${module_name}/bamboo-capabilities.properties.erb"),
                owner   => $avstapp::hosting_user,
                group   => $avstapp::hosting_group,
                mode    => '0644',
                before  => Exec["modify_application_with_avstapp_${name}"]
            }
        }

        unless ( $is_bamboo_agent ) {
            $parsed_version = parse_version($application_type, $product_source, str2bool($early_access))
            if ( $version and $parsed_version != $version ) {
                notify { $version :
                    message => "Found ${version} != ${parsed_version}",
                }
                fail("version provided (${version}) does not match version of tarball (${parsed_version})")
            }
        }

        # in case of clustered confluence
        if ( $application_type == 'confluence' and $clustered == '1' ) {
            # if it is slave node, we assume master is already running and is configured so we create link to confluence.cfg.xml to share dir
            if ( !$is_master or $is_master == '0' ) {
                if ( $shared_dir ){
                    exec { 'create_simlink_for_confluence_config_file' :
                        command   => "rm -f ${instance_dir}/home/confluence.cfg.xml; ln -s ${shared_dir}/confluence.cfg.xml ${instance_dir}/home/confluence.cfg.xml; chown -h ${avstapp::hosting_user}:${avstapp::hosting_group} ${instance_dir}/home/confluence.cfg.xml",
                        logoutput => on_failure,
                        onlyif    => "test -f ${shared_dir}/confluence.cfg.xml",
                        require   => Exec["install_application_with_avstapp_${name}"],
                        before    => Exec["modify_application_with_avstapp_${name}"],
                    }
                } else {
                    fail('Instance clustered confluence and is not master, please provide shared directory where confluence.cfg.xml is located.')
                }
            }
        }

        # AvstApp has bamboo_agent, but the package is called bamboo-agent
        $package_name = $application_type ? {
            'bamboo_agent'    => 'avst-app-bamboo-agent',
            $application_type => "avst-app-${application_type}"
        }

        # get avst-app from apt repo
        if ( !defined(Package[$package_name]) ) {
            package { $package_name :
                ensure  => 'installed',
                require => File["${instance_dir}/avst-app.cfg.sh"],
            }
        }
        if ( $restore ) {
            # provide source for restoring
            # run custom command to get backed up folders on the system
            $run_custom_downoad_system_backup = $custom_downoad_system_backup ? {
                undef   => "echo 'download backup folder here...'",
                default => $custom_downoad_system_backup,
            }

            exec { "download_system_backup_to_server_${name}" :
                command   => $run_custom_downoad_system_backup,
                logoutput => on_failure,
                timeout   => 0,
                require   => [File["${instance_dir}/avst-app.cfg.sh"], Package[$package_name]],
            }

            # run avst-app restore
            exec { "restore_application_with_avstapp_${name}" :
                command   => "avst-app --debug ${name} restore",
                logoutput => on_failure,
                cwd       => $instance_dir,
                timeout   => 0,
                require   => Exec["download_system_backup_to_server_${name}"]
            }

            # Prepare config for avstapp application
            file { "restore_${instance_dir}/avst-app.cfg.sh_tmp_as_it_may_be_overwritten_by_restore" :
                ensure  => file,
                path    => "${instance_dir}/avst-app.cfg.sh_tmp",
                content => template("${module_name}/avst-app.cfg.sh.erb"),
                owner   => $avstapp::hosting_user,
                group   => $avstapp::hosting_group,
                mode    => '0644',
                require => [File[$instance_dir], Exec["restore_application_with_avstapp_${name}"]],
            }

            # Prepare config for avstapp application
            exec { "rename_${instance_dir}/avst-app.cfg.sh_tmp_as_it_is_not_possible_to_create_two_file_resources_for_same_file" :
                command   => "mv ${instance_dir}/avst-app.cfg.sh_tmp ${instance_dir}/avst-app.cfg.sh",
                logoutput => on_failure,
                cwd       => $instance_dir,
                timeout   => 0,
                require   => [File["restore_${instance_dir}/avst-app.cfg.sh_tmp_as_it_may_be_overwritten_by_restore"]],
                notify    => Exec["modify_application_with_avstapp_${name}"],
            }

            # run avst-app modify
            exec { "modify_application_with_avstapp_${name}" :
                command     => "avst-app --debug ${name} modify",
                logoutput   => on_failure,
                cwd         => $instance_dir,
                refreshonly => true,
                onlyif      => [ "test -f ${instance_dir}/.state" ],
                require     => [Exec["rename_${instance_dir}/avst-app.cfg.sh_tmp_as_it_is_not_possible_to_create_two_file_resources_for_same_file"]],
            }
        } else {
            # in case application is already installed manually
            exec { "prepare_application_with_avstapp_${name}" :
                command   => "avst-app --debug ${name} prepare",
                logoutput => on_failure,
                cwd       => $instance_dir,
                onlyif    => [ "test ! -f ${instance_dir}/.state", "test -d ${instance_dir}/home", "test -d ${instance_dir}/install" ],
                require   => [File["${instance_dir}/avst-app.cfg.sh"], Package[$package_name]],
            }

            # run avst-app install with tarball passed
            exec { "install_application_with_avstapp_${name}" :
                command   => "avst-app --debug ${name} install ${product_source}",
                logoutput => on_failure,
                onlyif    => [ "test ! -f ${instance_dir}/.state", "test ! -d ${instance_dir}/home", "test ! -d ${instance_dir}/install" ],
                require   => [File["${instance_dir}/avst-app.cfg.sh"], Class['oracle_java'], Package[$package_name]],
            }

            # run avst-app modify
            exec { "modify_application_with_avstapp_${name}" :
                command     => "avst-app --debug ${name} modify",
                logoutput   => on_failure,
                cwd         => $instance_dir,
                refreshonly => true,
                require     => [Exec["install_application_with_avstapp_${name}"], Exec["prepare_application_with_avstapp_${name}"]],
            }
        }

        # install service via avst-app
        exec { "install_service_for_application_with_avstapp_${name}" :
            command   => "avst-app --debug ${name} install-service",
            logoutput => on_failure,
            cwd       => $instance_dir,
            onlyif    => 'grep "modified" .state',
            require   => Exec["modify_application_with_avstapp_${name}"]
        }

        unless ( $is_bamboo_agent ){
            # if Service is defined so manual_service_script is false
            if ( str2bool($manual_service_script) or str2bool($manual_upstart_script) ) {
                $upgrade_deps = Exec["install_service_for_application_with_avstapp_${name}"]
            } else {
                if ( str2bool($avst_wizard) ){
                    $upgrade_deps = Exec["complete_service_instalation_with_avst_wizard_${name}"]
                } else {
                    $upgrade_deps = Service[$name]
                }
            }

            exec { "upgrade_application_with_avstapp_${name}" :
                command   => "avst-app --debug ${name} upgrade ${product_source}",
                logoutput => on_failure,
                cwd       => $instance_dir,
                unless    => [ "grep ${parsed_version} .version", "test ! -f ${instance_dir}/.state" ],
                require   => $upgrade_deps
            }
        }

        # work out if we should be using systemd or upstart
        # currently RHEL/CentOS >= 7 are set to systemd and everything else to upstart
        # unless a custom provider has been passed in
        if ( $custom_service_provider != undef ) {
            $service_provider = $custom_service_provider
        }
        elsif ( $::operatingsystemmajrelease >= 7 ) and ( $::osfamily == 'RedHat' ) {
            $service_provider = 'systemd'
        }
        else {
            $service_provider = 'upstart'
        }

        unless ( str2bool($manual_service_script) or str2bool($manual_upstart_script) ) {
            # start service
            service { $name :
                ensure    => running,
                subscribe => Exec["modify_application_with_avstapp_${name}"],
                require   => Exec["install_service_for_application_with_avstapp_${name}"],
                provider  => $service_provider,
            }

            # avst-wizard
            if ( str2bool($avst_wizard) ){

                if ( !defined(Package['avst-wizard']) ) {
                    package {
                        'avst-wizard':
                            ensure   => installed,
                            provider => gem,
                            source   => $package_source_repo,
                    }
                }

                # Prepare config for avst-wizard application
                file { "${instance_dir}/avst-wizard.yaml" :
                    ensure  => file,
                    content => template("${module_name}/avst-wizard-templates/avst-wizard-${application_type}.yaml.erb"),
                    owner   => $avstapp::hosting_user,
                    group   => $avstapp::hosting_group,
                    mode    => '0644',
                    require => File[$instance_dir],
                }


                if defined(Class['apache']) {
                    $wizard_deps = [ File["${instance_dir}/avst-wizard.yaml"], Service[$name], Service[$::apache::service_name] ]
                } else {
                    $wizard_deps = [ File["${instance_dir}/avst-wizard.yaml"], Service[$name] ]
                }


                # # pass wizard with avst-wizard
                exec { "complete_service_instalation_with_avst_wizard_${name}" :
                    command   => "${avst_wizard_command_prefix} 'avst-wizard --custom_config ${instance_dir}/avst-wizard.yaml --product_type ${application_type} --base_url ${base_url} --version ${version} >> /var/log/avst_wizard.log' ",
                    logoutput => on_failure,
                    cwd       => $instance_dir,
                    timeout   => 3600,
                    require   => $wizard_deps
                }

            }
        }
    } else {
        # Prepare config for avstapp application
        file { "${instance_dir}/avst-app.cfg.sh" :
            ensure  => file,
            content => template("${module_name}/avst-app.cfg.sh.erb"),
            owner   => $avstapp::hosting_user,
            group   => $avstapp::hosting_group,
            mode    => '0644',
            require => File[$instance_dir],
        }
        # Prepare config for avstapp application
        file { "${instance_dir}/.state" :
            ensure  => file,
            content => 'modified',
            owner   => $avstapp::hosting_user,
            group   => $avstapp::hosting_group,
            mode    => '0644',
            require => File[$instance_dir],
        }
        # get avst-app from apt repo
        if ( !defined(Package["avst-app-${application_type}"]) ) {
            package { "avst-app-${application_type}" :
                ensure  => 'installed',
                require => [File["${instance_dir}/avst-app.cfg.sh"], File["${instance_dir}/.state"]]
            }
        }

        # install service via avst-app
        exec { "install_service_for_application_with_avstapp_${name}" :
            command   => "avst-app --debug ${name} install-service",
            logoutput => on_failure,
            cwd       => $instance_dir,
            require   => [File["${instance_dir}/avst-app.cfg.sh"], File["${instance_dir}/.state"], Package["avst-app-${application_type}"]],
        }

    }
}
