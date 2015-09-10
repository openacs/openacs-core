ad_page_contract {
    @author Bryan Quinn (bquinn@arsdigita.com)

    @creation-date August 15, 2000
    @cvs-id $Id$
}

set page_title [ad_conn instance_name]
set package_keys '[join [subsite::package_keys] ',']'
set subsite_number [db_string count_subsites [subst {
    select count(*) from apm_packages where package_key in ($package_keys)
}]]

db_multirow -extend { admin_url global_param_url } packages installed_packages {} {
    if {
	[apm_package_installed_p $package_key]
	&& [file exists "[acs_package_root_dir $package_key]/www/sitewide-admin/"]
    } {
        set admin_url "package/$package_key/"
    } else {
        set admin_url ""
    }
    if { [catch {db_1row global_params_exist {}} errmsg]
	 || $global_params == 0
     } {
	set global_param_url ""
    } else {
	set return_url [ad_conn url]
        set global_param_url [export_vars -base /shared/parameters {package_key return_url {scope global}}]
    }
    if { $admin_url eq "" && $global_param_url eq "" } {
        continue
    }
} 

template::list::create \
    -name packages \
    -multirow packages \
    -elements {
        pretty_name {
            label "Package"
	    html {align left}
        }
        admin_url {
            label "Site-Wide Administration"
            link_html { title "Site-wide Administration" }
            link_url_col admin_url
            display_template {<if @packages.admin_url@ not nil>#acs-admin.Administration#</if>}
	    html {align left}
        }
        global_param_url {
            label "Global Parameters"
            link_html {title "Manage Global Parameters" }
            link_url_col global_param_url
            display_template {<if @packages.global_param_url@ not nil>#acs-admin.Parameters#</if>}
	    html {align left}
        }
    }

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

