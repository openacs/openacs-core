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

db_multirow user_rows user_rows {}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
