ad_page_contract {

    Offer user a chance to confirm or deny package creation scripts.

    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date Mon Oct  9 00:15:52 2000
    @cvs-id $Id$
} {

}
set title "Package Installation"
set context [list [list "/acs-admin/apm/" "Package Manager"] $title]
set body {
    <h2>Select Data Model Scripts to Run</h2>
    <p>
    Check all the files you want to be loaded into the database.<p>
    <form action="packages-install-4" method="post">
}

set sql_file_list [list]
set file_count 0
foreach pkg_info [ad_get_client_property apm pkg_install_list] {

    set package_key [pkg_info_key $pkg_info]
    set package_path [pkg_info_path $pkg_info]

    array set version [apm_read_package_info_file [pkg_info_spec $pkg_info]]
    set final_version_name $version(name)

    # Determine if we are upgrading or installing.
    if { [apm_package_upgrade_p $package_key $final_version_name] == 1} {
        ns_log Debug "Upgrading package [string totitle $version(package-name)] to $final_version_name."
        set upgrade_p 1
        set initial_version_name [db_string apm_package_upgrade_from {} -default ""]
    } else {
        set upgrade_p 0
        set initial_version_name ""
    }

    # Find out which script is appropriate to be run.
    set data_model_in_package 0
    set table_rows ""
    set data_model_files [apm_data_model_scripts_find \
                              -upgrade_from_version_name $initial_version_name \
                              -upgrade_to_version_name $final_version_name \
                              -package_path $package_path \
                              $package_key]

    set sql_file_list [concat $sql_file_list $data_model_files]

    if {$data_model_files ne ""} {
        foreach file $data_model_files {
            set path [lindex $file 0]
            set file_type [lindex $file 1]
            append table_rows [subst {
                <tr>
                <td><input type="checkbox" checked name="sql_file" value="$file_count"></td>
                <td>$path</td>
                <td>[apm_pretty_name_for_file_type $file_type]</td>
                </tr>
            }]
            incr file_count
        }

        if { $version(auto-mount) eq "" 
             && $version(package.type) eq "apm_application" 
         } {
            set mount_html [subst {
                <div>
                <input type="checkbox" name="mount_packages" value="$version(package.key)" checked> 
                Mount package under the main site at path 
                <input type="text" name="mount_path.$version(package.key)" value="$version(package.key)">
                </div>
            }]
        } else {
            set mount_html ""
        }
        append body [subst {
            <p>Select what data files to load for $version(package-name) $final_version_name
            <blockquote>
            <table cellpadding='3' cellspacing='3' class='list-table'>
            <tr>
            <th>Load</th>
            <th>File Name</th>
            <th>File Type</th>
            </tr>
            $table_rows
            </table>
            $mount_html
            </blockquote> <p>
        }]
    }
}

ad_set_client_property -clob t apm sql_file_paths $sql_file_list

if {$sql_file_list eq ""} {
    ad_returnredirect packages-install-4
    ad_script_abort
}

append body {
    <input type=submit value="Install Packages">
    </form>
}

ad_return_template apm
#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

