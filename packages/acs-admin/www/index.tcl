ad_page_contract {
    @author Bryan Quinn (bquinn@arsdigita.com)

    @creation-date August 15, 2000
    @cvs-id $Id$
}

set title "[ad_conn instance_name] for [ad_system_name]"

set page "
[ad_admin_header $title]
<h2>$title</h2>
[ad_context_bar]
<hr>

<h3>Core Services</h3>

<ul>
  <li><a href=apm>ACS Package Manager</a>
  <li><a href=users>Users</a>
  <li><a href=cache>Cache info</a>
</ul>
<p>
"

db_foreach subsite_admin_urls {
    select site_node.url(node_id) || 'admin/' as subsite_admin_url, 
           instance_name
    from site_nodes s, apm_packages p
    where s.object_id = p.package_id
    and p.package_key = 'acs-subsite'
} { 
    lappend subsite_admin_list "<a href=\"$subsite_admin_url\">$instance_name Administration</a>"
} if_no_rows {
    set subsite_admin_widget "No subsites are available on this system."
}

if {! [exists_and_not_null subsite_admin_widget] } {
    set subsite_admin_widget "
<h3>Subsite Administration</h3>
<ul>"
    foreach url $subsite_admin_list {
	append subsite_admin_widget "\n    <li>$url</li><p>"
    }
    append subsite_admin_widget "
</ul>\n"
}

set package_admin_widget "<h3>Package Administration</h3> <ul>"
set packages_to_admin_p 0
db_foreach installed_packages {
    select package_key,
           pretty_name as package_pretty_name
    from apm_package_types
} {
    if { [apm_package_installed_p $package_key] && [file exists "[acs_package_root_dir $package_key]/www/sw-admin/"] } {
        append package_admin_widget "<li><a href=\"package/$package_key/\">$package_pretty_name</a></li>"
        set packages_to_admin_p 1
    }
} 
if { ! $packages_to_admin_p } {
    append package_admin_widget "<i>No packages installed with site-wide administration UI</i>"
}
append package_admin_widget "</ul>"

append page "
$subsite_admin_widget

<p>
$package_admin_widget

<p>
[ad_admin_footer]
"

ns_return 200 text/html $page
