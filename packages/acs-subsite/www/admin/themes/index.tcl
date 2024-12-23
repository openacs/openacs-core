ad_page_contract {
    Themes

    @author Gustaf Neumann
    @creation-date 2017-01-20
} {
    {rename_theme ""}
}

set doc(title) [_ acs-subsite.Themes]
set context [list $doc(title)]

set subsite_node_id [ad_conn subsite_node_id]

list::create \
    -name themes \
    -multirow themes \
    -key key \
    -pass_properties rename_theme \
    -page_query_name select_themes \
    -elements {
        edit {
            sub_class narrow
            display_template {
                <if @themes.active_p;literal@ true>
                <adp:icon name="edit" title="#acs-subsite.Edit_this_theme#">
                </if>
            }
            link_url_eval {[export_vars -base view { {theme $key} }]}
            link_html { title "#acs-subsite.Edit_this_theme#" }
        }

        key {
            label "[_ acs-subsite.Key]"
        }
        name {
            label "[_ acs-subsite.Name]"
        }
        usage_count {
            label "[_ acs-subsite.Usage]"
            html {style "text-align: center;"}

        }
        active_p {
            label "[_ acs-subsite.Active_theme]"
            display_template {
                <if @themes.active_p;literal@ true>
                <adp:icon name="radio-checked" title="#acs-subsite.Modified_theme#">
                </if>
                <else>
                <a href="set?theme=@themes.key@" title="#acs-subsite.Select_theme#">
                <adp:icon name="radio-unchecked" title="#acs-subsite.Select_theme#">                
                </a>
                </else>
            }
            html { align center }
        }
        modified_p {
            label "[_ acs-subsite.Modified_theme]"
            display_template {
                <if @themes.modified_p;literal@ true>
                <if @rename_theme@ eq @themes.key;literal@>
                <form name="rename_theme" action="save-new">
                <div>
                <label for="new-theme">New key: </label>
                <input id="new-theme" name="new_theme" type="text" value="@themes.key@" size="40"><br>
                <label for="new-name">New name: </label>
                <input id="new-name" name="new_name" type="text" value="@themes.name@" size="40"><br>
                <input type="submit" value="Save New"></div>
                </form>
                </if>
                <else>
                <adp:icon name="radio-checked" title="#acs-subsite.Modified_theme#">
                <a href="./?rename_theme=@themes.key;literal@">Save new</a>
                </else>
                </if>
            }
            html { align center }
        }
        delete {
            sub_class narrow
            display_template {
                <if @themes.usage_count;literal@ eq 0>
                <adp:icon name="trash" title="#acs-subsite.Delete_this_theme#">
                </if>
            }
            link_url_eval {[export_vars -base delete { {theme $key} }]}
            link_html { title "#acs-subsite.Delete_this_theme#" }
        }
    }

set subsite_id [ad_conn subsite_id]
set currentThemeKey [parameter::get -parameter ThemeKey -package_id $subsite_id]

set package_keys [subsite::package_keys]
db_multirow -extend {active_p modified_p delete_p usage_count} themes select_themes {} {
    set active_p [expr {$currentThemeKey eq $key}]
    set modified_p [expr {$active_p && [subsite::get_theme_subsites \
                                            -theme $key \
                                            -subsite_id $subsite_id \
                                            -unmodified] eq ""}]
    set usage_count [db_string count_theme_usages [subst {
        select count(*)
        from apm_parameters p, apm_parameter_values v
        where p.parameter_name = 'ThemeKey'
        and   p.package_key in ([ns_dbquotelist $package_keys])
        and   p.parameter_id = v.parameter_id
        and   v.attr_value = :key
    }]]
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
