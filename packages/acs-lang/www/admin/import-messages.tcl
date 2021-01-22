ad_page_contract {
    Import messages from catalog files to the database.

    @author Peter Marklund
} {
    {locale ""}
    {package_key ""}
    {return_url:localurl "/acs-lang/admin"}
}

set page_title "Import messages"

if { ![acs_user::site_wide_admin_p] } {
    ad_return_warning "Permission denied" "Sorry, only site-wide administrators are allowed to import message catalog files to the database."
    ad_script_abort
}

array set message_count [lang::catalog::import \
                             -package_key $package_key \
                             -locales $locale]

set conflict_count [lang::message::conflict_count \
                        -package_key $package_key \
                        -locale $locale]

set errors_list "<ul>
  <li>
    [join $message_count(errors) "</li><li>"]
</ul>
"

set conflict_url [export_vars -base message-conflicts { package_key locale }]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
