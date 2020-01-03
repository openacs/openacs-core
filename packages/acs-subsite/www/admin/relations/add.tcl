ad_page_contract {
    Add a member to a group. If there are subtypes of the specified
    rel_type, we ask the user to select a precise rel_type before
    continuing

    @author mbryzek@mit.edu
    @creation-date 2000-12-11
    @cvs-id $Id$
} {
    group_id:integer,notnull
    rel_type:notnull
    { party_id:naturalnum "" }
    { exact_p:boolean "f" }
    { return_url:localurl "" }
    { allow_out_of_scope_p:boolean "f" }
} -properties {
    context:onevalue
    role_pretty_name:onevalue
    group_name:onevalue
    export_form_vars:onevalue
    rel_types:multirow
    rel_type_pretty_name:onevalue
    add_party_url:onevalue
} -validate {
    party_in_scope_p -requires {party_id:notnull} {
        if { $allow_out_of_scope_p == "f"
             && ![application_group::contains_party_p -party_id $party_id]} {
            ad_complain "The party either does not exist or does not belong to this subsite."
        }
    }
    rel_type_valid_p -requires {group_id:notnull rel_type:notnull exact_p:notnull} {
        if {$exact_p == "t"
            && ![relation_type_is_valid_to_group_p -group_id $group_id $rel_type]} {
            ad_complain "Relations of this type to this group would violate a relational constraint."
        }
    }
}
# ISSUES / TO DO: still need to check that party_id is not already in the
# group through this relation.  Actually, we should handle this with
# double-click protection (which we're not doing yet).  We also need
# to check permissions on the party.

set context [list "Add relation"]

set export_var_list {group_id rel_type exact_p return_url allow_out_of_scope_p}
if {$party_id ne ""} {
    lappend export_var_list party_id
}

group::get -group_id $group_id -array group_info

# We assume the group is on side 1...
db_1row rel_type_info {
    select t.object_type_two,
           t.role_two as role,
           (select pretty_name from acs_rel_roles
            where role = t.role_two) as role_pretty_name,
           (select pretty_name from acs_object_types
            where object_type = t.object_type_two) as object_type_two_name
    from acs_rel_types t
    where rel_type = :rel_type
}

# The role pretty names can be message catalog keys that need
# to be localized before they are displayed
set role_pretty_name [lang::util::localize $role_pretty_name]
set exact_p true
if { $exact_p == "f"
     && [subsite::util::sub_type_exists_p $rel_type] } {

    # Sub rel-types exist... select one
    set exact_p "t"
    set export_url_vars [export_vars -exclude rel_type $export_var_list ]

    relation_types_valid_to_group_multirow \
            -datasource_name object_types \
            -start_with $rel_type \
            -group_id $group_id

    set object_type_pretty_name [subsite::util::object_type_pretty_name $rel_type]
    set this_url [ad_conn url]
    set object_type_variable rel_type

    ad_return_template ../parties/add-select-type
    return
}

template::form create add_relation

foreach var $export_var_list {
    template::element create add_relation $var \
            -value [set $var] \
            -datatype text \
            -widget hidden
}

# Build a URL used to create a new party of type object_type_two
set party_type $object_type_two
set party_type_exact_p f
set add_to_group_id $group_id
set add_with_rel_type $rel_type
set add_party_url [export_vars -base [ad_conn package_url]admin/parties/new {add_to_group_id add_with_rel_type party_type party_type_exact_p return_url}]

# Build a URL used to select an existing party from the system (as opposed
# to limiting the selection to parties on the current subsite).
set saved_allow_out_of_scope_p $allow_out_of_scope_p
set allow_out_of_scope_p t
set add_out_of_scope_url [export_vars -base [ad_conn url] $export_var_list]

# Build a URL used to select an existing party from the current subsite
set allow_out_of_scope_p f
set add_in_scope_url [export_vars -base [ad_conn url] $export_var_list]

set allow_out_of_scope_p $saved_allow_out_of_scope_p

