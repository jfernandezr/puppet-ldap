# type ldap::server::access
#

class ldap::server::access ($database = '{1}hdb,cn=config', $rules) {
	
	# Require the LDAP server class
	require ldap::server
	
	# Compose the access rules LDIF file
	file {
		"${ldap::server::moduledir}/access-${database}.ldif":
			ensure => present,
			owner => 'root',
			group => 'root',
			mode => '0640',
			content => template('ldap/access.ldif.erb'),
			require => File[$ldap::server::moduledir],
	}
	
	# Insert the LDIF into the LDAP DIT
	exec {
		"ldap_set_access-${database}":
			cwd => $ldap::server::moduledir,
			require => File["${ldap::server::moduledir}/access-${database}.ldif"],
			command => "${ldap::ldapmodify} -c -Y external -H ldapi:/// -f ${ldap::server::moduledir}/access-${database}.ldif",
			logoutput => on_failure,
			subscribe => File["${ldap::server::moduledir}/access-${database}.ldif"],
			refreshonly => true,
	}
}
