# /packages/mbryzek-subsite/www/admin/groups/rel-type-add.tcl

ad_page_contract {

    Displays relationship types to add as an allowable one

    @author mbryzek@arsdigita.com
    @creation-date Tue Jan  2 12:08:12 2001
    @cvs-id $Id$

} {
    group_id:naturalnum,notnull
    { return_url:localurl "" }
} -properties {
    context:onevalue
    export_vars:onevalue
    return_url_enc:onevalue
    primary_rels:multirow
}

set context [list [list "[ad_conn package_url]admin/groups/" "Groups"] [list [export_vars -base one group_id] "One Group"] "Add relation type"]
set return_url_enc [ad_urlencode "[ad_conn url]?[ad_conn query]"]

# Select out all the relationship types that are not currently
# specified for this group. Note that we use acs_object_types so that
# we can probably indent subtypes. We use acs_rel_types to limit our
# selection to acceptable relationship types.

# We need this group's type
db_1row select_group_type {
    select o.object_type as group_type
      from acs_objects o
     where o.object_id = :group_id
}

db_multirow primary_rels select_primary_relations {}

set export_vars [export_vars -form {group_id return_url}]

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
