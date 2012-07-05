#!/bin/sh

# Script to convert schema files to LDIF files
#
# OPTIONS:
#  -s	The input schema file to convert
#  -l	The resulting LDIF file
#  -d	A comma separated list of schema dependencies
#  -sd	The schema directory
#

SCHEMAFILE=""
LDIFFILE=""
DEPS=""
SCHEMADIR=""

while getopts "s:l:d:sd:" options; do
	case $options in
		s ) SCHEMAFILE=$OPTARG;;
		l ) LDIFFILE=$OPTARG;;
		d ) DEPS=$OPTARG;;
		sd ) SCHEMADIR=$OPTARG;;
		* ) echo "Specify input schema file with -s and output LDIF file with -l"
		    exit 1;;
	esac
done

# do we have -s?
if [ x${SCHEMAFILE} = "x" ]; then
	echo "Please specify a input schema file with -s"
	exit 1
fi

# do we have -l?
if [ x${LDIFFILE} = "x" ]; then
	echo "Please specify an output LDIF file with -l"
	exit 1
fi

# can we write to -l?
if [ -f ${LDIFFILE} ]; then
	if [ ! -w ${LDIFFILE} ]; then
		echo "Cannot write to ${LDIFFILE}"
		exit 1
	fi
else
	if [ ! -w `dirname ${LDIFFILE}` ]; then
		echo "Cannot write to `dirname ${LDIFFILE}` to create ${LDIFFILE}"
		exit 1
	fi
fi

# do we have -sd?
if [ x${SCHEMADIR} = "x" ]; then
	SCHEMADIR=/etc/ldap/schema
fi

# Get the base name of the schema file
BASENAME=`basename ${SCHEMAFILE} | cut -d'.' -f1`

# Create a temporary config file and directory to set the schemas to process
TEMPDIR=$(mktemp -d) || exit 1
TEMPFILE=$(tempfile -d ${TEMPDIR}) || exit 1

# Add all of the dependencies
for dep in `echo ${DEPS} | sed s/,/\\\n/g`; do
	if [ -f "${SCHEMADIR}/${dep}.schema" ]; then
		echo "include ${SCHEMADIR}/${dep}.schema" >> ${TEMPFILE}
	fi
done
echo "include ${SCHEMAFILE}" >> ${TEMPFILE}

# Determine the index of the schema
SCHEMAINDEX=$(slapcat -f ${TEMPFILE} -F ${TEMPDIR} -n 0 | grep "${BASENAME},cn=schema")
SCHEMADN=$(echo "${SCHEMAINDEX}" | sed 's/dn: //g')

# Convert the schema to LDIF format
slapcat -f ${TEMPFILE} -F ${TEMPDIR} -n 0 -H ldap:///${SCHEMADN} -l ${TEMPDIR}/cn=${BASENAME}.ldif || exit 1

# Remove index information
sed -e "s/{[0-9]*}${BASENAME}/${BASENAME}/g" \
	-e "/^structuralObjectClass:/d; /^entryUUID:/d; /^creatorsName:/d; /^createTimestamp:/d" \
	-e "/^entryCSN:/d; /^modifiersName:/d; /^creatorsName:/d; /^modifyTimestamp:/d" \
	${TEMPDIR}/cn=${BASENAME}.ldif > ${LDIFFILE}

# Cleanup resources
rm -rf -- "${TEMPDIR}"

