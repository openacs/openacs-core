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
                <adp:icon name="edit" title="#acs-subsite.Edit_application_name_and_path#">
            }
            link_url_eval {[export_vars -base application-add { node_id }]}
        }
        instance_name {
            label "[_ acs-subsite.Name]"
            link_url_eval {[site_node::get_url -node_id $node_id]}
        }
        name {
            label "[_ acs-subsite.URL]"
        }
        package_pretty_name {
            label "[_ acs-subsite.Application]"
        }
        actions {
            label "Actions"
            html "align left"
            display_template {
                <if @applications.permissions_url@ ne "">
                  <a href="@applications.permissions_url@"><adp:icon name='permissions' title='[_ acs-subsite.permissions]'></a>
                </if>
                <else><adp:icon name='permissions' invisible='true'></else>

                <if @applications.parameter_url@ ne "">
                  <a href="@applications.parameter_url@"><adp:icon name='cog' title='[_ acs-subsite.parameters]'></a>
                </if>
                <else><adp:icon name='cog' invisible='true'></else>

                <a href="@applications.delete_url@"><adp:icon name="trash" title="#acs-subsite.Delete_this_application#"></a>
            }
        }

    } -filters {
        search {
            hide_p 1
            where_clause {
                (:search is null or n.name || ' ' || p.instance_name || ' ' || pt.pretty_name || ' ' || coalesce(m.message, '') || ' ' || coalesce(md.message, '') ilike '%' || :search || '%')
            }
        }
    }


db_multirow -extend { parameter_url permissions_url delete_url} applications select_applications_page {} {
    set instance_name [string repeat "- " $treelevel]$instance_name
    if { $parameters_p } {
        set parameter_url [export_vars -base ../../shared/parameters { package_id { return_url [ad_return_url] } }]
    }
    set delete_url [export_vars -base application-delete { node_id }]
    set permissions_url [export_vars -base permissions { package_id }]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
