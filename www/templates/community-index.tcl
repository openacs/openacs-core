# /packages/editthispage/templates/article-index.tcl

ad_page_contract {
    @author Luke Pond (dlpond@pobox.com)
    @creation-date 2001-06-01

    This is the default page used to display an index listing
    for an Edit This Page package instance.  It assumes a 
    content type with no extended attributes, and presents
    a listing of all content pages belonging to this package.
    <p>
    If you want to use some other page instead, specify it with 
    the index_template package parameter.

} {
} -properties {
    pa:onerow
    forums:multirow
    sites:multirow
    jobs:multirow
    companies:multirow
}
##config for the boxes
set n_sites 6
set n_jobs  4
set n_companies  6
# logan is changing this


set user_id [ad_conn user_id]

etp::get_page_attributes
etp::get_content_items

set sites_limit [expr $n_sites + 1]
set jobs_limit  [expr $n_jobs + 1]
set companies_limit  [expr $n_companies + 1]

etp::get_content_items -package_id 3894 -result_name sites -limit $sites_limit
etp::get_content_items -package_id 3889 -result_name jobs -limit $jobs_limit
etp::get_content_items -package_id 3906 -result_name companies -limit $companies_limit



#db_multirow forums forums_select {
#    select forum_id, short_name, moderated_p, charter
#      from bboard_forums f
#      where 
#      acs_permission__permission_p(forum_id,:user_id,'bboard_read_forum') = 't'
#      and bboard_id = 2369
#    order by short_name
#}

# olah 
db_multirow forums forums_select {
    select forum_id, name as short_name, posting_policy, charter
      from forums_forums f
      where
      acs_permission__permission_p(forum_id,:user_id,'forum_read') = 't'
      and enabled_p = 't'
      and package_id = 3061
    order by upper(name)
}