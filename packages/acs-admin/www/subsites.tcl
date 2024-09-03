ad_page_contract {
    @author Gustaf Neumann

    @creation-date August 15, 2015
    @cvs-id $Id$
}

set page_title "Defined Subsites"
set context [list $page_title]
set package_keys [subsite::package_keys]
set subsite_number [db_string count_subsites [subst {
    select count(*) from apm_packages where package_key in ([ns_dbquotelist $package_keys])
}]]

if {$subsite_number > 500} {
    set too_many_subsites_p 1
} else {
    set too_many_subsites_p 0

    db_multirow -extend {
        theme
        theme_url
        admin_url
        path_pretty
        node_url
        parameter_url
        sitemap_url
    } subsites subsite_admin_urls [subst {
        select s.node_id,
               p.package_id
        from   site_nodes s, apm_packages p
        where  s.object_id = p.package_id
        and    p.package_key in ([ns_dbquotelist $package_keys])
    }] {
        set node [site_node::get -node_id $node_id]
        set path_pretty [dict get $node instance_name]
        set parent_id   [dict get $node parent_id]
        set node_url    [dict get $node url]

        set admin_url "${node_url}admin/"
        set parameter_url [export_vars -base /shared/parameters {package_id {return_url "[ad_conn url]"}}]
        set theme [parameter::get -parameter ThemeKey -package_id $package_id]
        set theme_url ${admin_url}themes/
        set sitemap_url [export_vars -base /admin/site-map { {root_id $node_id} }]

        while { $parent_id ne "" } {
            set node [site_node::get -node_id $parent_id]
            set path_pretty "[dict get $node instance_name] > $path_pretty"
            set parent_id [dict get $node parent_id]
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
            actions {
                label "Actions"
                html {style {white-space:nowrap;}}
                display_template {
                    <if @subsites.admin_url@ not nil><a href="@subsites.admin_url@"><adp:icon name="admin"
                          title="#acs-subsite.Administration#"></a></if>
                    <else><adp:icon name="admin" invisible="true"></else>&nbsp;
                    <a href="@subsites.parameter_url@"><adp:icon name="cog" title="#acs-admin.Parameters#"></a>&nbsp;
                    <a href="@subsites.sitemap_url@"><adp:icon name="sitemap" title="Manage sitemap"></a>
                }
            }
        }
}


#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
