require 'spec_helper'
 
base_directory = '/opt'
cust_base_directory = '/tmp'
hosting_user      = 'hosting'
hosting_group     = 'hosting'
host = { 'avstapp::conf' => {} }
conf = {}
custom_host = { 'avstapp::conf' => {
  'crowd-stg1'=>{
            'version' => '2.6.7',
            'application_type' => 'crowd',
            'tarball_location_url' => 'www.example.com/crowd-2.6.7.tar.gz',
            'avst_wizard' => false
            } 
          }
        }

describe 'avstapp', :type => 'class' do
  
  context "Should create base dir, avst-app file and instantiate resources" do
    let(:facts){{
      :osfamily => 'Debian',
      :lsbdistid => 'Ubuntu',
      :lsbdistrelease  => '12.04',
      :lsbdistcodename => 'precise',
      :host => host,
    }}
    it do
      should contain_class('oracle_java')
      should contain_file(base_directory).with(
          'ensure'  => 'directory',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0755',
      )
      should contain_file('/etc/default/avst-app').with(
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
      ).with_content(/BASE_DIR=\/opt/)
      .with_content(/INSTANCE_USER=root/)
    end
  end
  context "Should create base dir, avst_app file and instantiate resources with custom params" do
    let(:params){{
      :base_directory => cust_base_directory,
      :hosting_user => hosting_user,
      :hosting_group => hosting_group,
      :conf => conf, 
    }}
    let(:facts){{
      :osfamily => 'Debian',
      :lsbdistid => 'Ubuntu',
      :lsbdistrelease  => '12.04',
      :lsbdistcodename => 'precise',
      :host => custom_host,
    }}
    it do
      should contain_class('oracle_java')
      should contain_file(cust_base_directory).with(
          'ensure'  => 'directory',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0755',
      )
      should contain_file('/etc/default/avst-app').with(
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
      ).with_content(/BASE_DIR=#{cust_base_directory}/)
      .with_content(/INSTANCE_USER=#{hosting_user}/)

      should contain_avstapp__instance('crowd-stg1')
    end
  end
end

