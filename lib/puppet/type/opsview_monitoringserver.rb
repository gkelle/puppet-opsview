Puppet::Type.newtype(:opsview_monitoringserver) do
  @doc = "Manages distributed monitoring configuration in an Opsview monitoring system"

  ensurable

  newparam(:name, :namevar => true) do
  end

  newparam(:reload_opsview) do
    desc "True if you want an Opsview reload to be performed when the component is updated"
    defaultto :false
  end

  newproperty(:activated) do
    desc "Whether monitoring server is active or not"
    newvalues(:"0",:"1")
    defaultto :"0"
  end

  newproperty(:nodes, :array_matching => :all) do
    desc "Array of Opsview slave nodes that should be applied to this monitoring server"
    defaultto []
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
	is.sort == @should.sort
      else
        is == @should
      end
    end
  end

  newproperty(:passive) do
    desc "Whether configuration is sent to slave or not"
    newvalues(:"0",:"1")
    defaultto :"0"
  end

  newproperty(:ssh_tunnel) do
    desc "Type of SSH tunnel (forward [1] or reverse [0])"
    defaultto :"1"
    newvalues(:forward,:reverse,:"0",:"1")
    munge do |value|
      case value
      when :forward.to_s
       :"1"
      when :reverse.to_s
       :"0"
      else
       value
      end
    end
  end

  autorequire(:opsview_monitored) do
    self[:nodes].collect{|n| n["name"]}
  end

end
