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
            if { ![empty_string_p $section] } {
                lappend section_list [list "section_$i" $section [list "where" "section_name = '[db_quote $section]'"]]
            }
        }
        lappend section_list [list all "All" [list] ]
        return [list [list section_name "Section:" $package_key $section_list]]
    } else {
        return ""
    }
}

ad_proc apm_header { { -form "" } args } {
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
        set context_bar [eval ad_context_bar $context]
    }
    set header [ad_header $title ""]
    append body "$header\n"
    if {![empty_string_p $form]} {
        append body "<form $form>"
    }
    
    return "$body\n
    <h3>$title</h3>
    $context_bar
    <hr>
    "
}

proc_doc apm_shell_wrap { cmd } { Returns a command string, wrapped it shell-style (with backslashes) in case lines get too long. } {
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
    if {[empty_string_p $pkg_info_list]} {
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
        if { ![string compare [pkg_info_dependency_p $pkg_info] "t"]} {
            # Dependency passed.

            if { $install_enable_p } {
                if { ([lsearch -exact $to_install $package_key] != -1) } {
                    append widget "  <td align=center><input type=checkbox checked 
                    name=install value=\"$package_key\"
                    onclick=\"if (!checked) document.forms\[0\].elements\[$checkbox_count+1\].checked=false\"></td> "
                } else {
                    append widget "  <td align=center><input type=checkbox 
                    name=install value=\"$package_key\"
                    onclick=\"if (!checked) document.forms\[0\].elements\[$checkbox_count+1\].checked=false\"></td>"
                }
            }
            if { [lsearch -exact $to_enable $package_key] != -1 } {
                append widget "
                <td align=center><input type=checkbox checked 
                name=enable value=\"$package_key\" "
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
        } elseif { ![string compare [pkg_info_dependency_p $pkg_info] "f"] } {
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

            if { ([lsearch -exact $to_install $package_key] != -1) } {
                set install_checked "checked"
            } else { 
                set install_checked ""
            }
            if { ([lsearch -exact $to_enable $package_key] != -1) } {
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

