ad_page_contract {
    Install packages -- actual installation

    @param install Tcl list of packages to install in the order in which they should be installed
} {
    {repository_url ""}
}


#####
#
# Display progress bar
#
#####

ad_progress_bar_begin \
    -title "Installing Packages" \
    -message_1 "Installing selected packages, please wait ..." \
    -message_2 "We will continue automatically when installation is complete."

#####
#
# Get packages to install
#
#####

apm_get_package_repository -repository_url $repository_url -array repository

set install [ad_get_client_property acs-admin install]
if { [llength $install] == 0 } {
    ns_log Notice "install-3.tcl: Nothing to install. Is this a double-click?"
}

# We unset the client property so we won't install these packages twice
ad_set_client_property acs-admin install {}


#
# Perform a topological sort for the right install order
#
set install_order ""
set to_install $install
ns_log notice "to_install: $to_install"

while {[llength $to_install] > 0} {

    foreach package_key $to_install {
	array unset version
	array set version $repository($package_key)

	set satisfied_p 1
	foreach req [concat $version(embeds) $version(extends) $version(requires)] {
	    lassign $req pkg req_version

	    #
	    # A package can be installed, when its requirements are
	    # installed before the package. All other dependencies
	    # were checked earlier.
	    #

	    if { $pkg in $to_install } {
		set satisfied_p 0
		#ns_log notice "we have to delay $pkg"
		break
	    }
	}
	if {$satisfied_p} {
	    lappend install_order $package_key
	    set pos [lsearch $to_install $package_key]
	    set to_install [lreplace $to_install $pos $pos]
	}
    }
    #ns_log notice "iteration: \nto_install: $to_install\ninstall_order: $install_order"
}

ns_log notice "Install packages in this order: $install_order"

#####
#
# Install packages
#
#####

set success_p 1

foreach package_key $install_order {
    ns_log Notice "Installing $package_key"
    
    array unset version
    array set version $repository($package_key)
    
    if { ([info exists version(download_url)] && $version(download_url) ne "") } {
        set spec_file [apm_load_apm_file -url $version(download_url)]
        if { $spec_file eq "" } {
            ns_log Error "Error downloading package $package_key from $version(download_url). Installing package failed."
            set success_p 0
            continue
        }
        set package_path "[apm_workspace_install_dir]/$package_key"
    } else {
        set spec_file $version(path)
        set package_path "$::acs::rootdir/packages/$package_key"
    }
        
    set final_version_name $version(name)

    if { [apm_package_version_installed_p $version(package.key) $version(name)] } {
        # Already installed.

        # Enable this version, in case it's not already enabled
        if { ![apm_package_enabled_p $version(package.key)] } {
            ns_log Notice "Package $version(package.key) $version(name) is already installed but not enabled, enabling"
            apm_version_enable -callback apm_dummy_callback [apm_highest_version $version(package.key)]
        } else {
            ns_log Notice "Package $version(package.key) $version(name) is already installed and enabled, skipping"
        }
        continue
    }

    # Determine if we are upgrading or installing.
    if { [apm_package_upgrade_p $package_key $final_version_name] == 1} {
        ns_log Debug "Upgrading package [string totitle $version(package-name)] to $final_version_name."
        set upgrade_p 1
        
        set initial_version_name [apm_highest_version_name $package_key]
    } else {
        set upgrade_p 0
        set initial_version_name ""
    }

    # Find out which script is appropriate to be run.
    set data_model_files [apm_data_model_scripts_find \
                                   -upgrade_from_version_name $initial_version_name \
                                   -upgrade_to_version_name $final_version_name \
                                   -package_path $package_path \
                                   $package_key]

    ns_log Debug "Data model scripts: \nupgrade_from_version_name = $initial_version_name\nupgrade_to_version_name=$final_version_name\npackage_path=$package_path\npackage_key=$package_key\n => $data_model_files"

    ns_write [subst {
	<p>Installing $package_key ...<br>
	<script>window.scrollTo(0,document.body.scrollHeight);</script>
    }]
    # Install the packages -- this actually copies the files into the
    # right place in the file system and backs up any old files
    set version_id [apm_package_install \
                        -enable \
                        -package_path $package_path \
                        -load_data_model \
                        -data_model_files $data_model_files \
                        $spec_file]
    
    if { $version_id == 0 } {
        # Installation of the package failed and we shouldn't continue with installation
        # as there might be packages depending on the failed package. Ideally we should
        # probably check for such dependencies and continue if there are none.
        set success_p 0
    } elseif {[file exists $::acs::rootdir/packages/$package_key/install.xml]} {
	ns_write "... configure $package_key<br>\n"
	#ns_log notice "===== RUN /packages/$package_key/install.xml"
	apm::process_install_xml /packages/$package_key/install.xml ""
	ns_write "... installation OK <br>\n"
    } else {
	ns_write "... installation OK <br>\n"
    }
    ns_write {
	<script>window.scrollTo(0,document.body.scrollHeight);</script>
    }
}

#####
#
# Done
#
#####

ad_progress_bar_end -url [export_vars -base install-4 { repository_url success_p }]


