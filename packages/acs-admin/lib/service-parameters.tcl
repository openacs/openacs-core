#
# Service parameters list
#

template::list::create \
    -name packages \
    -multirow packages \
    -elements {
        instance_name {
            label {Package}
            link_url_eval {[export_vars -base "/shared/parameters" { package_id { return_url {[ad_return_url]} } }]}
            link_html { title "Edit parameters" }
        }
    }

set user_id [ad_conn user_id]
db_multirow packages services_select {}

