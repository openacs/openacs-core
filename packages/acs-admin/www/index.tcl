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

[ad_conn instance_name] is used to administer the site-wide services of the ArsDigita Community System.

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
To administer a particular subsite, please select from the list below.
<ul>"
    foreach url $subsite_admin_list {
	append subsite_admin_widget "\n    <li>$url</li><p>"
    }
    append subsite_admin_widget "
</ul>\n"
}

append page "
$subsite_admin_widget
<p>
[ad_admin_footer]
"

ns_return 200 text/html $page
