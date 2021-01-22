ad_page_contract {
    Delete an application.

    @author Lars Pind (lars@collaboraid.biz)
    @author Gustaf Neumann

    @creation-date 2003-05-28
    @cvs-id $Id$
} {
    {node_id:naturalnum,multiple ""}
    {package_id:naturalnum,multiple ""}
    {return_url:localurl .}
    {confirm_p:boolean 0}
}

foreach id $package_id {
    set id [site_node::get_node_id_from_object_id -object_id $id]
    if {$id ne ""} {
        lappend node_id $id
        set p [lsearch $package_id $id]
        set package_id [lreplace $package_id $p $p]
    }
}
ns_log notice "package_id <$package_id> node_id <$node_id>"

set num [expr {[llength $node_id] + [llength $package_id]}]
set page_title "Delete [ad_decode $num 1 "Application" "Applications"]"
set context [list [list "." "Applications"] $page_title]
set yes_url [export_vars -base [ad_conn url] { node_id:multiple package_id:multiple return_url { confirm_p 1 } }]
set no_url $return_url
set listing ""

if { !$confirm_p } {

    if { $num == 0 } {
        ad_returnredirect .
        return
    }

    append listing <ul>\n
    foreach id $node_id {

        set dict [site_node::get_from_node_id -node_id $id]
        append listing "<li>" \
            [dict get $dict instance_name] " " \
            [dict get $dict url] " " \
            "(instance of [dict get $dict package_key], package_id [dict get $dict package_id])" \
            </li> "\n"
    }

    foreach id $package_id {
        set instance_name [apm_instance_name_from_id $id]
        set package_key   [apm_package_key_from_id $id]
        append listing "<li>" \
            $instance_name " " \
            "(instance of $package_key, unmounted, package_id $id)" \
            </li> "\n"
    }
    append listing </ul>\n

    return
}

# First unmount and delete the site-nodes, then delete the package, in separate transactions, 
# so even if the package deletion fails, it'll be gone from this subsite.
set package_ids $package_id

db_transaction {
    foreach id $node_id {
        lappend package_ids [site_node::get_object_id -node_id $id]
        
        # Unmount the application
        site_node::unmount -node_id $id

        # Delete the node
        site_node::delete -node_id $id
    }
}

db_transaction {
    foreach id $package_ids {
        # Delete the instance
        apm_package_instance_delete $id
    }
} on_error {
    set error_p 1
    ns_log Error "Error deleting package with package_id $id: $errmsg\n$::errorInfo"
    # Hm. Not sure what to do. For now, let's rethrow the error.
    error $errmsg $::errorInfo
}
     
ad_returnredirect $return_url


#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
