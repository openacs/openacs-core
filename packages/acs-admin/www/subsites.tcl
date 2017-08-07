ad_page_contract {
    @author Gustaf Neumann

    @creation-date August 15, 2015
    @cvs-id $Id$
}

set page_title "Defined Subsites"
set context [list $page_title]

set package_keys '[join [subsite::package_keys] ',']'
set subsite_number [db_string count_subsites [subst {
    select count(*) from apm_packages where package_key in ($package_keys)
}]]

if {$subsite_number > 500} {
    set too_many_subsites_p 1
} else {
    set too_many_subsites_p 0

    db_multirow -extend { theme theme_url admin_url path_pretty parameter_url} subsites subsite_admin_urls {} {
        set admin_url "${node_url}admin/"
        set parameter_url [export_vars -base /shared/parameters {package_id {return_url "[ad_conn url]"}}]
        set path_pretty $instance_name
        array set node [site_node::get -node_id $node_id]
        set parent_id $node(parent_id)
        set theme [parameter::get -parameter ThemeKey -package_id $package_id]
        set theme_url ${admin_url}themes/
        
        while { $parent_id ne "" } {
            array unset node
            array set node [site_node::get -node_id $parent_id]
            set path_pretty "$node(instance_name) > $path_pretty"
            set parent_id $node(parent_id)
        }
    }
    multirow sort subsites path_pretty

    template::list::create \
        -name subsites \
        -multirow subsites \
        -elements {
            path_pretty {
                label "Subsite Name"
                html {align left}
            }
            node_url {
                label "Pages"
                link_html { title "Pages of Subsite" }
                link_url_col node_url
                display_template {\#acs-admin.Pages#}
                html {align left}
            }

            theme {
                label "Theme"
                link_url_col theme_url
                html {align left}
            }
            admin_url {
                label "Subsite Administration"
                link_html { title "Subsite Administration" }
                link_url_col admin_url
                display_template {<if @subsites.admin_url@ not nil>#acs-admin.Administration#</if>}
                html {align left}
            }
            parameter_url {
                label "Parameters"
                link_html {title "Manage Subsite Parameters" }
                display_template {\#acs-admin.Parameters#}
                link_url_col parameter_url
                html {align left}
            }
            sitemap {
                sub_class narrow
                display_template {
                    <img src="/shared/images/Edit16.gif" height="16" width="16" alt="Manage sitemap" style="border:0">
                    
                }
                link_url_eval {[export_vars -base /admin/site-map { {root_id $node_id} }]}
                link_html { title "Manage sitemap" }
            }
        }
}


#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
