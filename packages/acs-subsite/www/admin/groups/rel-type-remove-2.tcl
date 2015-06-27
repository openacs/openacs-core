# /packages/mbryzek-subsite/www/admin/groups/rel-type-remove-2.tcl

ad_page_contract {

    Removes the specified relation from the list of allowable ones

    @author mbryzek@arsdigita.com
    @creation-date Tue Jan  2 12:28:33 2001
    @cvs-id $Id$

} {
    group_rel_id:naturalnum,notnull
    { return_url "" }
    { operation:trim "No, I want to cancel my request" }
}

# Pull out info we need
if { ![db_0or1row select_group_id {
    select g.group_id, g.rel_type
      from group_rels g, acs_object_types t
     where g.rel_type = t.object_type
       and g.group_rel_id = :group_rel_id
}] } {
    # Already removed... just redirect
    ad_returnredirect $return_url
    ad_script_abort
}

if {$operation eq "Yes, I really want to delete this relationship type"} {
    set rel_id_list [db_list select_rel_ids {
	select r.rel_id 
          from acs_rels r
	 where r.rel_type = :rel_type
	   and r.object_id_one = :group_id
    }]
    
    db_transaction {
	# Remove each relation
	foreach rel_id $rel_id_list {
	    relation_remove $rel_id
	}

	# Remove the relational segment for this group/rel type if it exists
	if { [db_0or1row select_segments {
	    select segment_id
	      from rel_segments 
	     where group_id = :group_id
	       and rel_type = :rel_type
	}] } {
	    rel_segments_delete $segment_id
	}

	# now remove this relationship type from the list of allowable
	# ones for this group
	db_dml remove_relationship_type {
	    delete from group_rels where group_rel_id = :group_rel_id
	}
    } on_error {
	ad_return_error "Error removing this relationship type" $errmsg
	ad_script_abort
    }


}


if { $return_url eq "" } {
    set return_url [export_vars -base one {group_id}]
}

ad_returnredirect $return_url
