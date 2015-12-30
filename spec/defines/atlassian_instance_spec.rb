require 'spec_helper'
 
base_directory = '/opt'
cust_base_directory = '/tmp'
hosting_user      = 'hosting'
hosting_group     = 'hosting'
version = '2.6.7'
application_type = 'crowd'
tarball_location_url = 'wwww.example.com/crowd-2.6.7.tar.gz'
tarball_location_file = '/tmp/tarball.tar.gz'
host = { 'avstapp::conf' => {} }
instance_name = 'crowd_instance'
instance_dir = "#{base_directory}/#{instance_name}"
hosting_user = 'root'
hosting_group = 'root'
change_ownership_sh = "chown -R #{hosting_user}:#{hosting_group} #{instance_dir}/install"

describe 'avstapp::instance', :type => 'define' do
let('title'){instance_name}

  context "Should create dirs, download tar from url, extract tar and prepare avst-app.conf.sh " do
	let(:facts){{
		:osfamily => 'Debian',
		:lsbdistid => 'Ubuntu',
		:lsbdistcodename => 'precise',
		:host => host,
	}}
	let(:params){{
		:tarball_location_url => tarball_location_url,
	}}

    it do
		should contain_avstapp
		[instance_dir].each do |file_name|
	    	should contain_file( file_name ).with(
			    'ensure' => 'directory',
			    'owner'  => hosting_user,
			    'group'  => hosting_group,
			)
	    end

	    should contain_avstapp__download_tar_file(tarball_location_url)

	    should contain_file("#{instance_dir}/avst-app.cfg.sh").with(
		    'ensure'  => 'file',
		    'owner'   => hosting_user,
		    'group'   => hosting_group,
		    'mode'    => '0644',
		    'require' => "File[#{instance_dir}]",
		)
    end
  end

  context "Should create dirs, extract tar, prepare avst-app.conf.sh when tar_path is provided" do

	let(:facts){{
		:osfamily => 'Debian',
		:lsbdistid => 'Ubuntu',
		:lsbdistcodename => 'precise',
		:host => host,
	}}
	let(:params){{
		:tarball_location_file => tarball_location_file,
	}}

    it do
		should contain_avstapp
		[instance_dir].each do |file_name|
	    	should contain_file( file_name ).with(
			    'ensure' => 'directory',
			    'owner'  => hosting_user,
			    'group'  => hosting_group,
			)
	    end

	    should contain_file("#{instance_dir}/avst-app.cfg.sh").with(
		    'ensure'  => 'file',
		    'owner'   => hosting_user,
		    'group'   => hosting_group,
		    'mode'    => '0644',
		    'require' => "File[#{instance_dir}]",
		)
    end
  end
end

