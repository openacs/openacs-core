ad_page_contract {
    Delete an application.

    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-05-28
    @cvs-id $Id$
} {
    node_id:integer,multiple
}

# TODO:
# Add some kind of confirmation

db_transaction {
    foreach id $node_id {
        set package_id [site_node::get_object_id -node_id $id]
        
        # Unmount the application
        site_node::unmount -node_id $id

        # Delete the node
        site_node::delete -node_id $id
        
        # Delete the instance
        apm_package_instance_delete $package_id
        
    }
}

ad_returnredirect .

