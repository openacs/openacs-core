ad_page_contract {

    Removes a file.

    @author Bryan Quinn (bquinn@arsdigita.com)

    @creation-date 17 April 2000
    @param file_id An array of file ids to remove.
    @cvs-id $Id$
} {
    {version_id:naturalnum}
    {file_id:multiple}
}

if {![db_0or1row apm_get_version_id "
select distinct version_id 
from apm_package_files 
where file_id in ([join $file_id ","])"]} {
    ad_returnredirect "version-files?version_id=$version_id"
    ad_script_abort
}

db_transaction {
    db_dml apm_delete_files "delete from apm_package_files 
    where file_id in ([join $file_id ","])"
    apm_package_install_spec $version_id
} on_error {
    ad_return_error "File Removal Error" "The following error was returned when
    trying to remove the files:<blockquote><pre>[ad_quotehtml $errmsg]</pre></blockquote>"
}

db_release_unused_handles
ad_returnredirect "version-files?version_id=$version_id"