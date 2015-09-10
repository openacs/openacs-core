ad_page_contract {
  @cvs-id $Id$
} -properties {
  users:multirow
}


set query "select 
             first_name, last_name, state
           from
             ad_template_sample_users
           order by state, last_name"


db_multirow users users_query $query

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
