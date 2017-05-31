ad_page_contract {

    Do a dependency check of the install.

    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date Mon Oct  9 00:13:43 2000
    @cvs-id $Id$
} {
    {package_key:multiple ""}
    {force_p:boolean "f"}
}

set title "Package Installation"
set context [list [list "/acs-admin/apm/" "Package Manager"] $title]

# Clear out previous client properties.
ad_set_client_property -clob t apm pkg_install_list ""

if {$package_key eq ""} {
    set body {
        <p>
        No packages selected.<p>
    }
} else {

    #####
    #
    # Check dependencies
    #
    #####
    apm_get_package_repository -array repository
    apm_get_installed_versions -array installed

    set install_pkgs $package_key
    while 1 {
        set fixpoint_p 1

        ns_log notice "run apm_dependency_check_new with <$install_pkgs>"
        array set result [apm_dependency_check_new \
                              -repository_array repository \
                              -package_keys $install_pkgs]
        #ns_log notice "RESULT of apm_dependency_check_new: [array get result]"

        array set failed $result(failed)
      
        switch $result(status) {
            ok {
                set title "Confirm"
            }
            failed {
                set title "Missing Required Packages"
            }
            default {
                error "Bad status returned from apm_depdendency_check_new: '$result(status)'"
            }
        }

        #
        # Get the package info list with potential unresolved dependencies
        #
        set pkg_info_list {}
        foreach pkg $result(packages) {
            
            #
            # Load package info from spec file. 
            #
            unset -nocomplain spec_file
            if {[catch {set spec_file [apm_package_info_file_path $pkg]}]} {
                set workspace_dir [apm_workspace_install_dir]
                if {[catch {set spec_file [apm_package_info_file_path -path $workspace_dir $pkg]}]} {
                    #
                    # In case the spec file is not found (unknown package)
                    # produce an empty entry.
                    #
                    array set package [list package.key $pkg embeds "" extends "" \
                                           provides "" requires "" properties {install ""}]
                }                    
            }

            if {[info exists spec_file]} {
                array set package [apm_read_package_info_file $spec_file]
            } else {
                ad_return_complaint 1 "Could not find .info file of dependency: $pkg."
                ad_script_abort
            }

            if {[info exists failed($pkg)]} {
                set comments {}
                foreach e $failed($pkg) {
                    lappend comments "Requires: [lindex $e 0] [lindex $e 1]"
                }
                set flag f
            } else {
                lassign {t ""} flag comments
                array set properties $package(properties)
                
                set must_add {}
                foreach p $properties(install) {
                    if {$p ni $install_pkgs && ![info exists installed($p)]} {
                        #ns_log notice "+++ install_pkgs <$p> ni <$install_pkgs> and not already installed"
                        lappend must_add $p
                    }
                }
                if {[llength $must_add] > 0} {
                    ns_log notice "+++ install_pkgs <$install_pkgs> after must_add <$must_add>"
                    lappend install_pkgs {*}$must_add
                    set fixpoint_p 0
                    break
                }
            }
            lappend pkg_info_list [pkg_info_new $package(package.key) \
                                       $spec_file \
                                       $package(embeds) \
                                       $package(extends) \
                                       $package(provides) \
                                       $package(requires) \
                                       $flag $comments]
        }
        if {$fixpoint_p} break
    }

    #
    # When the package list was extended by the dependency test, show
    # it again to the user
    #

    if {$result(status) eq "ok" && [llength $result(install)] > [llength $package_key]} {

        set body [subst {
            <h2>Additional Packages Automatically Added</h2><p>
            
            Some of the packages you were trying to install required
            other packages to be installed first.  We've added these
            additional packages needed, and ask you to review the list
            of packages below.

            <form action="packages-install-2" method="post">
        }]

        append body [apm_package_selection_widget $pkg_info_list $result(install)]
        append body [subst {
            <div><input type="submit" value="Select Data Model Scripts"></div>
            </form>
        }]
        
    } elseif {$result(status) eq "ok" || $force_p} {
        
        # We use client properties to pass along this information as
        # it is fairly large.
        ad_set_client_property -clob t apm pkg_install_list $pkg_info_list

        ad_returnredirect packages-install-3
        ad_script_abort

    } else {

        ### Check failed.  Offer user an explanation and an ability to
        ### select unselect packages.

        #[export_vars -form {package_key}]<p>

        set body [subst {

            <h2>Unsatisfied Dependencies</h2><p>
            
            Some of the packages you are trying to install have
            unsatisfied dependencies.  The packages with unsatisfied
            dependencies have been deselected.  If you wish to install
            packages that do not pass dependencies, please click the
            "force" option below.

            <form action="packages-install-2" method="post">
            <p>
            If you think you might want to use a package later (but not right away),
            install it but don't enable it.
        }]
        
        append body \
            [apm_package_selection_widget $pkg_info_list $result(install)] \
            [subst {
                <input type="checkbox" name="force_p" value="t"> <strong>Force the install<p></strong>
                <input type="submit" value="Select Data Model Scripts">
                </form>
            }]
    }


}

ad_return_template apm

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
