if { [string equal [ad_conn package_url] "/"] } {
    set pretty_name [_ acs-subsite.community]
    set pretty_plural [_ acs-subsite.communities]
} else {
    set pretty_name [_ acs-subsite.subcommunity]
    set pretty_plural [_ acs-subsite.subcommunities]
}

set admin_p [permission::permission_p -object_id [ad_conn package_id] -privilege admin -party_id [ad_conn untrusted_user_id]]
if { $admin_p } {
    set add_url "[subsite::get_element -element url]admin/subsite-add"
}


list::create \
    -name subsites \
    -multirow subsites \
    -no_data "[_ acs-subsite.No_pretty_plural [list pretty_plural $pretty_plural]]" \
    -elements {
        instance_name {
            label "[_ acs-subsite.Name]"
            link_url_col url
        }
        num_members {
            label "\# [_ acs-subsite.Members]"
            html { align right }
        }
    }


set subsites [list]
set package_ids [list]

foreach url [site_node::get_children -package_key acs-subsite -node_id [subsite::get_element -element node_id]] {
    array unset node 
    array set node [site_node::get_from_url -url $url -exact]

    if { [permission::permission_p -object_id $node(object_id) -privilege read -party_id [ad_conn untrusted_user_id]] } {
        # TODO
        set edit_url {}
        if { [permission::permission_p -object_id $node(object_id) -privilege admin] } {
            set edit_url {}
        }
        lappend subsites [list \
                              $node(instance_name) \
                              $node(node_id) \
                              $node(name) \
                              $node(object_id) \
                              $node(url)]
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

multirow create subsites instance_name node_id name package_id url num_members

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

