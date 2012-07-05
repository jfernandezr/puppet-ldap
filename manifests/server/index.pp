# type ldap::server::index
#

class ldap::server::index ($database = '{1}hdb,cn=config', $indexes) {
	
	# Require the LDAP server class
	require ldap::server
	
	# Compose the indexes LDIF file
	file {
		"${ldap::server::moduledir}/index-${database}.ldif":
			ensure => present,
			owner => 'root',
			group => 'root',
			mode => '0640',
			content => template('ldap/index.ldif.erb'),
			require => File[$ldap::server::moduledir],
	}
	
	# Insert the LDIF into the LDAP DIT
	exec {
		"ldap_set_index-${database}":
			cwd => $ldap::server::moduledir,
			require => File["${ldap::server::moduledir}/index-${database}.ldif"],
			command => "${ldap::ldapmodify} -c -Y external -H ldapi:/// -f ${ldap::server::moduledir}/index-${database}.ldif",
			logoutput => on_failure,
			subscribe => File["${ldap::server::moduledir}/index-${database}.ldif"],
			refreshonly => true,
	}
}
