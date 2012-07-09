# Class: ldap::server.pp
#
class ldap::server (
	$rootPW,
	$rootDN = "cn=admin,${ldap::baseDN}",
	$user = 'openldap',
	$group = 'openldap',
	$services = ['ldap:///', 'ldapi:///'],
	$daemon_options = [],
	$enable_ssl = false,
	$ca_certificate = false,
	$certificate = false,
	$certificate_key = false,
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
	service { 'slapd':
		ensure => running,
		require => Package['slapd'],
	}
	
	# Setup environment
	
	# Create the module vardir
	file { $moduledir :
		ensure => directory,
		owner => 'root',
		group => 'root',
		mode => '0750',
	}

	# Upload the conversion script for the schemas
	file { "${moduledir}/convertschema.sh":
		owner => 'root',
		group => 'root',
		mode => '0750',
		source => 'puppet:///modules/ldap/convertschema.sh',
		require => File[$moduledir],
	}
	
	# SSL/TLS configuration
	
	# Check if the certificate is set
	if ($certificate) {
		class { 'ldap::server::tls':
			ca_certificate => $ca_certificate,
			certificate => $certificate,
			certificate_key => $certificate_key,
		}
	}
	
	# Enable SSL (note this just enables port 636)
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
	
}

