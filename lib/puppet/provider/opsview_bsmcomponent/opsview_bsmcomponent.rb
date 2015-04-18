#

# This file is part of the Opsview puppet module
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

Puppet::Type.type(:opsview_bsmcomponent).provide :opsview, :parent => Puppet::Provider::Opsview do
  @req_type = 'bsmcomponent'

  mk_resource_methods

  def internal
    super
    resource[:internal]
  end
  def internal=(should)
  end

  def self.bsmcomponent_map(bsmcomponent)
    p = { :name      => bsmcomponent["name"],
          :hosttemplate => bsmcomponent["host_template"]["name"],
          :has_icon => bsmcomponent["has_icon"],
	  :required_online => (bsmcomponent["hosts"].count * ( bsmcomponent["quorum_pct"].to_f/100.0) ).round().to_s,
          :hosts => bsmcomponent["hosts"].collect{ |h| h["name"] },
          :full_json => bsmcomponent,
          :ensure    => :present }
    p
  end

  # Query the current resource state from Opsview
  def self.prefetch(resources)
    instances.each do |provider|
      if bsmcomponent = resources[provider.name]
        bsmcomponent.provider = provider
      end
    end
  end

  def self.instances
    providers = []

    # Retrieve all attributes.  Expensive query.
    bsmcomponents = get_resources

    bsmcomponents.each do |bsmcomponent|
      providers << new(bsmcomponent_map(bsmcomponent))
    end

    providers
  end

  # Apply the changes to Opsview
  def flush
    if @bsmcomponent_json
      @updated_json = @bsmcomponent_json.dup
    else
      @updated_json = default_bsmcomponent
    end
 
    # Update the BSM component's JSON values based on any new params.  Sadly due to the
    # structure of the JSON vs the flat nature of the puppet properties, this
    # is a bit of a manual task.

    @updated_json["host_template"]["name"] = @property_hash[:hosttemplate]
    if @property_hash[:hosts]
	@updated_json["hosts"] = @property_hash[:hosts].collect{ |h| { :name => h } }
    end

    if not @property_hash[:required_online].to_s.empty?
      calculated_pct = ('%.2f' % (   (@property_hash[:required_online].to_f/@property_hash[:hosts].count.to_f)*100.0)   ).to_f
      if (calculated_pct % 1 == 0.00)
              calculated_pct=calculated_pct.truncate
      end
      @updated_json["quorum_pct"] = calculated_pct
    end

    @updated_json["name"] = @resource[:name]
  
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
    @bsmcomponent_properties.clear

    false
  end

  def initialize(*args)
    super

    # Save the JSON for the attribute if it's present in the arguments
    if args[0].class == Hash and args[0].has_key?(:full_json)
      @bsmcomponent_json = args[0][:full_json]
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

    @bsmcomponent_properties = @property_hash.dup
  end

  # Return the current state of the attribute in Opsview.
  def bsmcomponent_properties
    @bsmcomponent_properties.dup
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

  def default_bsmcomponent
    json = '
      {  
         "name" : "PUPPET-COMPONENT",
         "has_icon": "0",
         "host_template" : {
            "name" : "Application - Opsview Master"
         },
         "hosts" : [
            {  
               "name" : "opsview"
            }
         ],
         "quorum_pct" : "100"
      }'

    JSON.parse(json.to_s)
  end
end
