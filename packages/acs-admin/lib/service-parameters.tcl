ad_include_contract {

    Service parameters list

} {
} -validate {
    swa_p {
        if { ![acs_user::site_wide_admin_p] } {
            ad_return_forbidden
        }
    }
}

set user_id [ad_conn user_id]
set swadmin_p 0
db_multirow -extend { url admin_url param_url sitewide_admin_url} packages services_select {
    select package_id,
           ap.package_key,
           pretty_name as instance_name,
           (select count(*) from apm_parameters
             where package_key = ap.package_key) as parameter_count
    from apm_packages ap,
         apm_package_types
    where ap.package_key = apm_package_types.package_key
    and package_type = 'apm_service'
    and ap.package_key <> 'acs-subsite'
    order by instance_name
} {
    set root_dir [acs_package_root_dir $package_key]
    set sitewide_admin_url ""
    if { [file exists $root_dir/www/] } {
        set url [apm_package_url_from_id $package_id]
        if { $url ne "" && [file exists $root_dir/www/admin/] } {
            set admin_url "${url}admin/"
        }
        if { [file exists $root_dir/www/sitewide-admin/]
             && [glob -nocomplain $root_dir/www/sitewide-admin/index.*] ne ""
         } {
            set sitewide_admin_url "/acs-admin/package/$package_key/"
            set swadmin_p 1
        }
        if {[glob -nocomplain $root_dir/www/index.*] eq ""} {
            set url ""
        }
    }
    if { $parameter_count > 0 } {
        set param_url [export_vars -base "/shared/parameters" { package_id { return_url {[ad_return_url]} } }]
    }
    set instance_name [lang::util::localize $instance_name]

    if { $url eq "" && $admin_url eq "" && $param_url eq "" && $sitewide_admin_url eq ""} {
        continue
    }
}

template::list::create \
    -name packages \
    -multirow packages \
    -elements {
        instance_name {
            label {\#acs-admin.Service#}
            html {align left}
        }
        www {
            label "\#acs-admin.Pages\#"
            link_url_col url
            link_html { title "\#acs-admin.Visit_service_pages\#" }
            display_template {<if @packages.url@ not nil>\#acs-admin.Pages\#</if>}
            html {align left}
        }
        admin {
            label "\#acs-admin.Administration\#"
            link_url_col admin_url
            link_html { title "\#acs-admin.Service_administration\#" }
            display_template {<if @packages.admin_url@ not nil>\#acs-admin.Administration\#</if>}
            html {align left}
        }
        sitewide_admin {
            label "\#acs-admin.Site-Wide_Admin\#"
            link_url_col sitewide_admin_url
            link_html { title "\#acs-admin.Service_administration\#" }
            display_template {<if @packages.sitewide_admin_url@ not nil>\#acs-admin.Administration\#</if>}
            hide_p {[string is false $swadmin_p]}
            html {align left}
        }
        parameters {
            label "\#acs-admin.Parameters\#"
            link_url_col param_url
            link_html { title "\#acs-admin.Service_parameters\#" }
            display_template {<if @packages.param_url@ not nil>\#acs-admin.Parameters\#</if>}
            html {align left}
        }
    }


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
