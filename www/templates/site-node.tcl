set my_url [ad_conn url]
set user_id [ad_conn user_id]

db_multirow site_nodes site_nodes {
    select site_node__url(node_id) as url,
    acs_object__name(object_id) as name
    from site_nodes
    where parent_id = site_node__node_id(:my_url,null)
    and object_id is not null
    and acs_permission__permission_p(
        object_id,
        coalesce(:user_id, acs__magic_object_id('the_public')),
        'read') = 't'
}

set context [list]

etp::get_page_attributes
etp::get_content_items

set etp_link [etp::get_etp_link]
