ad_page_contract {
    Delete an application.

    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-05-28
    @cvs-id $Id$
} {
    node_id:integer,multiple
    {confirm_p 0}
}

if { !$confirm_p } {
    set num [llength $node_id]

    if { $num == 0 } {
        ad_returnredirect .
        return
    }

    set page_title "Delete [ad_decode $num 1 "Application" "Applications"]"
    set context [list [list "." "Applications"] $page_title]
    set yes_url [export_vars -base [ad_conn url] { node_id:multiple { confirm_p 1 } }]
    set no_url "."

    return
}

# First unmount and delete the site-nodes, then delete the package, in separate transactions, 
# so even if the package deletion fails, it'll be gone from this subsite.
set package_id [list]

db_transaction {
    foreach id $node_id {
        lappend package_id [site_node::get_object_id -node_id $id]
        
        # Unmount the application
        site_node::unmount -node_id $id

        # Delete the node
        site_node::delete -node_id $id
    }
}

db_transaction {
    foreach id $package_id {
        # Delete the instance
        apm_package_instance_delete $id
    }
} on_error {
    set error_p 1
    global errorInfo
    ns_log Error "Error deleting package with package_id $id: $errmsg\n$errorInfo"
    # Hm. Not sure what to do. For now, let's rethrow the error.
    error $errmsg $errorInfo
}
     
ad_returnredirect .


