ad_page_contract {
    Export messages from the database to catalog files.

    @author Peter Marklund
} {
    {locale:multiple ""}
    {package_key ""}
    {return_url:localurl "/acs-lang/admin"}
}

set page_title "Export messages"

if { ![acs_user::site_wide_admin_p] } {
    ad_return_warning "Permission denied" "Sorry, only site-wide administrators are allowed to export messages from the database to catalog files."
    ad_script_abort
}

lang::catalog::export \
    -package_key $package_key \
    -locales $locale

set catalog_dir [lang::catalog::package_catalog_dir $package_key]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
