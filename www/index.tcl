ad_page_contract {

    OpenACS main index page.  This is the standard page that is used to allow users
    to login to the site.  You can customize the presentation by editing index.adp.
    However, for a real web site, you will likely need to take this file as a boiler
    plate and add the necessary content and branding items.

    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date 10/10/2000
    @cvs-id $Id$

} {
    {username ""}
    {authority_id ""}
}

# DRB: vertical applications like dotLRN can set the IndexRedirectUrl parameter to force the user
# to an index page of its choice.

set redirect_url [parameter::get_from_package_key -package_key acs-kernel -parameter IndexRedirectUrl]
if { ![string equal $redirect_url ""] } {
    ad_returnredirect $redirect_url
    ad_script_abort
}

set user_id [ad_conn user_id]

db_multirow nodes site_nodes {}

if { $user_id != 0 } {
    # The user is loged in.
    if {[db_0or1row user_name_select {
	select first_names || ' ' || last_name as name, email
	from persons, parties
	where person_id = :user_id
	and person_id = party_id
    }]} {
	set home_url [ad_pvt_home]
	set home_url_name [ad_pvt_home_name]	
    }
    set requires_registration_p_clause ""
}

set system_name [ad_system_name]

set acs_version [ad_acs_version]

set acs_root_dir [acs_root_dir]

set focus {}
