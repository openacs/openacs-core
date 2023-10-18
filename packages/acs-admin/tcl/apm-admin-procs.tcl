ad_library {

    Definitions for the APM administration interface.

    @creation-date 29 September 2000
    @author Bryan Quinn (bquinn@arsdigita.com)
    @cvs-id $Id$

}

ad_proc -private apm_parameter_section_slider {package_key} {
    Build a dynamic section dimensional slider.
} {
    set sections [db_list apm_parameter_sections {
        select distinct(section_name)
        from apm_parameters
        where package_key = :package_key
    }]

    if { [llength $sections] > 1 } {
        lappend section_list [list $package_key $package_key [list "where" "section_name is null"]]
        foreach section $sections {
            if { $section ne "" } {
                lappend section_list [list $section $section [list "where" "section_name = [ns_dbquotevalue $section]"]]
            }
        }
        lappend section_list [list all "All" [list]]
        return [list [list section_name "Section:" $package_key $section_list]]
    } else {
        return ""
    }
}

ad_proc -deprecated apm_header { { -form "" } args } {
    Generates HTML for the header of a page (including context bar).
    Must only be used for APM admin pages (under /acs-admin/apm).

    We are adding the APM index page to the context bar
    so it doesn't have to be added on each page

    @author Peter Marklund
} {
    set apm_title "Package Manager"
    set apm_url "/acs-admin/apm/"

    if { [llength $args] == 0 } {
        set title $apm_title
        set context_bar [ad_context_bar $title]
    } else {
        set title [lindex $args end]
        set context [concat [list [list $apm_url $apm_title]] $args]
        set cmd [list ad_context_bar --]
        foreach elem $context {
            lappend cmd $elem
        }
        set context_bar [eval $cmd]
        # this is rather a hack, but just needed for streaming output
        # a more general solution can be provided at some later time...
        regsub "#acs-kernel.Main_Site#" $context_bar \
            [_ acs-kernel.Main_Site] context_bar
    }

    append body [ad_header $title ""] "\n"
    if {$form ne ""} {
        append body "<form $form>"
    }

    return "$body\n
    <h3>$title</h3>
    $context_bar
    <hr>
    "
}

ad_proc -deprecated apm_shell_wrap { cmd } {
    The value provided by this proc is unclear, quite hardcoded, and
    it is used nowhere in usptream code.

    @see many possible plain tcl idioms

    @return a command string, wrapped it shell-style (with backslashes)
    in case lines get too long.
} {
    set out ""
    set line_length 0
    foreach element $cmd {
        if { $line_length + [string length $element] > 72 } {
            append out "\\\n    "
            set line_length 4
        }
        append out "$element "
        incr line_length [expr { [string length $element] + 1 }]
    }
    append out "\n"
}



ad_proc -private apm_package_selection_widget {
    pkg_info_list
    {to_install ""}
    {operation "all"}
    {form pkgsForm}
} {

    Provides a widget for selecting packages.  Displays dependency information if available.

    @param pkg_info_list list of package infos for all packages to be listed
    @param to_install list of package_keys to install
    @param operation filter for added operations (all, upgrade, install)
} {
    if {$pkg_info_list eq ""} {
        return ""
    }

    set counter 0
    if {[llength $to_install] > 0} {
        set label [dict get {install Install upgrade Upgrade all Install/Update} $operation]
    } else {
        set label [subst {
            <input type="checkbox" name="_dummy" id="bulkaction-control" title="[_ acs-templating.lt_Checkuncheck_all_rows]">
        }]
        template::add_event_listener \
            -id bulkaction-control \
            -preventdefault=false \
            -script [subst {acs_ListCheckAll('$form', this.checked);}]
    }

    set widget [subst {
        <blockquote><table class='list-table' cellpadding='3' cellspacing='5' summary="Available Packages">
        <tr class='list-header'><th>$label</th><th>Package</th><th>Package Key</th><th>Comment</th></tr>
    }]

    foreach pkg_info $pkg_info_list {

        incr counter
        set package_key [pkg_info_key $pkg_info]
        set package_path [pkg_info_path $pkg_info]
        set spec_file [pkg_info_spec $pkg_info]
        set package [apm_read_package_info_file $spec_file]
        set package_name [dict get $package package-name]
        set version_name [dict get $package name]
        set id $form-$package_key
        ns_log Debug "Selection widget: $package_key, Dependency: [pkg_info_dependency_p $pkg_info]"

        if { [pkg_info_dependency_p $pkg_info] == "t" } {
            #
            # Dependency passed.
            #
            set checked [expr { $package_key in $to_install ? "checked " : "" }]
            append widget [subst {
                <tr class='[expr {$counter % 2 ? "odd" : "even"}]'>
                <td align='center'><input type='checkbox' $checked name='package_key' value='$package_key' id='$id'></td>
                <td>$package_name $version_name</td>
                <td>$package_key</td>
                <td><span style='color:green'>Dependencies satisfied.</span></td>
                </tr>
            }]
        } elseif { [pkg_info_dependency_p $pkg_info] == "f" } {
            #
            # Dependency failed.
            #
            append widget [subst {
                <tr class='[expr {$counter % 2 ? "odd" : "even"}]'>
                <td align='center'><input type='checkbox' name='package_key' value='$package_key' id='$id'></td>
                <td>$package_name $version_name</td>
                <td>$package_key</td>
                <td><span style='color:red'>
            }]
            foreach comment [pkg_info_comment $pkg_info] {
                append widget "$comment<br>"
            }
            append widget \
                </span></td> \
                </tr>
        } else {
            #
            # No dependency information.
            # See if the install is already installed with a higher version number.
            #
            if {[apm_package_registered_p $package_key]} {
                set higher_version_p [apm_higher_version_installed_p $package_key $version_name]
            } else {
                set higher_version_p 2
            }
            if {$higher_version_p == 2 } {
                if {$operation eq "upgrade"} {
                    incr counter -1
                    continue
                }
                set comment "New install."
            } elseif {$higher_version_p == 1 } {
                if {$operation eq "install"} {
                    incr counter -1
                    continue
                }
                set comment "Upgrade."
            } elseif {$higher_version_p == 0} {
                set comment "Package version already installed."
            } else {
                set comment "Installing older version of package."
            }

            set install_checked [expr {$package_key in $to_install ? "checked" : ""}]
            append widget [subst {
                <tr class='[expr {$counter % 2 ? "odd" : "even"}]'>
                <td align='center'><input type='checkbox' $install_checked name='package_key' value='$package_key' id='$id'></td>
                <td>$package_name $version_name</td>
                <td>$package_key</td>
                <td>$comment</td>
                </tr>
            }]
        }
    }
    if {$counter == 0} {
        set widget ""
    } else {
        append widget {</table></blockquote>}
    }
    return $widget
}


