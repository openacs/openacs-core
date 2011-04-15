ad_page_contract {
    Applications

    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-02
    @cvs-id $Id$
}

set page_title "[_ acs-subsite.Applications]"
set context [list $page_title]

# Get the subsite node ID
set subsite_url [site_node_closest_ancestor_package_url]
array set subsite_sitenode [site_node::get -url $subsite_url]
set subsite_node_id $subsite_sitenode(node_id)

db_multirow -extend { parameter_url } applications select_applications {} {
    set instance_name "[string repeat .. $treelevel]$instance_name"
    if { $num_parameters > 0 } {
        set parameter_url [export_vars -base ../../shared/parameters { package_id { return_url [ad_return_url] } }]
    }
}

list::create \
    -name applications \
    -multirow applications \
    -key node_id \
    -actions { 
        "#acs-subsite.Add_application#" application-add "#acs-subsite.Add_new_app#"
    } \
    -bulk_actions {
        "#acs-subsite.Delete#" application-delete "#acs-subsite.Delete_selected_app#"
    } \
    -elements {
        edit {
            sub_class narrow
            display_template {
                <img src="/shared/images/Edit16.gif" height="16" width="16" alt="#acs-subsite.Edit_application_name_and_path#" style="border:0">
            }
            link_url_eval {[export_vars -base application-add { node_id }]}
            link_html { title "#acs-subsite.Edit_application_name_and_path#" }
        }
        instance_name {
            label "[_ acs-subsite.Name]"
            link_url_eval {../../$name/}
        }
        name {
            label "[_ acs-subsite.URL]"
        }
        package_pretty_name {
            label "[_ acs-subsite.Application]"
        }
        permissions {
            label "[_ acs-subsite.Permissions]"
            link_url_eval {[export_vars -base permissions { package_id }]}
            display_template { #acs-subsite.Permissions# }
            sub_class narrow
        }
        parameters {
            label "[_ acs-subsite.Parameters]"
            link_url_col parameter_url
            display_template {<if @applications.parameter_url@ not nil>[_ acs-subsite.Parameters]</if>}
            sub_class narrow
        }
        delete {
            sub_class narrow
            display_template {
                <img src="/shared/images/Delete16.gif" height="16" width="16" alt="#acs-subsite.Delete_this_application#" style="border:0">
            }
            link_url_eval {[export_vars -base application-delete { node_id }]}
            link_html { title "#acs-subsite.Delete_this_application#" }
        }
    }



