ad_page_contract {
    Build package repository.
}

# TODO: anonymous cvs export the packages with a given CVS tag corresponding to the channel 
# (channel-5-0-oracle, channel-5-1-postgresql, etc.)



#####
#
# Read all package .info files, building manifest file
#
#####
set channel "[db_type]-5-0"

set repository_dir "/web/lars/www/repository/$channel/"
set repository_url "http://lars.cph02.collaboraid.net/repository/$channel/"

append manifest {<manifest>} \n

foreach spec_file [apm_scan_packages "[acs_root_dir]/packages"] {
    with_catch errmsg {
        array set version [apm_read_package_info_file $spec_file]
        
        append manifest {  } {<package>} \n
        
        append manifest {    } {<package-key>} [ad_quotehtml $version(package.key)] {</package-key>} \n
        append manifest {    } {<version>} [ad_quotehtml $version(name)] {</version>} \n
        append manifest {    } {<pretty-name>} [ad_quotehtml $version(package-name)] {</pretty-name>} \n
        append manifest {    } {<package-type>} [ad_quotehtml $version(package.type)] {</package-type>} \n
        
        set apm_file "${repository_dir}${version(package.key)}-${version(name)}.apm"
    
        set cmd [list exec [apm_tar_cmd] cf -  2>/dev/null]
        foreach file [apm_get_package_files -all_db_types -package_key $version(package.key)] {
            lappend cmd -C "[acs_root_dir]/packages"
            lappend cmd "$version(package.key)/$file"
        }
        
        lappend cmd "|" [apm_gzip_cmd] -c ">" $apm_file
        eval $cmd

        set apm_url "${repository_url}${version(package.key)}-${version(name)}.apm"

        append manifest {    } {<download-url>} $apm_url {</download-url>} \n
        foreach elm $version(provides) {
            append manifest {    } "<provides url=\"[ad_quotehtml [lindex $elm 0]]\" version=\"[ad_quotehtml [lindex $elm 1]]\" />" \n
        }
        
        foreach elm $version(requires) {
            append manifest {    } "<requires url=\"[ad_quotehtml [lindex $elm 0]]\" version=\"[ad_quotehtml [lindex $elm 1]]\" />" \n
        }
        
        append manifest {  } {</package>} \n
    } {
        global errorInfo
        ns_log Error "Error while checking package info file $spec_file: $errmsg\n$errorInfo"
    }
}
append manifest {</manifest>} \n

set fw [open "${repository_dir}manifest.xml" w]
puts $fw $manifest
close $fw

ns_return 200 text/html "OK"
        