ad_proc -public apm_higher_version_installed_p {
    package_key
    version_name
} {
    @param package_key  The package in question.
    @param version_name The name of the currently installed version.

    @return The return value of this procedure doesn't really fit with its name.
    What it returns is:

    <ul>
    <li>-1 if there's already a higher version of the given package installed than the version_name you gave it.
    <li>0 if the same version is installed as the one you supplied.
    <li>1 if the version you gave is higher than the highest version installed, or no version of this package is installed.
    </ul>
} {
    set package_version_name [apm_highest_version_name $package_key]
    if {$package_version_name eq ""} {
        return 1
    }
    return [apm_version_names_compare $version_name $package_version_name]
}



ad_proc -private apm_build_repository {
    {-debug:boolean 0}
    {-channels *}
    {-head_channel HEAD}
} {

    Rebuild the repository on the local machine.
    Only useful for the openacs.org site.
    Adapted from Lars' build-repository.tcl page.
    @param debug Set to 1 to test with only a small subset of packages instead of the whole cvs tree.
    @param head_channel The artificial branch label to apply to HEAD.  Should be one minor version past the current release.
    @param channels Generate apm files for the matching channels only
    @author Lars Pind (lars@collaboraid.biz)
    @return 0 for success. Also outputs debug messages to log.

} {

    #----------------------------------------------------------------------
    # Configuration Settings
    #----------------------------------------------------------------------

    set cd_helper              [file join $::acs::rootdir bin cd-helper]

    set cvs_command            cvs
    set cvs_root               :pserver:anonymous@cvs.openacs.org:/cvsroot

    set work_dir               [file join $::acs::rootdir repository-builder][file separator]

    set repository_dir         [file join $::acs::rootdir www repository][file separator]
    set repository_url         https://openacs.org/repository/

    set exclude_package_list {}

    set channel_index_template [template::themed_template /packages/acs-admin/www/apm/repository-channel-index]
    set index_template         [template::themed_template /packages/acs-admin/www/apm/repository-index]

    #----------------------------------------------------------------------
    # Prepare output
    #----------------------------------------------------------------------

    ns_log Debug "Repository: Building Package Repository"

    #----------------------------------------------------------------------
    # Find available channels
    #----------------------------------------------------------------------

    # Prepare work dir
    file mkdir $work_dir

    cd $work_dir
    set msg [ exec $cd_helper $work_dir $cvs_command -d $cvs_root -z3 co openacs-4/readme.txt ]
    set output [ exec $cd_helper $work_dir $cvs_command -d $cvs_root -z3 log -h openacs-4/readme.txt ]

    set lines [split $output \n]
    for { set i 0 } { $i < [llength $lines] } { incr i } {
        if { [string trim [lindex $lines $i]] eq "symbolic names:" } {
            incr i
            break
        }
    }

    array set channel_tag [list]
    array set channel_bugfix_version [list]

    for { } { $i < [llength $lines] } { incr i } {
        # Tag lines have the form   tag: cvs-version
        #     openacs-5-0-0-final: 1.25.2.5

        if { ![regexp {^\s+([^:]+):\s+([0-9.]+)} [lindex $lines $i] match tag_name version_name] } {
            break
        }

        # Look for tags named 'openacs-x-y-compat'
        if { [regexp {^openacs-([1-9][0-9]*-[0-9]+)-compat$} $tag_name match oacs_version] } {
            lassign [split $oacs_version "-"] major_version minor_version
            if { $major_version >= 5 && $minor_version >= 3} {
                set channel "${major_version}-${minor_version}"
                ns_log Notice "Repository: Found channel $channel using tag $tag_name"
                set channel_tag($channel) $tag_name
            }
        } elseif { [regexp {^openacs-([1-9][0-9]*-[0-9]+-[0-9]+)-final$} $tag_name match oacs_version] } {
            lassign [split $oacs_version "-"] major_version minor_version patch_version
            #ns_log Notice "Repository: tag <$tag_name> oacs version <$oacs_version> split into /$major_version/$minor_version/$patch_version/"
            if { $major_version >= 5 && $minor_version >= 8} {
                set channel "${major_version}-${minor_version}-$patch_version"
                ns_log Notice "Repository: Found channel $channel using tag $tag_name"
                set channel_tag($channel) $tag_name
            }
        }
    }

    set channel_tag($head_channel) HEAD
    set channel_tag(5-10) oacs-5-10

    ns_log Notice "Repository: Channels are: [array get channel_tag]"


    #----------------------------------------------------------------------
    # Read all package .info files, building manifest file
    #----------------------------------------------------------------------

    # Wipe and re-create the working directory
    file delete -force -- $work_dir
    file mkdir ${work_dir}
    set update_pretty_date [lc_time_fmt [clock format [clock seconds] -format "%Y-%m-%d %T"] %c]

    #cd $work_dir

    foreach channel [lsort -decreasing [array names channel_tag]] {

        if {![string match $channels $channel]} continue
        ns_log Notice "Repository: Channel $channel using tag $channel_tag($channel)"

        # Wipe and re-create the checkout directory
        file delete -force -- "${work_dir}openacs-4"
        file delete -force -- "${work_dir}dotlrn"
        file mkdir "${work_dir}dotlrn/packages"

        # Prepare channel directory
        set channel_dir "${work_dir}repository/$channel/"
        file mkdir $channel_dir

        # Store the list of packages we've seen for this channel, so we don't include the same package twice
        # Seems odd, but we have to do this given the forked packages sitting in /contrib
        set packages [list]

        # Checkout from the tag given by channel_tag($channel)
        if { $debug_p } {
            # Smaller list for debugging purposes
            set checkout_list [list $work_dir $cvs_root openacs-4/packages/acs-core-docs ]
        } else {
            # Full list for real use
            set checkout_list [list \
                                   $work_dir $cvs_root openacs-4/packages \
                                   $work_dir $cvs_root openacs-4/contrib/packages]
        }

        foreach { cur_work_dir cur_cvs_root cur_module } $checkout_list {
            #cd $cur_work_dir
            set cmd [list exec $cd_helper $cur_work_dir cvs -d $cur_cvs_root -z3 co]
            if { $channel_tag($channel) ne "HEAD" } {
                lappend cmd -r $channel_tag($channel)
            }
            catch { {*}$cmd $cur_module } output
            ns_log Notice "Repository: $cur_module [llength $output] files ($channel_tag($channel))"
        }
        #cd $work_dir

        set manifest "<manifest>\n"

        template::multirow create packages \
            package_path package_key version pretty_name \
            package_type summary description \
            release_date vendor_url vendor \
            maturity maturity_text \
            license license_url

        set work_dirs [list ${work_dir}openacs-4/packages ${work_dir}openacs-4/contrib/packages ]
        foreach packages_dir $work_dirs {

            foreach spec_file [lsort [apm_scan_packages $packages_dir]] {

                set package_path [file join {*}[lrange [file split $spec_file] 0 end-1]]
                set package_key [lindex [file split $spec_file] end-1]

                if { $package_key in $exclude_package_list } {
                    ns_log Debug "Repository: Package $package_key is on list of packages to exclude - skipping"
                    continue
                }

                if { [array exists pkg_info] } {
                    array unset pkg_info
                }
                if { [info exists pkg_info] } {
                    unset pkg_info
                }

                ad_try {
                    array set pkg_info [apm_read_package_info_file $spec_file]

                    if { $pkg_info(package.key) in $packages } {
                        ns_log Debug "Repository: Skipping package $package_key, because we already have another version of it"
                    } else {
                        lappend packages $pkg_info(package.key)

                        append manifest \
                            "  <package>" \n \
                            "    <package-key>[ns_quotehtml $pkg_info(package.key)]</package-key>\n" \
                            "    <version>[ns_quotehtml $pkg_info(name)]</version>\n" \
                            "    <pretty-name>[ns_quotehtml $pkg_info(package-name)]</pretty-name>\n" \
                            "    <package-type>[ns_quotehtml $pkg_info(package.type)]</package-type>\n" \
                            "    <summary>[ns_quotehtml $pkg_info(summary)]</summary>\n" \
                            "    <description format=\"[ns_quotehtml $pkg_info(description.format)]\">" \
                            [ns_quotehtml $pkg_info(description)] "</description>\n" \
                            "    <release-date>[ns_quotehtml $pkg_info(release-date)]</release-date>\n" \
                            "    <vendor url=\"[ns_quotehtml $pkg_info(vendor.url)]\">" \
                            [ns_quotehtml $pkg_info(vendor)] "</vendor>\n" \
                            "    <license url=\"[ns_quotehtml $pkg_info(license.url)]\">" \
                            [ns_quotehtml $pkg_info(license)] "</license>\n" \
                            "    <maturity>$pkg_info(maturity)</maturity>\n"

                        foreach e $pkg_info(install) {
                            append manifest "    <install package=\"$e\"/>\n"
                        }

                        template::multirow append packages \
                            $package_path $package_key $pkg_info(name) $pkg_info(package-name) \
                            $pkg_info(package.type) $pkg_info(summary) $pkg_info(description) \
                            $pkg_info(release-date) $pkg_info(vendor.url) $pkg_info(vendor) \
                            $pkg_info(maturity) $pkg_info(maturity_text) \
                            $pkg_info(license)  $pkg_info(license.url)

                        set apm_file "${channel_dir}${pkg_info(package.key)}-${pkg_info(name)}.apm"
                        ns_log Notice "Repository: Building package $package_key for channel $channel"

                        set files [apm_get_package_files \
                                       -all \
                                       -include_data_model_files \
                                       -all_db_types \
                                       -package_key $pkg_info(package.key) \
                                       -package_path $package_path]

                        if { [llength $files] == 0 } {
                            ns_log Notice "Repository: No files in package"
                        } else {
                            ns_log Notice "Repository: [llength $files] files in package $pkg_info(package.key) ($channel)"
                            set cmd [list exec [apm_tar_cmd] cf -  2>/dev/null]

                            # The path to the 'packages' directory in the checkout
                            set packages_root_path [file join {*}[lrange [file split $spec_file] 0 end-2]]

                            set fp [ad_opentmpfile tmp_filename]
                            foreach file $files {
                                puts $fp $package_key/$file
                            }
                            close $fp

                            lappend cmd -C $packages_root_path --files-from $tmp_filename

                            lappend cmd "|" [apm_gzip_cmd] -c ">" $apm_file
                            ns_log Notice "Executing: exec $cd_helper $packages_root_path $cmd"
                            if {[catch "exec $cd_helper $packages_root_path $cmd" errmsg]} {
                                ns_log Error "Error during tar in repository creation for\
                                  file ${channel_dir}$pkg_info(package.key)-$pkg_info(name).apm:\
                                  \n$errmsg\n$::errorCode,$::errorInfo"
                            }
                            file delete -- $tmp_filename
                        }

                        set apm_url "${repository_url}$channel/$pkg_info(package.key)-$pkg_info(name).apm"

                        append manifest "    <download-url>$apm_url</download-url>\n"
                        foreach elm $pkg_info(provides) {
                            append manifest "    <provides " \
                                "url=\"[ns_quotehtml [lindex $elm 0]]\" " \
                                "version=\"[ns_quotehtml [lindex $elm 1]]\" />\n"
                        }

                        foreach elm $pkg_info(requires) {
                            append manifest "    <requires " \
                                "url=\"[ns_quotehtml [lindex $elm 0]]\" " \
                                "version=\"[ns_quotehtml [lindex $elm 1]]\" />\n"
                        }
                        append manifest "  </package>\n"
                    }
                } on error {errorMsg} {
                    ns_log Notice "Repository: Error on spec_file $spec_file: $errorMsg\n$::errorInfo\n"
                }
            }
        }
        append manifest "</manifest>\n"

        ns_log Notice "Repository: Writing $channel manifest to ${channel_dir}manifest.xml"
        set fw [open "${channel_dir}manifest.xml" w]
        puts $fw $manifest
        close $fw

        ns_log Notice "Repository: Writing $channel index page to ${channel_dir}index.adp"
        set fw [open "${channel_dir}index.adp" w]
        set packages [lsort $packages]
        puts $fw "<master>\n<property name=\"doc(title)\">OpenACS $channel Compatible Packages</property>\n\n"
        puts $fw "<h1>OpenACS $channel (CVS tag $channel_tag($channel))</h1>
           <p>Packages can be installed with the OpenACS Automated Installer on
           your OpenACS site at <code>/acs-admin/install</code>.  Only packages
           potentially compatible with your OpenACS kernel will be shown.</p>
        "
        set category_title(core) "Core Packages"
        set package_keys(core) {
            acs-admin
            acs-api-browser
            acs-authentication
            acs-automated-testing
            acs-bootstrap-installer
            acs-content-repository
            acs-core-docs
            acs-kernel
            acs-lang
            acs-mail-lite
            acs-messaging
            acs-reference
            acs-service-contract
            acs-subsite
            acs-tcl
            acs-templating
            ref-timezones
            acs-translations
            intermedia-driver
            openacs-default-theme
            notifications
            search
            tsearch2-driver
        }
        set category_title(common-app) "Common Applications"
        set package_keys(common-app) {
            xowiki
            xotcl-request-monitor
            file-storage
            acs-developer-support
            forums
            calendar
            news
            faq
        }
        set category_title(extra) "Extra Packages and Libraries"
        set package_keys(extra) ""
        foreach p $packages {
            if {$p ni $package_keys(core) && $p ni $package_keys(common-app)} {
                lappend package_keys(extra) $p
            }
        }

        foreach category {core common-app extra} {

            template::multirow create pkgs \
                package_path package_key version pretty_name \
                package_type summary description \
                release_date vendor_url vendor \
                maturity maturity_text \
                license license_url

            template::multirow foreach packages {
                if {$package_key in $package_keys($category)} {
                    template::multirow append pkgs \
                        $package_path $package_key $version $pretty_name \
                        $package_type $summary $description \
                        $release_date $vendor_url $vendor \
                        $maturity $maturity_text \
                        $license $license_url
                }
            }

            puts $fw "\n<h2>$category_title($category)</h2>\n"

            puts $fw [template::adp_include $channel_index_template \
                          [list channel $channel &pkgs pkgs update_pretty_date $update_pretty_date]]

        }
        close $fw

        ns_log Notice "Repository:  Channel $channel complete."

    }

    ns_log Notice "Repository: Finishing Repository"

    foreach channel [array names channel_tag] {
        if {[regexp {^([1-9][0-9]*)-([0-9]+)$} $channel . major minor]} {
            #
            # *-compat channels: The "patchlevel" of these channels is
            # the highest possible value, higher than the released
            # -final channels.
            #
            set tag_order([format %.3d $major]-[format %.3d $minor]-999) $channel
            set tag_label($channel) "OpenACS $major.$minor"
        } elseif {[regexp {^([1-9][0-9]*)-([0-9]+)-([0-9]+)$} $channel . major minor patch]} {
            #
            # *-final channels: a concrete patchlevel is provided.
            #
            set tag_order([format %.3d $major]-[format %.3d $minor]-[format %.3d $patch]) $channel
            set tag_label($channel) "OpenACS $major.$minor.$patch"
        } else {
            set tag_order(999-999-999) $channel
            set tag_label($channel) "OpenACS $channel"
        }
    }


    # Write the index page
    ns_log Notice "Repository: Writing repository index page to ${work_dir}repository/index.adp"
    template::multirow create channels name tag label
    foreach key [lsort -decreasing [array names tag_order]] {
        set channel $tag_order($key)
        template::multirow append channels $channel $channel_tag($channel) $tag_label($channel)
    }
    set fw [open "${work_dir}repository/index.adp" w]
    puts $fw "<master>\n<property name=\"doc(title)\">OpenACS Package Repository</property>\n\n"
    puts $fw [template::adp_include -- $index_template \
                  [list &channels channels update_pretty_date $update_pretty_date]]
    close $fw

    # Add a redirector for outdated releases
    set fw [open "${work_dir}repository/index.vuh" w]
    puts $fw "ns_returnredirect /repository/"
    close $fw

    # Without the trailing slash
    set work_repository_dirname "${work_dir}repository"
    set repository_dirname [string range $repository_dir 0 end-1]
    set repository_bak "[string range $repository_dir 0 end-1]_bak"

    ns_log Notice "Repository: Moving work repository $work_repository_dirname to live repository dir at <a href=\"/repository\/>$repository_dir</a>\n"

    if { [file exists $repository_bak] } {
        file delete -force -- $repository_bak
    }
    if { [file exists $repository_dirname] } {
        file rename -- $repository_dirname $repository_bak
    }
    file rename -- $work_repository_dirname  $repository_dirname

    ns_log Debug "Repository: DONE"

    return 0
}

