# /packages/acs-subsite/www/admin/groups/one.tcl

ad_page_contract {
    View one group.

    @author Oumi Mehrotra (oumi@arsdigita.com)

    @creation-date 2001-02-23
    @cvs-id $Id$
} {
    group_id:naturalnum,notnull
    {return_url ""}
} -properties {
    context:onevalue
    group_id:onevalue
    group_name:onevalue
    admin_p:onevalue
    QQreturn_url:onevalue
    join_policy:onevalue
    possible_join_policies:onevalue
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


set context [list \
        [list "[ad_conn package_url]admin/groups/" "Groups"] \
	[list "one?group_id=$group_id" "One Group" ] \
        "Edit Join Policy"]

db_1row group_info {
    select g.group_name, g.join_policy
      from groups g
     where g.group_id = :group_id
}

set possible_join_policies [list open "needs approval" closed]
set QQreturn_url [ns_quotehtml $return_url]
ad_return_template
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
