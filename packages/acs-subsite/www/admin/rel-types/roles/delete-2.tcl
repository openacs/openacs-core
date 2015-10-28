# /packages/mbryzek-subsite/www/admin/rel-types/roles/delete-2.tcl

ad_page_contract {

    Deletes a role if there are no relationship types that use it

    @author mbryzek@arsdigita.com
    @creation-date Mon Dec 11 11:30:53 2000
    @cvs-id $Id$

} {
    role:notnull
    { operation "" }
    { return_url "" }
}


if {$operation eq "Yes, I really want to delete this role"} {
    db_transaction {
	if { [catch {db_exec_plsql drop_role {}} errmsg] } {
	    if { [db_string role_used_p {}] } {
		ad_return_complaint 1 "<li> The role \"$role\" is still in use. You must remove all relationship types that use this role before you can remove this role."
		return
	    } else {
		ad_return_error "Error deleting role" $errmsg
		return
	    }
	}
    }
}

ad_returnredirect $return_url

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
