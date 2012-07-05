# Class: ldap::server::tls
#
class ldap::server::tls ($ssl_ca_certificate = undef, $ssl_certificate, $ssl_certificate_key) {

	# The SSL setting only works for the server
	require ldap::server
	
	# Copy the referred certificates
	file {
		$ldap::server::ssldir:
			ensure => directory,
			owner => 'root',
			group => $ldap::server::group,
			mode => '0750',
	}
	
	# If the CA certificate is undefined, use the system wide certs
	if ($ssl_ca_certificate) {
		$ca_certificate = basename($ssl_ca_certificate)
		$ca_certificate_file = "${ldap::server::ssldir}/${ca_certificate}"
		file {
			$ca_certificate_file:
				ensure => present,
				owner => 'root',
				group => $ldap::server::group,
				mode => '0644',
				source => $ssl_ca_certificate,
				require => File[$ldap::server::ssldir],
		}
	} else {
		$ca_certificate_file = '/etc/tls/certs/ca-certificates.crt'
		file {
			$ca_certificate_file:
				ensure => present,
		}
	}
	
	# The public certificate
	$certificate = basename($ssl_certificate)
	$certificate_file = "${ldap::server::ssldir}/${certificate}"
	file {
		$certificate_file:
			ensure => present,
			owner => 'root',
			group => $ldap::server::group,
			mode => '0644',
			source => $ssl_certificate,
			require => File[$ldap::server::ssldir],
	}
	
	# The certificate private key, unencrypted
	$certificate_key = basename($ssl_certificate_key)
	$certificate_key_file = "${ldap::server::ssldir}/${certificate_key}"
	file {
		$certificate_key_file:
			ensure => present,
			owner => 'root',
			group => $ldap::server::group,
			mode => '0640',
			source => $ssl_certificate_key,
			require => File[$ldap::server::ssldir],
	}
	
	# Compose the TLS LDIF file
	file {
		"${ldap::server::moduledir}/tls.ldif":
			ensure => present,
			owner => 'root',
			group => 'root',
			mode => '0640',
			content => template('ldap/tls.ldif.erb'),
			require => File[$ldap::server::moduledir, $certificate_file, $certificate_key_file],
	}
	
	# Insert the LDIF into the LDAP DIT
	exec {
		"ldap_set_tls":
			cwd => $ldap::server::moduledir,
			require => File["${ldap::server::moduledir}/tls.ldif"],
			command => "${ldap::ldapadd} -Y external -H ldapi:/// -f ${ldap::server::moduledir}/tls.ldif",
			subscribe => File["${ldap::server::moduledir}/tls.ldif"],
			refreshonly => true,
	}
}

