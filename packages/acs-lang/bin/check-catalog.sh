#!/bin/sh
#
# Check consistency of the en_US message catalog of the given package.
# Checks that the set of keys in the message catalog is identical to the
# set of keys in the adp, info, and tcl files in the package.
# The scripts assumes that message lookups in adp and info files are 
# on the format #package_key.message_key#, and that message lookups 
# in tcl files are always done with the underscore procedure. 
#
# usage: check-catalog.sh package_key
#
# @author Peter Marklund (peter@collaboraid.biz)

script_path=$(dirname $(which $0))

export package_key=$1
package_path="${script_path}/../../${package_key}"

cd $package_path

# Check that all keys in the catalog file are either in tcl or adp or info files
for catalog_key in $(${script_path}/mygrep '<msg key="([^"]+)"' catalog/${package_key}.en_US.ISO-8859-1.xml); do find -iname '*.tcl'|xargs ${script_path}/mygrep "(?ms)\[_\s+(?:\[ad_conn locale\]\s+)?\"?${package_key}\.$catalog_key\"?" || find -regex '.*\.\(info\|adp\)'|xargs ${script_path}/mygrep "#${package_key}\.[a-zA-Z0-9_\.]+#" || echo "Warning key $catalog_key in catalog file not found in any adp or tcl file"; done

# Check that all message lookups in tcl files have entries in the message catalog
for tcl_message_key in $(find -iname '*.tcl'|xargs ${script_path}/mygrep '(?ms)\[_\s+(?:\[ad_conn locale\]\s+)?"?${package_key}\.([a-zA-Z0-9_\.]+)"?'); do grep -L $tcl_message_key catalog/${package_key}.en_US.ISO-8859-1.xml || echo "Warning: key $tcl_message_key not in catalog file"; done

# Check that all message lookups in adp and info files are in the catalog file
for adp_message_key in $(find -regex '.*\.\(info\|adp\)'|xargs ${script_path}/mygrep '#${package_key}\.([a-zA-Z0-9_\.]+)#'); do grep -L $adp_message_key catalog/${package_key}.en_US.ISO-8859-1.xml || echo "Warning: key $adp_message_key not in catalog file"; done
