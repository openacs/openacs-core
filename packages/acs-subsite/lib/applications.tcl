set admin_p [permission::permission_p -object_id [ad_conn package_id] -privilege admin -party_id [ad_conn untrusted_user_id]]
if { $admin_p } {
    set add_url [export_vars -base "[subsite::get_element -element url]admin/applications/application-add" { { return_url [ad_return_url] } }]
}

list::create \
    -name applications \
    -multirow applications \
    -no_data "[_ acs-subsite.No_applications]" \
    -elements {
        instance_name {
            label "[_ acs-subsite.Name]"
            link_url_eval {$name/}
        }
    }



set applications [list]

foreach url [site_node::get_children -package_type apm_application -node_id [subsite::get_element -element node_id]] {
    array unset node 
    array set node [site_node::get_from_url -url $url -exact]

    if { [permission::permission_p -object_id $node(object_id) -privilege read] } {
        lappend applications [list \
                                  $node(instance_name) \
                                  $node(node_id) \
                                  $node(name) \
                                  $node(object_id)]
    }
}

# Sort them by instance_name
set applications [lsort -index 0 $applications]

multirow create applications instance_name node_id name package_id read_p

foreach elm $applications {
    multirow append applications \
        [lindex $elm 0] \
        [lindex $elm 1] \
        [lindex $elm 2] \
        [lindex $elm 3] \
        [lindex $elm 4]
}

