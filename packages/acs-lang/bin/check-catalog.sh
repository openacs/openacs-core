#!/bin/sh
#
# Check consistency of the en_US message catalog of the given package.
# Checks that the set of keys in the message catalog is identical to the
# set of keys in the adp, info, and tcl files in the package.
# Also checks that the info in the catalog filename matches info in
# its xml content (package_key, locale and charset).
#
# The scripts assumes that message lookups in adp and info files are 
# on the format #package_key.message_key#, and that message lookups 
# in tcl files are always done with the underscore procedure. 
#
# usage: check-catalog.sh package_key
#
# @author Peter Marklund (peter@collaboraid.biz)

### Functions start
check_catalog_keys_have_lookups() {

    # Check that all keys in the catalog file are either in tcl or adp or info files
    for catalog_key in $(${script_path}/mygrep '<msg key="([^"]+)"' catalog/${package_key}.en_US.ISO-8859-1.xml) 
    do 
        find -iname '*.tcl' | xargs ${script_path}/mygrep \
           "(?ms)\[_\s+(?:\[ad_conn locale\]\s+)?\"?${package_key}\.$catalog_key\"?" \
         || \
        find -regex '.*\.\(info\|adp\)' | xargs ${script_path}/mygrep \
           "#${package_key}\.$catalog_key#" \
         || \
        echo "Warning key $catalog_key in catalog file not found in any adp or tcl file"
    done
}

check_tcl_file_lookups_are_in_catalog() {

    # Check that all message lookups in tcl files have entries in the message catalog
    for tcl_message_key in $(find -iname '*.tcl'|xargs ${script_path}/mygrep \
                             "(?ms)\[_\s+(?:\[ad_conn locale\]\s+)?\"?${package_key}\.([a-zA-Z0-9_\-\.]+)\"?")
    do 
        egrep -q "<msg[[:space:]]+key=\"$tcl_message_key\"" catalog/${package_key}.en_US.ISO-8859-1.xml \
          || \
        echo "Warning: key $tcl_message_key not in catalog file" 
    done
}

check_adp_file_lookups_are_in_catalog() {

    catalog_file=catalog/${package_key}.en_US.ISO-8859-1.xml

    # Check that all message lookups in adp and info files are in the catalog file
    for adp_message_key in $(find -regex '.*\.\(info\|adp\)'|xargs ${script_path}/mygrep \
                            "#${package_key}\.([a-zA-Z0-9_\-\.]+)#")
    do 
        egrep -q "<msg[[:space:]]+key=\"$adp_message_key\"" $catalog_file \
          || \
        echo "Warning: key $adp_message_key not in catalog file"
    done
}
### Functions end

script_path=$(dirname $(which $0))
packages_dir="${script_path}/../../"

# Process arguments
if [ "$#" == "0" ]; then
    # No package provided - check all packages
    for catalog_dir in $(find $package_dir -iname catalog -type d)
    do
        # Recurse with each package key that has a catalog dir
        $0 $(basename $(dirname $catalog_dir))
    done

    exit 0

elif [ "$#" == "1" ]; then
    # Package key provided
    export package_key=$1
else
    echo "$0: Error - invoked with more than one argument, this script only accepts one argument, exiting."
    exit 1
fi

# Check that the catalog file exists
catalog_file_path="${packages_dir}${package_key}/catalog/${package_key}.en_US.ISO-8859-1.xml"
if [ ! -e $catalog_file_path ]; then
    echo "$0: Error - the file $catalog_file_path in package $package_key doesn't exist, exiting"
    exit 1
fi

package_path="${script_path}/../../${package_key}"
cd $package_path

echo "$0: $package_key - checking catalog file name"
${script_path}/check-catalog-file-path.pl $catalog_file_path

echo "$0: $package_key - checking catalog keys are in lookups"
check_catalog_keys_have_lookups $package_key

echo "$0: $package_key - checking tcl lookups are in catalog file"
check_tcl_file_lookups_are_in_catalog $package_key

echo "$0: $package_key - checking adp lookups are in catalog file"
check_adp_file_lookups_are_in_catalog $package_key
