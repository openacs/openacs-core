# /packages/acs-subsite/www/admin/relations/one.tcl

ad_page_contract {

    Shows information about one relation

    @author mbryzek@arsdigita.com
    @creation-date Wed Dec 13 20:11:27 2000
    @cvs-id $Id$

} {
    rel_id:integer,notnull
} -properties {
    context:onevalue
    rel_id:onevalue
    rel:onerow
    delete_p:onevalue
    admin_p:onevalue
    attributes:multirow
    write_p:onevalue
    delete_p:onevalue
    subsite_group_id:onevalue
    object_two_attributes:multirow
    member_state:onevalue
    QQreturn_url:onevalue
    possible_member_states:onelist
} -validate {
    permission_p -requires {rel_id:notnull} {
	if { ![relation_permission_p $rel_id] } {
	    ad_complain "The relation either does not exist or you do not have permission to view it"
	}
    }
    relation_in_scope_p -requires {rel_id:notnull permission_p} {
	if { ![application_group::contains_relation_p -rel_id $rel_id]} {
	    ad_complain "The relation either does not exist or does not belong to this subsite."
	}
    }
}

set admin_p [ad_permission_p $rel_id "admin"]
set delete_p [ad_permission_p $rel_id "delete"]
set write_p [ad_permission_p $rel_id "write"]

set context [list "One relation"]

set subsite_group_id [application_group::group_id_from_package_id]

if { ![db_0or1row select_rel_info {
    select r.rel_type, acs_object_type.pretty_name(t.rel_type) as rel_type_pretty_name,
           acs_rel_type.role_pretty_name(t.role_one) as role_one_pretty_name,
           acs_rel_type.role_pretty_name(t.role_two) as role_two_pretty_name,
           t.object_type_two as object_type_two,
           acs_object.name(r.object_id_one) as object_id_one_name,
           r.object_id_one,
           acs_object.name(r.object_id_two) as object_id_two_name,
           r.object_id_two
      from acs_rels r, acs_rel_types t
     where r.rel_id = :rel_id
       and r.rel_type = t.rel_type} -column_array rel] 
} {
    ad_return_error "Error" "Relation #rel_id does not exist"
    ad_script_abort
}

set rel(rel_type_enc) [ad_urlencode $rel(rel_type)]
set rel(role_one_pretty_name) [lang::util::localize $rel(role_one_pretty_name)]
set rel(role_two_pretty_name) [lang::util::localize $rel(role_two_pretty_name)]


# Build up the list of attributes for the type specific lookup
set rel_type $rel(rel_type)

set attr_list [attribute::array_for_type -start_with "relationship" attr_props enum_values $rel_type]

attribute::multirow \
	-start_with relationship \
	-datasource_name attributes \
	-object_type $rel_type \
	$rel_id

# Membership relations have a member_state.  Composition relations don't.
# This query will return null if the relation is not a membership relation.
set member_state ""
db_0or1row select_member_state {
    select member_state from membership_rels
    where rel_id = :rel_id
}

# Data used to build the "toggle member state" widget.
set return_url [ad_conn url]?[ad_conn query]
set QQreturn_url [ad_quotehtml $return_url]
set possible_member_states [group::possible_member_states]

set object_two_read_p  [ad_permission_p $rel(object_id_two) "read"]
if {$object_two_read_p} {
    set object_two_write_p [ad_permission_p $rel(object_id_two) "write"]

    attribute::multirow \
	    -start_with party \
	    -datasource_name object_two_attributes \
	    -object_type $rel(object_type_two) \
	    $rel(object_id_two)
}

ad_return_template
