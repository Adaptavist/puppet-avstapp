require 'spec_helper'

base_directory = '/opt'
cust_base_directory = '/tmp'
java_module = 'oracle_java'
hosting_user      = 'hosting'
hosting_group     = 'hosting'
soft_nofile = '2048'
hard_nofile = '16384'
host = { 'avstapp::conf' => {} }
conf = {}
custom_host = { 'avstapp::conf' => {
  'crowd-stg1'=>{
            'version' => '2.6.7',
            'application_type' => 'crowd',
            'tarball_location_url' => 'www.example.com/tarball.tar.gz',
            }
          }
        }

describe 'avstapp::dependencies', :type => 'class' do

  context "Should include all dependencies based on operating system for generic avstapp app on Debian" do
    let(:params){{
      :soft_nofile => soft_nofile,
      :hard_nofile => hard_nofile,
      :java_module_name => java_module,
    }}
    let(:facts){{
      :osfamily => 'Debian',
      :lsbdistrelease  => '12.04',
      :lsbdistid => 'Ubuntu',
      :lsbdistcodename => 'precise',
      :host => host,

    }}

    it do
      should contain_class(java_module)
      should contain_limits__fragment('*/soft/nofile').with(
        'value' => soft_nofile
      )
      should contain_limits__fragment('*/hard/nofile').with(
        'value' => hard_nofile
      )
      should contain_package('libaugeas-ruby').with(
        'ensure' => 'installed',
      )
    end
  end

  context "Should include all dependencies based on operating system for generic avstapp app on RedHat" do
    let(:params){{
      :soft_nofile => soft_nofile,
      :hard_nofile => hard_nofile,
      :java_module_name => java_module,
    }}
    let(:facts){{
      :osfamily => 'RedHat',
      :operatingsystem => 'RedHat',
      :kernel => 'Linux',
      :os => { :family => "RedHat"  },
      :operatingsystemrelease => '6.5',
      :operatingsystemmajrelease => '6',
      :host => host,
    }}

    it do
      should contain_class(java_module)
      should contain_limits__fragment('*/soft/nofile').with(
        'value' => soft_nofile
      )
      should contain_limits__fragment('*/hard/nofile').with(
        'value' => hard_nofile
      )
      ['apr-util', 'neon', 'augeas'].each do |pack|
        should contain_package(pack).with(
              'ensure' => 'installed',
        )
      end
    end
  end
end
