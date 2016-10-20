Puppet::Type.newtype(:opsview_contact) do
  @doc = "Manages contacts in an Opsview monitoring system"

  ensurable

  newparam(:name, :namevar => true) do
  end
  newparam(:reload_opsview) do
    desc "True if you want an Opsview reload to be performed when the
      contact is updated"
    defaultto :false
  end

  newproperty(:internal) do
    desc "Internal use"
    defaultto 0
  end

  newproperty(:fullname) do
    desc "Full name of the user"
  end
  newproperty(:description) do
    desc "Short description for the contact"
  end
  newproperty(:role) do
    desc "The role that the user is in.  Defaults are:
      Administrator
      View all, change none
      View all, change some
      View some, change none
      View some, change some"
  end
  newproperty(:encrypted_password) do
    desc "The user's encrypted password.  Defaults to \"password\" if not
      specified."
  end
  newproperty(:language) do
    desc "The user's language"
  end
  newproperty(:variables) do
    desc "A hash containing the contact notification variables and their values.  Example:
    ...
    variables => { 'EMAIL' => 'someone@example.com', 'PAGER' => '555-1234' },
    ..."
    validate do |value|
      unless value.nil? or value.is_a? Hash
        raise Puppet::Error, "the opsview_contact 'variables' property must be a Hash, not #{value.class}"
      end
    end
    # Only check for variables that are being defined in the manifest. Opsview
    # will automatically add all available variables to every contact, and this
    # allows us to only care about the variables we defined in the manifest.
    def insync?(is)
      is.delete_if {|k, v| true if not @should[0].has_key?(k)} if is.is_a? Hash
      super(is)
    end
  end

  newproperty(:notificationprofiles, :array_matching => :all) do
    desc "Array of notification key pairs for this node"

    def should_to_s(newvalue)
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.inspect
    end

    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        if is.first.keys.uniq.sort! != @should.first.keys.uniq.sort!
	  Puppet.debug "keys don't match - not in sync"
	  :false
	end
        Puppet.debug "in the type sync Before"
	is.first.keys.each do |key|
	  Puppet.debug "#{key} ::: #{is.first[key]} ---- #{@should.first[key]}"
          is.first[key].delete_if {|k, v| true if not @should.first[key].has_key?(k)}
	end
      end
      Puppet.debug "in the type sync After #{is} ^^^^^^^^^^^ #{@should}"
      super(is)
    end
  end

  autorequire(:opsview_role) do
    [self[:role]]
  end
  autorequire(:opsview_notificationmethod) do
    nms = []
#    if not self[:notificationmethods8x5].to_s.empty?
#      nms += self[:notificationmethods8x5]
#    end
#    if not self[:notificationmethods24x7].to_s.empty?
#      nms += self[:notificationmethods24x7]
#    end
    nms
  end
end
