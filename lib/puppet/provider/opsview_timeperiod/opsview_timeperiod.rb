#
# Major refactor by Christian Paredes <christian.paredes@sbri.org>
# Original file by Devon Peters
#

# This file is part of the Opsview puppet module
#
# Copyright (C) 2016 Opsview Ltd.
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

Puppet::Type.type(:opsview_timeperiod).provide :opsview, :parent => Puppet::Provider::Opsview do
  @req_type = 'timeperiod'

  mk_resource_methods

  def internal
    super
    resource[:internal]
  end
  def internal=(should)
  end

  def self.rest_map(rest)
    p = { :name      => rest["name"],
          :full_json => rest,
          :ensure    => :present }

	  if defined? rest["alias"]
	   p[:alias] = rest["alias"]
	  end

	  [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday].each do |property|
	    if defined? rest[property.to_s]
	      p[property] = rest[property.to_s]
	    end
	  end
    p
  end

  # Query the current resource state from Opsview
  def self.prefetch(resources)
    instances.each do |provider|
      if rest = resources[provider.name]
        rest.provider = provider
      end
    end
  end

  def self.instances
    providers = []

    # Retrieve all Opsview config items.  Expensive query.
    rests = get_resources

    rests.each do |rest|
      providers << new(rest_map(rest))
    end

    providers
  end

  # Apply the changes to Opsview
  def flush
    type = 0
    if @opsview_json
      @updated_json = @opsview_json.dup
    else
      @updated_json = default_config
      type = 1
    end
 
    # Update the JSON values based on any new params.  Sadly due to the
    # structure of the JSON vs the flat nature of the puppet properties, this
    # is a bit of a manual task.
    @updated_json["name"] = @resource[:name]
    if @property_hash[:alias]
      @updated_json["alias"] = @property_hash[:alias]
    end
    [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday].each do |property|
      if @property_hash[property]
        @updated_json[property.to_s] = @property_hash[property]
      end
    end
    # Flush changes:
    put @updated_json.to_json,type

    if defined? @resource[:reload_opsview]
      if @resource[:reload_opsview].to_s == "true"
        Puppet.notice "Configured to reload opsview"
        do_reload_opsview
      else
        Puppet.notice "Configured NOT to reload opsview"
      end
    end

    @property_hash.clear
    @config_properties.clear

    false
  end

  def initialize(*args)
    super

    # Save the JSON for the config if it's present in the arguments
    if args[0].class == Hash and args[0].has_key?(:full_json)
      @opsview_json = args[0][:full_json]
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

    @config_properties = @property_hash.dup
  end

  # Return the current state of the tenancy in Opsview.
  def config_properties
    @config_properties.dup
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

  def default_config
    json = '
    {
         "alias" : "Puppet Managed Time Period",
         "name" : "Puppet Time Period"
    }'

    JSON.parse(json.to_s)
  end
end