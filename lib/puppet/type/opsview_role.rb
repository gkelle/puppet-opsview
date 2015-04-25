Puppet::Type.newtype(:opsview_role) do
  @doc = "Manages roles in an Opsview monitoring system."

  ensurable

  newparam(:name, :namevar => true) do
  end
  newparam(:reload_opsview) do
    desc "True if you want an Opsview reload to be performed when the
      role is updated."
    defaultto :false
  end

  newproperty(:internal) do
    desc "Internal use"
    defaultto 0
  end

  newproperty(:role) do
    desc "The name of this role."
    defaultto { @resource[:name] }
  end
  newproperty(:description) do
    desc "Short description of this role."
  end
  newproperty(:all_hostgroups, :boolean => true) do
    desc "Whether or not this role has access to all hostgroups.  Defaults
      to true."
   defaultto [true]
    munge do |value|
      if value == true
        value = "1"
      elsif value == false
        value = "0"
      end
    end

  end
  newproperty(:all_servicegroups, :boolean => true) do
    desc "Whether or not this role has access to all servicegroups.  Defaults
      to true."
    defaultto [true]
    munge do |value|
      if value == true
        value = "1"
      elsif value == false
        value = "0"
      end
    end

  end
  newproperty(:all_keywords, :boolean => true) do
    desc "Whether or not this role has access to all keywords.  Defaults
      to false."
    defaultto [false]
    munge do |value|
      if value == true
        value = "1"
      elsif value == false
        value = "0"
      end
    end
  end
  newproperty(:all_bsm_components, :boolean => true) do
    desc "Will grant view access to business services for authorised components.  Defaults
      to false."
    defaultto [false]
    munge do |value|
      if value == true
        value = "1"
      elsif value == false
        value = "0"
      end
    end
  end
  newproperty(:all_bsm_edit, :boolean => true) do
    desc "Whether or not this role has access to edit all bsm services.  Defaults
      to false."
    defaultto [false]
    munge do |value|
      if value == true
        value = "1"
      elsif value == false
        value = "0"
      end
    end
  end
  newproperty(:all_bsm_view, :boolean => true) do
    desc "Whether or not this role has access to view all bsm services.  Defaults
      to false."
    defaultto [false]
    munge do |value|
      if value == true
        value = "1"
      elsif value == false
        value = "0"
      end
    end
  end
  newproperty(:all_monitoringservers, :boolean => true) do
    desc "Whether or not this role has access to view all bsm services.  Defaults
      to false."
    defaultto [false]
    munge do |value|
      if value == true
        value = "1"
      elsif value == false
        value = "0"
      end
    end
  end

  newproperty(:access_hostgroups, :array_matching => :all) do
    desc "Array of hostgroups that this role can access."
    defaultto []
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end
  newproperty(:access_servicegroups, :array_matching => :all) do
    desc "Array of servicegroups that this role can access."
    defaultto []
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end
  newproperty(:access_keywords, :array_matching => :all) do
    desc "Array of keywords that this role can access."
    defaultto []
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end
  newproperty(:accesses, :array_matching => :all) do
    desc "Array of access properties defined for this role."
    defaultto []
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end
  newproperty(:business_services, :array_matching => :all) do
    desc "Array of authorized business service key pairs for this node"
    defaultto []

    def should_to_s(newvalue)
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.inspect
    end
    munge do |value|
    	if value["edit"].to_s.empty?
	  value["edit"] = "0"
	end
	value
    end
    validate do |value|
        unless not value["name"].to_s.empty?
          raise ArgumentError, "%s is not a valid business value access - needs name value" % value.inspect
	end
        unless value["edit"].to_s.empty? or value["edit"] =~ /^[01]$/
          raise ArgumentError, "%s is not a valid business value access - edit value must be 1 or 0" % value["edit"]
	end
    end
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is_temp=Array.new
	should_temp=Array.new
	is.each do |ha|
	  (is_temp << ha.sort_by{ |k,v| k})
	end
	@should.each do |ha|
	  (should_temp << ha.sort_by{ |k,v| k})
	end
	is_temp.sort == should_temp.sort
      else
        is == @should
      end
    end
  end

  newproperty(:hostgroups, :array_matching => :all) do
    desc "Array of hostgroups that this role can configure, if CONFIGUREHOSTS
      is defined in accesses."
    defaultto []
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end
  newproperty(:monitoringservers, :array_matching => :all) do
    desc "Array of hostgroups that this role can access."
    defaultto []
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end
  newproperty(:tenancy) do
    desc "Tenancy that the role is a member of"
  end
  autorequire(:opsview_hostgroup) do
    self[:hostgroups]
  end
  autorequire(:opsview_monitoringserver) do
    self[:monitoringservers]
  end
  autorequire(:opsview_bsmservice) do
    business_services = []
    if not self[:business_services].to_s.empty?
      self[:business_services].each do |bs|
        business_services << bs["name"]
      end
    end
    business_services
  end
  autorequire(:opsview_tenancy) do
    self[:tenancy]
  end

end
