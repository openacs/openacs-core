ad_page_contract {
    Show package instances
    @author Gustaf Neumann
    @creation-date 3 Sept 2014
    @cvs-id $Id$
} {
    {package_key:token,notnull}
}

set version_id [apm_highest_version $package_key]
apm_version_info $version_id

set title "Instances of Package $pretty_name $version_name ($package_key)"
set context [list \
                 [list "../developer" "Developer's Administration"] \
                 [list "/acs-admin/apm/" "Package Manager"] \
                 [list "/acs-admin/apm/version-view?version_id=$version_id" "Package $pretty_name"] \
                 $title]
set return_url [export_vars -base [ad_conn url] { package_key }]

append body <h3>$title</h3><ul>

db_foreach get_version_info {
    select package_id, instance_name from apm_packages where package_key = :package_key
    order by package_id
} {
    set urls [site_node::get_url_from_object_id -object_id $package_id]
    if {[llength $urls] > 0} {
        foreach url $urls {
            set node_id [dict get [site_node::get -url $url] node_id]
            set delete_href [export_vars -base /admin/applications/application-delete { node_id return_url }]
            set smap_href [export_vars -base /admin/site-map { {root_id $node_id} return_url }]
            append body [subst {
                <li>$package_id $instance_name <a href="$url">$url</a> (node_id $node_id): 
                \[<a href="[ns_quotehtml $delete_href]">delete</a>,
                <a href="[ns_quotehtml $smap_href]">Site Map</a>\]
                </li>
            }]
        }
    } else {
        set delete_href [export_vars -base /admin/applications/application-delete { package_id return_url }]
        append body [subst {
            <li>$package_id $instance_name (unmounted): 
            \[<a href="[ns_quotehtml $delete_href]">delete</a>\]
            </li>
        }]
    }
}

append body </ul>

ad_return_template apm

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
