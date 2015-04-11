Puppet::Type.newtype(:opsview_bsmcomponent) do
  @doc = "Manages BSM Components in an Opsview monitoring system"

  ensurable

  newparam(:name, :namevar => true) do
  end

  newparam(:reload_opsview) do
    desc "True if you want an Opsview reload to be performed when the component is updated"
    defaultto :false
  end
  
  newproperty(:quorum_percentage) do
    desc "The percentage of hosts that are required online"
    defaultto 100
  end

  newproperty(:has_icon) do
    desc "Set to zero if no icon available, otherwise number of seconds since icon was last updated"
    defaultto 0
  end

  newproperty(:hosts, :array_matching => :all) do
    desc "Array of Opsview hosts that should be applied to this component"
    defaultto []
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end

  newproperty(:hosttemplate) do
    desc "Opsview host template for BSM component"
  end

  autorequire(:opsview_hosttemplate) do
    self[:hosttemplate]
  end

  autorequire(:opsview_monitored) do
    [self[:hosts]]
  end

end
