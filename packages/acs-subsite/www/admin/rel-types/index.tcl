# /packages/mbryzek-subsite/www/admin/rel-types/index.tcl

ad_page_contract {

    Shows list of all defined relationship types, excluding the parent
    type "relationship"

    @author mbryzek@arsdigita.com
    @creation-date Sun Dec 10 17:10:56 2000
    @cvs-id $Id$

} {
} -properties {
    context:onevalue
    rel_types:multirow
}

set context [list [_ acs-subsite.Relationship_Types]]

set package_id [ad_conn package_id]

# Select out all relationship types, excluding the parent type names 'relationship'
# Count up the number of relations that exists for each type.
db_multirow rel_types select_relation_types {}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
