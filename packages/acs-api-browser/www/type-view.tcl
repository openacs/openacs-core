ad_page_contract {

    Displays information about a type.

    @cvs-id $Id$

} {
    version_id:optional
    type
} -properties {
    title:onevalue
    context:onevalue
    documentation:onevalue
}

if { ![info exists version_id] && \
        [regexp {^([^ /]+)/} $type "" package_key] } {
    db_0or1row version_id_from_package_key {
        select version_id 
          from apm_enabled_package_versions 
         where package_key = :package_key
    }
}
 

set public_p [api_set_public $version_id]


set context [list]

if { [info exists version_id] } {
    db_1row package_info_from_version_id {
        select package_name, package_key, version_name
          from apm_package_version_info
         where version_id = :version_id
    }
    lappend context [list "package-view?version_id=$version_id&kind=types" "$package_name $version_name"]
}

lappend context $type

set title $type
set documentation [api_type_documentation $type]