ad_page_contract {
    Generates package specs for every enabled version.
    @author Jon Salz (jsalz@arsdigita.com)
    @creation-date 17 April 2000
    @cvs-id $Id$
} {
}

ad_return_top_of_page "[apm_header "Generate Package Specifications"]

Regenerating all package specifications for locally maintained packages.

<ul>
"

db_foreach apm_get_all_packages {
    select version_id, version_name, pretty_name, distribution_uri, v.package_key
    from   apm_package_versions v, apm_package_types t
    where  installed_p = 't'
    and v.package_key = t.package_key
    order by upper(pretty_name)
} {
    if { $distribution_uri eq "" } {
	ns_log Debug "Generating package specificaiton for $package_key"
	ns_write "<li>$pretty_name $version_name... "
	if { [catch { 
	    apm_package_install_spec $version_id 
	} error] } {
	    ns_write "error: $error\n"
	} else {
	    ns_write "done.\n"
	}
    } else {
	ns_write "<li>$pretty_name $version_name was not generated locally.\n"
    }
}

db_release_unused_handles
ns_write "</ul>

<a href=\"./\">Return to the Package Manager</a>

[ad_footer]"
