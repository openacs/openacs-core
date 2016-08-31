ad_page_contract {

    Reusable page for searching for a user by email or last_name.
    Returns to "target" with user_id_from_search, first_names_from_search,
    ast_name_from_search, and email_from_search, and passing along all
    form variables listed in "passthrough".
    
    @cvs-id $Id$

    @param email search string
    @param last_name search string
    @param keyword For looking through both email and last_name (optional)
    @param target URL to return to
    @param passthrough Form variables to pass along from caller
    @param limit_to_users_in_group_id Limits search to users in the specified group id.  This can be a comma separated list to allow searches within multiple groups. (optional)
    @param limit_to_user_id This is useful is you don't want to show a list of user_ids. This could be a comma separated list. (optional)
    @param from_user_id is used if you want to merge the user_id with user_id_from_search (optional)

    @author Jin Choi (jsc@arsdigita.com)
} {
    {email ""}
    {last_name ""}
    keyword:optional
    target
    {passthrough ""}
    {limit_to_users_in_group_id:naturalnum ""}
    {only_authorized_p:boolean 1}
    {limit_to_user_id:naturalnum ""}
    {from_user_id:naturalnum ""}
} -properties {
    group_name:onevalue
    search_type:onevalue
    keyword:onevalue
    email:onevalue
    last_name:onevalue
    only_authorized_p:onevalue
    export_authorize:onevalue
    passthrough_parameters:onevalue
    context:onevalue
}

# Check input.
set exception_count 0
set exception_text ""

set context [list [list "./" "Users"] "Search"]

if {[info exists keyword]} {
    # this is an administrator 
    if { $keyword eq "" } {
	incr exception_count
	append exception_text "<li>You forgot to type a search string!\n"
    }
} else {
    # from one of the user pages
    if { $email eq "" && $last_name eq "" } {
	incr exception_count
	append exception_text "<li>You must specify either an email address or last name to search for.\n"
    }

    if { $email ne ""  && $last_name ne "" } {
	incr exception_count
	append exception_text "<li>You can only specify either email or last name, not both.\n"
    }

    if { ![info exists target] || $target eq "" } {
	incr exception_count
	append exception_text "<li>Target was not specified. This shouldn't have happened,
please contact the <a href=\"mailto:[ad_host_administrator]\">administrator</a>
and let them know what happened.\n"
    }
}

if { $exception_count != 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

####
# Input okay. Now start building the SQL

set where_clause [list]
if { [info exists keyword] } {
    set search_type "keyword"
    set sql_keyword "%[string tolower $keyword]%"
    lappend where_clause "(email like :sql_keyword or lower(first_names || ' ' || last_name) like :sql_keyword)"
} elseif { $email ne "" } {
    set search_type "email"    
    set sql_email "%[string tolower $email]%"
    lappend where_clause "email like :sql_email"
} else {
    set search_type "last"        
    set sql_last_name "%[string tolower $last_name]%"
    lappend where_clause "lower(last_name) like :sql_last_name"
}

if { $only_authorized_p } {
    lappend where_clause {member_state = 'approved'}
}

if { ![info exists passthrough] } {
    set passthrough_parameters ""
} else {
    set passthrough_parameters [export_entire_form_as_url_vars $passthrough]
}

if { $limit_to_user_id ne "" } {
    set limit_to_user_id [join $limit_to_user_id ","]
    lappend where_clause "cc_users.user_id not in ($limit_to_user_id)"
}

if { $limit_to_users_in_group_id ne "" } {
    set query [subst {
        select distinct first_names, last_name, email, member_state, email_verified_p, cu.user_id
        from cc_users cu, group_member_map gm, membership_rels mr
        where cu.user_id = gm.member_id
        and gm.rel_id = mr.rel_id
        and gm.group_id = :limit_to_users_in_group_id
        and [join $where_clause "\nand "]
    }]

} else {
    set query [subst {
        select user_id, email_verified_p, first_names, last_name, email, member_state
        from cc_users
        where [join $where_clause "\nand "]
    }]
}



set i 0

set user_items ""

set rowcount 0

db_foreach user_search_admin $query {
    incr rowcount

    set user_id_from_search $user_id
    set first_names_from_search $first_names
    set last_name_from_search $last_name
    set email_from_search $email
    
    if { $from_user_id eq "" } {
	set user_search:[set rowcount](user_id) $user_id
    } else {
	set user_search:[set rowcount](user_id) $from_user_id
    }

    set user_search:[set rowcount](first_names) $first_names
    set user_search:[set rowcount](last_name) $last_name
    set user_search:[set rowcount](email) $email
    set user_search:[set rowcount](export_vars) [export_vars {user_id_from_search first_names_from_search last_name_from_search email_from_search}]
    set user_search:[set rowcount](member_state) $member_state
    
    if { $member_state ne "approved" } {
	set user_search:[set rowcount](user_finite_state_links) [join [ad_registration_finite_state_machine_admin_links $member_state $email_verified_p $user_id_from_search [export_vars -base search {email last_name keyword target passthrough limit_to_users_in_group_id only_authorized_p}]] " | "]
    } else {
	set user_search:[set rowcount](user_finite_state_links) ""
    }
}

set user_search:rowcount $rowcount

# We are limiting the search to one group - display that group's name
if { $limit_to_users_in_group_id ne "" 
     && ![regexp {[^0-9]} $limit_to_users_in_group_id] } {
    set group_name [db_string user_group_name_from_id {
        select group_name from
        user_groups
        where group_id = :limit_to_users_in_group_id
    }]
    set title "User search in $group_name"
} else {
    set group_name ""
    set title "User search"
}

set export_authorize [export_ns_set_vars {url} {only_authorized_p}]

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
