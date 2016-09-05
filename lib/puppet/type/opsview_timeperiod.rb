Puppet::Type.newtype(:opsview_timeperiod) do
  @doc = "Manages timeperiods in an Opsview monitoring system"

  ensurable

  newparam(:name, :namevar => true) do
  end
  
  newparam(:reload_opsview) do
    desc "True if you want an Opsview reload to be performed when the servicegroup is updated"
    defaultto :false
  end

   newproperty(:internal) do
    desc "Internal use"
    defaultto 0
  end

  [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday].each do |property| 
    newproperty(property) do
      desc "Day of the week"
      validate do |value|
        unless value =~ /^(\d{2}:\d{2}-\d{2}:\d{2}(,\d{2}:\d{2}-\d{2}:\d{2})*)?$/
          raise ArgumentError, "%s is not a valid time period - format is HH:MM-HH:MM[,HH:MM-HH:MM][...] " % value
        end
      end
      defaultto ""
    end
  end

  newproperty(:alias) do
    desc "Description field"
  end
  
end
