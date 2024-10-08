ad_page_contract {
    Index page for External Authentication listing
    available authorities.

    @author Peter Marklund
    @creation-date 2003-09-08
}

set page_title "Authentication"
set context [list $page_title]

list::create \
    -name "authorities" \
    -multirow "authorities" \
    -key authority_id \
    -elements {
        edit {
            label ""
            display_template {
                <adp:icon name="edit" title="Edit this authority"> 
            }
            link_url_eval {[export_vars -base authority { authority_id {ad_form_mode edit}}]}
            link_html {title "Edit this authority"}
            sub_class narrow
        }
        pretty_name {
            label "\#acs-admin.Name\#"
            link_url_eval {[export_vars -base authority { authority_id }]}
        }
        enabled {
            label "\#acs-admin.Enabled\#"
            html { align center }
            display_template {
                <if @authorities.enabled_p;literal@ true>
                <a href="@authorities.enabled_p_url@">
                  <adp:icon name="checkbox-checked" title="\#acs-admin.Disable_this_authority\#"> 
                </a>
                </if>
                <else>
                <a href="@authorities.enabled_p_url@">
                  <adp:icon name="checkbox-unchecked" title="\#acs-admin.Enable_this_authority\#"> 
                </a>
                </else>
            }
        }
        move {
            label "\#acs-admin.Order\#"
            html { align center }
            display_template {
                <if @authorities.sort_order@ ne @authorities.highest_sort_order@>
                  <a href="@authorities.sort_order_url_up@" title="\#acs-admin.Move_this_authority_up\#">
                    <adp:icon name="arrow-up" title="\#acs-admin.Move_this_authority_up\#">
                  </a>
                </if>
                <else><span style="padding-left: 15px;"></span></else>
                <if @authorities.sort_order@ ne  @authorities.lowest_sort_order@>
                  <a href="@authorities.sort_order_url_down@">
                     <adp:icon name="arrow-down" title="\#acs-admin.Move_this_authority_down\#">
                  </a>
                </if>
                <else><span style="padding-left: 15px;"></span></else>
          }
        }
        registration {
            label "\#acs-admin.Registration\#"
            html { align center }
            display_template {
                <switch @authorities.registration_status@>
                  <case value="selected">
                    <adp:icon name="radio-checked"> 
                  </case>
                  <case value="can_select">
                    <a href="@authorities.registration_url@"
                       title="\#acs-admin.Make_this_the_authority_for_registering_new_users\#"
                       id="@authorities.select_id;literal@">
                       <adp:icon name="radio-unchecked" title="\#acs-admin.Make_this_the_authority_for_registering_new_users\#">
                    </a>
                  </case>
                  <case value="cannot_select">
                    <span style="color: gray;">N/A</span>
                  </case>
                </switch>
            }
        }
        auth_impl {
            label "\#acs-admin.Authentication\#"
        }
        pwd_impl {
            label "\#acs-admin.Password\#"
        }
        reg_impl {
            label "\#acs-admin.Registration\#"
        }
        delete {
            label ""
            display_template {
                <if @authorities.short_name@ ne local>
                  <a href="@authorities.delete_url@"
                     title="Delete this authority"
                     id="@authorities.delete_id;literal@">
                   <adp:icon name="trash" title="\#acs-admin.Delete\#">
                  </a>
                </if>
            }
            sub_class narrow
        }
    }


# The authority currently selected for registering users
set register_authority_id [auth::get_register_authority]

db_multirow -extend {
    enabled_p_url
    sort_order_url_up
    sort_order_url_down
    delete_url
    registration_url
    registration_status
    select_id delete_id
} authorities authorities_select {
    select authority_id,
           short_name,
           pretty_name,
           enabled_p,
           sort_order,
           (select max(sort_order) from auth_authorities) as lowest_sort_order,
           (select min(sort_order) from auth_authorities) as highest_sort_order,
           (select impl_pretty_name from acs_sc_impls where impl_id = auth_impl_id) as auth_impl,
           (select impl_pretty_name from acs_sc_impls where impl_id = pwd_impl_id) as pwd_impl,
           (select impl_pretty_name from acs_sc_impls where impl_id = register_impl_id) as reg_impl
    from   auth_authorities
    order  by sort_order
} {
    set toggle_enabled_p [expr {!$enabled_p}]
    set enabled_p_url [export_vars -base authority-set-enabled-p { authority_id {enabled_p $toggle_enabled_p} }]
    set delete_url [export_vars -base authority-delete { authority_id }]
    set sort_order_url_up [export_vars -base authority-set-sort-order { authority_id {direction up} }]
    set sort_order_url_down [export_vars -base authority-set-sort-order { authority_id {direction down} }]
    set select_id select-authority-$authority_id
    set delete_id delete-authority-$authority_id
    if {$authority_id eq $register_authority_id} {
        # The authority is selected as register authority
        set registration_status "selected"
    } elseif { $reg_impl ne "" } {
        # The authority can be selected as register authority
        set registration_status "can_select"
        set registration_url [export_vars -base authority-registration-select { authority_id }]
        template::add_confirm_handler \
            -id $select_id \
            -message [_ acs-admin.You_are_changing_all_user_registrations_to_be_in_authority_authorities_pretty_name \
                          [list authorities.pretty_name $pretty_name]]
    } else {
        # This authority has no account creation driver
        set registration_status "cannot_select"
    }
    if {$short_name ne "local"} {
        template::add_confirm_handler \
            -id $delete_id \
            -message [_ acs-admin.Are_you_sure_you_want_to_delete_authority_authorities_pretty_name \
                          [list authorities.pretty_name $pretty_name]]
    }
}

set auth_package_id [apm_package_id_from_key "acs-authentication"]
set parameter_url [export_vars -base /shared/parameters { { package_id $auth_package_id } { return_url [ad_return_url] } }]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
