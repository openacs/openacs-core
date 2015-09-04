ad_page_contract {
    Package installation.
} {
    package_type:optional
}

set page_title "Install Software"
set context [list $page_title]

template::multirow create install repository local

multirow append install \
    {Download and install/upgrade automatically from <a href="http://openacs.org/repository/">OpenACS.org repository</a>} \
    {Install/upgrade from local files.  Use this if your site has custom code or is in a local CVS repository.
	<a href="/doc/upgrade">Help</a>}

multirow append install \
    { <a href="@remote_install_url@">Install</a> or <a href="@remote_upgrade_url@">upgrade</a> 
	from repository.} \
    {<a href="@local_install_url@">Install or upgrade</a> from local file system.}

template::list::create \
    -name install \
    -multirow install \
    -elements {
        repository {
            label "From Repository"
	    display_template @install.repository;noquote@
        }
        local {
            label "Local Files"
	    display_template @install.local;noquote@
        }
    }




template::list::create \
    -name packages \
    -multirow packages \
    -elements {
        pretty_name {
            label "Package"
	    html {align left}
        }
        version_name {
            label "Version"
	    html {align left}
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
    [template::list::filter_where_clauses -and -name packages]
    order  by t.package_type, t.pretty_name
" {
    set package_type_pretty [string totitle [lindex [split $package_type "_"] 1]]
}

#set local_install_url [export_vars -base "install" { { package_type apm_application } }]
#set local_service_install_url [export_vars -base "install" { { package_type apm_service } }]
#set local_upgrade_url [export_vars -base "install" { { upgrade_p 1 } }]

set local_install_url "[ad_conn package_url]/apm/packages-install"

set repository_url "http://openacs.org/repository/"
set head_channel [lindex [apm_get_repository_channels $repository_url] 0]
set current_channel [apm_get_repository_channel]
set channel $current_channel
set remote_install_url [export_vars -base "install" { repository_url channel current_channel head_channel }]
set remote_upgrade_url [export_vars -base "install" { { upgrade_p 1 } repository_url channel current_channel head_channel}]
