ad_page_contract {

    Delete a package instance. If the package is 
    mounted it will be unmounted before deletion and an
    attempt will be made to delete the node.

    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date Mon Oct 23 14:58:57 2000
    @cvs-id $Id$

} {
    package_id:naturalnum
}
db_transaction {

    # DRB: There used to be a "catch" around the "set" but I removed it because
    # 1. blank is returned if no node_id exists for the object
    # 2. the following "if" would throw an error if the "catch" caught anything ...

    set node_id [site_node::get_node_id_from_object_id -object_id $package_id]

    # DRB: This is a small trick.  If you mount subsite "foo", visit its sitemap page
    # and delete it, you got an error when the code attempted to return.  So this code
    # will go to the deleted node's parent page which should either be the site map page
    # you were at when you clicked "delete" or its parent (the case mentioned above).

    set parent [site_node::closest_ancestor_package \
		    -node_id $node_id \
		    -package_key acs-subsite \
		    -element url]

    # node_id was null so we're not deleting a mounted subsite instance
    if {$parent eq "" } {
	set parent [ad_conn subsite_url]
    }

    if { $node_id ne "" } {
        # The package is mounted
        site_node::unmount -node_id $node_id
        site_node::delete -node_id $node_id
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
	
ad_returnredirect ${parent}admin/site-map
