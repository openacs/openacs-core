# /packages/mbryzek-subsite/www/admin/rel-type/new.tcl

ad_page_contract {

    Form to create a new relationship type

    @author mbryzek@arsdigita.com
    @creation-date Sun Nov 12 18:27:08 2000
    @cvs-id $Id$

} {
    supertype:trim,notnull
    rel_type:optional
    pretty_name:optional
    pretty_plural:optional 
    object_type_one:optional
    role_one:optional
    min_n_rels_one:optional
    max_n_rels_one:optional
    object_type_two:optional
    role_two:optional
    min_n_rels_two:optional
    max_n_rels_two:optional
    { return_url "" }
} -properties {
    context:onevalue
    supertype_pretty_name:onevalue
}

set context [list [list "[ad_conn package_url]admin/rel-types/" "Relationship types"] "Add relation type"]

template::form create rel_type

template::element create rel_type return_url \
	-optional \
	-value $return_url \
	-datatype text \
	-widget hidden

template::element create rel_type supertype \
	-value $supertype \
	-datatype text \
	-widget hidden

template::element create rel_type rel_type \
	-label "Relation type" \
	-datatype text \
	-html {maxlength 100}

template::element create rel_type pretty_name \
	-label "Pretty name" \
	-datatype text \
	-html {maxlength 100}

template::element create rel_type pretty_plural \
	-label "Pretty plural" \
	-datatype text \
	-html {maxlength 100}

# Select out the objects from which to generate pick lists for the
# relationship type

db_1row select_object_types {
    select r.object_type_one as max_object_type_one, 
           r.object_type_two as max_object_type_two,
           t.pretty_name as supertype_pretty_name,
           r.role_one as supertype_role_one, r.role_two as supertype_role_two,
           r.min_n_rels_one as supertype_min_n_rels_one,
           r.max_n_rels_one as supertype_max_n_rels_one,
           r.min_n_rels_two as supertype_min_n_rels_two,
           r.max_n_rels_two as supertype_max_n_rels_two
      from acs_object_types t, acs_rel_types r
     where r.rel_type = :supertype
       and r.rel_type = t.object_type
}

set object_types_one_list [db_list_of_lists select_object_types_one {
    select replace(lpad(' ', (level - 1) * 4), ' ', '&nbsp;') || t.pretty_name, 
           t.object_type as rel_type
      from acs_object_types t
   connect by prior t.object_type = t.supertype
     start with t.object_type=:max_object_type_one
}]

set object_types_two_list [db_list_of_lists select_object_types_two {
    select replace(lpad(' ', (level - 1) * 4), ' ', '&nbsp;') || t.pretty_name, 
           t.object_type as rel_type
      from acs_object_types t
   connect by prior t.object_type = t.supertype
     start with t.object_type=:max_object_type_two
}]

set roles_list [db_list_of_lists select_roles {
    select r.pretty_name, r.role
      from acs_rel_roles r
     order by lower(r.role)
}]

template::element create rel_type object_type_one \
	-label "Object type one" \
	-datatype text \
	-widget select \
	-options $object_types_one_list

# Set return_url here to set it up correctly for use with roles

set role_return_url_enc [ad_urlencode "[ad_conn url]?[ad_conn query]"]

template::element create rel_type role_one \
	-label "Role one<br><font size=-1>(<a href=roles/new?return_url=$role_return_url_enc>create new role</a>)</font>" \
	-datatype text \
	-widget select \
	-options $roles_list

template::element create rel_type min_n_rels_one \
	-value $supertype_min_n_rels_one \
	-label "Min n rels one" \
	-datatype integer

template::element create rel_type max_n_rels_one \
	-optional \
	-value $supertype_max_n_rels_one \
	-label "Max n rels one" \
	-datatype integer


template::element create rel_type object_type_two \
	-label "Object type two" \
	-datatype text \
	-widget select \
	-options $object_types_two_list


template::element create rel_type role_two \
	-label "Role two<br><font size=-1>(<a href=roles/new?return_url=$role_return_url_enc>create new role</a>)</font>" \
	-datatype text \
	-widget select \
	-options $roles_list

template::element create rel_type min_n_rels_two \
	-value $supertype_min_n_rels_two \
	-label "Min n rels two" \
	-datatype integer

template::element create rel_type max_n_rels_two \
	-optional \
	-value $supertype_max_n_rels_two \
	-label "Max n rels two" \
	-datatype integer


if { [template::form is_request rel_type] } {

    template::element set_properties rel_type role_one -value $supertype_role_one
    template::element set_properties rel_type role_two -value $supertype_role_two

}

if { [template::form is_valid rel_type] } {
    set exception_count 0
    set safe_rel_type [plsql_utility::generate_oracle_name -max_length 29 $rel_type]
    if { [plsql_utility::object_type_exists_p $safe_rel_type] } {
	incr exception_count
	append exception_text "<li> The specified type for this relationship, $rel_type, already exists. 
[ad_decode $safe_rel_type $rel_type "" "Note that we converted the object type to \"$safe_rel_type\" to ensure that the name would be safe for the database."]
Please back up and choose another.</li>"
    } else {
	# let's make sure the names are unique
	if { [db_string pretty_name_unique {
	    select case when exists (select 1 from acs_object_types t where t.pretty_name = :pretty_name)
                    then 1 else 0 end
	      from dual
	}] } {
	    incr exception_count
	    append exception_text "<li> The specified pretty name, $pretty_name, already exists. Please enter another </li>"
	}

	if { [db_string pretty_plural_unique {
	    select case when exists (select 1 from acs_object_types t where t.pretty_plural = :pretty_plural)
                    then 1 else 0 end
	      from dual
	}] } {
	    incr exception_count
	    append exception_text "<li> The specified pretty plural, $pretty_plural, already exists. Please enter another </li>"
	}
    }

    if { $exception_count > 0 } {
	ad_return_complaint $exception_count $exception_text
	ad_script_abort
    }

    rel_types::new \
	    -supertype $supertype \
	    -role_one $role_one \
	    -role_two $role_two \
	    $rel_type \
	    $pretty_name \
	    $pretty_plural \
	    $object_type_one \
	    $min_n_rels_one \
	    $max_n_rels_one \
	    $object_type_two \
	    $min_n_rels_two \
	    $max_n_rels_two
    
    ad_returnredirect $return_url
    ad_script_abort
}

ad_return_template
