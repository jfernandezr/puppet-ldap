# Class: ldap::server.pp
#
class ldap::server (
	$rootDN = "cn=admin,${ldap::baseDN}",
	$rootPW,
	$user = 'openldap',
	$group = 'openldap',
	$enable_ssl = false,
	$services = ['ldap:///', 'ldapi:///'],
	$daemon_options = []
	) {
	
	# Module dependencies
	require ldap
	require preseed
	
	# Set the configuration values
	$moduledir = "${::puppet_vardir}/ldap"
	$schemadir = '/etc/ldap/schema'
	$ssldir = '/etc/ldap/ssl'
	$ldapvardir = '/var/lib/ldap'
	
	# Install the preseed packages
	preseed::package { 'slapd':
			ensure => installed,
			content => template('ldap/slapd.preseed.erb'),
	}
	
	# Run the server
	service {
		'slapd':
			ensure => running,
			require => Package['slapd'],
	}
	
	# Set the default configuration
	if ($enable_ssl) {
		$ssl_services = ['ldaps:///']
		$server_services = split(inline_template("<%= (services+ssl_services).join(',') %>"),',')
	} else {
		$server_services = $services
	}
	
	file {
		'/etc/default/slapd':
			content => template('ldap/etc.default.slapd.erb'),
			notify => Service['slapd'],
	}
	
	# Create the module vardir
	file {
		$moduledir :
			ensure => directory,
			owner => 'root',
			group => 'root',
			mode => '0750',
	}

	# Upload the conversion script
	file {
		"${moduledir}/convertschema.sh":
			owner => 'root',
			group => 'root',
			mode => '0750',
			source => 'puppet:///modules/ldap/convertschema.sh',
			require => File[$moduledir],
	}
}

