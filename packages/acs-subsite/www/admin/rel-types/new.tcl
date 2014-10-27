# /packages/mbryzek-subsite/www/admin/rel-type/new.tcl

ad_page_contract {

    Form to select a supertype for a new relationship type

    @author mbryzek@arsdigita.com
    @creation-date Sun Nov 12 18:27:08 2000
    @cvs-id $Id$

} {
    { return_url "" }
} -properties {
    context:onevalue
}


db_multirow supertypes select_supertypes {
    select replace(lpad(' ', (level - 1) * 4), ' ', '&nbsp;') || t.pretty_name as name,
           t.object_type
      from acs_object_types t
   connect by prior t.object_type = t.supertype
     start with t.object_type in ('membership_rel','composition_rel')
}

set context [list [list "[ad_conn package_url]admin/rel-types/" [_ acs-subsite.Relationship_Types]] [_ acs-subsite.Create_relation_type]]

set export_vars [export_vars -form {return_url}]

ad_return_template
