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

db_foreach apm_package_drop_scripts {
    select file_id, path 
    from apm_package_files
    where version_id = :version_id
    and file_type = 'data_model_drop'
    and (db_type is null or db_type = :db_type)
} {
    append file_list "  <tr>
    <td><input type=checkbox name=\"sql_drop_scripts\" value=$file_id></td>
    <td>$path</td>
  </tr>"
} if_no_rows {
    set file_list ""
}

if {![empty_string_p $file_list]} {
    set file_list "
    Please check the drop scripts you want to run.  Be aware that this will
    erase all data associated with this package from the database.
<table cellpadding=3 cellspacing=3>
$file_list
</table>"
} 

set body "[apm_header -form "action=\"package-delete-2\" method=\"post\"" [list "version-view?version_id=$version_id" "$pretty_name $version_name"] "Delete"]

<p>Deleting a package removes all record of it from the APM's database.</p>

<p>

[export_form_vars version_id]
$file_list

<p>
<input type=\"checkbox\" name=\"remove_files\" value=\"1\"> Also delete package files from the filesystem.</p>
<input type=submit value=\"Delete Package\">
</form>
[ad_footer]"

doc_return 200 text/html $body


