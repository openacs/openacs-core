# creation-date 2007-01-21
# author Dave Bauer (dave@solutiongrove.com)
# includable search form
# results should be appended to multirow called users
# ADP level
# default local authority search

ad_form -name user-search -method GET -export {authority_id object_id} -form {
    {search_text:text(text),optional
	{label "Search"}
    }
} -on_request {
    element set_value user-search search_text $search_text
} -on_submit {

}
if {![info exists orderby]} {
    set orderby ""
}
set search_text [string tolower $search_text]
set search_terms [list]
foreach term [split $search_text] {
    lappend search_terms $term
}

set name_search "'()'"
if {[llength $search_terms]} {
    set name_search "([join $search_terms |])"
}

set system_name [ad_system_name]
    db_foreach get_users "
select 
first_names,
last_name, 
email, 
username,
user_id,
authority_id
from cc_users
where 
(	
  lower(first_names) ~ :name_search
  or lower(last_name) ~ :name_search
)
or lower(username) like '%' || :search_text || '%'
or lower(email) like '%' || :search_text || '%'
" {

set status [list]
if {[info exists object_id]} {
    set group_member_p [permission::permission_p -object_id $object_id -party_id $user_id -privilege $privilege]
    set status ""
    
} else {
    set group_member_p [group::member_p -group_id $group_id -user_id $user_id -cascade]
    set group_name [group::get_element -element group_name -group_id $group_id]
    if {$group_member_p} {
	lappend status "[_ acs-authentication.Member_of_group_name]"
    } else {
	lappend status "[_ acs-authentication.Not_a_member_of_group_name]"
    }
    set status [join $status "<br />"]
}
    template::multirow -ulevel 2 -local append users $first_names $last_name $username $email $status $group_member_p "" "" "" $user_id $authority_id
}

set orderby_list [split $orderby ,]
set orderby_column [lindex $orderby_list 0]
set direction [lindex $orderby_list 1]
set direction [string map {asc -increasing desc -decreasing} $direction]
if {$orderby_column ne ""} {
    template::multirow -ulevel 2 -local sort users $direction $orderby_column
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
