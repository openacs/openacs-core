ad_library {

    Test procs in defined in tcl/acs-cache-procs.tcl

}

aa_register_case \
    -cats {api smoke} \
    -procs {
        acs::disk_cache_eval
        acs::disk_cache_flush
    } \
    disk_cache {

        Test the disk cache api

    } {
        set key __acs_tcl_test_disk_cache
        set id 1234
        set have_disk_cache_parameter [acs::dc call apm parameter_p -package_key acs_tcl -parameter_name DiskCache]

        if {!$have_disk_cache_parameter} {
            #
            # If the optional parameter "DiskCache" is not defined, we
            # cannot set it. Therefore, there will be errors in the
            # log file causing the test
            # "acs_kernel__server_startup_ok" to fail.  Therefore, we
            # give up in this case.
            #
            aa_log "Optional parameter DiskCache is NOT defined"
            return
        }

        aa_log "Flush everything first"
        acs::disk_cache_flush -key $key -id $id

        set cache_p [::parameter::get_from_package_key \
                         -package_key acs-tcl \
                         -parameter DiskCache \
                         -default 1]
        ns_log notice "cache_p $cache_p have_disk_cache_parameter $have_disk_cache_parameter"

        try {
            if {!$cache_p} {
                ::parameter::set_from_package_key \
                    -package_key acs-tcl \
                    -parameter DiskCache \
                    -value 1
            }

            set call {
                nsv_incr __test_acs_tcl_disk_cache exec
                expr {1 + 1}
            }

            aa_log "Execute the call"
            set result [acs::disk_cache_eval -call $call -key $key -id $id]

            aa_log "Flush the cache"
            acs::disk_cache_flush -key $key -id $id

            aa_log "Execute the call again"
            set result [acs::disk_cache_eval -call $call -key $key -id $id]

            aa_equals "Result is 2" $result 2

            aa_log "Execute the call again"
            set result [acs::disk_cache_eval -call $call -key $key -id $id]

            aa_equals "Code was executed only twice" \
                [nsv_get __test_acs_tcl_disk_cache exec] \
                2

        } finally {
            nsv_unset -nocomplain __test_acs_tcl_disk_cache

            try {
                ::parameter::set_from_package_key \
                    -package_key acs-tcl \
                    -parameter DiskCache \
                    -value $cache_p
            } on error {errmsg} {
                aa_log "'DiskCache' parameter not defined, nothing to reset."
            }
        }
    }
