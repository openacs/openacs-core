ad_library {

    Definitions for the APM administration interface.

    @creation-date 29 September 2000
    @author Bryan Quinn (bquinn@arsdigita.com)
    @cvs-id $Id$

}

ad_proc apm_parameter_section_slider {package_key} {
    Build a dynamic section dimensional slider.
} {
    set sections [db_list apm_parameter_sections {
        select distinct(section_name) 
        from apm_parameters
        where package_key = :package_key
    }]

    if { [llength $sections] > 1 } {
        set i 0
        lappend section_list [list $package_key $package_key [list "where" "section_name is null"]]
        foreach section $sections {
            incr i
            if { $section ne "" } {
                lappend section_list [list "section_$i" $section [list "where" "section_name = '[db_quote $section]'"]]
            }
        }
        lappend section_list [list all "All" [list] ]
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

ad_proc apm_shell_wrap { cmd } { 
    Returns a command string, wrapped it shell-style (with backslashes) 
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
    -install_enable:boolean
    pkg_info_list
    {to_install ""} 
    {to_enable ""}
} {

    Provides a widget for selecting packages.  Displays dependency information if available.
    
    @param intall_enable Set this flag if you want separate install and enable checkboxes to be displayed. If you don't set it, 
    only the enable checkbox will be displayed, and the resulting page is expected to assume that enable also means install.

} {
    if {$pkg_info_list eq ""} {
        return ""
    }
    
    set checkbox_count 0
    set counter 0
    set band_colors { white "#ececec" }
    set widget "<blockquote><table cellpadding=5 cellspacing=5>
<tr bgcolor=\"\#f8f8f8\"><th>Install</th>[ad_decode $install_enable_p 1 "<th>Enable</th>" ""]<th>Package</th><th>Directory</th><th>Comment</th></tr>
    "

    foreach pkg_info $pkg_info_list {
        
        incr counter
        set package_key [pkg_info_key $pkg_info]
        set package_path [pkg_info_path $pkg_info]
        set package_rel_path [string range $package_path [string length [acs_root_dir]] end]
        set spec_file [pkg_info_spec $pkg_info]
        array set package [apm_read_package_info_file $spec_file]
        set version_name $package(name)
        ns_log Debug "Selection widget: $package_key, Dependency: [pkg_info_dependency_p $pkg_info]"


        append widget "  <tr valign=baseline bgcolor=[lindex $band_colors \
                [expr { $counter % [llength $band_colors] }]]>"
        if { [pkg_info_dependency_p $pkg_info] eq "t" } {
            # Dependency passed.

            if { $install_enable_p } {
                if { $package_key in $to_install } {
                    append widget "  <td align='center'><input type='checkbox' checked 
                    name='install' value=\"$package_key\"
                    onclick=\"if (!checked) document.forms\[0\].elements\[$checkbox_count+1\].checked=false\"></td> "
                } else {
                    append widget "  <td align='center'><input type='checkbox' 
                    name='install' value=\"$package_key\"
                    onclick=\"if (!checked) document.forms\[0\].elements\[$checkbox_count+1\].checked=false\"></td>"
                }
            }
            if { $package_key in $to_enable } {
                append widget "
                <td align='center'><input type='checkbox' checked 
                name='enable' value='$package_key' "
            } else {
                append widget "
                <td align=center><input type=checkbox 
                name=enable value=\"$package_key\" "
            }
            
            if { $install_enable_p } {
                append widget "
                onclick=\"if (checked) document.forms\[0\].elements\[$checkbox_count\].checked=true\""
            }

            append widget "></td>
            <td>$package(package-name) $package(name)</td>
            <td>$package_rel_path</td>
            <td><font color=green>Dependencies satisfied.</font></td>
            </tr> "
        } elseif { [pkg_info_dependency_p $pkg_info] eq "f" } {
            #Dependency failed.
            if { $install_enable_p } {
                append widget "  <td align=center><input type=checkbox name=install value=\"$package_key\"
                onclick=\"if (!checked) document.forms\[0\].elements\[$checkbox_count+1\].checked=false\"></td>"
            }
            append widget "
            <td align=center><input type=checkbox name=enable value=\"$package_key\" "

            if { $install_enable_p } {
                append widget "onclick=\"if (checked) document.forms\[0\].elements\[$checkbox_count\].checked=true\""
            }

            append widget "></td>
            <td>$package(package-name) $package(name)</td>
            <td>$package_rel_path</td>
    <td><font color=red>
            "
            foreach comment [pkg_info_comment $pkg_info] {
                append widget "$comment<br>"
            }
            append widget "
            </font></td>
            </tr>
            "
        } else {
            # No dependency information.           
            # See if the install is already installed with a higher version number.
            if {[apm_package_registered_p $package_key]} {
                set higher_version_p [apm_higher_version_installed_p $package_key $version_name]
                } else {
                    set higher_version_p 2
                }
                if {$higher_version_p == 2 } {
                    set comment "New install."
                } elseif {$higher_version_p == 1 } {
                    set comment "Upgrade."
                } elseif {$higher_version_p == 0} {
                    set comment "Package version already installed."
                } else {
                    set comment "Installing older version of package."
                }
            
            append widget "  <tr valign=baseline bgcolor=[lindex $band_colors [expr { $counter % [llength $band_colors] }]]>"

            if { $package_key in $to_install } {
                set install_checked "checked"
            } else { 
                set install_checked ""
            }
            if { $package_key in $to_enable } {
                set enable_checked "checked"
            } else { 
                set enable_checked ""
            }

            if { $install_enable_p } {
                append widget "<td align=center><input type=checkbox $install_checked name=install value=\"$package_key\"
                onclick=\"if (!checked) document.forms\[0\].elements\[$checkbox_count+1\].checked=false\"></td>
                <td align=center><input type=checkbox $enable_checked name=enable value=\"$package_key\"
                onclick=\"if (checked) document.forms\[0\].elements\[$checkbox_count\].checked=true\"></td>"
            } else {
                append widget "
                <td align=center><input type=checkbox $enable_checked name=enable value=\"$package_key\"></td>"
            }

            append widget "
           <td>$package(package-name) $package(name)</td>
    <td>$package_rel_path</td>
            <td>$comment</td>
           </tr>"
        }
        incr checkbox_count 2
    }
    append widget "</table></blockquote>"
    return $widget
}


ad_proc -private apm_higher_version_installed_p {
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

    # DRB: I turned this into a simple select by rearranging the code and
    # stuck the result into queryfiles.

    # LARS: Default to 1 (the package_key/version_name you supplied was higher than what's on the system)
    # for the case where nothing it returned, because this implies that there was no highest version installed,
    # i.e., no version at all of the package was installed.
    return [db_string apm_higher_version_installed_p {} -default 1]
}



ad_proc -private apm_build_repository {
    {-debug:boolean 0} 
    {-channels *} 
    {-head_channel 5-9} 
} {    

    Rebuild the repository on the local machine.  
    Only useful for the openacs.org site.   
    Adapted from Lars' build-repository.tcl page.
    @param debug_p Set to 1 to test with only a small subset of packages instead of the whole cvs tree.
    @param head_channel The artificial branch label to apply to HEAD.  Should be one minor version past the current release.
    @channels@ Generate apm files for the matching channels only
    @author Lars Pind (lars@collaboraid.biz)
    @return 0 for success.   Also outputs debug strings to log.

} {

    #----------------------------------------------------------------------
    # Configuration Settings
    #----------------------------------------------------------------------

    set cd_helper 		"[acs_root_dir]/bin/cd-helper"

    set cvs_command 		"cvs"
    set cvs_root 		":pserver:anonymous@cvs.openacs.org:/cvsroot"

    set work_dir 		"[acs_root_dir]/repository-builder/"

    set repository_dir 		"[acs_root_dir]/www/repository/"
    set repository_url 		"http://openacs.org/repository/"

    set channel_index_template  "/packages/acs-admin/www/apm/repository-channel-index"
    set index_template 		"/packages/acs-admin/www/apm/repository-index"

    set exclude_package_list {}

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
    catch { exec $cd_helper $work_dir $cvs_command -d $cvs_root -z3 co openacs-4/readme.txt } msg
    catch { exec $cd_helper $work_dir $cvs_command -d $cvs_root -z3 log -h openacs-4/readme.txt } output

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
	}
    }

    set channel_tag($head_channel) HEAD
    ns_log Notice "Repository: Channels are: [array get channel_tag]"


    #----------------------------------------------------------------------
    # Read all package .info files, building manifest file
    #----------------------------------------------------------------------

    # Wipe and re-create the working directory
    file delete -force $work_dir
    file mkdir ${work_dir}
    set update_pretty_date [lc_time_fmt [clock format [clock seconds] -format "%Y-%m-%d %T"] %c]
    
    #cd $work_dir
    
    foreach channel [lsort -decreasing [array names channel_tag]] {

	if {![string match $channels $channel]} continue
	ns_log Notice "Repository: Channel $channel using tag $channel_tag($channel)"
	
	# Wipe and re-create the checkout directory
	file delete -force "${work_dir}openacs-4"
	file delete -force "${work_dir}dotlrn"
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
		
		with_catch errmsg {
		    array set pkg_info [apm_read_package_info_file $spec_file]
		    
		    if { $pkg_info(package.key) in $packages } {
			ns_log Debug "Repository: Skipping package $package_key, because we already have another version of it"
		    } else {
			lappend packages $pkg_info(package.key)
			
			append manifest \
			    "  <package>" \n \
			    "    <package-key>[ad_quotehtml $pkg_info(package.key)]</package-key>\n" \
			    "    <version>[ad_quotehtml $pkg_info(name)]</version>\n" \
			    "    <pretty-name>[ad_quotehtml $pkg_info(package-name)]</pretty-name>\n" \
			    "    <package-type>[ad_quotehtml $pkg_info(package.type)]</package-type>\n" \
			    "    <summary>[ad_quotehtml $pkg_info(summary)]</summary>\n" \
			    "    <description format=\"[ad_quotehtml $pkg_info(description.format)]\">" \
			    [ad_quotehtml $pkg_info(description)] "</description>\n" \
			    "    <release-date>[ad_quotehtml $pkg_info(release-date)]</release-date>\n" \
			    "    <vendor url=\"[ad_quotehtml $pkg_info(vendor.url)]\">" \
			    [ad_quotehtml $pkg_info(vendor)] "</vendor>\n" \
			    "    <maturity>$pkg_info(maturity)</maturity>\n"
			
			if {![info exists pkg_info(maturity_text)]} {
			    set pkg_info(maturity_text) ""
			}
			
			template::multirow append packages \
			    $package_path $package_key $pkg_info(name) $pkg_info(package-name) \
			    $pkg_info(package.type) $pkg_info(summary) $pkg_info(description) \
			    $pkg_info(release-date) $pkg_info(vendor.url) $pkg_info(vendor) \
			    $pkg_info(maturity) $pkg_info(maturity_text) \
			    $pkg_info(license)  $pkg_info(license_url)
			
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
			    
			    set tmp_filename [ns_tmpnam]
			    lappend cmd  --files-from $tmp_filename -C $packages_root_path
			    
			    set fp [open $tmp_filename w]
			    foreach file $files {
				puts $fp $package_key/$file
			    }
			    close $fp
			    
			    lappend cmd "|" [apm_gzip_cmd] -c ">" $apm_file
			    ns_log Notice "Executing: $cmd"
			    if {[catch "exec $cd_helper $packages_root_path $cmd" errmsg]} {
				ns_log notice "Error during tar in repository creation for\
					file ${channel_dir}$pkg_info(package.key)-$pkg_info(name).apm:\
					\n$errmsg\n$::errorCode,$::errorInfo"
			    }
			    file delete $tmp_filename
			}
			
			set apm_url "${repository_url}$channel/$pkg_info(package.key)-$pkg_info(name).apm"
			
			append manifest "    <download-url>$apm_url</download-url>\n"
			foreach elm $pkg_info(provides) {
			    append manifest "    <provides " \
				"url=\"[ad_quotehtml [lindex $elm 0]]\" " \
				"version=\"[ad_quotehtml [lindex $elm 1]]\" />\n"
			}
			
			foreach elm $pkg_info(requires) {
			    append manifest "    <requires " \
				"url=\"[ad_quotehtml [lindex $elm 0]]\" " \
				"version=\"[ad_quotehtml [lindex $elm 1]]\" />\n"
			}
			append manifest "  </package>\n"
		    }
		} {
		    ns_log Notice "Repository: Error on spec_file $spec_file: $errmsg\n$::errorInfo\n"
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
	puts $fw "<h2>OpenACS $channel Core and compatibile packages</h2>
           <p>Packages can be installed with the OpenACS Automated Installer on
           your OpenACS site at <code>/acs-admin/install</code>.  Only packages
           designated compatible with your OpenACS kernel will be shown.</p>
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

    # Write the index page
    ns_log Notice "Repository: Writing repository index page to ${work_dir}repository/index.adp"
    template::multirow create channels name tag
    foreach channel [lsort -decreasing [array names channel_tag]] {
	template::multirow append channels $channel $channel_tag($channel)
    }
    set fw [open "${work_dir}repository/index.adp" w]
    puts $fw "<master>\n<property name=\"doc(title)\">OpenACS Package Repository</property>\n\n"
    puts $fw [template::adp_include -- $index_template \
		  [list &channels channels update_pretty_date $update_pretty_date]]
    close $fw


    # Without the trailing slash
    set work_repository_dirname "${work_dir}repository"
    set repository_dirname [string range $repository_dir 0 end-1]
    set repository_bak "[string range $repository_dir 0 end-1]_bak"

    ns_log Notice "Repository: Moving work repository $work_repository_dirname to live repository dir at <a href=\"/repository\/>$repository_dir</a>\n"

    if { [file exists $repository_bak] } {
	file delete -force $repository_bak
    }
    if { [file exists $repository_dirname] } {
	file rename $repository_dirname $repository_bak
    }
    file rename $work_repository_dirname  $repository_dirname

    ns_log Debug "Repository: DONE"

    return 0
}
    
