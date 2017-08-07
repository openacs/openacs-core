# /packages/mbryzek-subsite/www/admin/rel-types/delete-2.tcl

ad_page_contract {

    Deletes the relationship type

    @author mbryzek@arsdigita.com
    @creation-date Mon Dec 11 12:00:12 2000
    @cvs-id $Id$

} {
    rel_type:notnull,rel_type_dynamic_p
    { operation "" }
    { return_url:localurl "" }
}

if { $operation ne "Yes, I really want to delete this relationship type" } {
    # set the return_url to something useful if we are not deleting
    if { $return_url eq "" } {
	set return_url [export_vars -base one rel_type]
    }
} else {
    db_1row select_type_info {
	select t.table_name 
	  from acs_object_types t
	 where t.object_type = :rel_type
    }

    set user_id [ad_conn user_id]

    set rel_id_list [db_list select_rel_ids {}]

    set segment_id [db_string select_segment_id {} -default ""]
    
    # delete all relations, all segments, and drop the relationship
    # type. This will fail if a relation / segment for this type is created
    # after we select out the list of rels/segments to delete but before we
    # finish dropping the type.

    db_transaction {
	foreach rel_id $rel_id_list {
	    relation_remove $rel_id
	}
	
	if { $segment_id ne "" } {
	    rel_segments_delete $segment_id
	}
	    
	db_exec_plsql drop_relationship_type {}
    } on_error {
	ad_return_error "Error deleting relationship type" "We got the following error trying to delete this relationship type:<pre>$errmsg</pre>"
	ad_script_abort
    }
    # If we successfully dropped the relationship type, drop the table.
    # Note that we do this outside the transaction as it commits all
    # transactions anyway
    if { [db_table_exists $table_name] } {
	db_exec_plsql drop_type_table "drop table $table_name"
    }
}

# Reset the attribute view for objects of this type
package_object_view_reset $rel_type

ad_returnredirect $return_url

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
