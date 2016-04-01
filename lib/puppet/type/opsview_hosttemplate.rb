Puppet::Type.newtype(:opsview_hosttemplate) do
  @doc = "Manages hosttemplates in an Opsview monitoring system"

  ensurable

  newparam(:name, :namevar => true) do
  end
  
  newparam(:reload_opsview) do
    desc "True if you want an Opsview reload to be performed when the hosttemplate is updated"
    defaultto :false
  end

  newproperty(:internal) do
    desc "Internal use"
    defaultto 0
  end
 
  newproperty(:hosttemplate) do
    desc "This hosttemplate"
  end
  
  newproperty(:description) do
    desc "description for this hosttemplate"
  end
  
  newproperty(:servicechecks, :array_matching => :all) do
    desc "Array of servicechecks for this hosttemplate."
    defaultto []
    munge do |value|
     if value.is_a?(String)
       { "name" => value }
     else
       value
     end
    end
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is - @should == @should - is
      else
        is == @should
      end
    end
  end

  newproperty(:managementurls, :array_matching => :all) do
    desc "Array of management urls for this hosttemplate"
    defaultto []
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is - @should == @should - is
      else
        is == @should
      end
    end
  end
  
  autorequire(:opsview_servicecheck) do
    sc=Array.new
    self[:servicechecks].each do |name|    
      sc << name['name']
    end
    sc
  end
  
end
