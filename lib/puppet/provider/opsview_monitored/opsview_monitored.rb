#
# Major refactor by Christian Paredes <christian.paredes@sbri.org>
#

# This file is part of the Opsview puppet module
#
# Copyright (C) 2010 Opsera Ltd.
#
# The Opsview puppet module is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
require File.join(File.dirname(__FILE__), '..', 'opsview')

begin
  require 'json'
rescue LoadError => e
  Puppet.info "You need the `json` gem for communicating with Opsview servers."
end
begin
  require 'rest-client'
rescue LoadError => e
  Puppet.info "You need the `rest-client` gem for communicating wtih Opsview servers."
end

require 'puppet'
# Config file parsing
require 'yaml'

Puppet::Type.type(:opsview_monitored).provide :opsview, :parent => Puppet::Provider::Opsview do
  @req_type = 'host'

  mk_resource_methods

  def internal
    super
    resource[:internal]
  end
  def internal=(should)
  end

  def self.node_map(node)
    p = { :name          => node["name"],
          :ip            => node["ip"],
          :hostgroup     => node["hostgroup"]["name"],
          :servicechecks => node["servicechecks"].collect{ |sc| sc["name"] },
          :hosttemplates => node["hosttemplates"].collect{ |ht| ht["name"] },
          :keywords      => node["keywords"].collect{ |kw| kw["name"] },
          :hostattributes => node["hostattributes"],
          :enable_snmp   => node["enable_snmp"],
          :snmp_community   => node["snmp_community"],
          :encrypted_snmp_community   => node["encrypted_snmp_community"],
          :encrypted_snmpv3_authpassword   => node["encrypted_snmpv3_authpassword"],
          :encrypted_snmpv3_privpassword   => node["encrypted_snmpv3_privpassword"],
          :snmp_version   => node["snmp_version"],
          :snmp_port   => node["snmp_port"],
          :snmpinterfaces => node["snmpinterfaces"],
          :snmpv3_authpassword => node["snmpv3_authpassword"],
          :snmpv3_authprotocol => node["snmpv3_authprotocol"],
          :snmpv3_privpassword => node["snmpv3_privpassword"],
          :snmpv3_privprotocol => node["snmpv3_privprotocol"],
          :snmpv3_username => node["snmpv3_username"],
          :tidy_ifdescr_level => node["tidy_ifdescr_level"],
          :snmp_extended_throughput_data => node["snmp_extended_throughput_data"],
          :icon_name => node["icon"]["name"],
          :full_json     => node,
          :ensure        => :present }
          
    # optional properties
    if defined? node["notification_options"]
      p[:notification_options] = node["notification_options"]
    end
    if defined? node["notification_period"]["name"]
      p[:notification_period] = node["notification_period"]["name"]
    end
    if defined? node["check_period"]["name"]
      p[:check_period] = node["check_period"]["name"]
    end
    if defined? node["check_attempts"]
      p[:check_attempts] = node["check_attempts"]
    end
    if defined? node["parents"]
      p[:parents] = node["parents"].collect{ |prnt| prnt["name"] }
    end
    if defined? node["keywords"]
      p[:keywords] = node["keywords"].collect{ |kw| kw["name"] }
    end
    if defined? node["hostattributes"]
      p[:hostattributes] = node["hostattributes"].collect{ |ha| {"name" => ha["name"], "value" => ha["value"], "arg1" => ha["arg1"], "arg2" => ha["arg2"], "arg3" => ha["arg3"], "arg4" => ha["arg4"], "encrypted_arg1" => ha["encrypted_arg1"], "encrypted_arg2" => ha["encrypted_arg2"], "encrypted_arg3" => ha["encrypted_arg3"], "encrypted_arg4" => ha["encrypted_arg4"] }.delete_if{ |k, v| v.nil?}  }
    end
    if defined? node["monitored_by"]["name"]
      p[:monitored_by] = node["monitored_by"]["name"]
    end
    if defined? node["check_command"]["name"]
      p[:check_command] = node["check_command"]["name"]
    end

    if defined? node["snmpinterfaces"]
      p[:snmpinterfaces] = node["snmpinterfaces"].collect{ |si| {"interfacename" => si["interfacename"], "active" => si["active"], "discards_critical" => si["discards_critical"], "discards_warning" => si["discards_warning"], "errors_critical" => si["errors_critical"], "throughput_critical" => si["throughput_critical"], "throughput_warning" => si["throughput_warning"] }.delete_if{ |k, v| v.nil?}  }
    end

    if defined? node["snmp_max_msg_size"]
      case node["snmp_max_msg_size"].to_s
        when "0" then 
          p[:snmp_max_msg_size] = "default"
        when "1023" then 
          p[:snmp_max_msg_size] = "1Kio"
        when "2047" then 
          p[:snmp_max_msg_size] = "2Kio"
        when "4095" then 
          p[:snmp_max_msg_size] = "4Kio"
        when "8191" then 
          p[:snmp_max_msg_size] = "8Kio"
        when "16383" then 
          p[:snmp_max_msg_size] = "16Kio"
        when "32767" then 
          p[:snmp_max_msg_size] = "32Kio"
        when "65535" then 
          p[:snmp_max_msg_size] = "64Kio"
      end
    end
    if defined? node["tidy_ifdescr_level"]
      case node["tidy_ifdescr_level"].to_s
        when "0" then
          p[:tidy_ifdescr_level] = "off"
        when "1" then 
          p[:tidy_ifdescr_level] = "level1"
        when "2" then 
          p[:tidy_ifdescr_level] = "level2"
        when "3" then 
          p[:tidy_ifdescr_level] = "level3"
      end
    end

    #All other options

    [:check_interval, :retry_check_interval, :notification_interval].each do |prop|
      p[prop] = node[prop.id2name] if defined? node[prop.id2name]
    end

    p
  end

  # Query the current resource state from Opsview
  def self.prefetch(resources)
    instances.each do |provider|
      if node = resources[provider.name]
        node.provider = provider
      end
    end
  end

  def self.instances
    providers = []

    # Retrieve all nodes.  Expensive query.
    nodes = get_resources

    nodes.each do |node|
      providers << new(node_map(node))
    end

    providers
  end

  # Apply the changes to Opsview
  def flush
    if @node_json
      @updated_json = @node_json.dup
    else
      @updated_json = default_node
    end
 
    @property_hash.delete(:groups)
    @node_properties.delete(:groups)
 
    # Update the node's JSON values based on any new params.  Sadly due to the
    # structure of the JSON vs the flat nature of the puppet properties, this
    # is a bit of a manual task.
    @updated_json["hostgroup"]["name"] = @property_hash[:hostgroup]
    @updated_json["name"] = @resource[:name]
    @updated_json["ip"] = @property_hash[:ip]

    @updated_json["enable_snmp"] = @property_hash[:enable_snmp]

