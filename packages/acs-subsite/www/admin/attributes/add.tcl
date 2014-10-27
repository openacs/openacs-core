# /packages/mbryzek-subsite/www/admin/attribute/add.tcl

ad_page_contract {

    Form to adds attributes

    @author mbryzek@arsdigita.com
    @creation-date Tue Nov  7 12:14:42 2000
    @cvs-id $Id$

} {
    object_type:notnull,trim
    { return_url "" }
} -properties {
    context:onevalue
    export_vars:onevalue
    object_pretty_name:onevalue
    datatypes:multirow
} -validate {
    dynamic_type -requires {object_type:notnull} {
	if { ![package_type_dynamic_p $object_type] } {
	    ad_complain "The specified object type, $object_type, is not dynamic and therefore cannot be modified."
	}
    }
}

set context [list "Add attribute"]
set export_vars [export_vars -form {object_type return_url}]

set object_pretty_name [db_string object_pretty_name {
    select t.pretty_name 
      from acs_object_types t
     where t.object_type = :object_type
}]


# Create a datasource of all the datatypes for which we have validators
set ctr 0
template::multirow create datatypes datatype

db_foreach select_datatypes {
    select d.datatype
      from acs_datatypes d
     order by lower(d.datatype)
} {
    if { [attribute::datatype_validator_exists_p $datatype] } {
	incr ctr
	template::multirow append datatypes $datatype
    }
}

if { $ctr == 0 } {
    ad_return_error "No datatypes" "There are no datatypes with validators available for use"
    ad_script_abort
}

ad_return_template
