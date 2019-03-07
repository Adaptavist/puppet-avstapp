#
# base class for avstapp containers
#
# conf - default configuration of instance
# 
# 
# params: 
#  
# setup in hiera specific to host 
# 'hostname':
#    avstapp::conf:
#      'dell-jira-stg':
#        tarball_location_url: <http>
#        tarball_location_file: <path>
# 
#      'dell-conf-stg':
#        tarball_location_url: <http>
#        tarball_location_file: <path>
# 
class avstapp(
    $base_directory    = '/opt',
    $share_directory   = '/usr/share/avst-app',
    $hosting_user      = 'root',
    $hosting_group     = 'root',
    $soft_nofile       = '1024',
    $hard_nofile       = '8192',
    $java_module_name  = 'oracle_java',
    $conf = {},
){


    class { 'avstapp::syslog': } -> class { 'avstapp::dependencies':
        soft_nofile      => $soft_nofile,
        hard_nofile      => $hard_nofile,
        java_module_name => $java_module_name
    } -> Class['avstapp']

    if $::host != undef {
        # merge custom configuration with defaults
        $custom_conf = $host["${name}::conf"]
        $config = $custom_conf ? {
            undef => $conf,
            default => merge($conf, $custom_conf),
        }
    } else {
        $config = $conf
    }

    if ! defined( File[$base_directory] ) {
        file { $base_directory:
            ensure => 'directory',
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }

    # make sure that basedir exists
    file { $share_directory :
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    #make sure avst_app file exists and holds basedir and baseuser 
    file { '/etc/default/avst-app' :
        ensure  => file,
        content => template("${module_name}/etc/default/avst-app.erb"),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    # create and configure instances required
    create_resources('avstapp::instance', $config)
}
