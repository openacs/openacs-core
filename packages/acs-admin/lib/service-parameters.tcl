#
# Service parameters list
#

template::list::create \
    -name packages \
    -multirow packages \
    -elements {
        instance_name {
            label {Service}
            link_url_col url
            link_html { title "Visit service interface" }
        }
        admin {
            label "Administration"
            link_url_col admin_url
            link_html { title "Service administration" }
            display_template {<if @packages.admin_url@ not nil>Administration</if>}
        }
        parameters {
            label "Parameters"
            link_url_col param_url
            link_html { title "Service parameters" }
            display_template {<if @packages.param_url@ not nil>Parameters</if>}
        }
    }

set user_id [ad_conn user_id]
db_multirow -extend { url admin_url param_url } packages services_select {} {
    if { [file exists "[acs_package_root_dir $package_key]/www/"] } {
        catch {
            set url [apm_package_url_from_key $package_key]
            if { ![empty_string_p $url] && [file exists "[acs_package_root_dir $package_key]/www/admin/"] } {
                set admin_url "${url}admin/"
            }
        }
    }
    if { $parameter_count > 0 } {
        set param_url [export_vars -base "/shared/parameters" { package_id { return_url {[ad_return_url]} } }]
    }

    if { [empty_string_p $url] && [empty_string_p $admin_url] && [empty_string_p $param_url] } {
        continue
    }
}

