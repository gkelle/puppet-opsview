Puppet::Type.newtype(:opsview_servicecheck) do
  @doc = "Manages servicechecks in an Opsview monitoring system"

  ensurable

  newparam(:name, :namevar => true) do
  end
  newparam(:reload_opsview) do
    desc "True if you want an Opsview reload to be performed when the
          servicecheck is updated"
    defaultto :false
  end

  newparam(:interval_mode) do
    desc "Controls how to calculate intervals (seconds versus minutes)"
    newvalues(:clever,:minutes,:seconds)
    munge do |value|
      [:check_interval, :notification_interval, :retry_check_interval].each do |property|
         if not resource[property].nil?
           if (value.to_s == "minutes" or (resource[property].to_i < 30 and value.to_s == "clever"))
             resource[property] = resource[property].to_i*60
             Puppet.debug "Munged #{resource} #{property.to_s}: #{resource[property]}"
	   end
         end
      end
      value
    end

    defaultto :clever
  end

  newproperty(:internal) do
    desc "Internal use"
    defaultto 0
  end

  newproperty(:checktype) do
    desc "Type of plugin"
    newvalues(:"Active Plugin",:"SNMP trap",:"Passive",:"SNMP Polling")
  end

  newproperty(:description) do
    desc "Short description for the servicecheck"
  end
  newproperty(:servicegroup) do
    desc "The servicegroup that this servicecheck belongs to.  This
          servicegroup must be defined in puppet."
  end
  newproperty(:dependencies, :array_matching => :all) do
    desc "Array of dependencies for this servicecheck"
    defaultto []
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end
  newproperty(:keywords, :array_matching => :all) do
    desc "Array of keywords for this servicecheck"
    defaultto []
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end

  #Fields for SNMP polling
  
  newproperty(:calculate_rate) do
    desc "SNMP polling Calculate Rate field"
    newvalues(:no, :per_second, :per_minute, :per_hour)
  end

  newproperty(:critical_comparison) do
    desc "SNMP polling Critical Comparison"
    newvalues(:numeric, :"==", :"<", :">", :separator, :string, :eq, :ne, :regex)
  end

  newproperty(:warning_comparison) do
    desc "SNMP polling Warning Comparison"
    newvalues(:numeric, :"==", :"<", :">")
  end

  newproperty(:label) do
    desc "Label for SNMP polling oid"
    validate do |value|
      unless value =~ /^[\w]{0,40}$/
        raise ArgumentError, "%s is not a valid label - did not match /^[\w]{0,40}$/" % value
      end
    end
  end

  newproperty(:oid) do
    desc "OID for SNMP Polling"
    validate do |value|
      unless value =~ /^.+$/
        raise ArgumentError, "%s is not a valid oid" % value
      end
    end
  end

  [:critical_value, :warning_value].each do |property|
    newproperty(property) do
      desc "General opsview polling servicecheck parameter"
    end
  end

  #Fields for notifications
  [:notification_options,:notification_period].each do |property|
    newproperty(property) do
      desc "General opsview polling servicecheck parameter"
    end
  end

  #Fields for advanced
  [:attribute, :event_handler, :flap_detection, :markdown_filter, :sensitive_arguments].each do |property|
    newproperty(property) do
      desc "General opsview advanced servicecheck parameter"
    end
  end

  newproperty(:alert_every_failure) do
    desc "Raises a notification on every failure, not just the first one"
    newvalues(:"0", :"1", :"2", :enable, :disable, :"enable with re-notification interval")
    munge do |value|
      case value
      when :enable.to_s
       :"1"
      when :disable.to_s
       :"0"
      when :"enable with re-notification interval".to_s
       :"2"
      else
       value
      end
    end
  end

  newproperty(:record_output_changes) do
    desc "Advanced Tab - Records output for a particular state"
  end

  #Fields for Passive checks

  newproperty(:action) do
    desc "Action to take when freshness timeout has been reached"
    newvalues(:set_stale,:renotify, /^[Rr]esend [Nn]otifications$/, /^[Ss]ubmit [Rr]esult$/)
    munge do |value|
      case value.to_s.downcase
      when "resend notifications"
       :renotify
      when "submit result"
       :set_stale
      else
       value
      end
    end
  end

  newproperty(:state) do
    desc "Action to take when freshness timeout has been reached"
    newvalues(:WARNING,:CRITICAL,:OK,:UNKNOWN,:"0", :"1", :"2", :"3")
    munge do |value|
      case value
      when :OK.to_s
       :"0"
      when :WARNING.to_s
       :"1"
      when :CRITICAL.to_s
       :"2"
      when :UNKNOWN.to_s
       :"3"
      else
       value
      end
    end
  end

  newproperty(:timeout) do
    desc "How many seconds before our results are stale"
    validate do |value|
      unless value =~ /^\d+[dmwhs]{0,1}(\s\d+[dmwhs]{0,1})*$/
        raise ArgumentError, "%s is not a valid timeout - valid examples are 5, 10s, 20m, 1h, 2d, 18h 20m" % value
      end
    end
    def insync?(is)
      @should_str = @should.join(" ")
      counter_should=0
      counter_is=-1
      if is != :absent
       counter_is = is.to_i
      end
      multiplier={ 'd' => 86400, 'h' => 3600, 'm' => 60, 'w' => 604800, 's' => 1 }
      @should_str.split(" ").each do |time|
        case time
	  when /([dmwhs]$)/
	    time.chop!
	    counter_should += multiplier[$1] * time.to_i
	  else
	    counter_should += time.to_i
	end
      end
      counter_is.to_i == counter_should.to_i
    end
  end

  newproperty(:alert_from_failure) do
    desc "General opsview passive servicecheck parameter"
    validate do |value|
      unless value =~ /^\d+$/
        raise ArgumentError, "%s is not a valid value. Please use a digit" % value
      end
    end

  end

  [:cascaded_from, :check_freshness, :text].each do |property|
    newproperty(property) do
      desc "General opsview passive servicecheck parameter"
    end
  end

  #Fields for SNMP Traps

  newproperty(:snmptraprules, :array_matching => :all) do
    desc "Array of snmptraprule key pairs for this node"

    def should_to_s(newvalue)
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.inspect
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
	is_temp == should_temp
      else
        is == @should
      end
    end
  end

  [:check_interval, :notification_interval, :retry_check_interval].each do |property|
    newproperty(property) do
      desc "Interval parameter"
    end
  end

  #General properties

  [:check_period, :check_attempts,
   :plugin, :args, :invertresults].each do |property|
    newproperty(property) do
      desc "General opsview servicecheck parameter"
    end
  end

  autorequire(:opsview_attribute) do
    [self[:attribute]]
  end
  
  autorequire(:opsview_servicegroup) do
    [self[:servicegroup]]
  end
  
  autorequire(:opsview_keyword) do
    [self[:keywords]]
  end
  
end
