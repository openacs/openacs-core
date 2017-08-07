# /packages/mbryzek-subsite/www/admin/groups/one.tcl

ad_page_contract {
    Display all types of groups for this subsite

    @author mbryzek@arsdigita.com

    @creation-date 2000-11-06
    @cvs-id $Id$
} {
} -properties {
    context:onevalue
    group_types:multirow
}

set doc(title) [_ acs-subsite.Group_type_administration]
set context [list [_ acs-subsite.Group_Types]]

# we may want to move the inner count to get the number of groups of
# each type to its own pl/sql function. That way, we execute the
# function once for each group type, a number much smaller than the
# number of objects in the system.

set user_id [ad_conn user_id]

set package_id [ad_conn package_id]

db_multirow group_types select_group_types {}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
