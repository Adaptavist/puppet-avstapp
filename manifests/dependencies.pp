class avstapp::dependencies {

    # Installs Oracle Java
    include packages_repos
    include oracle_java

    case $::osfamily {
        RedHat: {
            package { ['apr-util', 'neon']:
                ensure => installed
            }
            package { 'augeas':
                ensure => installed,
            }
        }
        Debian: {
            package { 'libaugeas-ruby':
                ensure => installed,
            }
        }
        default: { }
    }

    # setup filehandle limits
    limits::fragment {
        '*/soft/nofile':
            value => '1024'
        ;
        '*/hard/nofile':
            value => '8192'
        ;
    }
}
