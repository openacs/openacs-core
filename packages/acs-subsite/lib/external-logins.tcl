ad_include_contract {
    ADP include for listing logins of external registries

    @param return_url - optional
} {
    {return_url:localurl,trim ""}
}

template::multirow create registries name login_url

foreach auth_obj [ad_get_external_registries] {
    template::multirow append registries \
        [$auth_obj name] \
        [$auth_obj login_url -return_url $return_url]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
