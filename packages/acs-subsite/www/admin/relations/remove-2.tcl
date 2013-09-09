# /packages/mbryzek-subsite/www/admin/relations/remove-2.tcl

ad_page_contract {
    Removes relations
    
    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 2000-12-16
    @cvs-id $Id$
} {
    rel_id:integer,notnull
    { operation "" }
    { return_url "" }
} -validate {
    permission_p -requires {rel_id:notnull} {
	if { ![relation_permission_p -privilege delete $rel_id] } {
	    ad_complain "The relation either does not exist or you do not have permission to remove it"
	}
    }
}

if {$operation eq "Yes, I really want to remove this relation"} {
    db_transaction {
	relation_remove $rel_id
    } on_error {
	ad_return_error "Error creating the relation" "We got the following error while trying to remove the relation: <pre>$errmsg</pre>"
	ad_script_abort
    }
} else {
    if { $return_url eq "" } {
	# redirect to the relation by default, if we haven't deleted it
	set return_url "one?[ad_export_vars rel_id]"
    }
}

db_release_unused_handles

ad_returnredirect $return_url
