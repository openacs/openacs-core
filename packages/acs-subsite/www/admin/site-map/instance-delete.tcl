ad_page_contract {

    Delete a package instance. If the package is 
    mounted it will be unmounted before deletion and an
    attempt will be made to delete the node.

    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date Mon Oct 23 14:58:57 2000
    @cvs-id $Id$

} {
    package_id:naturalnum
    {root_id ""}
}

db_transaction {
    if { ![catch {set node_id [site_node::get_node_id_from_object_id -object_id $package_id]} errmsg] } {
        # The package is mounted
        site_node::unmount -node_id $node_id
        site_node::delete -node_id $node_id
    } else {
        set node_id ""
    }

    # Delete the package
    apm_package_instance_delete $package_id

} on_error {
    if {[db_string instance_delete_doubleclick_ck {
	select decode(count(*), 0, 0, 1) from apm_packages
	where package_id = :package_id
    } -default 0]} {
	ad_return_error "Error Deleting Instance" "The following error was returned:
	<blockquote><pre>[ad_quotehtml $errmsg]</pre></blockquote>"
    }
}
	
ad_returnredirect [ad_decode $node_id "" unmounted "index?root_id=$root_id"]
