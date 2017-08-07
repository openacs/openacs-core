ad_page_contract {
  $Id$
} -query {
    state_abbrev
} -properties {} -validate {
    validate_state_abbrev -requires state_abbrev {
        if {$state_abbrev ni {CA HI NV}} {
            ad_complain  "Invalid state abbreviation $state_abbrev."
        }
    }
}

set query {
    select 
        first_name, last_name, state
    from
        ad_template_sample_users
    where
        state = :state_abbrev
        order by last_name
}
          
db_multirow users state_query $query


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
