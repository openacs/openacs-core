ad_page_contract {
    Package installation.
}

set page_title "Install Software"

set context [list $page_title]

set local_install_url "local-install"

set local_service_install_url [export_vars -base "local-install" { { package_type apm_service } }]

set local_upgrade_url [export_vars -base "local-install" { { package_type all } { upgrade_p 1 } }]
