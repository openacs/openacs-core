if { [string equal [ad_conn package_url] "/"] } {
    set pretty_name "community"
    set pretty_plural "communities"
} else {
    set pretty_name "subcommunity"
    set pretty_plural "subcommunities"
}

set user_id [ad_conn user_id]

set admin_p [permission::permission_p -object_id [ad_conn package_id] -privilege admin]
if { $admin_p } {
    set add_url "[subsite::get_element -element url]admin/subsite-add"
}


# Get the subsite node ID
set subsite_url [site_node_closest_ancestor_package_url]
array set subsite_sitenode [site_node::get -url $subsite_url]
set subsite_node_id $subsite_sitenode(node_id)

multirow create subsites node_id name package_id instance_name read_p

foreach url [site_node::get_children -package_type apm_service -node_id $subsite_node_id] {
    array unset node 
    array set node [site_node::get_from_url -url $url -exact]

    if { [string equal $node(package_key) "acs-subsite"] } { 
        multirow append subsites \
            $node(node_id) \
            $node(name) \
            $node(object_id) \
            $node(instance_name) \
            [permission::permission_p -object_id $node(object_id) -privilege read]
    }
}

list::create \
    -name subsites \
    -multirow subsites \
    -key node_id \
    -elements {
        instance_name {
            label "Name"
            link_url_eval {$name/}
        }
    }



