ad_page_contract {
    displays a table of number of registrations by month

    @author philg@mit.edu
    @creation-date Jan 1999
    @cvs-id $Id$
} -properties {
    context:onevalue
    user_rows:multirow
}

set context [list [list "./" "Users"] "Registration History"]

# we have to query for pretty month and year separately because Oracle pads
# month with spaces that we need to trim

db_multirow user_rows user_rows "select to_char(creation_date,'YYYYMM') as sort_key, rtrim(to_char(creation_date,'Month')) as pretty_month, to_char(creation_date,'YYYY') as pretty_year, count(*) as n_new
from users, acs_objects
where users.user_id = acs_objects.object_id
and creation_date is not null
group by to_char(creation_date,'YYYYMM'), to_char(creation_date,'Month'), to_char(creation_date,'YYYY')
order by 1"

ad_return_template
