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

Puppet::Type.type(:opsview_contact).provide :opsview, :parent => Puppet::Provider::Opsview do
  @req_type = 'contact'

  mk_resource_methods

  def internal
    super
    resource[:internal]
  end
  def internal=(should)
  end

  def self.contact_map(contact)
    p = { :name      => contact["name"],
          :full_json => contact,
          :ensure    => :present }

    # optional properties
    [:fullname, :description, :encrypted_password, :language].each do |prop|
      p[prop] = contact[prop.id2name] if defined? contact[prop.id2name]
    end

    if defined? contact["variables"]
      p[:variables] = {}
      contact["variables"].each do |var|
        p[:variables][var["name"]] = var["value"]
      end
    end
    if defined? contact["role"]["name"]
      p[:role] = contact["role"]["name"]
    end
    if defined? contact["notificationprofiles"]
      p[:notificationprofiles] = []
      np_hash = {}
      contact["notificationprofiles"].each do |np|
        np.keys.each do |k|
	  next if k == "ref"
	  if np[k].is_a?(Array)
	    np[k].each do |npk|
	     npk.delete_if { |key, value| key == "ref" } if npk.is_a?(Hash)
	    end
	  elsif np[k].is_a?(Hash)
	    np[k].delete_if { |key, value| key == "ref" }
	  end
	end
	np_hash[np['name']] = np
      end
      p[:notificationprofiles] << np_hash
    end
    p
  end

  # Query the current resource state from Opsview
  def self.prefetch(resources)
    instances.each do |provider|
      if contact = resources[provider.name]
        contact.provider = provider
      end
    end
  end

  def self.instances
    providers = []

    # Retrieve all contacts.  Expensive query.
    contacts = get_resources

    contacts.each do |contact|
      providers << new(contact_map(contact))
    end

    providers
  end

  # Apply the changes to Opsview
  def flush
    if @contact_json
      @updated_json = @contact_json.dup
    else
      @updated_json = default_contact
    end

    # Update the contact's JSON values based on any new params.  Sadly due to the
    # structure of the JSON vs the flat nature of the puppet properties, this
    # is a bit of a manual task.
    @updated_json["name"] = @resource[:name]
    [:fullname, :description, :encrypted_password, :language].each do |property|
      if not @property_hash[property].to_s.empty?
        @updated_json[property.id2name] = @property_hash[property]
      end
    end
    if not @property_hash[:variables].to_s.empty?
      @updated_json["variables"] = []
      @property_hash[:variables].each do |k,v|
        @updated_json["variables"] << {"name" => k, "value" => v}
      end
    end
    if not @property_hash[:role].to_s.empty?
      @updated_json["role"]["name"] = @property_hash[:role]
    end
    
    if @property_hash[:notificationprofiles]
      @merged_np=[]
      @base_np = default_notificationprofile
      @property_hash[:notificationprofiles].first.keys.each do |np|
        temp_np = @base_np.merge(@property_hash[:notificationprofiles].first[np])
	temp_np["name"] = np
	@merged_np << temp_np
      end
      @updated_json["notificationprofiles"] = @merged_np
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
    @contact_properties.clear

    false
  end

  def initialize(*args)
    super

    # Save the JSON for the contact if it's present in the arguments
    if args[0].class == Hash and args[0].has_key?(:full_json)
      @contact_json = args[0][:full_json]
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

    @contact_properties = @property_hash.dup
  end

  # Return the current state of the contact in Opsview.
  def contact_properties
    @contact_properties.dup
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

  def default_notificationprofile 
    json = '
     {
            "all_business_components" : "0",
            "all_business_services" : "0",
            "all_hostgroups" : "0",
            "all_keywords" : "0",
            "all_servicegroups" : "0",
            "business_component_availability_below" : "99.999",
            "business_component_options" : "f,i",
            "business_component_renotification_interval" : "1800",
            "business_components" : [],
            "business_service_availability_below" : "99.999",
            "business_service_options" : "o,i",
            "business_service_renotification_interval" : "1800",
            "business_services" : [],
            "host_notification_options" : "u,d,r,f",
            "hostgroups" : [],
            "include_component_notes" : "0",
            "include_service_notes" : "0",
            "keywords" : [],
            "notification_level" : "1",
            "notification_level_stop" : "0",
            "notification_period" : {
               "name" : "24x7"
            },
            "notificationmethods" : [],
            "service_notification_options" : "w,c,r,f",
            "servicegroups" : []
     }'
     JSON.parse(json.to_s)
  end

  def default_contact
    json = '
     {
        "name" : "puppet",
        "fullname" : "",
        "description" : "",
        "encrypted_password" : "$apr1$HTQogYE7$09TNcZWa/WzoBXdUF6Iyr1",
        "realm" : "local",
        "language" : "",
        "role" : {
           "name" : "View all, change none"
        },
        "variables" : [
           {
              "value" : "",
              "name" : "EMAIL"
           },
           {
              "value" : "1",
              "name" : "RSS_COLLAPSED"
           },
           {
              "value" : "1440",
              "name" : "RSS_MAXIMUM_AGE"
           },
           {
              "value" : "30",
              "name" : "RSS_MAXIMUM_ITEMS"
           }
        ],
        "notificationprofiles" : []
    }'

    JSON.parse(json.to_s)
  end

  # return the nested array->hash->array data structure required for
  # notificationprofiles.
  # If only opsview would let us edit these directly via the API. :(
  def update_notificationprofiles
    # This will only modify/affect the 8x5 and 24x7 profiles
    ["8x5", "24x7"].each do |profile_name|
      nm_sym = profile_name.sub(/^/, 'notificationmethods').to_sym
      hg_sym = profile_name.sub(/^/, 'hostgroups').to_sym
      allhg_sym = profile_name.sub(/^/, 'allhostgroups').to_sym
      sg_sym = profile_name.sub(/^/, 'servicegroups').to_sym
      allsg_sym = profile_name.sub(/^/, 'allservicegroups').to_sym
      hno_sym = profile_name.sub(/^/, 'host_notification_options').to_sym
      sno_sym = profile_name.sub(/^/, 'service_notification_options').to_sym
      notificationprofiles = []
      # Get both current profiles.  We'll update the profile that we're
      # changing now, and just pass through the one we're not changing.
      @updated_json["notificationprofiles"].each do |profile|
        if profile["name"] == profile_name
          # Make the hostgroups array of hashes
          if not @property_hash[hg_sym].to_s.empty?
            profile["hostgroups"] = []
            @property_hash[hg_sym].each do |hg|
              profile["hostgroups"] << {:name => hg}
            end
          end
          # Set the all_hostgroups parameter
          if not @property_hash[allhg_sym].to_s.empty?
            profile["all_hostgroups"] = @property_hash[allhg_sym]
          end
          # Make the servicegroups array of hashes
          if not @property_hash[sg_sym].to_s.empty?
            profile["servicegroups"] = []
            @property_hash[sg_sym].each do |sg|
              profile["servicegroups"] << {:name => sg}
            end
          end
          # Set the all_servicegroups parameter
          if not @property_hash[allsg_sym].to_s.empty?
            profile["all_servicegroups"] = @property_hash[allsg_sym]
          end
          # Set the notificationmethods
          if not @property_hash[nm_sym].to_s.empty?
            profile["notificationmethods"] = []
            @property_hash[nm_sym].each do |nm|
              profile["notificationmethods"] << {:name => nm}
            end
          end
          # Set the notification options
          if not @property_hash[hno_sym].to_s.empty?
            profile["host_notification_options"] = @property_hash[hno_sym]
          end
          if not @property_hash[sno_sym].to_s.empty?
            profile["service_notification_options"] = @property_hash[sno_sym]
          end
        end
        # append the profile to our new array
        notificationprofiles << profile
      end
      # now overwrite all the profiles
      @updated_json["notificationprofiles"] = notificationprofiles
    end
  end
end