# We select out all parties that are to not already belong to the
# specified group with the specified rel_type. Note that we take
# special care to not allow the user to select the group itself... we
# don't want circular references. It remains to be seen if this query
# will be faster if we assume we are only adding parties, and thus
# drive off the smaller parties table. We still somehow need to get
# the object type though...

set user_id [ad_conn user_id]
set package_id [ad_conn package_id]

attribute::add_form_elements -form_id add_relation -start_with relationship -object_type $rel_type
element::create add_relation rel_id -widget hidden -value [db_nextval "acs_object_id_seq"]

if { [template::form is_valid add_relation] } {

    if {[catch {
        group::add_member -group_id $group_id -user_id $party_id -rel_type $rel_type
    } errorMsg]} {
        ad_complain $errorMsg
    }

    if { $return_url eq "" } {
        set return_url [export_vars -base one rel_id]
    }
    ad_returnredirect $return_url
    ad_script_abort
}


if {$party_id ne ""} {
    # ISSUES / TO DO: add a check to make sure the party is not
    # already in the group.  We only want to do this on is_request,
    # in which case we know its not a double-click issue.

    set party_name [acs_object_name $party_id]

    # Note: party_id is not null, which means that it got added already
    # to $export_var_list, which means that there is already a hidden
    # form element containing the party_id variable.

    # Inform user which party will be on side two of the new relation.
    template::element create add_relation party_inform \
            -widget "inform" -value "$party_name" -label "$role_pretty_name"

} else {

    # We special case 'party' because we don't want to include
    # parties whose direct object_type is:
    #    'rel_segment' - users will get confused by segments here.
    #    'party' - this is an abstract type and should have no objects,
    #              but the system creates party -1 which users
    #              shouldn't see.

    # The $allow_out_of_scope_p flag controls whether or not we limit
    # the list of parties to those that belong to the current subsite
    # (allow_out_of_scope_p = 'f').  Even when allow_out_of_scope_p = 't',
    # permissions checks and relational constraints may limit
    # the list of parties that can be added to $group_id with a relation
    # of type $rel_type.

    # SENSITIVE PERFORMANCE - this comment tag is here to make it
    # easy for us to find all the queries that we know may be unscalable.
    # This query has been tuned as well as possible given development
    # time constraints, but more tuning may be necessary.
    set party_option_list [db_list_of_lists select_parties {
        with recursive subtypes as (
            select object_type
              from acs_object_types
             where (object_type = :object_type_two
                    and :object_type_two <> 'party') or
                   (object_type in ('person', 'group')
                    and :object_type_two = 'party')

             union all

            select t.object_type
              from acs_object_types t,
                   subtypes s
             where t.supertype = s.object_type
        )
        select DISTINCT
               case when groups.group_id is null then
                   case when persons.person_id is null then 'INVALID'
                   else persons.first_names || ' ' || persons.last_name end
               else groups.group_name end as party_name,
               p.object_id as party_id
          from acs_objects p
               left join groups on groups.group_id = p.object_id
               left join persons on persons.person_id = p.object_id,
               subtypes s,
               rc_parties_in_required_segs pirs
            where p.object_type = s.object_type
                  -- do not list the group as a possible member
              and p.object_id <> :group_id
                  -- do not list parties that are already members
              and not exists (select 1 from group_element_map
                               where element_id = p.object_id
                                 and group_id = :group_id
                                 and rel_type = :rel_type)
              and pirs.rel_type = :rel_type
              and pirs.group_id = :group_id
              and pirs.party_id = p.object_id
              and (:allow_out_of_scope_p <> 'f' or
                   exists (select 1 from application_group_element_map
                            where package_id = :package_id
                              and element_id = p.object_id))
    }]

    if { [llength $party_option_list] == 0 } {
        ad_return_template add-no-valid-parties
        return
    }

    template::element create add_relation party_id \
            -datatype "text" \
            -widget select \
            -options $party_option_list \
            -label "Select $role_pretty_name"
}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
