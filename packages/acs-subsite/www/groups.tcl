ad_page_contract {
    Applications

    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-02
    @cvs-id $Id$
}

set page_title "Groups"
set context [list $page_title]

set user_id [ad_conn user_id]

# Get the subsite node ID
set subsite_url [site_node_closest_ancestor_package_url]
array set subsite_sitenode [site_node::get -url $subsite_url]
set subsite_node_id $subsite_sitenode(node_id)

db_multirow groups select_subsites {}

list::create \
    -name groups \
    -multirow groups \
    -key node_id \
    -elements {
        instance_name {
            label "Name"
            link_url_eval {$name/}
        }
    }



