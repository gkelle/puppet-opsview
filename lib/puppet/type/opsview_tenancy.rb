Puppet::Type.newtype(:opsview_tenancy) do
  @doc = "Manages tenancies in an Opsview monitoring system"

  ensurable

  newparam(:name, :namevar => true) do
  end

  newparam(:reload_opsview) do
    desc "True if you want an Opsview reload to be performed when the component is updated"
    defaultto :false
  end

  newproperty(:internal) do
    desc "Internal use"
    defaultto 0
  end

  newproperty(:primary_role) do
    desc "Primary role to use for tenancy"
  end

  newproperty(:priority) do
    desc "Priority"
  end

  autorequire(:opsview_role) do
    self[:primary_role]
  end

end
