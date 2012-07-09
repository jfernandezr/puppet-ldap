Puppet LDAP Module
==================

The Puppet LDAP module, `puppet-ldap`, installs the OpenLDAP LDAP server, allowing
SSL/TLS configuration, master-slave replication, and schema files importing into
the DIT. The code has been tested on Ubuntu Server 12.04 64bit.

Initializing the LDAP domain
----------------------------

This module only allows for a single LDAP domain installation, and has to be defined
separately from the server instance, allowing for future auth client implementation.

<pre>
# Initialize the LDAP domain information
class { 'ldap':
	domain => 'example.com',
	uri => 'ldap://ldap.example.com',
}
</pre>


Instantiating the server
------------------------

Once the LDAP domain is defined, we can instantiate a basic server with the `ldap::server`
class. The `enable_ssl` parameter indicates if it will listen to the SSL port, and requires
the certificates being set. The certificates can be set without SSL, as they can be used
with a TLS connection on the standard port.

<pre>
# Instantiate the server
class { 'ldap::server':
	rootPW => 'root_password_LDAP',
	enable_ssl => true,
	ca_certificate => 'puppet:///files/ldap/ssl/Example_Root_CA.pem',
	certificate => 'puppet:///files/ldap/ssl/example.pem',
	certificate_key => 'puppet:///files/ldap/ssl/example.key.pem',
}
</pre>


Converting and importing LDAP schemas
-------------------------------------

Once we have a LDAP server instance running, we can convert and import LDAP schemas. Those
schemas will be put on the default `/etc/ldap/schemas` directory and converted if needed.

This module ships with the following schema files:

- authldap.schema: Courier Mail Server authentication schema
- kerberos.schema: Novell Kerberos Schema Definitions v1.0
- samba.schema: Samba3 schema for storing Samba user accounts and group maps

So, in order to import one of those schemas, or add a different one, the `ldap::server::schema`
defined type must be used.

<pre>
# Add the needed schemas
ldap::server::schema { 'samba':
	source => 'puppet:///modules/ldap/samba.schema',
	deps => 'core,cosine,nis,inetorgperson'
}
</pre>


Setting indexes
---------------

When the schemas have been imported, it's convenient to set indexes to the database on the fields
used for searching. This is done by using the `ldap::server::index` defined type.

<pre>
# Set some indexes
class { 'ldap::server::index':
	indexes => [
		'objectClass eq',
		'uid pres,eq',
		'cn,sn,mail,givenName,displayName pres,eq,approx,sub',
		'sambaDomainName,sambaSID,sambaSIDList,sambaGroupType eq',
	]
} 
</pre>


Setting access rules
--------------------

Access rules are used to prevent sensitive information from leaking to other accounts. The rules
are set by using the `ldap::server::access` class.

<pre>
# Set the access rules
class { 'ldap::server::access':
	rules => [
		'to attrs=userPassword,shadowLastChange by self write by anonymous auth by dn="cn=admin,dc=example,dc=com" write by * none',
		'to dn.base="" by * read',
		'to * by self write by dn="cn=admin,dc=example,dc=com" write by * read',
	]
}
</pre> 


Replication
-----------

NOT YET COMPLETED

This module allows to set master-slave replication, with more than one slave node. The master
node should be defined as such.

<pre>
# Set the server as a sync provider
class { 'ldap::server::syncprov': }
</pre>

And the slave node can connect to the master by instantiating the `ldap::server::syncrepl` class,
specifying a unique numeric replica identifier. We reccomend that the server configuration is
the same in all nodes, regarding to access rules, passwords, etc.

<pre>
# Set the server as a sync consumer
class { 'ldap::server::syncrepl':
	replica_id => '900',
}
</pre>


Known issues
------------

* No proper check if generated .ldif file exists on the /etc/ldap/schemas directory
* It would be better to set the indexes on the server and schema definitions
* It's not possible to change the admin password once set
* Not possible yet to change the SSL certificates
* The SSL certificates could be set on the server instead of a separate class
* The access rules could be set on the server, but need to check dependencies. Maybe use of virtual resources triggered at the end of the server installation
* Maybe there is a bug on using the -d flag for the script convertschema.sh
* The replication synchronization fails on its first run, needs a restart, but we cannot trigger a notify on the service due to cycles in dependencies
* Missing completely the puppet module style guide


License
-------

This software is distributed under the GNU General Public License
version 3 or any later version.

Copyright
---------

Copyright (C) 2012 Juan Fernandez-Rebollos
