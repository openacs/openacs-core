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


