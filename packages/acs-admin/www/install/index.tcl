ad_page_contract {
    Package installation.
} {
    package_type:optional
}

set page_title "Install Software"

set context [list $page_title]


template::list::create \
    -name packages \
    -multirow packages \
    -elements {
        pretty_name {
            label "Package"
        }
        version_name {
            label "Version"
        }
        package_type_pretty {
            label "Type"
            hide_p 1
        }
    } -filters {
        package_type {
            label "Type"
            default_value apm_application
            where_clause {
                t.package_type = :package_type
            }
            values {
                {Application apm_application}
                {Service apm_service}
            }
        }
    }

db_multirow -extend { package_type_pretty } packages packages "
    select v.version_id, 
           v.package_key, 
           t.pretty_name, 
           t.package_type,
           v.version_name
    from   apm_package_versions v, 
           apm_package_types t
    where  t.package_key = v.package_key
    and    v.enabled_p = 't'
    and    v.installed_p = 't'
    [template::list::filter_where_clauses -and -name "packages"]
    order  by t.package_type, t.pretty_name
" {
    set package_type_pretty [string totitle [lindex [split $package_type "_"] 1]]
}


set local_install_url [export_vars -base "install" { { package_type apm_application } }]

set local_service_install_url [export_vars -base "install" { { package_type apm_service } }]

set local_upgrade_url [export_vars -base "install" { { upgrade_p 1 } }]


set repository_url "http://openacs.org/repository/[apm_get_repository_channel]/"

set remote_install_url [export_vars -base "install" { repository_url { package_type apm_application } }]

set remote_service_install_url [export_vars -base "install" { { package_type apm_service } repository_url }]

set remote_upgrade_url [export_vars -base "install" { { upgrade_p 1 } repository_url }]
