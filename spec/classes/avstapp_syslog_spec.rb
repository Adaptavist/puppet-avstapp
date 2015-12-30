require 'spec_helper'

def_syslog_file = '/etc/rsyslog.d/avst-app.conf'
def_logrotate_file = '/etc/logrotate.d/avst-app'

syslog_no_log = '~'

 
describe 'avstapp::syslog', :type => 'class' do
  
  context "Should not create rsyslog or logrotate config" do
    let(:facts){{
      :osfamily => 'RedHat',
      :operatingsystemrelease => '7.1',
      :operatingsystem => 'RedHat'
    }}
    let(:params){{
      :enable_syslog => false,
      :enable_logrotate => true,
      :syslog_implementation => "rsyslog",
      :syslog_destination => def_syslog_file,
    }}
    it do
      should contain_service('rsyslog').with( 'ensure' => 'running')
      should contain_file("#{def_syslog_file}").with('ensure' => 'absent')
      should contain_file("#{def_logrotate_file}").with('ensure' => 'absent')
    end
  end

  context "Should not create rsyslog but not logrotate config" do
    let(:facts){{
      :osfamily => 'RedHat',
      :operatingsystemrelease => '7.1',
      :operatingsystem => 'RedHat'
    }}
    let(:params){{
      :enable_syslog => true,
      :enable_logrotate => false,
      :syslog_implementation => "rsyslog",
      :syslog_destination => def_syslog_file,
    }}
    it do
      should contain_service('rsyslog').with( 'ensure' => 'running')
      should contain_file("#{def_syslog_file}").with(
        'ensure' => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
       )
      should contain_file("#{def_logrotate_file}").with('ensure' => 'absent')
    end
  end

  context "Should create rsyslog that drops messages but not logrotate config" do
    let(:facts){{
      :osfamily => 'RedHat',
      :operatingsystemrelease => '7.1',
      :operatingsystem => 'RedHat'
    }}
    let(:params){{
      :enable_syslog => true,
      :enable_logrotate => true,
      :syslog_implementation => "rsyslog",
      :syslog_destination => syslog_no_log,
    }}
    it do
      should contain_service('rsyslog').with( 'ensure' => 'running')
      should contain_file("#{def_syslog_file}").with(
        'ensure' => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
      )
      should contain_file("#{def_logrotate_file}").with('ensure' => 'absent')
    end
  end

  context "Should create rsyslog and logrotate config" do
    let(:facts){{
      :osfamily => 'RedHat',
      :operatingsystemrelease => '7.1',
      :operatingsystem => 'RedHat'
    }}
    let(:params){{
      :enable_syslog => true,
      :enable_logrotate => true,
      :syslog_implementation => "rsyslog",
      :syslog_destination => def_syslog_file,
    }}
    it do
      should contain_service('rsyslog').with( 'ensure' => 'running')
      should contain_file("#{def_syslog_file}").with(
        'ensure' => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
      )
      should contain_file("#{def_logrotate_file}").with(
        'ensure' => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
      )
    end
  end
  
  context "Should error with unsupported syslog implementation" do
    let(:facts){{
      :osfamily => 'RedHat',
      :operatingsystemrelease => '7.1',
      :operatingsystem => 'RedHat'
    }}
    let(:params){{
      :enable_syslog => true,
      :enable_logrotate => true,
      :syslog_implementation => "syslog-ng",
      :syslog_destination => def_syslog_file,
    }}
    it do
      should raise_error(Puppet::Error, /avst-app::syslog: Unsupported syslog implementation/)
    end
  end
end

