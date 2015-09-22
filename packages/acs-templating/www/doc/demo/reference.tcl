ad_page_contract {
  @cvs-id $Id$
} -properties {
  users:multirow
}

set query "select first_name, last_name, state from ad_template_sample_users"
set e_query "$query where first_name like '%e%'"

db_multirow users    users_query $query
db_multirow e_people e_people_q  $e_query

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
