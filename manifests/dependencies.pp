class avstapp::dependencies(
    $soft_nofile       = '1024',
    $hard_nofile       = '8192',
    $java_module_name  = 'oracle_java',
) {


    # Installs Oracle Java
    include packages_repos
    include $java_module_name

    case $::osfamily {
        'RedHat': {
            package { ['apr-util', 'neon']:
                ensure => installed
            }
            package { 'augeas':
                ensure => installed,
            }
        }
        'Debian': {
            package { 'libaugeas-ruby':
                ensure => installed,
            }
        }
        default: { }
    }

    # setup filehandle limits
    limits::fragment {
        '*/soft/nofile':
            value => $soft_nofile
        ;
        '*/hard/nofile':
            value => $hard_nofile
        ;
    }
}
