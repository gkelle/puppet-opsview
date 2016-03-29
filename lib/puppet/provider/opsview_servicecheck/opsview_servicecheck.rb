#
# Major refactor by Christian Paredes <christian.paredes@sbri.org>
# Original file by Devon Peters
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

Puppet::Type.type(:opsview_servicecheck).provide :opsview, :parent => Puppet::Provider::Opsview do
  @req_type = 'servicecheck'

  mk_resource_methods

  def internal
    super
    resource[:internal]
  end
  def internal=(should)
  end

  def self.servicecheck_map(servicecheck)
    p = { :name         => servicecheck["name"],
          :description  => servicecheck["description"],
          :servicegroup => servicecheck["servicegroup"]["name"],
          :args         => servicecheck["args"],
          :full_json    => servicecheck,
          :ensure       => :present }
    # optional properties

    if defined? servicecheck["cascaded_from"]["name"]
      p[:cascaded_from] = servicecheck["cascaded_from"]["name"]
    end

    if defined? servicecheck["checktype"]["name"]
      p[:checktype] = servicecheck["checktype"]["name"]
    end

    if defined? servicecheck["plugin"]["name"]
      p[:plugin] = servicecheck["plugin"]["name"]
    end
    if defined? servicecheck["dependencies"]
      p[:dependencies] = servicecheck["dependencies"].collect{ |dp| dp["name"] }
    end
    if defined? servicecheck["keywords"]
      p[:keywords] = servicecheck["keywords"].collect{ |kw| kw["name"] }
    end
    if defined? servicecheck["check_period"]["name"]
      p[:check_period] = servicecheck["check_period"]["name"]
    end

    #Notification options

    [:notification_interval, :notification_options].each do |prop|
     p[prop] = servicecheck[prop.id2name] if defined? servicecheck[prop.id2name]
    end

    if defined? servicecheck["notification_period"]["name"]
      p[:notification_period] = servicecheck["notification_period"]["name"]
    end

    #Advanced tab options

    if defined? servicecheck["attribute"]["name"]
      p[:attribute] = servicecheck["attribute"]["name"]
    end

    if defined? servicecheck["stalking"]
      p[:record_output_changes] = servicecheck["stalking"]
    end

    if defined? servicecheck["volatile"]
      p[:alert_every_failure] = servicecheck["volatile"]
    end

    if defined? servicecheck["flap_detection_enabled"]
      p[:flap_detection] = servicecheck["flap_detection_enabled"]
    end

    [:event_handler, :markdown_filter, :sensitive_arguments].each do |prop|
     p[prop] = servicecheck[prop.id2name] if defined? servicecheck[prop.id2name]
    end

    #SNMP Polling
    [:calculate_rate, :critical_comparison, :critical_value,
     :label, :warning_comparison, :warning_value, :oid].each do |prop|
     p[prop] = servicecheck[prop.id2name] if defined? servicecheck[prop.id2name]
    end

    #Passive checks
    if defined? servicecheck["freshness_type"]
     p[:action] = servicecheck["freshness_type"]
    end

    if defined? servicecheck["stale_state"]
     p[:state] = servicecheck["stale_state"]
    end

    if defined? servicecheck["stale_text"]
     p[:text] = servicecheck["stale_text"]
    end

    if defined? servicecheck["stale_threshold_seconds"]
     p[:timeout] = servicecheck["stale_threshold_seconds"]
    end


    [:alert_from_failure, :check_freshness].each do |prop|
      p[prop] = servicecheck[prop.id2name] if defined? servicecheck[prop.id2name]
    end

    #SNMP Trap rules
    if defined? servicecheck["snmptraprules"]
      action_map={ "1" => "Send Alert", "0" => "Stop Processing"}
      alert_level_map={ "0" => "OK", "1" => "WARNING", "2" => "CRITICAL", "3" => "UNKNOWN"}
      p[:snmptraprules] = servicecheck["snmptraprules"].collect{ |st| {"name" => st["name"], "rule" => st["code"], "action" => action_map[st["process"]], "alert_level" => alert_level_map[st["alertlevel"]], "message" => st["message"] }.delete_if{ |k, v| v.nil?}  }
    end

    #All other options

    [:check_interval, :check_attempts, :retry_check_interval, :invertresults].each do |prop|
      p[prop] = servicecheck[prop.id2name] if defined? servicecheck[prop.id2name]
    end
    p
  end

  # Query the current resource state from Opsview
  def self.prefetch(resources)
    instances.each do |provider|
      if servicecheck = resources[provider.name]
        servicecheck.provider = provider
      end
    end
  end

  def self.instances
    providers = []

    # Retrieve all servicechecks.  Expensive query.
    servicechecks = get_resources

    servicechecks.each do |servicecheck|
      providers << new(servicecheck_map(servicecheck))
    end

    providers
  end

  # Apply the changes to Opsview
  def flush
    if @servicecheck_json
      @updated_json = @servicecheck_json.dup
    else
      @updated_json = default_servicecheck
    end
 
    # Update the servicecheck's JSON values based on any new params.  Sadly due to the
    # structure of the JSON vs the flat nature of the puppet properties, this
    # is a bit of a manual task.
    @updated_json["name"] = @resource[:name]
    @updated_json["dependencies"] = []
    if @property_hash[:dependencies]
      @property_hash[:dependencies].each do |dep|
        @updated_json["dependencies"] << {:name => dep}
      end
    end
    @updated_json["keywords"] = []
    if @property_hash[:keywords]
      @property_hash[:keywords].each do |kw|
        @updated_json["keywords"] << {:name => kw}
      end
    end
    if not @property_hash[:servicegroup].to_s.empty?
      @updated_json["servicegroup"]["name"] = @property_hash[:servicegroup]
    end
    if not @property_hash[:description].to_s.empty?
      @updated_json["description"] = @property_hash[:description]
    end
    if not @property_hash[:plugin].to_s.empty?
      @updated_json["plugin"]["name"] = @property_hash[:plugin]
    end
    if not @property_hash[:check_period].to_s.empty?
      @updated_json["check_period"]["name"] = @property_hash[:check_period]
    end

    if not @property_hash[:checktype].to_s.empty?
      @updated_json["checktype"] = Hash.new
      @updated_json["checktype"]["name"] = @property_hash[:checktype]
    end


    #Notification Tab
    [:notification_interval, :notification_options].each do |property|
      if not @property_hash[property].to_s.empty?
        @updated_json[property.id2name] = @property_hash[property]
      end
    end

    if not @property_hash[:notification_period].to_s.empty?
      @updated_json["notification_period"] = Hash.new
      @updated_json["notification_period"]["name"] = @property_hash[:notification_period]
    end

    #Advanced Tab
    if not @property_hash[:attribute].to_s.empty?
      @updated_json["attribute"] = Hash.new
      @updated_json["attribute"]["name"] = @property_hash[:attribute]
    else
      @updated_json["attribute"] = nil
    end

    if not @property_hash[:event_handler].nil?
      @updated_json["event_handler"] = @property_hash[:event_handler] 
    end

    if not @property_hash[:record_output_changes].to_s.empty?
      @updated_json["stalking"] = @property_hash[:record_output_changes] 
    end

    if not @property_hash[:alert_every_failure].to_s.empty?
      @updated_json["volatile"] = @property_hash[:alert_every_failure] 
    end

    if not @property_hash[:flap_detection].to_s.empty?
      @updated_json["flap_detection_enabled"] = @property_hash[:flap_detection]
    end

    [:markdown_filter, :sensitive_arguments].each do |property|
      if not @property_hash[property].to_s.empty?
        @updated_json[property.id2name] = @property_hash[property]
      end
    end

    #SNMP Polling
    [:critical_value, :label, :warning_value].each do |property|
      if defined? @property_hash[property]
        @updated_json[property.id2name] = @property_hash[property]
      end
    end

    [:calculate_rate, :critical_comparison, :warning_comparison, :oid].each do |property|
      if not @property_hash[property].to_s.empty?
        @updated_json[property.id2name] = @property_hash[property]
      end
    end

    #Passive checks
    if not @property_hash[:action].to_s.empty?
      @updated_json["freshness_type"] = @property_hash[:action]
    end

    if not @property_hash[:cascaded_from].nil?
      @updated_json["cascaded_from"] = Hash.new
      @updated_json["cascaded_from"]["name"] = @property_hash[:cascaded_from]
    end

    if not @property_hash[:state].to_s.empty?
      @updated_json["stale_state"] = @property_hash[:state]
    end

    if not @property_hash[:text].nil?
      @updated_json["stale_text"] = @property_hash[:text]
    end

    if not @property_hash[:timeout].to_s.empty?
      @updated_json["stale_threshold_seconds"] = @property_hash[:timeout]
    end

    [:alert_from_failure, :check_freshness].each do |property|
    if not @property_hash[property].to_s.empty?
        @updated_json[property.id2name] = @property_hash[property]
      end
    end

    #SNMP Trap rules
    if @property_hash[:snmptraprules].is_a?(Array)
      action_map={ "Send Alert" => "1", "Stop Processing" => "0"}
      alert_level_map={ "OK" => "0", "WARNING" => "1", "CRITICAL" => "2", "UNKNOWN" => "3"}
      @property_hash[:snmptraprules].each do |st_hash|
        @updated_json["snmptraprules"] << {:name => st_hash["name"], :code => st_hash["rule"],
						:process => action_map[st_hash["action"]], :alertlevel => alert_level_map[st_hash["alert_level"]],
						:message => st_hash["message"]
						}
      end
    end

    #interval_mode will determine how the check_interval gets set
    if not @property_hash[:check_interval].to_s.empty?
      multiplier = 1
      if defined? @resource[:interval_mode]
        if (@resource[:interval_mode].to_s == "clever" and @property_hash[:check_interval].to_i < 30) or @resource[:interval_mode].to_s == "minutes"
	  multiplier = 60
	end
      end
      adjusted_interval = @property_hash[:check_interval].to_i * multiplier
      @updated_json["check_interval"] = adjusted_interval
      Puppet.debug "The adjusted interval is #{adjusted_interval}"
    end

    #Other checks

    [:check_attempts, :retry_check_interval,
     :args, :invertresults
    ].each do |property|
      if not @property_hash[property].to_s.empty?
        @updated_json[property.id2name] = @property_hash[property]
      end
    end
  
    # Flush changes:
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
    @servicecheck_properties.clear

    false
  end

  def initialize(*args)
    super

    # Save the JSON for the servicecheck if it's present in the arguments
    if args[0].class == Hash and args[0].has_key?(:full_json)
      @servicecheck_json = args[0][:full_json]
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

    @servicecheck_properties = @property_hash.dup
  end

  # Return the current state of the servicecheck in Opsview.
  def servicecheck_properties
    @servicecheck_properties.dup
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

  def default_servicecheck
    json = '
     {
         "name" : "Puppet - Unknown",
         "description" : "Puppet - Unknown",
         "keywords" : [],
         "servicegroup" : {
            "name" : "Puppet - Unknown"
         },
         "dependencies" : [
            {
               "name" : "Opsview Agent"
            }
         ],
         "check_period" : {
            "name" : "24x7"
         },
         "check_interval" : "300",
         "check_attempts" : "3",
         "retry_check_interval" : "1",
         "plugin" : {
            "name" : "check_nrpe"
         },
         "args" : "",
         "stalking" : null,
         "volatile" : "0",
         "invertresults" : "0",
         "notification_options" : "w,c,r",
         "notification_period" : null,
         "notification_interval" : null,
         "flap_detection_enabled" : "1",
         "checktype" : {
            "name" : "Active Plugin"
         },
	 "alert_from_failure" : "1",
	 "calculate_rate" : "no",
	 "cascaded_from" : null,
	 "check_freshness" : "0",
	 "critical_comparison" : "string",
	 "critical_value" : "",
	 "freshness_type" : "set_stale",
	 "event_handler" : "",
	 "snmptraprules": [],
	 "stale_state" : "0",
	 "stale_text" : "Resetting State",
	 "stale_threshold_seconds" : "3600",
	 "warning_comparison" : "numeric",
	 "warning_value" : ""
     }'

    JSON.parse(json.to_s)
  end
end
