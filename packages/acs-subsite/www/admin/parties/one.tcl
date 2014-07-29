
# /packages/subsite/www/admin/parties/one.tcl

ad_page_contract {
    View one party.

    @author Oumi Mehrotra (oumi@arsdigita.com)

    @creation-date 2001-02-06
    @cvs-id $Id$
} {
    party_id:naturalnum,notnull
} -properties {
    context:onevalue
    party_id:onevalue
    party_name:onevalue
    admin_p:onevalue
    write_p:onevalue
    attributes:multirow
} -validate {
    parties_exists_p -requires {party_id:notnull} {
	if { ![party::permission_p $party_id] } {
	    ad_complain "The party either does not exist or you do not have permission to view it"
	}
    }
    party_in_scope_p -requires {party_id:notnull parties_exists_p} {
	if { ![application_group::contains_party_p -party_id $party_id]} {
	    ad_complain "The party either does not exist or does not belong to this subsite."
	}
    }
}


# Select out the party name and the party's object type. Note we can
# use 1row because the validate filter above will catch missing parties

db_1row party_info {
    select acs_object.name(:party_id) as party_name,
           object_type as party_type
      from acs_objects
     where object_id = :party_id
}

### This page redirects to different pages for groups or rel_segments.
### We have to check whether the party_type is a type of group or rel_segment.

# Get a list of types in the type hierarchy that are in the path between
# 'party' and $party_type
set object_type_path_list [subsite::util::object_type_path_list $party_type party]

set redirects_for_type [list \
	group "groups/one?group_id=$party_id" \
	rel_segment "rel-segments/one?segment_id=$party_id"]

foreach {type url} $redirects_for_type {
    if {[lsearch $object_type_path_list $type] != -1} {
	ad_returnredirect [ad_conn package_url]admin/$url
        ad_script_abort
    }
}

set user_id [ad_conn user_id]
set write_p [permission::permission_p -object_id $party_id -privilege "write"]
set admin_p [permission::permission_p -object_id $party_id -privilege "admin"]

set context [list [list "" "Parties"] "One Party"]

attribute::multirow \
	-start_with party \
	-datasource_name attributes \
	-object_type $party_type \
	$party_id

