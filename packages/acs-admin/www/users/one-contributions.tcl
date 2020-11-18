ad_page_contract {
    Display the contributions of a user.

    This content was previously part of one.tcl, but on laarge
    systems, this information of overboarding and it is dangerous to
    visit the page, which might become very large and expensive to
    compute.
    
} {
    user_id:naturalnum,notnull
}

set context [list [list "./" "Users"] "One User Contribution"]

set user_dict [acs_user::get -user_id $user_id -array user_info]
if {[array size user_info] == 0} {
    ad_return_complaint 1 "<li>We couldn't find user #$user_id; perhaps this person was deleted?"
    ad_script_abort
}

set number_contributions [db_string nr_contribs {
    select count(*) from acs_objects
    where creation_user = :user_id
}]

db_multirow user_contributions user_contributions {
    select at.pretty_name,
           at.pretty_plural,
           to_char(a.creation_date, 'YYYY-MM-DD HH24:MI:SS') as creation_date,
           acs_object.name(a.object_id) as object_name
      from acs_objects a, acs_object_types at
     where a.object_type = at.object_type
       and a.creation_user = :user_id
     order by pretty_name, creation_date desc, object_name
}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
