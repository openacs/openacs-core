ad_page_contract {
    Applications

    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-02
    @cvs-id $Id$
}


if { [string equal [ad_conn package_url] "/"] } {
    set pretty_name "community"
    set pretty_plural "communities"
} else {
    set pretty_name "subcommunity"
    set pretty_plural "subcommunities"
}

set page_title [string totitle $pretty_plural]
set context [list $page_title]

set user_id [ad_conn user_id]


set admin_p [permission::permission_p -object_id [ad_conn package_id] -privilege admin]
if { $admin_p } {
    set add_url "[subsite::get_element -element url]admin/subsite-add"
}


# Get the subsite node ID
set subsite_url [site_node_closest_ancestor_package_url]
array set subsite_sitenode [site_node::get -url $subsite_url]
set subsite_node_id $subsite_sitenode(node_id)

db_multirow subsites select_subsites {}

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



