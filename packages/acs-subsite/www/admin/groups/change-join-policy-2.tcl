# /packages/acs-subsite/www/admin/groups/one.tcl

ad_page_contract {
    Change join policy of a group.

    @author Oumi Mehrotra (oumi@arsdigita.com)

    @creation-date 2001-02-23
    @cvs-id $Id$
} {
    group_id:integer,notnull
    join_policy:notnull
    {return_url ""}
} -validate {
    groups_exists_p -requires {group_id:notnull} {
	if { ![group::permission_p -privilege admin $group_id] } {
	    ad_complain "The group either does not exist or you do not have permission to administer it"
	}
    }
    group_in_scope_p -requires {group_id:notnull} {
	if { ![application_group::contains_party_p -party_id $group_id]} {
	    ad_complain "The group either does not exist or does not belong to this subsite."
	}
    }
}



db_dml update_join_policy {
    update groups
    set join_policy = :join_policy
    where group_id = :group_id
}

if {[empty_string_p $return_url]} {
    set return_url one?group_id=@group_id@
}

ad_returnredirect $return_url