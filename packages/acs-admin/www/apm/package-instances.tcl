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

append body \
    <h1>$title</h1><ul><p> \
    "<table class='table table-striped'>" \
    "<tr><th>Package ID</th></th><th>Instance Name</th><th>Mount Point</th><th>Actions</th></tr>\n"
    
set lines {}
db_foreach get_version_info {
    select package_id, instance_name from apm_packages where package_key = :package_key
    order by package_id
} {
    ns_log notice "GOT $package_id, $instance_name "
    set URLs [site_node::get_url_from_object_id -object_id $package_id]
    set actions ""
    if {[llength $URLs] > 0} {
        ns_log notice "GOT $package_id, $instance_name -> URLs $URLs"
 
        foreach url $URLs {
            set node_id [dict get [site_node::get -url $url] node_id]
            set delete_href [export_vars -base /admin/applications/application-delete { node_id return_url }]
            set smap_href [export_vars -base /admin/site-map { {root_id $node_id} return_url }]
            set permissions_href [export_vars -base /permissions/one {{object_id $package_id}}]
            set line [subst {
                <td>$package_id</td><td>$instance_name</td><td><a href="$url">$url</a></td><td> 
                <a href="[ns_quotehtml $delete_href]"><adp:icon name="trash" title="Delete Instance"></a>
                <a href="[ns_quotehtml $smap_href]"><adp:icon name="sitemap" title="Site Map"></a>
                <a href="[ns_quotehtml $permissions_href]"><adp:icon name="permissions" title="Permissions"></a>
                </td>
            }]
            lappend lines $line
        }
    } else {
        set delete_href [export_vars -base /admin/applications/application-delete { package_id return_url }]
        set line [subst {
            <td>$package_id</td><td>$instance_name</td><td>(unmounted)</td><td>
            <a href="[ns_quotehtml $delete_href]"><adp:icon name="trash" title="delete instance"></a></td>
        }]
        lappend lines $line
    }    
}
foreach line $lines {
    append body <tr>$line</tr>\n
}
append body </table>

ad_return_template apm

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
