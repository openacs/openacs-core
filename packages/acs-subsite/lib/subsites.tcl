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


list::create \
    -name subsites \
    -multirow subsites \
    -key node_id \
    -elements {
        instance_name {
            label "Name"
            link_url_eval {$name/}
        }
        num_members {
            label "\# Members"
            html { align right }
        }
    }



# Get the subsite node ID
set subsite_url [site_node_closest_ancestor_package_url]
array set subsite_sitenode [site_node::get -url $subsite_url]
set subsite_node_id $subsite_sitenode(node_id)

set subsites [list]
set package_ids [list]

foreach url [site_node::get_children -package_type apm_service -node_id $subsite_node_id] {
    array unset node 
    array set node [site_node::get_from_url -url $url -exact]

    if { [string equal $node(package_key) "acs-subsite"] } { 
        lappend subsites [list \
                              $node(instance_name) \
                              $node(node_id) \
                              $node(name) \
                              $node(object_id) \
                              [permission::permission_p -object_id $node(object_id) -privilege read]]
        lappend package_ids $node(object_id)
    }
}

array set num_members [list]
if { [llength $package_ids] > 0 } { 
    db_foreach num_members "
        select ag.package_id,
               count(member_id) as n_members
        from   application_groups ag,
               group_approved_member_map m
        where  ag.package_id in ('[join $package_ids "','"]')
        and    m.group_id = ag.group_id
        group  by ag.package_id
    " {
        set num_members($package_id) [lc_numeric $n_members]
    }
}

# Sort them by instance_name
set subsites [lsort -index 0 $subsites]

multirow create subsites instance_name node_id name package_id read_p num_members

foreach elm $subsites {
    set package_id [lindex $elm 3]
    if { ![info exists num_members($package_id)] } {
        set num_members($package_id) {}
    }

    multirow append subsites \
        [lindex $elm 0] \
        [lindex $elm 1] \
        [lindex $elm 2] \
        [lindex $elm 3] \
        [lindex $elm 4] \
        $num_members($package_id)
}

