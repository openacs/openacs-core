ad_page_contract {
  @cvs-id $Id$
} -properties {
  users:multirow
}


set query "select 
             first_name, last_name
           from
             ad_template_sample_users"


db_multirow users users_query $query



















