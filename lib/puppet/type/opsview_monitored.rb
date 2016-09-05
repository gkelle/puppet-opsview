Puppet::Type.newtype(:opsview_monitored) do
  @doc = "Monitors the node from an Opsview monitoring system"

  ensurable

  newparam(:name, :namevar => true) do
  end

  newparam(:reload_opsview) do
    desc "True if you want an Opsview reload to be performed when the host is updated"
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

  newproperty(:hostgroup) do
    desc "Opsview hostgroup"
  end

  newproperty(:ip) do
    desc "Node IP address or name"
  end

#Intervals
  [:check_interval, :notification_interval, :retry_check_interval].each do |property|
    newproperty(property) do
      desc "Interval parameter"
    end
  end

  newproperty(:hosttemplates, :array_matching => :all) do
    desc "Array of Opsview host templates that should be applied to this node"
    defaultto []
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.uniq.sort
      else
        is == @should
      end
    end
  end

  newproperty(:servicechecks, :array_matching => :all) do
    desc "Array of Opsview service checks that should be applied to this node"
    defaultto []
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.uniq.sort
      else
        is == @should
      end
    end
  end
  
  newproperty(:keywords, :array_matching => :all) do
    desc "Array of Opsview keywords should be applied to this node"
    defaultto []
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.uniq.sort
      else
        is == @should
      end
    end
  end

  newproperty(:notification_options) do
    desc "Notification options for host"
    validate do |value|
      unless value =~/^([udrf](,[udrf])*)?$/
        raise ArgumentError, "%s is not a valid notification option - input should be a comma-separated list of u,d,r,f" % value
      end
    end
    def insync?(is)
      if is != :absent and @should.is_a?(Array)
        is.split(",").sort == @should.first.split(",").sort
      else
        is == @should
      end
    end
  end

  newproperty(:notification_period) do
    desc "Notification period for host"
  end

   newproperty(:check_period) do
    desc "Check period for host"
  end
 
   newproperty(:check_attempts) do
    desc "Number of check attempts for host"
  end

  newproperty(:monitored_by) do
    desc "The Opsview server that monitors this node"
  end

  newproperty(:parents, :array_matching => :all) do
    desc "Array of parents for this node"
    defaultto []
    def insync?(is)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.uniq.sort
      else
        is == @should
      end
    end
  end

  newproperty(:enable_snmp) do
    desc "Whether or not SNMP is enabled for the host"
    defaultto "0" 
  end

  newproperty(:encrypted_snmp_community) do
    desc "Encrypted SNMP community string for SNMP protocol 1 and 2c"
    def insync?(is)
      is == should 
    end
  end

  newproperty(:snmp_community) do
    desc "SNMP community string for SNMP protocol 1 and 2c"
    def insync?(is)
      true
    end
  end

  newproperty(:snmp_version) do
    desc "SNMP protocol version"
    defaultto "3" 
  end

  newproperty(:snmp_port) do
    desc "SNMP port"
    defaultto "161" 
  end

  newproperty(:snmpv3_username) do
    desc "SNMP v3 username"
    defaultto ""
  end

  newproperty(:snmpv3_authpassword) do
    desc "SNMP v3 Auth Password (should be 8 chars)"
    defaultto ""
    def insync?(is)
      true
    end
  end

  newproperty(:encrypted_snmpv3_authpassword) do
    desc "Encrypted SNMP v3 Auth Password"
    defaultto ""
    def insync?(is)
      is == should
    end
  end

  newproperty(:snmpv3_authprotocol) do
    desc "SNMP v3 Auth Protocol (md5 or sha)"

    newvalue :md5
    newvalue :sha

    defaultto :md5
  end

  newproperty(:encrypted_snmpv3_privpassword) do
    desc "Encrypted SNMP v3 Priv Password"
    defaultto ""
    def insync?(is)
      is == should
    end
  end

  newproperty(:snmpv3_privpassword) do
    desc "SNMP v3 Priv Password (should be 8 chars)"
    defaultto ""
    def insync?(is)
      true
    end
  end

  newproperty(:snmpv3_privprotocol) do
    desc "SNMP v3 Priv Protocol (des, aes or aes128)"

    newvalue :des
    newvalue :aes
    newvalue :aes128

    defaultto :des
  end

  newproperty(:snmp_max_msg_size) do
    desc "SNMP message size (default, 1Kio, 2Kio, 4Kio, 8Kio, 16Kio, 42Kio, 64Kio)"
    newvalue :default
    newvalue :"1Kio"
    newvalue :"2Kio"
    newvalue :"4Kio"
    newvalue :"8Kio"
    newvalue :"16Kio"
    newvalue :"32Kio"
    newvalue :"64Kio"

    defaultto :default
  end

  newproperty(:tidy_ifdescr_level) do
    desc "Set level of removing common words from ifDescr strings"

    newvalue :off
    newvalue :"level1"
    newvalue :"level2"
    newvalue :"level3"
  
    defaultto :off
  end

  newproperty(:snmp_extended_throughput_data) do
    desc "Whether or not to gather extended data from interfaces (the unicast, multicasdt, broadcast stats)"
  end

  newproperty(:icon_name) do
    desc "Icon to set for the device"
  end

  newproperty(:check_command) do
    desc "Host check command"
  end

  newproperty(:hostattributes, :array_matching => :all) do
    desc "Array of host attribute key pairs for this node"
    defaultto []

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
	is_temp.sort == should_temp.sort
      else
        is == @should
      end
    end
  end

  newproperty(:snmpinterfaces, :array_matching => :all) do
    desc "Array of snmp interface key pairs for this node"

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
	is_temp.sort == should_temp.sort
      else
        is == @should
      end
    end
  end

  autorequire(:opsview_hostgroup) do
    [self[:hostgroup]]
  end

  autorequire(:opsview_hosttemplate) do
    self[:hosttemplates]
  end

  autorequire(:opsview_servicecheck) do
    self[:servicechecks]
  end
  
  autorequire(:opsview_monitored) do
    self[:parents]
  end
  
  autorequire(:opsview_keyword) do
    self[:keywords]
  end

  autorequire(:opsview_timeperiod) do
    self[:notification_period]
  end

  autorequire(:opsview_timeperiod) do
    self[:check_period]
  end

end
