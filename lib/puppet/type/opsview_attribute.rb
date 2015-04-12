Puppet::Type.newtype(:opsview_attribute) do
  @doc = "Manages attributes in an Opsview monitoring system"

  ensurable

  newparam(:name, :namevar => true) do
  end

  newparam(:reload_opsview) do
    desc "True if you want an Opsview reload to be performed when the attribute is updated"
    defaultto :false
  end
  
  newproperty(:attribute) do
    desc "The name of the attribute to manage"
    defaultto { @resource[:name] }
  end
  
  newproperty(:value) do
    desc "Optional default attribute value."
  end

  newproperty(:label1) do
    desc "Optional label 1 value."
  end

  newproperty(:label2) do
    desc "Optional label 2 value."
  end

  newproperty(:label3) do
    desc "Optional label 3 value."
  end

  newproperty(:label4) do
    desc "Optional label 4 value."
  end

  newproperty(:secured1) do
    desc "Optional secured 1 value."
  end

  newproperty(:secured2) do
    desc "Optional secured 2 value."
  end

  newproperty(:secured3) do
    desc "Optional secured 3 value."
  end

  newproperty(:secured4) do
    desc "Optional secured 4 value."
  end

  newproperty(:arg1) do
    desc "Optional argument 1 value."
  end

  newproperty(:encrypted_arg1) do
    desc "Optional encrypted argument 1 value."
  end

  newproperty(:arg2) do
    desc "Optional argument 2 value."
  end

  newproperty(:encrypted_arg2) do
    desc "Optional encrypted argument 2 value."
  end

  newproperty(:arg3) do
    desc "Optional argument 3 value."
  end

  newproperty(:encrypted_arg3) do
    desc "Optional encrypted argument 3 value."
  end

  newproperty(:arg4) do
    desc "Optional argument 4 value."
  end

  newproperty(:encrypted_arg4) do
    desc "Optional encrypted argument 4 value."
  end

end