ad_proc -private apm_git_repo_branches {
    -path:required
} {
    Extracts the available branches from an OpenACS Git repo. This is
    assumes the specific Git setup for our repo, hence it is meant for
    internal use only.

    @return list of branch names
} {
    set cd_helper   [file join $::acs::rootdir bin cd-helper]
    set git_command git

    set output [exec $cd_helper $path $git_command branch -r]

    set branches [list]
    foreach line [split $output \n] {
        if {[regexp {^\s+origin/(oacs-\d+-\d+).*$} $line _ branch]} {
            lappend branches $branch
        }
    }

    return $branches
}

ad_proc -private apm_git_build_repository {
    {-debug:boolean 0}
    {-force_fresh:boolean false}
    {-channels *}
} {
    Rebuild the repository on the local machine.
    Only useful for the openacs.org site.

    Adapted from the CVS implementation, which came from Lars'
    build-repository.tcl page.

    @param debug Set to 1 to test with only a small subset of packages
                 and branches instead of all of them.
    @param force_fresh Force a frech clone of the Git repos.
    @param channels A string match style pattern. Generate apm files
                    for the matching channels only
} {

    #----------------------------------------------------------------------
    # Configuration Settings
    #----------------------------------------------------------------------

    set sep [file separator]

    set cd_helper              [file join $::acs::rootdir bin cd-helper]

    set git_command            git
    set git_url                https://github.com/openacs

    set work_dir               [file join $::acs::rootdir repository-builder]${sep}

    set repository_dir         [file join $::acs::rootdir www repository]${sep}
    set repository_url         https://openacs.org/repository/

    set exclude_package_list {}

    set channel_index_template [template::themed_template /packages/acs-admin/www/apm/repository-channel-index]
    set index_template         [template::themed_template /packages/acs-admin/www/apm/repository-index]


    #
    # Make sure workdir exists. Clear it before we start if requested.
    #
    if {$force_fresh_p} {
        file delete -force -- $work_dir
    }

    file mkdir $work_dir

    #----------------------------------------------------------------------
    # Prepare output
    #----------------------------------------------------------------------

    ns_log Debug "Repository: Building Package Repository"

    #----------------------------------------------------------------------
    # Find available channels
    #----------------------------------------------------------------------

    #
    # We first checkout the core repository. This will be the skeleton
    # of our mirror.
    #
    set core_repo_dir ${work_dir}openacs-core
    if {[file isdirectory $core_repo_dir]} {
        #
        # Folder exists. We fetch from the repo to see if new branches
        # exist.
        #
        ns_log notice "Fetching new branches for core repository"
        exec -ignorestderr -- $cd_helper $core_repo_dir $git_command fetch origin
    } else {
        #
        # Folder does not exist. We check out the repo from scratch.
        #
        ns_log notice "Cloning core repository at $git_url/openacs-core.git"
        exec -ignorestderr -- $cd_helper $work_dir $git_command clone $git_url/openacs-core.git
    }

    #
    # The core repo is considered the source of truth concerning
    # release branches. We extract them from here and we will look for
    # them in the non-core repos.
    #
    set core_channels [list]
    foreach branch [apm_git_repo_branches -path $core_repo_dir] {
        regsub {^oacs-} $branch {} channel
        if {[string match $channels $channel]} {
            lappend core_channels $channel $branch
        }
    }
    lappend core_channels main main

    if {$debug_p} {
        #
        # When debugging, only pick the last branch.
        #
        set core_channels [lrange $core_channels end-1 end]
    }

    #
    # The core packages are those included in the openacs-core
    # repository.
    #
    set core_packages_dir ${core_repo_dir}${sep}packages

    set core_packages [list]
    foreach package_folder [glob \
                                -types d \
                                -directory $core_packages_dir *] {
        lappend core_packages [file tail $package_folder]
    }
    ns_log notice "Core packages:" $core_packages

    set non_core_packages_dir ${work_dir}openacs-non-core
    file mkdir $non_core_packages_dir

    #
    # This is the list of all packages that are not included in the
    # openacs-core repository. We currently maintain this list as
    # hardcoded here. One improvement would be to fetch it from the
    # Git host directly, either via scraping or via API.
    #
    # As long as this does not change, everytime a new package is
    # added to the Git mirror, one should also add the corresponding
    # package key to this list.
    #
    set non_core_packages {
        accounts-desk
        accounts-finance
        accounts-ledger
        accounts-payables
        accounts-payroll
        accounts-receivables
        acs-datetime
        acs-events
        acs-interface
        acs-ldap-authentication
        acs-mail
        acs-notification
        acs-object-management
        acs-object-managment
        acs-outdated
        acs-person
        address-book
        adserver
        ae-portlet
        ajax-filestorage-ui
        ajax-photoalbum-ui
        ajaxhelper
        ams
        anon-eval
        application-track
        application-track-portlet
        assessment
        assessment-portlet
        attachments
        attendance
        auth-cas
        auth-http
        auth-ldap
        auth-pam
        auth-server
        authorize-gateway
        bboard-portlet
        beehive
        beehive-portlet
        bm-portlet
        bookmarks
        bookshelf
        boomerang
        bootstrap-icons
        bug-tracker
        bulk-mail
        caldav
        calendar
        calendar-includelet
        calendar-portlet
        captcha
        cards
        cards-portlet
        categories
        chat
        chat-includelet
        chat-portlet
        clickthrough
        clipboard
        cms
        cms-news-demo
        connections
        contacts
        contacts-lite
        contacts-portlet
        content-includelet
        content-portlet
        cookie-consent
        courses
        cronjob
        curriculum
        curriculum-central
        curriculum-portlet
        curriculum-tracker
        customer-service
        datamanager
        datamanager-portlet
        dbm
        diagram
        directory
        docker-s6
        dotfolio
        dotfolio-ui
        dotkul
        dotkul-admin
        dotlrn
        dotlrn-admin
        dotlrn-ae
        dotlrn-application-track
        dotlrn-assessment
        dotlrn-attendance
        dotlrn-bboard
        dotlrn-beehive
        dotlrn-bm
        dotlrn-calendar
        dotlrn-cards
        dotlrn-catalog
        dotlrn-chat
        dotlrn-contacts
        dotlrn-content
        dotlrn-curriculum
        dotlrn-datamanager
        dotlrn-dotlrn
        dotlrn-ecommerce
        dotlrn-edit-this-page
        dotlrn-eduwiki
        dotlrn-evaluation
        dotlrn-expense-tracking
        dotlrn-faq
        dotlrn-forums
        dotlrn-fs
        dotlrn-glossar
        dotlrn-homework
        dotlrn-imsld
        dotlrn-invoices
        dotlrn-jabber
        dotlrn-lamsint
        dotlrn-latest
        dotlrn-learning-content
        dotlrn-lorsm
        dotlrn-messages
        dotlrn-mmplayer
        dotlrn-news
        dotlrn-news-aggregator
        dotlrn-photo-album
        dotlrn-portlet
        dotlrn-project-manager
        dotlrn-quota
        dotlrn-random-photo
        dotlrn-recruiting
        dotlrn-research
        dotlrn-static
        dotlrn-survey
        dotlrn-syllabus
        dotlrn-tasks
        dotlrn-user-tracking
        dotlrn-weblogger
        dotlrn-wikipedia
        dotlrn-wps
        dotlrn-xowiki
        dotlrndoc
        download
        dynamic-types
        ec-serial-numbers
        ecommerce
        edit-this-page
        edit-this-page-portlet
        eduwiki
        eduwiki-portlet
        email-handler
        evaluation
        evaluation-portlet
        expense-tracking
        expenses
        ezic-gateway
        fa-icons
        fabrik
        facebook-api
        faq
        faq-portlet
        feed-parser
        file-manager
        file-storage
        file-storage-includelet
        forums
        forums-includelet
        forums-portlet
        fs-portlet
        gatekeeper
        general-comments
        glossar
        glossar-portlet
        glossary
        highcharts
        image-magick
        ims-ent
        imsld
        imsld-portlet
        inventory-control
        invoices
        invoices-portlet
        jabber
        jabber-portlet
        lab-report
        lab-report-central
        lams-conf
        lamsint
        lamsint-portlet
        lars-blogger
        latest
        latest-portlet
        layout-managed-subsite
        layout-manager
        learning-content
        learning-content-portlet
        logger
        lors
        lors-central
        lorsm
        lorsm-includelet
        lorsm-portlet
        mail-tracking
        messages
        messages-portlet
        mmplayer
        mmplayer-portlet
        monitoring
        new-portal
        news
        news-aggregator
        news-aggregator-portlet
        news-includelet
        news-portlet
        notes
        oacs-dav
        oct-election
        online-catalog
        openacs-bootstrap3-theme
        openacs-bootstrap5-theme
        openfts-driver
        organizations
        package-builder
        page
        pages
        payflowpro
        payment-gateway
        photo-album
        photo-album-portlet
        places
        planner
        poll
        postal-address
        postcard
        press
        proctoring-support
        profile-provider
        project-manager
        project-manager-portlet
        quota
        quota-portlet
        random-photo-portlet
        ratings
        recruiting
        recruiting-portlet
        redirect
        ref-currency
        ref-gifi
        ref-itu
        ref-unspec
        ref-us-counties
        ref-us-states
        ref-us-zipcodes
        related-items
        research-portlet
        richtext-ckeditor4
        richtext-ckeditor5
        richtext-tinymce
        richtext-xinha
        robot-detection
        rss-support
        rules
        s5
        sample-gateway
        schema-browser
        scholarship-fund
        scorm-core
        scorm-importer
        scorm-player
        scorm-simple-lms
        shipping-gateway
        shipping-tracking
        simple-survey
        simulation
        site-wide-search
        skin
        sloan-bboard
        soap-db
        soap-gateway
        spam
        spreadsheet
        static-pages
        static-portlet
        survey
        survey-builder-ui
        survey-library
        survey-portlet
        survey-reports
        t-account
        tasks
        tasks-portlet
        telecom-number
        theme-selva
        theme-zen
        timezones
        trackback
        tracker
        tsoap
        user-preferences
        user-profile
        user-tracking
        user-tracking-portlet
        value-based-shipping
        version-control
        views
        weblogger-portlet
        webmail
        webmail-system
        wiki
        wikipedia
        wikipedia-portlet
        workflow
        wp-slim
        wps-portlet
        xcms-ui
        xml-rpc
        xolp
        xooauth
        xotcl-core
        xotcl-request-monitor
        xowf
        xowf-monaco-plugin
        xowiki
        xowiki-includelet
        xowiki-portlet
    }

    if {$debug_p} {
        #
        # When debugging, pick only a subset of all packages.
        #
        set non_core_packages [lrange $non_core_packages 0 10]
    }

    foreach package_key $non_core_packages {
        set package_dir ${non_core_packages_dir}${sep}${package_key}
        if {[file isdirectory $package_dir]} {
            #
            # Folder exists. We fetch from the repo to see if new branches
            # exist.
            #
            ns_log notice "Fetching new branches for non-core repository '$package_key'"
            exec -ignorestderr -- $cd_helper $package_dir $git_command fetch origin
        } else {
            #
            # Folder does not exist. Clone the repo from
            # scratch. Tolerate errors here, as some legacy packages
            # require authentication and would fail.
            #
            try {
                exec -ignorestderr -- $cd_helper $non_core_packages_dir $git_command clone ${git_url}/${package_key}.git
            } on error {errmsg} {
                ns_log warning "Could not clone '$package_key' from ${git_url}/${package_key}.git:" $errmsg
            }
        }
    }


    #----------------------------------------------------------------------
    # Read all package .info files, building manifest file
    #----------------------------------------------------------------------

    set update_pretty_date [lc_time_fmt [clock format [clock seconds] -format "%Y-%m-%d %T"] %c]

    foreach {channel branch} $core_channels {
        ns_log Notice "Repository: Channel $channel using branch $branch"

        #
        # Checkout the channel branch on the core repository.
        #
        ns_log Notice "Checking out core-repository"
        exec -ignorestderr -- $cd_helper $core_repo_dir $git_command checkout $branch
        #
        # Make sure the repo is up to date.
        #
        ns_log Notice "Updating core-repository"
        exec -ignorestderr -- $cd_helper $core_repo_dir $git_command pull

        #
        # Try to check out the channel from the non-core packages.
        #
        set branch_packages [list]
        foreach package_key $non_core_packages {
            set package_dir ${non_core_packages_dir}${sep}${package_key}
            if {![file isdirectory $package_dir]} {
                ns_log notice "Package '$package_key' was not cloned in '$package_dir', skipping."
                continue
            }

            #
            # Not all packages will have a release branch. Skip the
            # package when the branch is not found.
            #
            if {$branch in [apm_git_repo_branches -path $package_dir]} {
                try {
                    ns_log Notice "Checking out '$package_key'"
                    exec -ignorestderr -- $cd_helper $package_dir $git_command checkout $branch
                } on error {errmsg} {
                    #
                    # Checking out a branch that was already checked
                    # out will complain. As we know the branch exists
                    # for this repo, we are pretty confident this
                    # error can be ignored.
                    #
                    ns_log notice "Checking out existing branch '$branch' for package '$package_key' complained:" $errmsg
                }
                #
                # Make sure repo is up to date.
                #
                ns_log Notice "Updating '$package_key'"
                exec -ignorestderr -- $cd_helper $package_dir $git_command pull

                lappend branch_packages $package_key
            }
        }

        #
        # Now collect the info files for all core and non-core
        # packages belonging to this branch.
        #
        set info_files [list]
        foreach package_key $core_packages {
            if {[catch {
                set info_file [apm_package_info_file_path -path $core_packages_dir $package_key]
            } errmsg]} {
                ns_log warning "Cannot find an .info file on '$branch' for core package '$package_key':" $errmsg
                continue
            }

            lappend info_files $info_file
        }
        foreach package_key $branch_packages {
            if {[catch {
                set info_file [apm_package_info_file_path -path $non_core_packages_dir $package_key]
            } errmsg]} {
                ns_log warning "Cannot find an .info file on '$branch' for non.core package '$package_key':" $errmsg
                continue
            }

            lappend info_files $info_file
        }

        # Prepare channel directory
        set channel_dir "${work_dir}repository${sep}${channel}${sep}"
        file mkdir $channel_dir

        set manifest "<manifest>\n"

        template::multirow create packages \
            package_path package_key version pretty_name \
            package_type summary description \
            release_date vendor_url vendor \
            maturity maturity_text \
            license license_url

        set packages [list]

        foreach spec_file [lsort $info_files] {

            set package_path [file join {*}[lrange [file split $spec_file] 0 end-1]]
            set package_key [lindex [file split $spec_file] end-1]

            if { $package_key in $exclude_package_list } {
                ns_log Debug "Repository: Package $package_key is on list of packages to exclude - skipping"
                continue
            }

            if { [array exists pkg_info] } {
                array unset pkg_info
            }
            if { [info exists pkg_info] } {
                unset pkg_info
            }

            ad_try {
                array set pkg_info [apm_read_package_info_file $spec_file]

                if { $pkg_info(package.key) in $packages } {
                    ns_log Debug "Repository: Skipping package $package_key, because we already have another version of it"
                } else {
                    lappend packages $pkg_info(package.key)

                    append manifest \
                        "  <package>" \n \
                        "    <package-key>[ns_quotehtml $pkg_info(package.key)]</package-key>\n" \
                        "    <version>[ns_quotehtml $pkg_info(name)]</version>\n" \
                        "    <pretty-name>[ns_quotehtml $pkg_info(package-name)]</pretty-name>\n" \
                        "    <package-type>[ns_quotehtml $pkg_info(package.type)]</package-type>\n" \
                        "    <summary>[ns_quotehtml $pkg_info(summary)]</summary>\n" \
                        "    <description format=\"[ns_quotehtml $pkg_info(description.format)]\">" \
                        [ns_quotehtml $pkg_info(description)] "</description>\n" \
                        "    <release-date>[ns_quotehtml $pkg_info(release-date)]</release-date>\n" \
                        "    <vendor url=\"[ns_quotehtml $pkg_info(vendor.url)]\">" \
                        [ns_quotehtml $pkg_info(vendor)] "</vendor>\n" \
                        "    <license url=\"[ns_quotehtml $pkg_info(license.url)]\">" \
                        [ns_quotehtml $pkg_info(license)] "</license>\n" \
                        "    <maturity>$pkg_info(maturity)</maturity>\n"

                    foreach e $pkg_info(install) {
                        append manifest "    <install package=\"$e\"/>\n"
                    }

                    template::multirow append packages \
                        $package_path $package_key $pkg_info(name) $pkg_info(package-name) \
                        $pkg_info(package.type) $pkg_info(summary) $pkg_info(description) \
                        $pkg_info(release-date) $pkg_info(vendor.url) $pkg_info(vendor) \
                        $pkg_info(maturity) $pkg_info(maturity_text) \
                        $pkg_info(license)  $pkg_info(license.url)

                    set apm_file "${channel_dir}${pkg_info(package.key)}-${pkg_info(name)}.apm"
                    ns_log Notice "Repository: Building package $package_key for channel $channel"

                    set files [apm_get_package_files \
                                   -all \
                                   -include_data_model_files \
                                   -all_db_types \
                                   -package_key $pkg_info(package.key) \
                                   -package_path $package_path]

                    if { [llength $files] == 0 } {
                        ns_log Notice "Repository: No files in package"
                    } else {
                        ns_log Notice "Repository: [llength $files] files in package $pkg_info(package.key) ($channel)"
                        set cmd [list exec [apm_tar_cmd] cf -  2>/dev/null]

                        # The path to the 'packages' directory in the checkout
                        set packages_root_path [file join {*}[lrange [file split $spec_file] 0 end-2]]

                        set fp [ad_opentmpfile tmp_filename]
                        foreach file $files {
                            puts $fp $package_key/$file
                        }
                        close $fp

                        lappend cmd -C $packages_root_path --files-from $tmp_filename

                        lappend cmd "|" [apm_gzip_cmd] -c ">" $apm_file
                        ns_log Notice "Executing: exec $cd_helper $packages_root_path $cmd"
                        if {[catch "exec $cd_helper $packages_root_path $cmd" errmsg]} {
                            ns_log Error "Error during tar in repository creation for\
                                  file ${channel_dir}$pkg_info(package.key)-$pkg_info(name).apm:\
                                  \n$errmsg\n$::errorCode,$::errorInfo"
                        }
                        file delete -- $tmp_filename
                    }

                    set apm_url "${repository_url}$channel/$pkg_info(package.key)-$pkg_info(name).apm"

                    append manifest "    <download-url>$apm_url</download-url>\n"
                    foreach elm $pkg_info(provides) {
                        append manifest "    <provides " \
                            "url=\"[ns_quotehtml [lindex $elm 0]]\" " \
                            "version=\"[ns_quotehtml [lindex $elm 1]]\" />\n"
                    }

                    foreach elm $pkg_info(requires) {
                        append manifest "    <requires " \
                            "url=\"[ns_quotehtml [lindex $elm 0]]\" " \
                            "version=\"[ns_quotehtml [lindex $elm 1]]\" />\n"
                    }
                    append manifest "  </package>\n"
                }
            } on error {errorMsg} {
                ns_log Notice "Repository: Error on spec_file $spec_file: $errorMsg\n$::errorInfo\n"
            }
        }

        append manifest "</manifest>\n"

        ns_log Notice "Repository: Writing $channel manifest to ${channel_dir}manifest.xml"
        set fw [open "${channel_dir}manifest.xml" w]
        puts $fw $manifest
        close $fw

        ns_log Notice "Repository: Writing $channel index page to ${channel_dir}index.adp"
        set fw [open "${channel_dir}index.adp" w]
        set packages [lsort $packages]
        puts $fw "<master>\n<property name=\"doc(title)\">OpenACS $channel Compatible Packages</property>\n\n"
        puts $fw "<h1>OpenACS $channel (Git branch $branch)</h1>
           <p>Packages can be installed with the OpenACS Automated Installer on
           your OpenACS site at <code>/acs-admin/install</code>.  Only packages
           potentially compatible with your OpenACS kernel will be shown.</p>
        "
        set category_title(core) "Core Packages"
        set package_keys(core) $core_packages

        set category_title(common-app) "Common Applications"
        set package_keys(common-app) {
            xowiki
            xotcl-request-monitor
            file-storage
            acs-developer-support
            forums
            calendar
            news
            faq
        }

        set category_title(extra) "Extra Packages and Libraries"
        set package_keys(extra) ""
        foreach p $packages {
            if {$p ni $package_keys(core) && $p ni $package_keys(common-app)} {
                lappend package_keys(extra) $p
            }
        }

        foreach category {core common-app extra} {

            template::multirow create pkgs \
                package_path package_key version pretty_name \
                package_type summary description \
                release_date vendor_url vendor \
                maturity maturity_text \
                license license_url

            template::multirow foreach packages {
                if {$package_key in $package_keys($category)} {
                    template::multirow append pkgs \
                        $package_path $package_key $version $pretty_name \
                        $package_type $summary $description \
                        $release_date $vendor_url $vendor \
                        $maturity $maturity_text \
                        $license $license_url
                }
            }

            puts $fw "\n<h2>$category_title($category)</h2>\n"

            puts $fw [template::adp_include $channel_index_template \
                          [list channel $channel &pkgs pkgs update_pretty_date $update_pretty_date]]

        }
        close $fw

        ns_log Notice "Repository:  Channel $channel complete."

    }

    ns_log Notice "Repository: Finishing Repository"

    foreach channel [dict keys $core_channels] {
        if {[regexp {^([1-9][0-9]*)-([0-9]+)$} $channel . major minor]} {
            #
            # *-compat channels: The "patchlevel" of these channels is
            # the highest possible value, higher than the released
            # -final channels.
            #
            set tag_order([format %.3d $major]-[format %.3d $minor]-999) $channel
            set tag_label($channel) "OpenACS $major.$minor"
        } elseif {[regexp {^([1-9][0-9]*)-([0-9]+)-([0-9]+)$} $channel . major minor patch]} {
            #
            # *-final channels: a concrete patchlevel is provided.
            #
            set tag_order([format %.3d $major]-[format %.3d $minor]-[format %.3d $patch]) $channel
            set tag_label($channel) "OpenACS $major.$minor.$patch"
        } else {
            set tag_order(999-999-999) $channel
            set tag_label($channel) "OpenACS $channel"
        }
    }


    # Write the index page
    ns_log Notice "Repository: Writing repository index page to ${work_dir}repository/index.adp"
    template::multirow create channels name tag label
    foreach key [lsort -decreasing [array names tag_order]] {
        set channel $tag_order($key)
        template::multirow append channels $channel [dict get $core_channels $channel] $tag_label($channel)
    }
    set fw [open "${work_dir}repository/index.adp" w]
    puts $fw "<master>\n<property name=\"doc(title)\">OpenACS Package Repository</property>\n\n"
    puts $fw [template::adp_include -- $index_template \
                  [list &channels channels update_pretty_date $update_pretty_date]]
    close $fw

    # Add a redirector for outdated releases
    set fw [open "${work_dir}repository/index.vuh" w]
    puts $fw "ns_returnredirect /repository/"
    close $fw

    # Without the trailing slash
    set work_repository_dirname "${work_dir}repository"
    set repository_dirname [string range $repository_dir 0 end-1]
    set repository_bak "[string range $repository_dir 0 end-1]_bak"

    ns_log Notice "Repository: Moving work repository $work_repository_dirname to live repository dir at <a href=\"/repository\/>$repository_dir</a>\n"

    if { [file exists $repository_bak] } {
        file delete -force -- $repository_bak
    }
    if { [file exists $repository_dirname] } {
        file rename -- $repository_dirname $repository_bak
    }
    file rename -- $work_repository_dirname  $repository_dirname

    ns_log Debug "Repository: DONE"

    return 0
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
