set admin_p [permission::permission_p -object_id [ad_conn subsite_id] -privilege admin -party_id [ad_conn untrusted_user_id]]

set actions [list]
if { $admin_p } {
    lappend actions \
        [_ acs-subsite.Add_new_app] \
        [export_vars -base "[subsite::get_element -element url]admin/applications/application-add" {
            { return_url [ad_return_url] }
        }]
}

list::create \
    -name applications \
    -multirow applications \
    -no_data "[_ acs-subsite.No_applications]" \
    -actions $actions \
    -elements {
        instance_name {
            label "[_ acs-subsite.Name]"
            link_url_eval {$name/}
        }
    }

set subsite_node_id [subsite::get_element -element node_id]

set user_id [ad_conn user_id]

db_multirow applications select_applications {}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
