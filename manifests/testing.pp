class opsview::attributevalidation {
	opsview_attribute {"MINIMUMATTRIBUTETEST":
		reload_opsview => false,
                ensure => present,
		value => 'This is the value',
	}

	opsview_attribute {"NORMALATTRIBUTETEST":
		reload_opsview => false,
                ensure => present,
		value => 'This is the value',
		arg1 => 'arg1',
		arg2 => 'arg2',
		arg3 => 'arg3',
		arg4 => 'arg4'
	}

	opsview_attribute {"BLANKENCRYPTEDATTRIBUTETEST":
		reload_opsview => false,
                ensure => present,
		value => 'This is the value',
		secured1 => 1,
		secured2 => 1,
		secured3 => 1,
		secured4 => 1
	}

	opsview_attribute {"ENCRYPTEDATTRIBUTETEST":
		reload_opsview => false,
                ensure => present,
		value => 'This is the value',
		label1 => 'label1',
		label2 => 'label2',
		label3 => 'label3',
		label4 => 'label4',
                encrypted_arg1 => 'b8a98ef9a82aa1012a8cbec292224ee4413c4a1b1343afe4f5adcb51191bd77c',
                encrypted_arg2 => 'b8a98ef9a82aa1012a8cbec292224ee4413c4a1b1343afe4f5adcb51191bd77c',
                encrypted_arg3 => 'b8a98ef9a82aa1012a8cbec292224ee4413c4a1b1343afe4f5adcb51191bd77c',
                encrypted_arg4 => 'b8a98ef9a82aa1012a8cbec292224ee4413c4a1b1343afe4f5adcb51191bd77c'
	}
}
class opsview::bsmvalidation {
	opsview_monitored {"bsmtesthost1":
		ensure => present,
		reload_opsview => false,
		ip => 'localhost',
		hostgroup => 'puppet-testing',
		hosttemplates => ['Network - Base']
	}
	opsview_monitored {"bsmtesthost2":
		ensure => present,
		reload_opsview => false,
		ip => 'localhost',
		hostgroup => 'puppet-testing',
		hosttemplates => ['Network - Base']
	}
	opsview_monitored {"bsmtesthost3":
		ensure => present,
		reload_opsview => false,
		ip => 'localhost',
		hostgroup => 'puppet-testing',
		hosttemplates => ['Network - Base']
	}

	opsview_bsmcomponent {"bsmcomponenttest1":
		ensure => present,
		hosts => [ "bsmtesthost1", "bsmtesthost2", "bsmtesthost3" ],
		hosttemplate => 'Network - Base',
		required_online => 2
	}
	opsview_bsmcomponent {"bsmcomponenttest2":
		ensure => present,
		hosts => [ "bsmtesthost1", "bsmtesthost3" ],
		hosttemplate => 'Network - Base',
		required_online => 2
	}

	opsview_bsmservice {"bsmservicetest1":
		reload_opsview => 'false',
		ensure => present,
		components => [ "bsmcomponenttest1", "bsmcomponenttest2"]
	}
	opsview_bsmservice {"bsmservicetest2":
		reload_opsview => 'false',
		ensure => present,
		components => [ "bsmcomponenttest2"]
	}


}

