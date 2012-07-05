# Class:	ldap::server::syncrepl
#
# Following instructions from
# https://help.ubuntu.com/12.04/serverguide/openldap-server.html#openldap-server-replication
#
class ldap::server::syncrepl ($replica_id) {

	# The sync provider only works for the server
	require ldap::server
	
	# Create the sync consumer LDIF file
	file {
		"${ldap::server::moduledir}/syncrepl.ldif":
			ensure => present,
			owner => 'root',
			group => 'root',
			mode => '0640',
			content => template('ldap/syncrepl.ldif.erb'),
			require => File[$ldap::server::moduledir],
	}

	# Insert the LDIF into the LDAP DIT
	exec {
		"ldap_set_syncrepl":
			cwd => $ldap::server::moduledir,
			require => [File["${ldap::server::moduledir}/syncrepl.ldif"], Service['slapd']],
			command => "${ldap::ldapadd} -Y external -H ldapi:/// -f ${ldap::server::moduledir}/syncrepl.ldif",
			logoutput => on_failure,
			subscribe => File["${ldap::server::moduledir}/syncrepl.ldif"],
			refreshonly => true,
	}
}

