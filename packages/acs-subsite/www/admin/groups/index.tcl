# /packages/subsite/www/admin/groups/index.tcl

ad_page_contract {

    Shows the user all groups on which s/he has permission

    @author mbryzek@arsdigita.com
    @creation-date Thu Dec  7 18:09:49 2000
    @cvs-id $Id$

} {
    {view_by "group_type"}
} -validate {
    view_by_valid_p {
	if { $view_by ni {group_type rel_type}} { 
	    ad_complain "view_by is invalid."
	}
    }
} -properties {
    context:onevalue
    groups:multirow
    subsite_group_id:onevalue
    view_by:onevalue
}

set context [list [_ acs-subsite.Groups]]
set doc(title) [_ acs-subsite.Group_administration]

set this_url [ad_conn url]

set package_id [ad_conn package_id]

db_1row subsite_info {
    select ag.group_id as subsite_group_id, ap.instance_name
    from application_groups ag, apm_packages ap
    where ag.package_id = ap.package_id
      and ag.package_id = :package_id
}

set intro_text [lang::util::localize [_ acs-subsite.Currently_the_instance_name_has_the_following_groups]]

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
