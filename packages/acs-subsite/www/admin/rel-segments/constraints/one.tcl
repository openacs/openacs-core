# /packages/mbryzek-subsite/www/admin/rel-segments/constraints/one.tcl

ad_page_contract {

    Shows information about one constraint

    @author mbryzek@arsdigita.com
    @creation-date Thu Dec 14 18:06:02 2000
    @cvs-id $Id$

} {
    constraint_id:naturalnum,notnull
} -properties {
    context:onevalue
    admin_p:onevalue
    props:onerow
    rel:onerow
    req_rel:onerow
}

permission::require_permission -object_id $constraint_id -privilege read

set admin_p [permission::permission_p -object_id $constraint_id -privilege admin]

set package_id [ad_conn package_id]

# Pull out the information about the constraint, required segments,
# associated relationship type, and associated roles. 

# We are driving this query off of rel_constraints:
#
#  rel_side: Identifies the object that must be in
#  required_rel_segment
#
#  rel_segment: Identifies the segment for which we've created this
#  constraint
#
#  required_rel_segment: Identifies the segment to which the object
#  (itself identified by rel_side) must belong before belonging to
#  rel_segment

if { ![db_0or1row select_constraint_properties {} -column_array props] } {
    ad_return_error "Error" "Constraint #$constraint_id could not be found or is out of the scope of this subsite."
    return
}

set segment_id $props(segment_id)

set context [list [list "../" "Relational segments"] [list "../one?segment_id=$props(segment_id)" "One Segment"] "One constraint"]

# Now we pull out information about the relationship types for each
# segment. The outer join is there in case the role in acs_rel_types
# is null. Finally, note that we choose to do these queries separately
# because they would be too hard to read in one query.

set rel_type $props(rel_type)
db_1row select_rel_type_info {
    select role1.role as role_one, 
           nvl(role1.pretty_name,'Object on side one') as role_one_pretty_name,
           nvl(role1.pretty_plural,'Objects on side one') as role_one_pretty_plural,
           role2.role as role_two, 
           nvl(role2.pretty_name,'Object on side two') as role_two_pretty_name,
           nvl(role2.pretty_plural,'Objects on side two') as role_two_pretty_plural,
           acs_object_type.pretty_name(rel.rel_type) as rel_type_pretty_name
      from acs_rel_types rel, acs_rel_roles role1, acs_rel_roles role2
     where rel.rel_type = :rel_type
       and rel.role_one = role1.role(+)
       and rel.role_two = role2.role(+)
} -column_array rel

set rel_type $props(req_rel_type)
db_1row select_rel_type_info {
    select role1.role as role_one, 
           nvl(role1.pretty_name,'Object on side one') as role_one_pretty_name,
           nvl(role1.pretty_plural,'Objects on side one') as role_one_pretty_plural,
           role2.role as role_two, 
           nvl(role2.pretty_name,'Object on side two') as role_two_pretty_name,
           nvl(role2.pretty_plural,'Objects on side two') as role_two_pretty_plural,
           acs_object_type.pretty_name(rel.rel_type) as rel_type_pretty_name
      from acs_rel_types rel, acs_rel_roles role1, acs_rel_roles role2
     where rel.rel_type = :rel_type
       and rel.role_one = role1.role(+)
       and rel.role_two = role2.role(+)
} -column_array req_rel


# Choose the appropriate role based on the side of the relation used
# in this constraint. 

set rel_side $props(rel_side)

set rel(role) $rel(role_${rel_side})
set rel(role_pretty_name) [lang::util::localize $rel(role_${rel_side}_pretty_name)]
set rel(role_pretty_plural) [lang::util::localize $rel(role_${rel_side}_pretty_plural)]

set req_rel(role) $req_rel(role_${rel_side})
set req_rel(role_pretty_name) [lang::util::localize $req_rel(role_${rel_side}_pretty_name)]
set req_rel(role_pretty_plural) [lang::util::localize $req_rel(role_${rel_side}_pretty_plural)]


# Now query for any violations. Note that we use union all since we
# know that the two views contain independent elements.

# Removed this query 1/18/2001 - constraints enforced in the data
# model. There are never any violations.

#  db_multirow violations select_violated_rels {
#      select viol.rel_id, acs_object.name(viol.party_id) as name
#        from rel_constraints_violated_one viol
#       where viol.constraint_id = :constraint_id
#      UNION ALL
#      select viol.rel_id, acs_object.name(viol.party_id) as name
#        from rel_constraints_violated_two viol
#       where viol.constraint_id = :constraint_id
#  }

ad_return_template
