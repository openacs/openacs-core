ad_page_contract {

    Shows all constraints on which the user has read permission

    @author mbryzek@arsdigita.com
    @creation-date Fri Dec 15 11:30:52 2000
    @cvs-id $Id$

}

set context    [list [list ../ "Relational segments"] "Constraints"]
set user_id    [ad_conn user_id]
set package_id [ad_conn package_id]

# Select out basic information about all the constraints on which the
# user has read permission

db_multirow constraints select_rel_constraints {}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
