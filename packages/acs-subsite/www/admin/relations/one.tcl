# /packages/acs-subsite/www/admin/relations/one.tcl

ad_page_contract {

    Shows information about one relation

    @author mbryzek@arsdigita.com
    @creation-date Wed Dec 13 20:11:27 2000
    @cvs-id $Id$

} {
    rel_id:naturalnum,notnull
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

set admin_p [permission::permission_p -object_id $rel_id -privilege "admin"]
set delete_p [permission::permission_p -object_id $rel_id -privilege "delete"]
set write_p [permission::permission_p -object_id $rel_id -privilege "write"]

set context [list "One relation"]

set subsite_group_id [application_group::group_id_from_package_id]

if { ![db_0or1row select_rel_info {} -column_array rel] 
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
set QQreturn_url [ns_quotehtml $return_url]
set possible_member_states [group::possible_member_states]

set object_two_read_p  [permission::permission_p -object_id $rel(object_id_two) -privilege "read"]
if {$object_two_read_p} {
    set object_two_write_p [permission::permission_p -object_id $rel(object_id_two) -privilege "write"]

    attribute::multirow \
	    -start_with party \
	    -datasource_name object_two_attributes \
	    -object_type $rel(object_type_two) \
	    $rel(object_id_two)
}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
