ad_library {

    Tests for resource_info dicts and functions

}

aa_register_case \
    -cats {api smoke} \
    -procs {
        ::util::resources::resource_info_procs
    } \
    resource_info_dicts {
    } {
        set required_members {
            cdn
            cdnHost
            configuredVersion
            cssFiles
            extraFiles
            jsFiles
            parameterInfo
            prefix
            resourceDir
            resourceName
            urnMap
        }
        set optional_members {
            cspMap
            downloadURLs
            versionCheckAPI
            vulnerabilityCheck
        }
        foreach resource_info_proc [::util::resources::resource_info_procs] {
            set resource_info [$resource_info_proc]
            foreach member $required_members {
                aa_true "$resource_info_proc resource_info contains $member" {$member in $required_members}
            }
            foreach key [dict keys $resource_info] {
                if {$key ni $required_members && $key ni $optional_members} {
                    aa_log "$resource_info_proc resource_info contains unexpected member '$key'"
                }
            }
            if {[dict exists $resource_info urnMap] && [dict get $resource_info urnMap] ne ""} {
                aa_true "$resource_info_proc resource_info cspMap exists" [dict exists $resource_info cspMap]
                if {[dict exists $resource_info cspMap] && [dict get $resource_info cdnHost] ne ""} {
                    aa_true "$resource_info_proc resource_info cspMap must not be empty" {[dict get $resource_info cspMap] ne ""}
                }
            }
        }

    }
