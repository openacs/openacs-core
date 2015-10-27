# /packages/mbryzek-subsite/www/admin/group-types/rel-type-add.tcl

ad_page_contract {

    Shows list of available rel types to add for this group type

    @author mbryzek@arsdigita.com
    @creation-date Sun Dec 10 16:50:58 2000
    @cvs-id $Id$

} {
    group_type:trim,notnull
    { return_url "" }
} -properties {
    context:onevalue
    return_url_enc:onevalue
    export_vars:onevalue
    primary_rels:multirow
}

set return_url_enc [ad_urlencode "[ad_conn url]?[ad_conn query]"]

set doc(title) [_ acs-subsite.Add_a_permissible_relationship_type]
set context [list [list "[ad_conn package_url]admin/group-types/" [_ acs-subsite.Group_Types]] [list [export_vars -base one {group_type}] $group_type] $doc(title)]


# Select out all the relationship types that are not currently
# specified for this group type. Note that we use acs_object_types so
# that we can probably indent subtypes. We use acs_rel_types to ensure
# that the passed in group type is acceptable for object_type_one of
# the relationship type. Acceptable means equal to or a child of the
# rel type. If you can find a more efficient way to do this query,
# please let us know! -mbryzek

db_multirow primary_rels select_primary_relations {}


set export_vars [export_vars -form {group_type return_url}]

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
