set package_id [apm_package_id_from_key "acs-templating"]

set size [parameter::get -package_id $package_id -parameter TemplateCacheSize -default 200000]
ns_cache create template_cache -size $size

set size [parameter::get -package_id $package_id -parameter TemplateQueryCacheSize -default 20000]
ns_cache create template_query_cache -size $size

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
