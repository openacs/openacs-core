ad_page_contract {
    Install from local file system
} {
    {package_type ""}
    {upgrade_p:boolean 0}
    {repository_url "http://openacs.org/repository/"}
    {channel ""}
    {maturity:naturalnum ""}
    {current_channel ""}
    {head_channel ""}
}


if {$current_channel eq ""} {
    set current_channel [apm_get_repository_channel]
    set channel $current_channel
}
if {$head_channel eq ""} {
    set head_channel [lindex [apm_get_repository_channels] 0 0]
}

#
# In upgrade mode, offer per default all maturities, in install-mode,
# start with mature packages.
#

if {$upgrade_p} {
    set default_maturity 0
} else {
    set default_maturity 2
}

if {$maturity eq ""} {
    set maturity $default_maturity
}

#
# Set page title to reflect install from repository or from file system
#

if { $repository_url ne "" } {
    set page_title "Install or Upgrade From OpenACS Repository"
} else {
    set page_title "Install or Upgrade From Local File System"
}

set context [list [list "." "Install Software"] $page_title]


#####
#
# Get list of packages available for install/upgrade
#
#####

apm_get_installed_versions -array installed_versions
set upgrades_p 0
array set package [list]

if {$channel eq ""} {
    set channel $current_channel
}

if {[regexp {^(.*/)(\d+-\d+)/$} $repository_url . base_url passed_in_channel]} {
    #
    # The passed in repository_url has already a channel
    #
    set fetch_url $repository_url
} else {
    #
    # The passed in repository_url has no channel
    #
    set base_url  $repository_url
    set fetch_url $base_url/$channel/
}

apm_get_package_repository -repository_url $fetch_url -array repository

if {$channel ne $current_channel} {
    apm_get_package_repository -repository_url $base_url/$current_channel/ -array current_repository
}

foreach package_key [array names repository] {
    set version $repository($package_key)
    #
    # Ignore the package in the following cases:
    #  - maturity is below specified level
    #  - package is deprecated
    #  - package is not supported by the installed database
    #  - don't offer "-portlet" alone (currently only useful in connection with DotLRN)
    #  - dont't offer packages of HEAD, when these are included in the current channel
    #
    if {[dict get $version maturity] < $maturity
	|| [dict get $version maturity] == 4
	|| ![apm_package_supports_rdbms_p -package_key $package_key]
	|| [string match "*-portlet" $package_key]
        || ($channel ne $current_channel && [info exists current_repository($package_key)])
    } continue

    if { $package_type eq "" || [dict get $version package.type] eq $package_type } {
	#
        # If in upgrade mode, only add to list if it's an upgrade, in
        # install-mode list only installs.
	#
        if { (!$upgrade_p && [dict get $version install_type] eq "install")
	     || ($upgrade_p && [dict get $version install_type] eq "upgrade")
	 } {
            set package([string toupper [dict get $version package-name]]) \
                [list $package_key \
                     [dict get $version package-name] \
                     [dict get $version name] \
                     [dict get $version package.type] \
                     [dict get $version install_type] \
		     [dict get $version summary] \
		     [::apm::package_version::attributes::maturity_int_to_text [dict get $version maturity]] \
                     [dict get $version vendor] \
                     [dict get $version vendor.url] \
                     [dict get $version owner] \
                     [dict get $version owner.url] \
                     [dict get $version release-date] \
                     [dict get $version license] \
		    ]
        }
    }
}


#####
#
# Output the list
#
#####

# Sort the list alphabetically (in case package_name and package_key doesn't sort the same)
multirow create packages package_key package_name version_name package_type install_type summary \
    maturity vendor vendor_url owner owner_url release_date license 

if {[catch {set maturity_label [apm::package_version::attributes::get_pretty_name maturity]} errmsg]} {
    set maturity_label "Maturity"
}

foreach name [lsort -ascii [array names package]] {
    multirow append packages {*}$package($name)
}

multirow extend packages install_url
multirow -unclobber foreach packages {
    set install_url [export_vars -base install-2 { package_key {repository_url $fetch_url}}]
}

set operation_label [expr {$upgrade_p ? "Upgrade" : "Install"}]

# Build the list-builder list
template::list::create \
    -name packages \
    -multirow packages \
    -key package_key \
    -bulk_actions [list \
                       "$operation_label checked applications" \
                       "install-2" \
                       "$operation_label checked applications" ] \
    -bulk_action_export_vars {
        {repository_url $fetch_url}
    } \
    -elements {
        package_name {
            label "Package"
            link_url_col install_url
            link_html { title "Install or upgrade this package" }
        }
        summary {
            label "Summary"
	    display_template {@packages.summary@<br>
		Vendor: <if @packages.vendor_url@ nil>@packages.vendor@</if>
		        <else><a href=" @packages.vendor_url@">@packages.vendor@</a></else>
		        <if @packages.release_date@ not nil> (released on @packages.release_date@<if @packages.license@ not nil>, license: @packages.license@</if>)</if>
		<br>
		Details: <a href="http://openacs.org/xowiki/@packages.package_key@">@packages.package_key@</a>
	    }
        }   
        maturity {
	    label "$maturity_label"
        }
        version_name {
            label "Version"
        }
        package_type {
            label "Type"
            display_eval {[ad_decode $package_type "apm_application" "Application" "Service"]}
        }
        upgrade {
            label "Upgrade"
            hide_p {[ad_decode $upgrades_p 1 0 1]}
            display_eval {[ad_decode $install_type "upgrade" "Upgrade" ""]}
        }
    } -filters {
        channel {
            label "Channel"
            values {
                {"$current_channel" $current_channel}
                {"Supplemental" $head_channel}
            }
            default_value $current_channel
        }

        maturity {
            label "Maturity at least"
            values {
                {"[_ acs-tcl.maturity_new_submission]" 0}
                {"[_ acs-tcl.maturity_immature]" 1}
                {"[_ acs-tcl.maturity_mature]" 2}
                {"[_ acs-tcl.maturity_mature_and_standard]" 3}
            }
	    default_value default_maturity
        }

        package_type {
            label "Type"
            values {
                {Application apm_application}
                {Service apm_service}
            }
        }
        upgrade_p {
            label "Upgrade"
            values {
                {"Install" 0}
                {"Upgrade" 1}
            }
            default_value 0
        }
        repository_url  { hide_p 1 }
        current_channel { hide_p 1 }
        head_channel    { hide_p 1 }
    }



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
