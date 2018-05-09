set admin_p [permission::permission_p -object_id [ad_conn subsite_id] -privilege admin -party_id [ad_conn untrusted_user_id]]

list::create \
    -name services \
    -multirow services \
    -no_data "[_ acs-subsite.No_services]" \
    -elements {
        instance_name {
            label "[_ acs-subsite.Name]"
            link_url_eval {$name/}
        }
    }

set services [list]

foreach url [site_node::get_children -package_type apm_service -node_id [subsite::get_element -element node_id]] {
    array unset node 
    array set node [site_node::get_from_url -url $url -exact]

    if { $node(package_key) ne "acs-subsite" && [permission::permission_p -object_id $node(object_id) -privilege read] } {
        lappend services [list \
                                  $node(instance_name) \
                                  $node(node_id) \
                                  $node(name) \
                                  $node(object_id)]
    }
}

# Sort them by instance_name
set services [lsort -index 0 $services]

multirow create services instance_name node_id name package_id read_p

foreach elm $services {
    multirow append services \
        [lindex $elm 0] \
        [lindex $elm 1] \
        [lindex $elm 2] \
        [lindex $elm 3] \
        [lindex $elm 4]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