class opsview::hostvalidation {
	opsview_hostgroup {"puppet-testing":
		ensure => present,
		reload_opsview => false
	}
	opsview_monitored {"hostinterfacestest":
                ensure => present,
		reload_opsview => false,
		ip => 'localhost',
		hosttemplates => ['SNMP - MIB-II'],
		hostgroup => 'puppet-testing',
		enable_snmp => 1,
		snmp_version => "2c",
		notification_interval => 60,
		snmpinterfaces => [
{"interfacename"=>"", "active"=>"0", "discards_critical"=>"15", "errors_critical"=>"10", "throughput_critical"=>"0:50%", "throughput_warning"=>"0:25%"},
 {"interfacename"=>"Ethernet0/1", "active"=>"1", "discards_critical"=>"", "discards_warning"=>"", "errors_critical"=>"", "throughput_critical"=>"", "throughput_warning"=>""},
 {"interfacename"=>"Loopback0", "active"=>"1", "discards_critical"=>"", "discards_warning"=>"", "errors_critical"=>"", "throughput_critical"=>"", "throughput_warning"=>""},
 {"interfacename"=>"Null0", "active"=>"0", "discards_critical"=>"", "discards_warning"=>"", "errors_critical"=>"", "throughput_critical"=>"", "throughput_warning"=>""},
 {"interfacename"=>"Virtual-Access1", "active"=>"0", "discards_critical"=>"", "discards_warning"=>"", "errors_critical"=>"", "throughput_critical"=>"", "throughput_warning"=>""},
 {"interfacename"=>"Ethernet0/0", "active"=>"1", "discards_critical"=>"", "discards_warning"=>"", "errors_critical"=>"", "throughput_critical"=>"", "throughput_warning"=>""},
 {"interfacename"=>"Virtual-Access2", "active"=>"0", "discards_critical"=>"", "discards_warning"=>"", "errors_critical"=>"", "throughput_critical"=>"", "throughput_warning"=>""},
 {"interfacename"=>"Serial0/0", "active"=>"0", "discards_critical"=>"", "discards_warning"=>"", "errors_critical"=>"", "throughput_critical"=>"", "throughput_warning"=>""},
 {"interfacename"=>"Virtual-Template1", "active"=>"0", "discards_critical"=>"", "discards_warning"=>"", "errors_critical"=>"", "throughput_critical"=>"", "throughput_warning"=>""}
		]
	}


	opsview_monitored {"encryptedargtest":
                ensure => present,
		reload_opsview => false,
		ip => "localhost",
		hostgroup => 'puppet-testing',
		hostattributes => [
			{ name => "ENCRYPTEDATTRIBUTETEST", value => "/", encrypted_arg1 => 'c5aeaf4f0546ca70d6a89b9056eade8228162c8abcbc4e021c46a3a4309d1a7c'},
			{ name => "ENCRYPTEDATTRIBUTETEST", value => "/2", encrypted_arg2 => 'c5aeaf4f0546ca70d6a89b9056eade8228162c8abcbc4e021c46a3a4309d1a7c'},
			{ name => "ENCRYPTEDATTRIBUTETEST", value => "/3", encrypted_arg3 => 'c5aeaf4f0546ca70d6a89b9056eade8228162c8abcbc4e021c46a3a4309d1a7c'},
			{ name => "ENCRYPTEDATTRIBUTETEST", value => "/4", encrypted_arg4 => 'c5aeaf4f0546ca70d6a89b9056eade8228162c8abcbc4e021c46a3a4309d1a7c'},
		]
	}

}

class opsview::rolevalidation {
	opsview_role {"roletest1":
		ensure => present,
		description => 'Bare bones',
		reload_opsview => false,
	}
	opsview_role {"roletest2":
		ensure => present,
		reload_opsview => false,
		all_bsm_edit => true,
		all_bsm_view => true,
		all_bsm_components => true,
		all_monitoringservers => true,
		accesses => ['BSM','CONFIGUREBSM','CONFIGUREBSMCOMPONENT']
	}
	opsview_role {"roletest3":
		ensure => present,
		reload_opsview => false,
		accesses => ['BSM','CONFIGUREBSM','CONFIGUREBSMCOMPONENT'],
		business_services => [ { name => 'bsmservicetest1', edit => 1 }, {name => 'bsmservicetest2'} ],
		monitoringservers => ['Master Monitoring Server']
	}
}

class opsview::servicecheckvalidation {
	opsview_servicegroup {"puppet-testing":
		ensure => present
	}

	opsview_servicecheck {"activetest1":
		ensure => present,
		description => 'Bare bones',
		servicegroup => 'puppet-testing',
		reload_opsview => false,
		checktype => 'Active Plugin',
		plugin => 'check_tcp',
		args => '-H localhost -p 80'
	}

	opsview_servicecheck {"activetest2":
		ensure => present,
		description => 'Managed by puppet',
		servicegroup => 'puppet-testing',
		reload_opsview => false,
		interval_mode => clever,
		checktype => 'Active Plugin',
		plugin => 'check_tcp',
		args => '-H localhost -p 443',
		check_interval => '29'
	}

	opsview_servicecheck {"activetest3":
		ensure => present,
		description => 'Managed by puppet',
		servicegroup => 'puppet-testing',
		reload_opsview => false,
		interval_mode => clever,
		checktype => 'Active Plugin',
		plugin => 'check_tcp',
		args => '-H localhost -p 443',
		check_interval => '30'
	}


