ad_page_contract {
    Adds a dependency to a version of a package.
    @author Jon Salz [jsalz@arsdigita.com]
    @creation-date 17 April 2000
    @cvs-id $Id$
} {
    {version_id:naturalnum,notnull}
    dependency_type
}

db_1row apm_package_info_by_version_id_and_package {}

set dependency_id [db_nextval acs_object_id_seq] 

set title "Add a Dependency"
set context [list \
		 [list "/acs-admin/apm/" "Package Manager"] \
		 [list "version-view?version_id=$version_id" "$pretty_name $version_name"] \
		 [list "version-dependencies?version_id=$version_id" "Dependencies"] \
		 $title]

set body [subst {
    <form action='version-dependency-add-2' method='post'>
    [export_vars -form {version_id dependency_type dependency_id {our_package_key $package_key}}]

    <p>$pretty_name ${dependency_type}s the following service:
    <p>
    <select name="service" size="20">
}]

db_foreach apm_packages {} {
    append body [subst {
	<option value="$package_key;$version_name">$package_key, version $version_name
    }]
}

append body [subst {
    </select>
    <br>
    <input type="submit" value="Add Dependency">
    </form>
}]

ad_return_template apm

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
