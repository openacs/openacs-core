ad_page_contract {
    Applications

    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-02
    @cvs-id $Id$
}

set page_title "Applications"
set context [list $page_title]

# Get the subsite node ID
set subsite_url [site_node_closest_ancestor_package_url]
array set subsite_sitenode [site_node::get -url $subsite_url]
set subsite_node_id $subsite_sitenode(node_id)

db_multirow applications select_applications {
    select n.node_id, 
           n.name, 
           p.package_id,
           p.instance_name,
           pt.pretty_name as package_pretty_name
    from   site_nodes n,
           apm_packages p,
           apm_package_types pt
    where  n.parent_id = :subsite_node_id
    and    p.package_id = n.object_id
    and    pt.package_key = p.package_key
}

list::create \
    -name applications \
    -multirow applications \
    -key node_id \
    -actions { 
        "Add application" application-add "Add new application"
    } \
    -bulk_actions {
        "Delete" application-delete "Delete selected applications"
    } \
    -elements {
        edit {
            sub_class narrow
            display_template {
                <img src="/shared/images/Edit16.gif" height="16" width="16" border="0">
            }
            link_url_eval {[export_vars -base application-add { node_id }]}
            link_html { title "Edit application name and path" }
        }
        instance_name {
            label "Name"
            link_url_eval {../../$name/}
        }
        name {
            label "URL"
        }
        package_pretty_name {
            label "Application"
        }
        permissions {
            label "Permissions"
            link_url_eval {[export_vars -base permissions { package_id }]}
            display_template {Permissions}
        }
        delete {
            sub_class narrow
            display_template {
                <img src="/shared/images/Delete16.gif" height="16" width="16" border="0">
            }
            link_url_eval {[export_vars -base application-delete { node_id }]}
            link_html { title "Delete this application" }
        }
    }