	opsview_servicecheck {"passivetest1":
		ensure => present,
		description => 'Bare bones',
		servicegroup => 'puppet-testing',
		reload_opsview => false,
		checktype => 'Passive',
	}

	opsview_servicecheck {"passivetest2":
		ensure => present,
		servicegroup => 'puppet-testing',
		reload_opsview => false,
		checktype => 'Passive',
		check_freshness => 1,
		cascaded_from => 'DHCP',
		action => 'Submit Result',
		timeout => '30h 10m',
		text => "This is the stale text"
	}

	opsview_servicecheck {"snmppolltest1":
		ensure => present,
		description => 'Bare bones',
		servicegroup => 'puppet-testing',
		reload_opsview => false,
		checktype => 'SNMP Polling',
	}

	opsview_servicecheck {"snmppolltest2":
		ensure => present,
		servicegroup => 'puppet-testing',
		reload_opsview => false,
		checktype => 'SNMP Polling',
		calculate_rate => 'per_second',
		oid => 'IF-MIB::ifInNUcastPkts.1',
		label => 'OidLabel',
		warning_value => 3,
		warning_comparison => '==',
		critical_value => 5,
		critical_comparison => '>'
	}

	opsview_servicecheck {"snmptraptest1":
		ensure => present,
		servicegroup => 'puppet-testing',
		reload_opsview => false,
		checktype => 'SNMP trap',
	}

	opsview_servicecheck {"snmptraptest2":
		ensure => present,
		servicegroup => 'puppet-testing',
		reload_opsview => false,
		checktype => 'SNMP trap',
		snmptraprules => [
				   {'action' => 'Send Alert', 'alert_level' => 'WARNING', 'message' => 'This is the message ${DUMP}', 'name' => 'Rule 2', 'rule' => '"${TRAPNAME} eq "trap"'},
				   {'action' => 'Stop Processing', 'alert_level' => 'CRITICAL', 'message' => 'This is the message ${DUMP}', 'name' => 'Rule 1', 'rule' => '"${TRAPNAME} eq "trap"'},
				   {'action' => 'Send Alert', 'alert_level' => 'WARNING', 'message' => 'This is the message ${DUMP}', 'name' => 'Rule 3', 'rule' => '"${TRAPNAME} eq "trap"'}
				]
	}

	opsview_servicecheck {"notificationtest":
		ensure => present,
		servicegroup => 'puppet-testing',
		reload_opsview => false,
		notification_options => 'r,f',
		notification_period => '24x7',
		notification_interval => '5'
	}

	opsview_servicecheck {"advancedtabtest":
		ensure => present,
		servicegroup => 'puppet-testing',
		reload_opsview => false,
		attribute => 'DISK',
		flap_detection => 0,
		sensitive_arguments => 0,
		record_output_changes => 'w,u,o',
		alert_every_failure => enable,
		event_handler => 'myeventhandler.sh',
		markdown_filter => 1
	}
}
class opsview::tenancyvalidation {
	opsview_tenancy {"tenancytest":
		ensure => present,
		description => 'Managed by puppet',
		reload_opsview => false,
		primary_role => 'roletest1',
	}
	opsview_role {"tenancyroletest1":
		ensure => present,
		reload_opsview => false,
		tenancy => 'tenancytest'
	}
}

class opsview::hosttemplatevalidation {
	opsview_hosttemplate { 'Puppet - Host Template - Validation':
	  ensure         => 'present',
	  description    => 'Puppet validation',
	  servicechecks  => [{'name' => 'Unix Load Average'}, {'exception' => '-H $HOSTADDRESS$ -c check_memory -a \'-w 50 -c 98\'', 'name' => 'Unix Memory'}, {'name' => 'Unix Swap'},{'name' => 'Disk'}]
	}

}

class opsview::hosttemplatevalidation {
	opsview_hosttemplate { 'Puppet - Host Template - Validation2':
	  ensure         => 'present',
	  description    => 'Puppet validation',
	  servicechecks  => ['Unix Load Average', 'Unix Memory', {'name' => 'DHCP', 'exception' => '-H $HOSTADDRESS$'}, 'Unix Swap','Disk']
	}

}
