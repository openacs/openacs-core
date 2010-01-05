ad_page_contract {
    Adds a dependency to a version of a package.
    @author Jon Salz [jsalz@arsdigita.com]
    @creation-date 17 April 2000
    @cvs-id $Id$
} {
    {version_id:integer}
    dependency_type
}

db_1row apm_package_info_by_version_id_and_package {}

set dependency_id [db_nextval acs_object_id_seq] 

doc_body_append "[apm_header -form "action=version-dependency-add-2" [list "version-view?version_id=$version_id" "$pretty_name $version_name"] [list "version-dependencies?version_id=$version_id" "Dependencies"] "Add a Dependency"]

[export_vars -form {version_id dependency_type dependency_id {our_package_key $package_key}}]

$pretty_name ${dependency_type}s the following service:
<p>
<select name=service size=8>
"

db_foreach apm_packages {} {
    doc_body_append "<option value=\"$package_key;$version_name\">$package_key, version $version_name\n"
}


db_release_unused_handles

doc_body_append "</select>
<br>
<input type=submit value=\"Add Dependency\">

[ad_footer]
"