#    Disabled for version 4.6.1
#    @updated_json["snmp_community"] = @property_hash[:snmp_community]
#    if not @property_hash[:snmpv3_authpassword].to_s.empty?
#      @updated_json["snmpv3_authpassword"] = @property_hash[:snmpv3_authpassword]
#    end
#    if not  @property_hash[:snmpv3_privpassword].to_s.empty?
#      @updated_json["snmpv3_privpassword"] = @property_hash[:snmpv3_privpassword]
#    end
#    /Disabled for version 4.6.1

    if not @property_hash[:encrypted_snmp_community].to_s.empty?
      @updated_json["encrypted_snmp_community"] = @property_hash[:encrypted_snmp_community]
    end

    if not @property_hash[:encrypted_snmpv3_authpassword].to_s.empty?
      @updated_json["encrypted_snmpv3_authpassword"] = @property_hash[:encrypted_snmpv3_authpassword]
    end

    if not @property_hash[:encrypted_snmpv3_privpassword].to_s.empty?
      @updated_json["encrypted_snmpv3_privpassword"] = @property_hash[:encrypted_snmpv3_privpassword]
    end

    @updated_json["snmp_version"] = @property_hash[:snmp_version]
    @updated_json["snmp_port"] = @property_hash[:snmp_port]


    if not  @property_hash[:snmpv3_authprotocol].to_s.empty?
      @updated_json["snmpv3_authprotocol"] = @property_hash[:snmpv3_authprotocol]
    end


    if not  @property_hash[:snmpv3_privprotocol].to_s.empty?
      @updated_json["snmpv3_privprotocol"] = @property_hash[:snmpv3_privprotocol]
    end

    if not  @property_hash[:snmpv3_usernamesnmpv3_authprotocol].to_s.empty?
      @updated_json["snmpv3_username"] = @property_hash[:snmpv3_username]
    end

    if not  @property_hash[:check_command].to_s.empty?
      @updated_json["check_command"]["name"] = @property_hash[:check_command]
    end

    case @property_hash[:snmp_max_msg_size].to_s
      when "default" then 
        @updated_json["snmp_max_msg_size"] = 0
      when "1Kio" then 
        @updated_json["snmp_max_msg_size"] = 1023
      when "2Kio" then 
        @updated_json["snmp_max_msg_size"] = 2047
      when "4Kio" then 
        @updated_json["snmp_max_msg_size"] = 4095
      when "8Kio" then 
        @updated_json["snmp_max_msg_size"] = 8191
      when "16Kio" then 
        @updated_json["snmp_max_msg_size"] = 16383
      when "32Kio" then 
        @updated_json["snmp_max_msg_size"] = 32767
      when "64Kio" then 
        @updated_json["snmp_max_msg_size"] = 65535
    end

    case @property_hash[:tidy_ifdescr_level].to_s
      when "off" then
        @updated_json["tidy_ifdescr_level"] = 0
      when "level1" then
        @updated_json["tidy_ifdescr_level"] = 1
      when "level2" then
        @updated_json["tidy_ifdescr_level"] = 2
      when "level3" then
        @updated_json["tidy_ifdescr_level"] = 3
    end

    if not@property_hash[:snmp_extended_throughput_data].to_s.empty?
      @updated_json["snmp_extended_throughput_data"] = @property_hash[:snmp_extended_throughput_data]
    end

    if not @property_hash[:icon_name].to_s.empty?
      @updated_json["icon"]["name"] = @property_hash[:icon_name]
    end

    @updated_json["hosttemplates"] = []
    if @property_hash[:hosttemplates]
      @property_hash[:hosttemplates].each do |ht|
        @updated_json["hosttemplates"] << {:name => ht}
      end
    end

    @updated_json["servicechecks"] = []
    if @property_hash[:servicechecks]
      @property_hash[:servicechecks].each do |sc|
        @updated_json["servicechecks"] << {:name => sc}
      end
    end

    @updated_json["hostattributes"] = []
    if @property_hash[:hostattributes]
      @property_hash[:hostattributes].each do |ha_hash|
        @updated_json["hostattributes"] << {:name => ha_hash["name"], :value => ha_hash["value"],
						:arg1 => ha_hash["arg1"], :arg2 => ha_hash["arg2"],
						:arg3 => ha_hash["arg3"], :arg4 => ha_hash["arg4"],
						:encrypted_arg1 => ha_hash["encrypted_arg1"], :encrypted_arg2 => ha_hash["encrypted_arg2"],
						:encrypted_arg3 => ha_hash["encrypted_arg3"], :encrypted_arg4 => ha_hash["encrypted_arg4"]
	}
      end
    end

    @updated_json["snmpinterfaces"] = []
    if @property_hash[:snmpinterfaces]
      @property_hash[:snmpinterfaces].each do |si_hash|
        @updated_json["snmpinterfaces"] << {:interfacename => si_hash["interfacename"], :active => si_hash["active"],
						:discards_critical => si_hash["discards_critical"], :discards_warning => si_hash["discards_warning"],
						:errors_critical => si_hash["errors_critical"], :errors_warning => si_hash["errors_warning"],
						:throughput_critical => si_hash["throughput_critical"], :throughput_warning => si_hash["throughput_warning"],
	}
      end
    end

    @updated_json["keywords"] = []
    if @property_hash[:keywords]
      @property_hash[:keywords].each do |kw|
        @updated_json["keywords"] << {:name => kw}
      end
    end
    
    @updated_json["parents"] = []
    if @property_hash[:parents]
      @property_hash[:parents].each do |pa|
        @updated_json["parents"] << {:name => pa}
      end
    end

    if @property_hash[:notification_options]
      @updated_json["notification_options"] = @property_hash[:notification_options]
    end

    if @property_hash[:notification_period]
      @updated_json["notification_period"]["name"] = @property_hash[:notification_period]
    end

    if @property_hash[:check_period]
      @updated_json["check_period"]["name"] = @property_hash[:check_period]
    end

    if @property_hash[:check_attempts]
      @updated_json["check_attempts"] = @property_hash[:check_attempts]
    end
  
    if not @property_hash[:monitored_by].to_s.empty?
      @updated_json["monitored_by"]["name"] = @property_hash[:monitored_by]
    end

    [:check_interval, :notification_interval, :retry_check_interval].each do |property|
      #interval_mode will determine how the interval gets set
      if not @property_hash[property].to_s.empty?
        Puppet.debug "The property_hash is #{@property_hash[property].to_s}"
        @updated_json[property.id2name] = @property_hash[property]
      end
    end
  
    put @updated_json.to_json

    if defined? @resource[:reload_opsview]
      if @resource[:reload_opsview].to_s == "true"
        Puppet.notice "Configured to reload opsview"
        do_reload_opsview
      else
        Puppet.notice "Configured NOT to reload opsview"
      end
    end

    @property_hash.clear
    @node_properties.clear

    false
  end

  def initialize(*args)
    super

    # Save the JSON for the node if it's present in the arguments
    if args[0].class == Hash and args[0].has_key?(:full_json)
      @node_json = args[0][:full_json]
    end

    @property_hash = @property_hash.inject({}) do |result, ary|
      param, values = ary

      # Skip any attributes we don't manage.
      next result unless self.class.resource_type.validattr?(param)

      paramclass = self.class.resource_type.attrclass(param)

      unless values.is_a?(Array)
        result[param] = values
        next result
      end

      # Only use the first value if the attribute class doesn't manage
      # arrays of values.
      if paramclass.superclass == Puppet::Parameter or paramclass.array_matching == :first
        result[param] = values[0]
      else
        result[param] = values
      end

      result
    end

    @node_properties = @property_hash.dup
  end

  # Return the current state of the node in Opsview.
  def node_properties
    @node_properties.dup
  end

  # Return (and look up if necessary) the desired state.
  def properties
    if @property_hash.empty?
      @property_hash = query || {:ensure => :absent}
      if @property_hash.empty?
        @property_hash[:ensure] = :absent
      end
    end
    @property_hash.dup
  end

  def default_node
    json = '
     {
       "flap_detection_enabled" : "1",
       "snmpv3_privprotocol" : null,
       "hosttemplates" : [],
       "keywords" : [],
       "check_period" : {
          "name" : "24x7"
       },
       "hostattributes" : [],
       "notification_period" : {
          "name" : "24x7"
       },
       "notification_options" : "u,d,r",
       "name" : "puppet-unknown",
       "rancid_vendor" : null,
       "hostgroup" : {
          "name" : "From Puppet - Unknown"
       },
       "enable_snmp" : "0",
       "monitored_by" : {
          "name" : "Master Monitoring Server"
       },
       "alias" : "Puppet Managed Host",
       "uncommitted" : "0",
       "parents" : [],
       "icon" : {
          "name" : "LOGO - Opsview"
       },
       "retry_check_interval" : "60",
       "ip" : "localhost",
       "use_mrtg" : "0",
       "servicechecks" : [],
       "use_rancid" : "0",
       "nmis_node_type" : "router",
       "snmp_version" : "2c",
       "snmp_max_msg_size" : "default",
       "snmp_extended_throughput_data" : "0",
       "tidy_ifdescr_level" : "off",
       "use_nmis" : "0",
       "rancid_connection_type" : "ssh",
       "snmpv3_authprotocol" : null,
       "rancid_username" : null,
       "check_command" : {
          "name" : "ping"
       },
       "check_attempts" : "2",
       "check_interval" : "300",
       "notification_interval" : "3600",
       "snmp_port" : "161",
       "snmpv3_username" : "",
       "other_addresses" : ""
     }'

    JSON.parse(json.to_s)
  end
end
