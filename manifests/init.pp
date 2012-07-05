# Class: ldap
#
class ldap ($domain, $uri) {

	# Module dependencies
	require stdlib

	# Set the specific distribution values
	$ldapadd = '/usr/bin/ldapadd'
	$ldapmodify = '/usr/bin/ldapmodify'

	# Compose some configuration default values
	$baseDN = regsubst("dc=${domain}", '[.]', ',dc=', 'G')

	# Install the required packages
	package { 'ldap-utils':
		ensure => installed
	}
}

