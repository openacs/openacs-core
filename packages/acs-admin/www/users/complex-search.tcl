ad_page_contract {

    Page for searching for a user by group membership, email,
    first_names, last_name, how many days ago they last visited, how
    many days ago they registered, and how many times they have
    visited.

    This page is based on "search.tcl", so in theory it should
    reusable but that has not been tested.  See "search.tcl" for
    details.
    
    @cvs-id $Id$

    @param email search string (optional)
    @param last_name_starts_with search string (optional)
    @param first_names search string (optional)
    @param registration_before_days search value--users must have registered more than this number of days ago (optional)
    @param registration_after_days search value--users must have registered within this number of days (optional)
    @param last_visit_before_days search value--users whose last login was more than this number of days ago (optional)
    @param last_visit_after_days search value--users whose last login was within this number of days (optional)
    @param number_visits_below search value--users who have visited fewer than this many times (optional)
    @param number_visits_above search value--users who have visited at least this many times (optional)
    @param combine_method the string "and" or "or" that tells where to search for users matching ALL the criteria or ANY of the criteria
    @param keyword For looking through both email and last_name (optional)
    @param target URL to return to (untested)
    @param passthrough Form variables to pass along from caller (untested)
    @param limit_to_users_in_group_id Limits search to users in the specified group id.  This can be a comma separated list to allow searches within multiple groups. (optional)

    @author Mark Thomas (mthomas@arsdigita.com)
} {
    {authority_id:naturalnum ""}
    {email ""}
    {ip ""}
    {last_name_starts_with ""}
    {first_names ""}
    keyword:optional
    target
    {passthrough ""}
    {limit_to_users_in_group_id:integer ""}
    {only_authorized_p:boolean 1}
    {only_needs_approval_p:boolean 0}
    {registration_before_days:integer -1}
    {registration_after_days:integer -1}
    {last_visit_before_days:integer -1}
    {last_visit_after_days:integer -1}
    {number_visits_below:integer -1}
    {number_visits_above:integer -1}
    {combine_method "all"}
} -properties {
    group_name:onevalue
    keyword:onevalue
    email:onevalue
    last_name:onevalue
    first_name:onevalue
    only_authorized_p:onevalue
    export_authorize:onevalue
    passthrough_parameters:onevalue
    combine_method:onevalue
    context:onevalue
}

# Check input.
set exception_count 0
set exception_text ""


set context [list [list "index" "Users"] "Complex search"]

if { ![info exists target] || $target eq "" } {
    incr exception_count
    append exception_text "<li>Target was not specified. This shouldn't have
happened, please contact the
<a href=\"mailto:[ad_host_administrator]\">administrator</a>
and let them know what happened.\n"
}

if { $exception_count != 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}


if {$combine_method eq "any"} {
    set where_conjunction "or"
} else {
    set where_conjunction "and"
    set combine_method "all"
}

if { ![info exists passthrough] } {
    set passthrough_parameters ""
} else {
    set passthrough_parameters "[export_entire_form_as_url_vars $passthrough]"
}


####

# Input okay. Now start building the SQL

set where_clause [list]
set rowcount 0

if {$limit_to_users_in_group_id ne "" 
    && ![regexp {[^-0-9]} $limit_to_users_in_group_id] } {
    set group_name [db_string user_group_name_from_id {
        select group_name
        from groups
        where group_id = :limit_to_users_in_group_id
    }]
    incr rowcount
    set criteria:[set rowcount](data) \
        "Is a member of '$group_name'"
}

if { $authority_id ne "" } {
    lappend where_clause "authority_id = :authority_id"
    incr rowcount
    set criteria:[set rowcount](data) "Authority is '[auth::authority::get_element -authority_id $authority_id -element pretty_name]'"
}

if { $email ne "" } {
    set sql_email "%[string tolower $email]%"
    lappend where_clause "email like :sql_email"
    incr rowcount
    set criteria:[set rowcount](data) "Email contains '$email'"
}

if { ([info exists ip] && $ip ne "") } {
    lappend where_clause "creation_ip = :ip"
    incr rowcount
    set criteria:[set rowcount](data) "Creation IP is $ip"
}

