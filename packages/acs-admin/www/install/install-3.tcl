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
    
    if { [info exists version(download_url)] && $version(download_url) ne "" } {
        ns_write [subst {
            <p>Transferring $version(download_url) ...
            <script nonce='$::__csp_nonce'>window.scrollTo(0,document.body.scrollHeight);</script>
        }]
        set spec_file [apm_load_apm_file -url $version(download_url)]
        if { $spec_file eq "" } {
            set msg "Error downloading package $package_key from $version(download_url). Installing package failed."
            ns_write [subst {
                <p>$msg
                <script nonce='$::__csp_nonce'>window.scrollTo(0,document.body.scrollHeight);</script>
            }]
            ns_log Error $msg
            set success_p 0
            continue
        }
        ns_write [subst {
            Done<br>
            <script nonce='$::__csp_nonce'>window.scrollTo(0,document.body.scrollHeight);</script>
        }]
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
	<script nonce='$::__csp_nonce'>window.scrollTo(0,document.body.scrollHeight);</script>
    }]
    
    # Install the package -- this actually copies the files into the
    # right place in the file system and backs up any old files

    set version_id [apm_package_install \
                        -enable \
                        -install_from_repository \
                        -package_path $package_path \
                        -load_data_model \
                        -data_model_files $data_model_files \
                        $spec_file]
    
    if { $version_id == 0 } {
        # Installation of the package failed and we shouldn't continue with installation
        # as there might be packages depending on the failed package. Ideally we should
        # probably check for such dependencies and continue if there are none.
        set success_p 0
    } else {
	ns_write "... installation OK <br>\n"
    }

    if {$success_p} {
        #
        # The update has finished successfully. Since all the new
        # files were sourced, the actual connection thread is already
        # up to date.  In order to provide this code to the other
        # threads, it is necessary to update the internal
        # blueprint. This works different in NaviServer and AOLserver,
        # and is supported only by NaviServer for the time being.
        #
        # Other options:
        #
        #   - run apm_package_install via "ns_eval": does not work,
        #     since "ns_eval" runs a script twice, a package can only
        #     be installed once.
        #        
        #   - run parts of apm_package_install: e.g. loading just the
        #     procs does not work, when it depends e.g. on package
        #     parameters, which have as well be updated in the
        #     blueprint.
        #
        #   - fix the behavior in AOLserver
        #
        if {[info commands ::nstrace::statescript] ne ""} {
            #
            # NaviServer variant:
            #   - nstrace::statescript produces the blueprint
            #   - "ns_ictl  save" updates it in the server
            #
            ns_ictl save [nstrace::statescript]
            ns_write "... blueprint updated <br>\n"
        } else {
            #
            # AOLserver: _ns_savenamespaces produces the update script
            # and updates the blueprint, .... but it kills the
            # internal state of the server. After running this
            # command, e.g. all ns_sets are gone, later commands run
            # into problems.
            #
            # _ns_savenamespaces
        }
    } else {
        #
        # At least one update has failed. Since it is not clear whether or
        # not library files were sourced, it is necessary to delete this
        # thread asap to avoid potential confusion with already updated
        # procs.
        #
        ns_ictl markfordelete
    }
    ns_write {
	<script nonce='$::__csp_nonce'>window.scrollTo(0,document.body.scrollHeight);</script>
    }
}

#####
#
# Done
#
#####

ad_progress_bar_end -url [export_vars -base install-4 { repository_url success_p }]


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
