ad_page_contract {

    Deletes a package from the database and the filesystem.

    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date Fri Oct 13 08:42:50 2000
    @cvs-id $Id$
} {
    version_id:naturalnum
    {remove_files:boolean 0}
    {sql_drop_scripts:multiple ""}
}


if {![apm_version_installed_p $version_id]} {
    doc_body_append "[apm_header "Package Deleted."]
The version you have indicated has been deleted.<p>
Return to the <a href=\"index\">index</a>.
[ad_footer]
"
ad_script_abort
}

apm_version_info $version_id

doc_body_append [apm_header "Delete"]

db_transaction {
    apm_package_delete -sql_drop_scripts $sql_drop_scripts -remove_files=0 -callback apm_doc_body_callback $package_key
} on_error {
    if {[apm_package_registered_p $package_key] } {
	doc_body_append "The database returned the following error
	message <pre><blockquote>[ad_quotehtml $errmsg]</blockquote></pre>"
    }
}

doc_body_append "
</ul>
<p>
<p>You should restart the server now to make sure the memory footprint and cache of the package is cleared out. <a href=\"../server-restart\">Click here</a> to restart the server now.</p>
[ad_footer]
"