if { $last_name_starts_with ne "" } {
    set sql_last_name_starts_with "[string tolower $last_name_starts_with]%"
    lappend where_clause "lower(last_name) like :sql_last_name_starts_with"
    incr rowcount
    set criteria:[set rowcount](data) "Last name starts with '$last_name_starts_with'"
}

if { $first_names ne "" } {
    set sql_first_names "%[string tolower $first_names]%"
    lappend where_clause "lower(first_names) like :sql_first_names"
    incr rowcount
    set criteria:[set rowcount](data) "First names contain '$first_names'"
}

if { $only_authorized_p } {
    lappend where_clause {member_state = 'approved'}
} elseif { $only_needs_approval_p } {
    lappend where_clause {member_state = 'needs approval'}
    incr rowcount
    set criteria:[set rowcount](data) "Needs approval"
}

if { $registration_before_days >= 0 } {
    lappend where_clause [db_map registration_before_days]
    incr rowcount
    set criteria:[set rowcount](data) \
        "Registered more than past $registration_before_days days ago"
}
if { $registration_after_days >= 0 } {
    lappend where_clause [db_map registration_after_days]
    incr rowcount
    set criteria:[set rowcount](data) \
        "Registered within the past $registration_after_days days"
}

if { $last_visit_before_days >= 0 } {
    lappend where_clause [db_map last_visit_before_days]
    incr rowcount
    set criteria:[set rowcount](data) \
        "Most recent visit was more that $last_visit_before_days days ago"
}
if { $last_visit_after_days >= 0 } {
    lappend where_clause [db_map last_visit_after_days]
    incr rowcount
    set criteria:[set rowcount](data) \
        "Visited within the past $last_visit_after_days days"
}

if { $number_visits_below >= 0 } {
    lappend where_clause "n_sessions < :number_visits_below"
    incr rowcount
    set criteria:[set rowcount](data) \
        "Has visited fewer than $number_visits_below times"
}
if { $number_visits_above >= 0 } {
    lappend where_clause "n_sessions >= :number_visits_above"
    incr rowcount
    set criteria:[set rowcount](data) \
        "Has visited at least $number_visits_above times"
}

set criteria:rowcount $rowcount


if { $limit_to_users_in_group_id ne "" } {
    set query {
        select distinct first_names, last_name, email, member_state, email_verified_p, cu.user_id
        from cc_users cu, group_member_map gm
        where (cu.user_id = gm.member_id
               and gm.group_id = :limit_to_users_in_group_id)
    }
    if {[llength $where_clause] > 0} {
        append query \
            "\n$where_conjunction [join $where_clause "\n$where_conjunction "]"
    }
} else {
    set query {select user_id, email_verified_p, first_names, last_name, email, member_state from cc_users}
    if {[llength $where_clause] > 0} {
        append query "\nwhere [join $where_clause "\n$where_conjunction "]"
    }
}
append query "\norder by first_names, last_name"

set rowcount 0

db_foreach user_search_admin $query {
    incr rowcount

    set user_id_from_search $user_id
    set first_names_from_search $first_names
    set last_name_from_search $last_name
    set email_from_search $email
    
    set user_search:[set rowcount](user_id) $user_id
    set user_search:[set rowcount](first_names) $first_names
    set user_search:[set rowcount](last_name) $last_name
    set user_search:[set rowcount](email) $email
    set user_search:[set rowcount](export_vars) [export_vars {
        user_id_from_search first_names_from_search last_name_from_search email_from_search
    }]
    set user_search:[set rowcount](member_state) $member_state
    
    if { $member_state ne "approved" } {
        set user_search:[set rowcount](user_finite_state_links) \
            [join [ad_registration_finite_state_machine_admin_links \
                       $member_state $email_verified_p $user_id_from_search \
                       [export_vars -base /acs-admin/users/complex-search {
                           email last_name keyword target passthrough limit_to_users_in_group_id only_authorized_p
                       }]] " | "]
    } else {
        set user_search:[set rowcount](user_finite_state_links) ""
    }
}

set user_search:rowcount $rowcount

set export_authorize [export_ns_set_vars {url} {only_authorized_p}]


ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
