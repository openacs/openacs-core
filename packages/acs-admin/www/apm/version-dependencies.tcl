ad_page_contract {
    Views dependency information about a version.
    @author Jon Salz [jsalz@arsdigita.com]
    @creation-date 17 April 2000
    @cvs-id $Id$
} {
    {version_id:integer}
}

db_1row apm_package_info_by_version_id {}

set title "Dependencies"
set context [list \
		 [list "/acs-admin/apm/" "Package Manager"] \
		 [list "version-view?version_id=$version_id" "$pretty_name $version_name"] \
		 $title]
set body ""

foreach dependency_type { provide require extend embed } {

    set dependency_type_prep "${dependency_type}s"
    if { [string index $dependency_type end] eq "e" } {
        set dependency_type_prep_2 ${dependency_type}d
    } else {
        set dependency_type_prep_2 ${dependency_type}ed
    }
    append body "<h3>Services [string totitle $dependency_type_prep_2]</h3><ul>\n"

    db_foreach apm_all_dependencies {} {
	append body "<li>[string totitle $dependency_type_prep] service $service_uri, version $service_version "
	
        if { $dependency_type ne "provide" } {
	    set qvars [export_vars -url {package_key dependency_id version_id dependency_type}]
            append body "(<a href=\"version-dependency-remove?$qvars\">remove</a>)\n"
        }
	
	# If this package provides a service, show a list of all packages that require it,
	# or vice versa. If this package provides a service, show other packages requiring
	# a *lower* version of the service; if it requires one, show packages providing
	# a *higher* version.

	set sign [ad_decode $dependency_type "provide" "<=" ">="]

	set counter 0
        set other_dependency_in [ad_decode $dependency_type "provide" "'requires','extends','embeds'" "'provides'"]
	db_foreach apm_specific_version_dependencies {} {
            incr counter
	    if { $counter == 1 } {
		append body "<ul>\n"
	    }
            switch $dep_type {
                provides { set dep_d provided }
                requires { set dep_d required }
                extends { set dep_d extended }
                embeds { set dep_d embeds }
            } 
	    append body [subst {
		<li>[string totitle $dep_d] by <a href="version-view?version_id=$dep_version_id">$dep_pretty_name, 
		version $dep_version_name</a>
	    }]
	}
	if { $counter != 0 } {
	    append body "</ul>\n"
	}
    } else {
	append body "<li>This package does not $dependency_type any services.\n"
    }
    if { $installed_p eq "t" && $dependency_type ne "provide"} {
	append body [subst {
	    <li><a href="version-dependency-add?[export_vars -url {version_id dependency_type}]">Add a 
	    service $dependency_type_prep_2 by this package</a>
	}]
    }
    append body "</ul>\n"
}

append body "</ul>\n"

ad_return_template apm

