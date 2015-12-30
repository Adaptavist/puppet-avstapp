class avstapp::syslog(
    $enable_syslog           = undef,
    $syslog_implementation   = 'rsyslog',
    $syslog_config_file      = '/etc/rsyslog.d/avst-app.conf',
    $syslog_destination      = '/var/log/avst-app.log',
    $syslog_filter_value     = 'avst-app',
    $enable_logrotate        = true,
    $logrotate_config_file   = '/etc/logrotate.d/avst-app',
    $logrotate_rotate_period = 'weekly',
    $logrotate_keep          = '4',
    $logrorate_compress      = true,
){

    # unless otherwise specified only enable syslog filters for RHEL/CentOS > 7 or Fedora > 18 (as these systems use systemd)
    if ( $enable_syslog == undef or $enable_syslog == 'undef' ) {
        case $::osfamily {
            'RedHat': {
                if (versioncmp($::operatingsystemrelease,'7') >= 0 and $::operatingsystem != 'Fedora') or  (versioncmp($::operatingsystemrelease,'18') >= 0 and $::operatingsystem == 'Fedora') {
                    $real_enable_syslog = true
                }
                else {
                    $real_enable_syslog = false
                }
            }
            default: {
                $real_enable_syslog = false
            }
        }
    }
    else {
        $real_enable_syslog = $enable_syslog
    }


    case $syslog_implementation {
        'rsyslog': {
            if (!defined(Service['rsyslog'])) {
                service { 'rsyslog':
                    ensure  => 'running',
                }
            }
            if ( str2bool($real_enable_syslog) ) {
                $rsyslog_filter="\$programname == '${syslog_filter_value}'"
                file { $syslog_config_file:
                    ensure  => file,
                    content => template("${module_name}/syslog/rsyslog-template.erb"),
                    owner   => 'root',
                    group   => 'root',
                    mode    => '0644',
                    notify  => Service['rsyslog'],
                }
                if ( str2bool($enable_logrotate)  and $syslog_destination != '~' and $syslog_destination != 'stop'){
                    file { $logrotate_config_file:
                        ensure  => file,
                        content => template("${module_name}/logrotate/avst-app.erb"),
                        owner   => 'root',
                        group   => 'root',
                        mode    => '0644',
                        require => File[$syslog_config_file],
                    }
                }
                else {
                    file { $logrotate_config_file:
                        ensure  => 'absent',
                    }
                }
            }
            else {
                file { $syslog_config_file:
                    ensure => 'absent',
                    notify => Service['rsyslog'],
                }
                file { $logrotate_config_file:
                    ensure => 'absent',
                }
            }
        }
        default: {
            fail("avst-app::syslog: Unsupported syslog implementation: ${::syslog_implementation}")
        }
    }

}
