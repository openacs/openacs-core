ad_page_contract {
    Views dependency information about a version.
    @author Jon Salz [jsalz@arsdigita.com]
    @creation-date 17 April 2000
    @cvs-id $Id$
} {
    {version_id:integer}
}

db_1row  apm_package_info_by_version_id {
    select package_key, pretty_name, version_name, installed_p 
    from apm_package_version_info 
    where version_id = :version_id
}

doc_body_append "[apm_header [list "version-view?version_id=$version_id" "$pretty_name $version_name"] "Dependencies"]

"

foreach dependency_type { provide require } {
    set other_dependency_type [ad_decode $dependency_type "provide" "require" "provide"]
    doc_body_append "<h3>Services [string totitle $dependency_type]d</h3><ul>\n"

    set dependency_type_prep "${dependency_type}s"
    db_foreach apm_all_dependencies {
	select dependency_id, service_uri, service_version
	from   apm_package_dependencies
	where  version_id = :version_id
	and    dependency_type = :dependency_type_prep
	order by service_uri
    } {
	doc_body_append "<li>[string totitle $dependency_type]s service $service_uri, version $service_version (<a href=\"version-dependency-remove?[export_url_vars dependency_id version_id dependency_type]\">remove</a>)\n"
	
	# If this package provides a service, show a list of all packages that require it,
	# or vice versa. If this package provides a service, show other packages requiring
	# a *lower* version of the service; if it requires one, show packages providing
	# a *higher* version.

	set sign [ad_decode $dependency_type "provide" "<=" ">="]

	set counter 0
	set other_dependency_type_prep "${other_dependency_type}s"
	db_foreach apm_specific_version_dependencies "
select t.pretty_name dep_pretty_name, v.version_name dep_version_name, v.version_id dep_version_id
from apm_package_versions v, apm_package_dependencies d, apm_package_types t
where d.service_uri = :service_uri
and d.dependency_type = :other_dependency_type_prep
and d.version_id = v.version_id
and t.package_key = v.package_key 
and apm_package_version.sortable_version_name(d.service_version) $sign apm_package_version.sortable_version_name(:service_version)" {
	    incr counter
	    if { $counter == 1 } {
		doc_body_append "<ul>\n"
	    }
	    doc_body_append "<li>[string totitle $other_dependency_type]d by <a href=\"version-view?version_id=$dep_version_id\">$dep_pretty_name, version $dep_version_name</a>\n"
	}
	if { $counter != 0 } {
	    doc_body_append "</ul>\n"
	}	
    } else {
	doc_body_append "<li>This package does not $dependency_type any services.\n"
    }
    if { $installed_p == "t" } {
	doc_body_append "<li><a href=\"version-dependency-add?[export_url_vars version_id dependency_type]\">Add a service ${dependency_type}d by this package</a>\n"
    }
    doc_body_append "</ul>\n"
}

db_release_unused_handles
doc_body_append "
</ul>
[ad_footer]
"

