Puppet::Type.newtype(:opsview_bsmservice) do
  @doc = "Manages BSM Services in an Opsview monitoring system"

  ensurable

  newparam(:name, :namevar => true) do
  end

  newparam(:reload_opsview) do
    desc "True if you want an Opsview reload to be performed when the component is updated"
    defaultto :false
  end

  newproperty(:components, :array_matching => :all) do
    desc "Array of Opsview BSM components that should be applied to this BSM service"
    defaultto []
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end

  autorequire(:opsview_bsmcomponent) do
    self[:components]
  end

end
