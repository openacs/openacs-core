ad_page_contract {
    Import messages from catalog files to the database.

    @author Peter Marklund
} {
    {locale ""}
    {package_key ""}
    {keeplocal_p ""}
    {confirmed_p ""}
    {return_url "/acs-lang/admin"}
}

set page_title "Import messages"

if { ![acs_user::site_wide_admin_p] } {
    ad_return_warning "Permission denied" "Sorry, only site-wide administrators are allowed to import message catalog files to the database."
    ad_script_abort
}

set confirm_url {}
if {[string length $keeplocal_p]} {
    if {[string is true $keeplocal_p]} {
	    append page_title " (keep local changes)"
    } else {
	    append page_title " (overwrite local changes)"
	    if {[string length $confirmed_p]} {
	        set confirmed_p 1
	    } else {
	        set confirmed_p 0
	        set confirm_url [export_vars -base [ad_conn url] { locale package_key keeplocal_p confirmed_p return_url}]
	        return
	    }
    }
}

array set message_count [lang::catalog::import \
                             -package_key $package_key \
                             -locales $locale \
                             -keeplocal_p $keeplocal_p ]

set conflict_count [lang::message::conflict_count \
                        -package_key $package_key \
                        -locale $locale]

set errors_list "<ul>
  <li>
    [join $message_count(errors) "</li><li>"]
</ul>
"

set conflict_url [export_vars -base message-conflicts { package_key locale }]
