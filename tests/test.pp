

node default {
	
	# Initialize the LDAP information
	class { 'ldap':
		domain => 'example.com',
		uri => 'ldap://ldap.example.com',
	}
	
	# Instantiate a server
	class { 'ldap::server':
		rootPW => 'root_password_LDAP',
		enable_ssl => true,
	}
	
	# Add the needed schemas
	ldap::server::schema { 'authldap':
		source => 'puppet:///modules/ldap/authldap.schema',
		deps => 'core,cosine,nis'
	}
	ldap::server::schema { 'samba':
		source => 'puppet:///modules/ldap/samba.schema',
		deps => 'core,cosine,nis,inetorgperson'
	}
	ldap::server::schema { 'kerberos':
		source => 'puppet:///modules/ldap/kerberos.schema',
		deps => 'core,cosine,nis'
	}
	
	# Set the indexes
	class { 'ldap::server::index':
		indexes => [
			'objectClass eq',
			'uid pres,eq',
			'cn,sn,mail,givenName,displayName pres,eq,approx,sub',
			'sambaDomainName,sambaSID,sambaSIDList,sambaGroupType eq',
			'uidNumber,gidNumber,uniqueMember,memberUid eq',
		]
	} 
	
	# Set the access rules
	class { 'ldap::server::access':
		rules => [
			'to attrs=userPassword,shadowLastChange by self write by anonymous auth by dn="cn=admin,dc=example,dc=com" write by * none',
			'to dn.base="" by * read',
			'to * by self write by dn="cn=admin,dc=example,dc=com" write by * read',
		]
	}
	
	# Set the TLS parameters
	# Note: make sure for the test that the files exist
	class { 'ldap::server::tls':
		ssl_ca_certificate => 'puppet:///files/ldap/ssl/Example_Root_CA.pem',
		ssl_certificate => 'puppet:///files/ldap/ssl/example.pem',
		ssl_certificate_key => 'puppet:///files/ldap/ssl/example.key.pem',
	}
	
	# Set the server as a sync provider
	class { 'ldap::server::syncprov': }
	
	# Set the server as a sync consumer
	#class { 'ldap::server::syncrepl':
	#	replica_id => '900',
	#}
}

