# /packages/acs-lang/www/admin/index.tcl

ad_page_contract {

    Administration of the localized messages

    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
    @creation-date 19 October 2001
    @cvs-id $Id$
} {
    {tab "locales"}
}

set locale_user [ad_locale user locale]
set instance_name [ad_conn instance_name]
set context_bar [ad_context_bar [ad_conn instance_name]]

if { [ad_permission_p 0 admin] } {
    set show_locales_p "t"
} else {
    set show_locales_p "f"
}
