ad_page_contract {
    Applications

    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-02
    @cvs-id $Id$
} {
    page:naturalnum,optional
    {search ""}
}

set page_title [_ acs-subsite.Applications]
set context [list $page_title]

set subsite_node_id [ad_conn subsite_node_id]

set locale [ad_conn locale]

ad_form \
    -name filter \
    -edit_buttons [list [list "Go" go]] \
    -has_submit 1 \
    -html { style "float:right;" } \
    -form {
	{search:text,optional
            {label ""}
	    {html {length 20 placeholder "[_ acs-kernel.common_Search]"} }
	    {value $search}
	}
    } -on_submit {}

list::create \
    -name applications \
    -multirow applications \
    -key node_id \
    -page_flush_p 1 \
    -page_size 250 \
    -page_query_name select_applications \
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
    } -filters {
	search {
	    hide_p 1
            where_clause {(:search is null or upper(coalesce(coalesce(m.message, md.message), p.instance_name) || n.name || pt.pretty_name) like '%' || upper(:search) || '%')}
        }
    }


db_multirow -extend { parameter_url } applications select_applications_page {} {
    set instance_name [string repeat "- " $treelevel]$instance_name
    if { $parameters_p } {
        set parameter_url [export_vars -base ../../shared/parameters { package_id { return_url [ad_return_url] } }]
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
