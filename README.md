MISSING

Ability to change the password like puppetlabs::mysql module, without loosing data (maybe call ldappasswd)

Change SSL certs?

Set the schemas as requirements (put the schema and ldif file on /etc/ldap/schema)


Set the execution order to set indexes after the schemas
	- DB
	- Schemas
	- Indexes
	- Access rules


Join the certificates, schemas and indexes on the server definition, maybe not the schemas as they have
several components


Maybe there is a bug on using the -d flag for the script convertschema.sh, no, seems not


When the repl sync is configured, it misses its chance to start, it needs a restart but cannot trigger a notify due to cycles in the dep graph

