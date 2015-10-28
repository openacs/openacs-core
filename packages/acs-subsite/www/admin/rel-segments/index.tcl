# /packages/mbryzek-subsite/www/admin/rel-segments/index.tcl

ad_page_contract {

    Shows all relational segments that the user has read permission on

    @author mbryzek@arsdigita.com
    @creation-date Mon Dec 11 12:13:02 2000
    @cvs-id $Id$

} {
} -properties {
    context:onevalue
    seg:multirow
}

set context [list [_ acs-subsite.Relational_Segments]]
set doc(title) [_ acs-subsite.Relational_Segment_administration]

set user_id [ad_conn user_id]

set package_id [ad_conn package_id]

# Select out basic information about all the segments on which the
# user has read permission

db_multirow seg select_rel_segments {}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
