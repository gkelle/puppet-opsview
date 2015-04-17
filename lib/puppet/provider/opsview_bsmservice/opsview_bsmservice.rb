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

Puppet::Type.type(:opsview_bsmservice).provide :opsview, :parent => Puppet::Provider::Opsview do
  @req_type = 'bsmservice'

  mk_resource_methods

  def internal
    super
    resource[:internal]
  end
  def internal=(should)
  end

  def self.bsmservice_map(bsmservice)
    p = { :name      => bsmservice["name"],
          :components => bsmservice["components"].collect{ |c| c["name"] },
          :full_json => bsmservice,
          :ensure    => :present }
    p
  end

  # Query the current resource state from Opsview
  def self.prefetch(resources)
    instances.each do |provider|
      if bsmservice = resources[provider.name]
        bsmservice.provider = provider
      end
    end
  end

  def self.instances
    providers = []

    # Retrieve all attributes.  Expensive query.
    bsmservices = get_resources

    bsmservices.each do |bsmservice|
      providers << new(bsmservice_map(bsmservice))
    end

    providers
  end

  # Apply the changes to Opsview
  def flush
    if @bsmservice_json
      @updated_json = @bsmservice_json.dup
    else
      @updated_json = default_bsmservice
    end
 
    # Update the BSM component's JSON values based on any new params.  Sadly due to the
    # structure of the JSON vs the flat nature of the puppet properties, this
    # is a bit of a manual task.

    if @property_hash[:components]
	@updated_json["components"] = @property_hash[:components].collect{ |c| { :name => c } }
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
    @bsmservice_properties.clear

    false
  end

  def initialize(*args)
    super

    # Save the JSON for the attribute if it's present in the arguments
    if args[0].class == Hash and args[0].has_key?(:full_json)
      @bsmservice_json = args[0][:full_json]
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

    @bsmservice_properties = @property_hash.dup
  end

  # Return the current state of the attribute in Opsview.
  def bsmservice_properties
    @bsmservice_properties.dup
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

  def default_bsmservice
    json = '
      {  
         "components" : [
            {
               "name" : "PUPPET-COMPONENT"
            }
         ],
         "name" : "PUPPET-SERVICE"
      }'

    JSON.parse(json.to_s)
  end
end
