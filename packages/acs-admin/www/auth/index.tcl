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
                <img src="/shared/images/Edit16.gif" height="16" width="16" alt="Edit" border="0">
            }
            link_url_eval {[export_vars -base authority { authority_id {ad_form_mode edit}}]}
            link_html {title "Edit this authority"}
            sub_class narrow
        }
        pretty_name {
            label "Name"
            link_url_eval {[export_vars -base authority { authority_id }]}
        }
        enabled {
            label "Enabled"
            display_template {
                <if @authorities.short_name@ ne "local">
                  <if @authorities.enabled_p@ true>
                    <a href="@authorities.enabled_p_url@" title="Disable this authority"><img src="/shared/images/checkboxchecked" height="13" width="13" border="0"></a>
                  </if>
                  <else>
                    <a href="@authorities.enabled_p_url@" title="Enable this authority"><img src="/shared/images/checkbox" height="13" width="13" border="0"></a>
                  </else>
                </if>
                <else>
                  Yes
                </else>
            }
        }
        move {
            label "Order*"
            display_template {
                <if @authorities.sort_order@ ne @authorities.highest_sort_order@>
                  <a href="@authorities.sort_order_url_up@" title="Move this authority up"><img src="/shared/images/arrow-up.gif" border="0" width="15" height="15"></a></if>
                </if>
                <if @authorities.sort_order@ ne  @authorities.lowest_sort_order@>
                  <a href="@authorities.sort_order_url_down@" title="Move this authority down"><img src="/shared/images/arrow-down.gif" border="0" width="15" height="15"></a>
                </if>
          }
        }
        auth_impl {
            label "Authentication"
        }
        pwd_impl {
            label "Password"
        }
        reg_impl {
            label "Registration"
        }
        delete {
            label ""
            display_template {
                <a href="@authorities.delete_url@"
                   title="Delete this authority"
                   onclick="return confirm('Are you sure you want to delete authority @authorities.pretty_name@?');">
                  <img src="/shared/images/Delete16.gif" height="16" width="16" alt="Delete" border="0">
                </a>
            }
            sub_class narrow
        }
    }

db_multirow -extend { 
    enabled_p_url 
    sort_order_url_up 
    sort_order_url_down 
    delete_url 
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
    set toggle_enabled_p [ad_decode $enabled_p "t" "f" "t"]
    set enabled_p_url "authority-set-enabled-p?[export_vars { authority_id {enabled_p $toggle_enabled_p} }]"
    set delete_url [export_vars -base authority-delete { authority_id }]
    set sort_order_url_up "authority-set-sort-order?[export_vars { authority_id {direction up} }]"
    set sort_order_url_down "authority-set-sort-order?[export_vars { authority_id {direction down} }]"
}
