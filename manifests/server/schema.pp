# Definition: ldap::server::schema
#
define ldap::server::schema($source, $deps = '') {
	
	# Require the LDAP server class
	require ldap::server
	
	# Create the schema file
	file {
		"${ldap::server::schemadir}/${name}.schema":
			ensure => present,
			owner => 'root',
			group => 'root',
			mode => '0644',
			source => $source,
			require => Package['slapd'],
	}
	
	# Create the LDIF file from the conversion script and insert the schema into the LDAP DIT
	exec {
		"convert_schema_${name}_to_ldif":
			cwd => $ldap::server::schemadir,
			require => [File["${ldap::server::schemadir}/${name}.schema"],Service['slapd']],
			creates => "${ldap::server::schemadir}/${name}.ldif",
			command => "${ldap::server::moduledir}/convertschema.sh -s ${name}.schema -l ${name}.ldif -d ${deps}; ${ldap::ldapadd} -Y external -H ldapi:/// -f ${name}.ldif",
			subscribe => File["${ldap::server::schemadir}/${name}.schema"],
			refreshonly => true,
	}

}
