#
# Service parameters list
#


if { ![acs_user::site_wide_admin_p] } {
    ad_return_forbidden \
        "Permission Denied" \
        "<blockquote>You don't have permission to view this page.</blockquote>"
    ad_script_abort
}

set user_id [ad_conn user_id]
set swadmin_p 0
db_multirow -extend { url admin_url param_url } packages services_select {} {
    if { [file exists "[acs_package_root_dir $package_key]/www/"] } {
        catch {
            set url [apm_package_url_from_key $package_key]
            if { $url ne "" && [file exists "[acs_package_root_dir $package_key]/www/admin/"] } {
                set admin_url "${url}admin/"
            }
            if { [file exists "[acs_package_root_dir $package_key]/www/sitewide-admin/"] } {
                set sitewide_admin_url "/acs-admin/package/$package_key/"
                set swadmin_p 1
            }
        }
    }
    if { $parameter_count > 0 } {
        set param_url [export_vars -base "/shared/parameters" { package_id { return_url {[ad_return_url]} } }]
    }
    set instance_name [lang::util::localize $instance_name]

    if { $url eq "" && $admin_url eq "" && $param_url eq "" } {
        continue
    }
}

template::list::create \
    -name packages \
    -multirow packages \
    -elements {
        instance_name {
            label {#acs-admin.Service#}
        }
        www {
            label "\#acs-admin.Pages\#"
            link_url_col url
            link_html { title "\#acs-admin.Visit_service_pages\#" }
            display_template {<if @packages.url@ not nil>\#acs-admin.Pages\#</if>}
        }
        admin {
            label "\#acs-admin.Administration\#"
            link_url_col admin_url
            link_html { title "\#acs-admin.Service_administration\#" }
            display_template {<if @packages.admin_url@ not nil>\#acs-admin.Administration\#</if>}
        }
        sitewide_admin {
            label "\#acs-admin.Site-Wide_Admin\#"
            link_url_col sitewide_admin_url
            link_html { title "\#acs-admin.Service_administration\#" }
            display_template {<if @packages.sitewide_admin_url@ not nil>\#acs-admin.Administration\#</if>}
            hide_p {[ad_decode $swadmin_p 1 0 1]}
        }
        parameters {
            label "\#acs-admin.Parameters\#"
            link_url_col param_url
            link_html { title "\#acs-admin.Service_parameters\#" }
            display_template {<if @packages.param_url@ not nil>\#acs-admin.Parameters\#</if>}
        }
    }

