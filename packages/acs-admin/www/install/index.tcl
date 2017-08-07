ad_page_contract {
    Package installation.
} {
    package_type:optional
}

set page_title "Install OpenACS Packages"
set context [list $page_title]

set local_install_url [export_vars -base [ad_conn package_url]/apm/packages-install { {operation install} }]
set local_upgrade_url [export_vars -base [ad_conn package_url]/apm/packages-install { {operation upgrade} }]
set local_path $::acs::rootdir/packages

set remote_install_url [export_vars -base "install/install" { repository_url channel current_channel head_channel }]
set remote_upgrade_url [export_vars -base "install/install" { {upgrade_p 1} repository_url channel current_channel head_channel}]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
