ad_page_contract {
    Install from local file system
} {
    {package_type ""}
    {upgrade_p:boolean 0}
    {repository_url ""}
    {channel ""}
    {maturity:naturalnum ""}
    {current_channel}
    {head_channel}
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

if {$channel eq ""} {set channel $current_channel}
set fetch_url $repository_url/$channel/

apm_get_package_repository -repository_url $fetch_url -array repository

foreach package_key [array names repository] {
    array unset version
    array set version $repository($package_key)

    if {![info exists version(maturity)] || $version(maturity) eq ""} {
	set version(maturity) 0
    }

    #ns_log notice "$version(package.key) $repository($package_key)"
    #ns_log notice "compare $version(package.key) $version(maturity) < $maturity"
    if {$version(maturity) < $maturity} continue
    if {![apm_package_supports_rdbms_p -package_key $package_key]} continue

    if { $package_type eq "" || $version(package.type) eq $package_type } {
        set package_key $version(package.key)
         
	#
        # If in upgrade mode, only add to list if it's an upgrade, in
        # install-mode list only installs.
	#
        if { (!$upgrade_p && $version(install_type) eq "install")
	     || ($upgrade_p && $version(install_type) eq "upgrade")
	 } {

	    if {[info commands ::apm::package_version::attributes::maturity_int_to_text] ne ""} {
		set maturity_text [::apm::package_version::attributes::maturity_int_to_text $version(maturity)]
	    } else { 
		set maturity_text ""
	    }

            set package([string toupper $version(package-name)]) \
                [list \
                     $version(package.key) \
                     $version(package-name) \
                     $version(name) \
                     $version(package.type) \
                     $version(install_type) \
		     $version(summary) \
                     $maturity_text \
                     $version(vendor) \
                     $version(vendor.url) \
                     $version(owner) \
                     $version(owner.url) \
                     $version(release-date) \
                     $version(license) \
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

# Build the list-builder list
template::list::create \
    -name packages \
    -multirow packages \
    -key package_key \
    -bulk_actions {
        "Install or upgrade checked applications" "install-2" "Install or upgrade checked applications"
    } \
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
                {Current $current_channel}
                {Head $head_channel}
            }
            default_value $current_channel
        }

        maturity {
            label "Maturity at least"
            values {
                {New 0}
                {Immature 1}
                {Mature 2}
                {"Mature and Standard" 3}
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


