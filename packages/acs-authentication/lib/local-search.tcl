ad_include_contract {

    
    Includable search form.
    Results should be appended to multirow called users at ADP level
    Default local authority search.

    @creation-date 2007-01-21
    @author Dave Bauer (dave@solutiongrove.com)

} {
    authority_id:naturalnum,notnull
    {search_text ""}
    {orderby:token ""}
    {return_url:localurl ""}
    {member_url:localurl ""}
    group_id:naturalnum,notnull
    {rel_type:token ""}
    object_id:naturalnum,optional
    privilege:token,optional
} -validate {
    object_id_with_privilege {
        if {[info exists object_id] && ![info exists privilege]} {
            # needed for the message key
            set formal_name "privilege"
            ad_complain
        }
    }
} -errors {
    object_id_with_privilege [_ acs-tcl.lt_You_must_supply_a_val]
}

ad_form -name user-search -method GET -export {authority_id object_id} -form {
    {search_text:text(text),optional
	{label "Search"}
    }
} -on_request {
    element set_value user-search search_text $search_text
} -on_submit {

}

set search_text [string tolower $search_text]

set name_search "'()'"
if {[llength $search_text]} {
    set name_search "([join $search_text |])"
}

set system_name [ad_system_name]
# Why don't we use authority_id if we get one from the parent page?
db_foreach get_users {
    select
     first_names, last_name, email, username, user_id, authority_id
    from cc_users
    where (
     lower(first_names) ~ :name_search
     or lower(last_name) ~ :name_search
    )
    or lower(username) like '%' || :search_text || '%'
    or lower(email) like '%' || :search_text || '%'
} {
    if {[info exists object_id]} {
        set group_member_p [permission::permission_p -object_id $object_id -party_id $user_id -privilege $privilege]
        set status ""
    } else {
        set group_member_p [group::member_p -group_id $group_id -user_id $user_id -cascade]
        set group_name [group::get_element -element group_name -group_id $group_id]
        if {$group_member_p} {
            set status [_ acs-authentication.Member_of_group_name]
        } else {
            set status [_ acs-authentication.Not_a_member_of_group_name]
        }
    }
    template::multirow -ulevel 2 -local append users $first_names $last_name $username $email $status $group_member_p "" "" "" $user_id $authority_id
}

set orderby_list [split $orderby ,]
lassign $orderby_list orderby_column direction
set direction [string map {asc -increasing desc -decreasing} $direction]
if {$orderby_column ne ""} {
    template::multirow -ulevel 2 -local sort users $direction $orderby_column
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
