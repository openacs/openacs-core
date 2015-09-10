# @param admin_p - generate admin action links.

set pretty_name [_ acs-subsite.subsite]
set pretty_plural [_ acs-subsite.subsites]

set admin_p [permission::permission_p -object_id [ad_conn subsite_id] -privilege admin -party_id [ad_conn untrusted_user_id]]

set actions {}
if {[info exists admin_p] 
    && $admin_p } {
    lappend actions [_ acs-subsite.Create_new_subsite] "[subsite::get_element -element url]admin/subsite-add" {}
}

list::create \
    -name subsites \
    -multirow subsites \
    -actions $actions \
    -no_data "[_ acs-subsite.No_pretty_plural [list pretty_plural $pretty_plural]]" \
    -elements {
        instance_name {
            label "[_ acs-subsite.Name]"
            link_url_col url
        }
        num_members {
            label "\# [_ acs-subsite.Members]"
            html { align right }
        }
        member_state {
            label "Member state"
            display_template {
                <switch @subsites.member_state@>
                  <case value="approved">Approved</case>
                  <case value="needs approval">Awaiting approval</case>
                  <case value="rejected">Rejected</case>
                  <default>
                    @subsites.member_state@
                    <if @subsites.join_policy@ eq "open"><a href="@subsites.join_url@" class="button">Join</a></if>
                    <else><a href="@subsites.join_url@" class="button">Request membership</a></else>
                  </default>
                </switch>
            }
        }
    }


set subsite_node_id [subsite::get_element -element node_id]
set subsite_url [subsite::get_element -element url]

set untrusted_user_id [ad_conn untrusted_user_id]

db_multirow -extend { url join_url request_url } subsites select_subsites {*SQL*} {
    set join_url [export_vars -base "${subsite_url}register/user-join" { group_id { return_url [ad_return_url] } }]
    set url $subsite_url$name
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
