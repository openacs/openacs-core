ad_page_contract {
    Localization home
} {
    {return_url ""}
    {return_p "f"}
}

set instance_name [ad_conn instance_name]
set context_bar [ad_context_bar]

#
# Get user pref setting
#

set locale [lang::user::locale]
set language [lang::user::language]
set admin_p [ad_permission_p [ad_conn package_id] admin]
