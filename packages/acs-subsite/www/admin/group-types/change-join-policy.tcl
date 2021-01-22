# /packages/acs-subsite/www/admin/groups/one.tcl

ad_page_contract {
    Change default join policy for a group type.

    @author Oumi Mehrotra (oumi@arsdigita.com)

    @creation-date 2001-02-23
    @cvs-id $Id$
} {
    group_type:notnull
    {return_url:localurl ""}
} -properties {
    context:onevalue
    group_type:onevalue
    QQgroup_type:onevalue
    group_type_pretty_name:onevalue
    admin_p:onevalue
    QQreturn_url:onevalue
    default_join_policy:onevalue
    possible_join_policies:onevalue
}

set context [list \
        [list "[ad_conn package_url]admin/group-types/" "Group types"] \
	[list [export_vars -base one group_type] "One type"] \
	"Edit default join policy"]

if { ![db_0or1row select_pretty_name {}] } {
    ad_return_error "Group type doesn't exist" "Group type \"$group_type\" doesn't exist"
    return
}

if {$dynamic_p != "t" } {
    ad_return_error "Cannot administer group type" "Group type \"$group_type\" can only be administered by programmers"
}

set possible_join_policies [list open "needs approval" closed]
set QQreturn_url [ns_quotehtml $return_url]
set QQgroup_type [ns_quotehtml $group_type]
ad_return_template
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
