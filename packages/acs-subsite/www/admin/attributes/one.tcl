# /packages/mbryzek-subsite/www/admin/attributes/one.tcl

ad_page_contract {

    Shows information about one attribute

    @author mbryzek@arsdigita.com
    @creation-date Sun Nov 12 17:59:39 2000
    @cvs-id $Id$

} {
    attribute_id:naturalnum,notnull
    { return_url "" }
} -properties {
    context:onevalue
    attribute:onerow
    url_vars:onevalue
    dynamic_p:onevalue
    enum_values:multirow
}
set context [list "One attribute"]

set url_vars [export_vars {attribute_id return_url}]

# Note we really do want all the columns here for this generic display
# Stuff it into a column array to avoid writing all these damn column
# names again

db_1row select_attribute_info {
    select a.attribute_id, a.object_type, a.table_name, a.attribute_name, 
           a.pretty_name, a.pretty_plural, a.sort_order, a.datatype, 
           a.default_value, a.min_n_values, a.max_n_values, a.storage, 
           a.static_p, a.column_name, t.dynamic_p
     from acs_attributes a, acs_object_types t
    where a.object_type = t.object_type
      and a.attribute_id = :attribute_id
} -column_array attribute


# Set up a multirow datasource to process this data
template::multirow create attr_props key value
foreach n [lsort [array names attribute]] { 
    template::multirow append attr_props $n $attribute($n)
}

if {$attribute(datatype) eq "enumeration"} {
    # set up the enum values datasource
    db_multirow enum_values enum_values {
	select v.enum_value, v.pretty_name
	  from acs_enum_values v
	 where v.attribute_id = :attribute_id
	 order by v.sort_order
    }
}

set dynamic_p $attribute(dynamic_p)

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
