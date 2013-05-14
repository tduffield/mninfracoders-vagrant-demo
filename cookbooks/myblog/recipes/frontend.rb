#
# Cookbook Name:: myblog
# Recipe:: frontend
#
# Copyright (C) 2013 Tom Duffield (@tomduffield)
# Copyright (C) 2009-2010, OpsCode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "openssl"
include_recipe "apache2"
include_recipe "php"
include_recipe "php::module_mysql"
include_recipe "apache2::mod_php5"

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

if node.has_key?("ec2")
    server_fqdn = node['ec2']['public_hostname']
else
    server_fqdn = node['fqdn']
end

partial_search(:node, 'name:backend', :keys => {
	'fqdn' => ['fqdn'], 
	'password' => ['wordpress','db','password'],
	'auth_key' => ['wordpress','keys','auth'],
	'secure_auth_key' => ['wordpress','keys','secure_auth'],
	'logged_in_key' => ['wordpress','keys','logged_in'],
	'nonce_key' => ['wordpress','keys','nonce']
}).each do |backend|
	node.set_unless['wordpress']['db']['hostname'] = backend['fqdn']
	node.set_unless['wordpress']['db']['password'] = backend['password']
	node.set_unless['wordpress']['keys']['auth'] = backend['auth_key']
	node.set_unless['wordpress']['keys']['secure_auth'] = backend['secure_auth_key']
	node.set_unless['wordpress']['keys']['logged_in'] = backend['logged_in_key']
	node.set_unless['wordpress']['keys']['nonce'] = backend['nonce_key']
end

if node['wordpress']['version'] == 'latest'
  # WordPress.org does not provide a sha256 checksum, so we'll use the sha1 they do provide
  require 'digest/sha1'
  require 'open-uri'
  local_file = "#{Chef::Config[:file_cache_path]}/wordpress-latest.tar.gz"
  latest_sha1 = open('http://wordpress.org/latest.tar.gz.sha1') {|f| f.read }
  unless File.exists?(local_file) && ( Digest::SHA1.hexdigest(File.read(local_file)) == latest_sha1 )
    remote_file "#{Chef::Config[:file_cache_path]}/wordpress-latest.tar.gz" do
      source "http://wordpress.org/latest.tar.gz"
      mode "0644"
    end
  end
else
  remote_file "#{Chef::Config[:file_cache_path]}/wordpress-#{node['wordpress']['version']}.tar.gz" do
    source "#{node['wordpress']['repourl']}/wordpress-#{node['wordpress']['version']}.tar.gz"
    mode "0644"
  end
end

directory "#{node['wordpress']['dir']}" do
  owner "root"
  group "root"
  mode "0755"
  action :create
  recursive true
end

execute "untar-wordpress" do
  cwd node['wordpress']['dir']
  command "tar --strip-components 1 -xzf #{Chef::Config[:file_cache_path]}/wordpress-#{node['wordpress']['version']}.tar.gz"
  creates "#{node['wordpress']['dir']}/wp-settings.php"
end

# save node data after writing the MYSQL root password, so that a failed chef-client run that gets this far doesn't cause an unknown password to get applied to the box without being saved in the node data.
unless Chef::Config[:solo]
  ruby_block "save node data" do
    block do
      node.save
    end
    action :create
  end
end

log "Navigate to 'http://#{server_fqdn}/wp-admin/install.php' to complete wordpress installation" do
  action :nothing
end

template "#{node['wordpress']['dir']}/wp-config.php" do
  source "wp-config.php.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    :database        => node['wordpress']['db']['database'],
    :user            => node['wordpress']['db']['user'],
    :password        => node['wordpress']['db']['password'],
    :hostname        => node['wordpress']['db']['hostname'],
    :auth_key        => node['wordpress']['keys']['auth'],
    :secure_auth_key => node['wordpress']['keys']['secure_auth'],
    :logged_in_key   => node['wordpress']['keys']['logged_in'],
    :nonce_key       => node['wordpress']['keys']['nonce']
  )
  notifies :write, "log[Navigate to 'http://#{server_fqdn}/wp-admin/install.php' to complete wordpress installation]"
end

apache_site "000-default" do
  enable false
end

web_app "wordpress" do
  cookbook "wordpress"
  template "wordpress.conf.erb"
  docroot "#{node['wordpress']['dir']}"
  server_name server_fqdn
  server_aliases node['wordpress']['server_aliases']
end
