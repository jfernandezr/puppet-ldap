# Class: ldap::server::tls
#
class ldap::server::tls ($ca_certificate = undef, $certificate, $certificate_key) {

	# The TLS setting only works for the server
	require ldap::server
	
	# Copy the certificates to the SSL directory
	file { $ldap::server::ssldir:
		ensure => directory,
		owner => 'root',
		group => $ldap::server::group,
		mode => '0750',
	}
	
	# If the CA certificate is undefined, use the system wide certs
	if ($ca_certificate) {
		$ca_certificate_base = basename($ca_certificate)
		$ca_certificate_file = "${ldap::server::ssldir}/${ca_certificate_base}"
		file { $ca_certificate_file:
			ensure => present,
			owner => 'root',
			group => $ldap::server::group,
			mode => '0644',
			source => $ca_certificate,
			require => File[$ldap::server::ssldir],
		}
	} else {
		$ca_certificate_file = '/etc/ssl/certs/ca-certificates.crt'
		file { $ca_certificate_file:
			ensure => present,
		}
	}
	
	# The public certificate
	$certificate_base = basename($certificate)
	$certificate_file = "${ldap::server::ssldir}/${certificate_base}"
	file { $certificate_file:
		ensure => present,
		owner => 'root',
		group => $ldap::server::group,
		mode => '0644',
		source => $certificate,
		require => File[$ldap::server::ssldir],
	}
	
	# The certificate private key, unencrypted
	$certificate_key_base = basename($certificate_key)
	$certificate_key_file = "${ldap::server::ssldir}/${certificate_key_base}"
	file { $certificate_key_file:
		ensure => present,
		owner => 'root',
		group => $ldap::server::group,
		mode => '0640',
		source => $certificate_key,
		require => File[$ldap::server::ssldir],
	}
	
	# Compose the TLS LDIF file
	file { "${ldap::server::moduledir}/tls.ldif":
		ensure => present,
		owner => 'root',
		group => 'root',
		mode => '0640',
		content => template('ldap/tls.ldif.erb'),
		require => File[$ldap::server::moduledir, $certificate_file, $certificate_key_file],
	}
	
	# Insert the LDIF into the LDAP DIT
	exec { 'ldap_set_tls':
		cwd => $ldap::server::moduledir,
		require => File["${ldap::server::moduledir}/tls.ldif"],
		command => "${ldap::ldapadd} -Y external -H ldapi:/// -f ${ldap::server::moduledir}/tls.ldif",
		subscribe => File["${ldap::server::moduledir}/tls.ldif"],
		refreshonly => true,
	}
}

