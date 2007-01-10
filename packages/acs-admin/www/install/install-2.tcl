ad_page_contract {
    Install packages - dependency check
} {
    package_key:multiple
    {repository_url ""}
}

if { [llength $package_key] == 0 } {
    ad_returnredirct .
    ad_script_abort
}


#####
#
# Check dependencies
#
#####

apm_get_package_repository -repository_url $repository_url -array repository

array set result [apm_dependency_check_new \
                      -repository_array repository \
                      -package_keys $package_key]

switch $result(status) {
    ok {
        set continue_url [export_vars -base "install-3" { repository_url }]
        ad_set_client_property acs-admin install $result(install)
        set page_title "Confirm"
    }
    failed {
        set page_title "Missing Required Packages"
    }
    default {
        error "Bad status returned from apm_depdendency_check_new: '$result(status)'"
    }
}

if { $repository_url ne "" } {
    set parent_page_title "Install From OpenACS Repository"
} else {
    set parent_page_title "Install From Local File System"
}


set context [list [list "." "Install Software"] [list "install" $parent_page_title] $page_title]



#####
#
# Build list to display to user
#
#####

# Tells us whether there are any added or problematic packages in the list
set problems_p 0
set extras_p 0

array set failed $result(failed)

multirow create install package_key version_name package_name comment extra_p

foreach key $result(packages) {
    set extra_p [expr {[lsearch $package_key $key] == -1}]
    if { $extra_p } {
        set extras_p 1
    }

    if { [info exists failed($key)] } {
        set problems_p 1
        set comments {}
        foreach elm $failed($key) {
            lappend comments "[lindex $elm 0] [lindex $elm 1]"
        }
        set comment "Requires [join $comments "; "]"
    } else {
        set comment {}
    }

    array unset version
    array set version $repository($key)

    multirow append install \
        $key \
        $version(name) \
        $version(package-name) \
        $comment \
        $extra_p
}

template::list::create \
    -name install \
    -multirow install \
    -elements {
        package_name {
            label "Package"
        }
        version_name {
            label "Version"
        }
        comment {
            label "Error Message"
            hide_p {[ad_decode $problems_p 1 0 1]}
        }
        extra_p {
            label "Added"
            display_eval {[ad_decode $extra_p 1 "*" ""]}
            hide_p {[ad_decode $extras_p 1 0 1]}
            html { align center }
        }
    }

