# /packages/mbryzek-subsite/www/admin/rel-types/delete.tcl

ad_page_contract {

    Confirms deletion of a relationship type

    @author mbryzek@arsdigita.com
    @creation-date Mon Dec 11 11:57:29 2000
    @cvs-id $Id$

} {
    rel_type:notnull,rel_type_dynamic_p
    { return_url:localurl "" }
} -properties {
    context:onevalue
    rel_type_pretty_name:onevalue
    rel_type:onevalue
    counts:onerow
}

set context [list [list "" "Relationship types"] [list [export_vars -base one rel_type] "One type"] "Delete type"]

set rel_type_pretty_name [db_string select_pretty_name {
    select t.pretty_name
      from acs_object_types t
     where t.object_type = :rel_type
}]


set subtypes_exist_p [db_string number_subtypes {}]

if { $subtypes_exist_p } {
    set return_url "[ad_conn url]?[ad_conn query]"

    # Just grab direct children... 
    template::multirow create subtypes rel_type pretty_name export_vars

    db_foreach select_subtypes {
	select t.object_type as rel_type, t.pretty_name
          from acs_object_types t
         where t.supertype = :rel_type
    } {
	template::multirow append subtypes $rel_type $pretty_name [export_vars {rel_type return_url}]
    }
    ad_return_template "delete-subtypes-exist"
    return
}

# Now let's count up the number of things we're going to delete
db_1row select_counts {} -column_array counts

set export_vars [export_vars -form {rel_type return_url}]

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
