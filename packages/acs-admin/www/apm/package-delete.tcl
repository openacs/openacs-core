ad_page_contract {

    Deletes a package and all of its versions from the package manager.

    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date Fri Oct 13 08:40:54 2000
    @cvs-id $Id$
} {
    version_id:naturalnum
}

apm_version_info $version_id
# Find the drop scripts.

set db_type [db_type]

set dependent_packages_list [db_list dependency_p {
select package_key
    from apm_package_versions av
    where av.enabled_p = 't'
      and av.installed_p = 't'
      and exists (select 1 from
                  apm_package_dependencies ad
                  where ad.version_id = av.version_id 
                    and ad.service_uri = :package_key
                    and ad.dependency_type = 'requires'
                  )
}]

if { [llength $dependent_packages_list] > 0 } {
    set dependency_warning_text "
The following packages depend on package <code>$package_key</code> that you are about to delete: 

<p>
<code> 
  [join $dependent_packages_list "<br>"]
</code>
</p>
"
} else {
    set dependency_warning_text ""
}

set initial_install_p [db_string initial_install_p {
    select initial_install_p
    from apm_package_types
    where package_key = :package_key
}]

if {$initial_install_p eq "t"} {
    set kernel_deletion_warning "
<p>
  You are about to delete package <code>$package_key</code> which is part of the <b>OpenACS core</b>
</p>
"
} else {
    set kernel_deletion_warning ""
}

if { $dependency_warning_text ne "" || $kernel_deletion_warning ne "" } {
    set warning_text "
<p>
  <b><font color=\"red\">WARNING</font></b> 
</p>

$kernel_deletion_warning

$dependency_warning_text

<p>
<b>Proceeding with the deletion of the package may render the system in a broken state.</b>
</p>
"
} else {
    set warning_text ""
}

set file_list ""
foreach file [apm_get_package_files -package_key $package_key -file_types data_model_drop] {
    append file_list "  <tr>
    <td><input type=checkbox name=\"sql_drop_scripts\" value=$file checked></td>
    <td>$file</td>
  </tr>"
} 

if {$file_list ne ""} {
    set file_list "
    We recommend sourcing all of the drop scripts for the package.  Be aware that this will
    erase all data associated with this package from the database.
<table cellpadding=3 cellspacing=3>
$file_list
</table>"
} 

set body "[apm_header -form "action=\"package-delete-2\" method=\"post\"" [list "version-view?version_id=$version_id" "$pretty_name $version_name"] "Delete"]

$warning_text

<p>Deleting a package removes all record of it from the APM's database.</p>

<p>

[export_form_vars version_id]
$file_list

<p>
<input type=submit value=\"Delete Package\">
</form>
[ad_footer]"

doc_return 200 text/html $body


