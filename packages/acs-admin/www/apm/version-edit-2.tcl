ad_page_contract {
    Edit a package version
    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date 17 April 2000
    @cvs-id $Id$

} {
    version_id:naturalnum,notnull
    version_name
    version_uri
    summary
    description:html
    {description_format ""}
    { owner_name:multiple}
    { owner_uri:multiple}
    vendor
    vendor_uri
    {auto_mount ""}
    {release_date ""}
    { upgrade_p 0 }
}

# Validate dynamic package version attributes
# Also put all dynamic attributes in an array
array set all_attributes [apm::package_version::attributes::get_spec]
foreach attribute_name [array names all_attributes] {
    array set attribute $all_attributes($attribute_name)

    set attribute_value [ns_set iget [rp_getform] $attribute_name]

    if { [info exists attribute(validation_proc)] } {
        set attribute_error [eval $attribute(validation_proc) $attribute_value]

        if { ![empty_string_p $attribute_error] } {
            ad_return_complaint 1 $attribute_error
        }
    }
        
    set dynamic_attributes($attribute_name) $attribute_value
}

if {![regexp {^[0-9]+((\.[0-9]+)+((d|a|b|)[0-9]*)?)$} $version_name match]} {
    ad_return_complaint 1 "The version name has invalid characters"
    ad_script_abort
} 

# Figure out if we're changing version
db_1row old_version_info {}
set version_changed_p [expr ![string equal $version_name $old_version_name]]

if { [string equal $old_version_name $version_name] } {
    # The version name didn't change, so don't attempt to upgrade
    set upgrade_p 0
}

# The user has to update the URL if he changes the name.
if { $version_changed_p && [string equal $version_uri $old_version_uri] } {
    ad_return_complaint 1 {You have changed the version number but not the version URL. When creating
        a package for a new version, you must select a new URL for the version.}
}

if { $upgrade_p && [db_string apm_version_uri_unique_ck {
    select decode(count(*), 0, 0, 1) from apm_package_versions 
    where version_uri = :version_uri
} -default 0] } {
    ad_return_complaint 1 "A version with the URL $version_uri already exists."
}

db_transaction {
    set version_id [apm_version_update -array dynamic_attributes $version_id $version_name $version_uri \
	    $summary $description $description_format $vendor $vendor_uri $auto_mount $release_date]
    apm_package_install_owners [apm_package_install_owners_prepare $owner_name $owner_uri] $version_id
    apm_package_install_spec $version_id
    if {$upgrade_p} {
	apm_version_upgrade $version_id

        # The package now provides the new version of itself as interface
        db_dml update_version_provides {update apm_package_dependencies
                                    set service_version = :version_name
                                    where version_id = :version_id
                                    and service_uri = (select package_key
                                                       from apm_package_versions
                                                       where version_id = :version_id)
                                    and dependency_type = 'provides'}
    }
} on_error {
    ad_return_error "Error" "
I was unable to update your version for the following reason:

<blockquote><pre>[ns_quotehtml $errmsg]</pre></blockquote>
"
}

ad_returnredirect "version-generate-info?version_id=$version_id&write_p=1"
