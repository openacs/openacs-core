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

doc_body_append [apm_header [list "version-view?version_id=$version_id" "$pretty_name $version_name"] "Delete"]

# Unmount all instances of this package with the Tcl API that invokes before-unmount callbacks
db_foreach all_package_instances {
    select site_nodes.node_id
    from apm_packages, site_nodes
    where apm_packages.package_id = site_nodes.object_id
    and   apm_packages.package_key = :package_key
} {
    set url [site_node::get_url -node_id $node_id]
    doc_body_append "Unmounting package instance at url $url <br />"
    site_node::unmount -node_id $node_id
}

# Delete the package instances with Tcl API that invokes before-uninstantiate callbacks
db_foreach all_package_instances {
    select package_id
    from apm_packages
    where package_key = :package_key
} {
    doc_body_append "Deleting package instance $package_id <br />"
    apm_package_instance_delete $package_id
}

# Invoke the before-uninstall Tcl callback before the sql drop scripts
apm_invoke_callback_proc -version_id $version_id -type before-uninstall

if {![empty_string_p $sql_drop_scripts]} {
    
    doc_body_append "Now executing drop scripts.
<ul>
"
    foreach path $sql_drop_scripts {
	doc_body_append "<li><pre>"
	db_source_sql_file -callback apm_doc_body_callback "[acs_package_root_dir $package_key]/$path"
	doc_body_append "</pre>"
    }
}

db_transaction {
    apm_package_delete -remove_files=$remove_files -callback apm_doc_body_callback $package_key
} on_error {
    if {[apm_package_registered_p $package_key] } {
	doc_body_append "The database returned the following error
	message <pre><blockquote>[ad_quotehtml $errmsg]</blockquote></pre>"
    }
}

doc_body_append "
</ul>
<p>
Return to the <a href=\"index\">index</a>.
[ad_footer]
"
