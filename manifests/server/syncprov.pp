# Class:	ldap::server::syncprov
#
# Following instructions from
# https://help.ubuntu.com/12.04/serverguide/openldap-server.html#openldap-server-replication
#
class ldap::server::syncprov {

	# The sync provider only works for the server
	require ldap::server
	
	# Set variables
	$accesslogdir = "${ldap::server::ldapvardir}/accesslog"
	
	# Create the sync provider LDIF file
	file {
		"${ldap::server::moduledir}/syncprov.ldif":
			ensure => present,
			owner => 'root',
			group => 'root',
			mode => '0640',
			content => template('ldap/syncprov.ldif.erb'),
			require => File[$ldap::server::moduledir],
	}
	
	# Adjust the apparmor profile
	file {
		'/etc/apparmor.d/local/usr.sbin.slapd':
			ensure => present,
			owner => 'root',
			group => 'root',
			mode => '0644',
			content => template('ldap/usr.sbin.slapd.erb'),
	}
	exec {
		'syncprov-apparmor-reload':
			require => File['/etc/apparmor.d/local/usr.sbin.slapd'],
			command => "/usr/sbin/service apparmor reload",
			unless => "/usr/bin/test ! -f /etc/init.d/apparmor",
			subscribe => File['/etc/apparmor.d/local/usr.sbin.slapd'],
			refreshonly => true,
	}
	
	# Create the accesslog directory
	file {
		$accesslogdir:
			ensure => directory,
			owner => $ldap::server::user,
			group => $ldap::server::group,
			mode => '0750',
	}
	
	# Setup the DB_CONFIG file from the hdb
	exec {
		"ldap_sync_copy_DB_CONFIG":
			cwd => $accesslogdir,
			require => File[$accesslogdir],
			creates => "${accesslogdir}/DB_CONFIG",
			command => "/bin/cp -a ${ldap::server::ldapvardir}/DB_CONFIG ${accesslogdir}/DB_CONFIG",
			subscribe => File[$accesslogdir],
			refreshonly => true,
	}
	
	# Insert the LDIF into the LDAP DIT
	exec {
		"ldap_set_syncprov":
			cwd => $ldap::server::moduledir,
			require => File["${ldap::server::moduledir}/syncprov.ldif"],
			command => "${ldap::ldapadd} -Y external -H ldapi:/// -f ${ldap::server::moduledir}/syncprov.ldif",
			logoutput => on_failure,
			subscribe => File["${ldap::server::moduledir}/syncprov.ldif"],
			refreshonly => true,
	}
}

