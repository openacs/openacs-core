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
	set valid_view_by_list [list group_type rel_type]
	if { [lsearch $valid_view_by_list $view_by] == -1} { 
	    ad_complain "view_by is invalid."
	}
    }
} -properties {
    context:onevalue
    groups:multirow
    subsite_group_id:onevalue
    view_by:onevalue
}

set context [list "Groups"]

set this_url [ad_conn url]

set package_id [ad_conn package_id]

db_1row subsite_info {
    select ag.group_id as subsite_group_id, ap.instance_name
    from application_groups ag, apm_packages ap
    where ag.package_id = ap.package_id
      and ag.package_id = :package_id
}


ad_return_template
