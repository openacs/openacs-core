# packages/acs-core-ui/www/acs_object/permissions/revoke-2.tcl

ad_page_contract {

  @author rhs@mit.edu
  @creation-date 2000-08-20
  @cvs-id $Id$
} {
  object_id:integer,notnull
  revoke_list:multiple
  { operation "" }
}

ad_require_permission $object_id admin

if { [string eq $operation "Yes"] } {
    db_transaction {
	foreach item $revoke_list {
	    set party_id [lindex $item 0]
	    set privilege [lindex $item 1]
	    db_exec_plsql revoke {
		begin
		    acs_permission.revoke_permission(:object_id, :party_id, :privilege);
		end;
	    }
	}
    }
}

ad_returnredirect "one?[export_url_vars object_id]"
