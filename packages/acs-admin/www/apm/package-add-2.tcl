ad_page_contract {
    Adds a package to the package manager.
    
    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date 17 April 2000
    @cvs-id $Id$
} {
    package_key
    pretty_name
    pretty_plural
    { package_type "apm_application"}
    { initial_install_p "f" }
    { singleton_p "f" }
    { auto_mount "" }
    package_uri
    version_name
    version_uri
    summary
    description:html
    description_format
    package_id:naturalnum
    version_id:naturalnum
    { owner_name:multiple }
    { owner_uri:multiple}
    { vendor [db_null] } 
    { vendor_uri [db_null] }
    { install_p 0 }
} -validate {
    package_key_format -requires {package_key} {
	if { [regexp {[^a-z0-9-]} $package_key] } {
	    ad_complain
	}
    }
    package_key_unique -requires {package_key} {
	if {[apm_package_registered_p $package_key] } {
	    ad_complain "The package key, <tt>$package_key</tt>, you have requested 
is already registerd to another package."
	}
    }

    pretty_plural_unique -requires {pretty_plural} {
	if {[db_string apm_pretty_plural_unique_ck {
	    select decode(count(*), 0, 0, 1) from apm_package_types 
	    where pretty_plural = :pretty_plural
	} -default 0]} {
	    ad_complain "A package with the pretty plural of $pretty_plural already exists."
	}
    }

    package_name_unique -requires {pretty_name} {
	if { [db_string apm_name_unique_ck {
	    select decode(count(*), 0, 0, 1) from apm_package_types 
	    where pretty_name = :pretty_name
	} -default 0] } {
	    ad_complain "A package with the name <strong>$pretty_name</strong> already exists."
	}
    }

    package_uri_unique -requires {package_uri} {
	if { [db_string apm_uri_unique_ck {
	    select decode(count(*), 0, 0, 1) from apm_package_types 
	    where package_uri = :package_uri
	} -default 0] } {
	    ad_complain "A package with the URL $package_uri already exists."
	}
    }

    version_uri_unique -requires {version_uri} {
	if { [db_string apm_version_uri_unique_ck {
	    select decode(count(*), 0, 0, 1) from apm_package_versions 
	    where version_uri = :version_uri
	} -default 0] } {
	    ad_complain "A version with the URL $version_uri already exists."
	}
    }

    version_name_ck -requires {version_uri} {	
	if {![regexp {^[0-9]+((\.[0-9]+)+((d|a|b|)[0-9]?)?)$} $version_name match]} {
	    ad_complain
	} 
    }

} -errors {
    package_key {You must provide a package key to identify your package.}
    pretty_name {You must provide a name for your package.}
    package_uri {You must indicate a unique URI for your package.}
    version_name {You must provide a version number for your package.}
    version_name_ck {The version name must fit this format: <strong>major number</strong>.<strong>minor number</strong> with an optional suffix of <strong>d</strong> for development, <strong>a</strong> for alpha, or <strong>b</strong> for beta.}
    version_uri {You must provide a unique URI for this version of your package.}
    summary {Please summarize your package so that users can determine what it is for.}
    description {Please provide a description of your package so that users can consider using it.}
    descrption_format {Please indicate if your package is HTML or text.}    
    package_key_format {The package key should contain only letters, numbers, and hyphens (dashes) and it must be lowercase.}
    package_id {You must provide an integer key for your package.}
    version_id {You must provide an integer key for your package version.}
}

db_transaction {
    # Register the package.
    apm_package_register $package_key $pretty_name $pretty_plural $package_uri \
	    $package_type $initial_install_p $singleton_p
    # Insert the version
    set version_id [apm_package_install_version -callback apm_dummy_callback -version_id \
	    $version_id $package_key $version_name $version_uri $summary $description \
	    $description_format $vendor $vendor_uri $auto_mount]
    apm_version_enable -callback apm_dummy_callback $version_id
    apm_package_install_owners -callback apm_dummy_callback \
	    [apm_package_install_owners_prepare $owner_name $owner_uri] $version_id

    if { $install_p } {
	if {[catch {
	    apm_package_install_spec $version_id
	} errmsg]} {
	    ad_return_error "Filesystem Error" "
	    I was unable to create your package for the following reason:
	    <blockquote><pre>[ns_quotehtml $errmsg]</pre></blockquote>"
	}
    }
} on_error {
    if {[db_string apm_package_add_doubleclick {
	select decode(count(*), 0, 0, 1) from apm_package_versions
	where version_id = :version_id
    } -default 0]} {
	ad_returnredirect "version-view?version_id=$version_id"
	ad_script_abort
    }
    ad_return_error "Database Error" "
    I was unable to create your package for the following reason:

    <blockquote><pre>[ns_quotehtml $errmsg]</pre></blockquote>
    "
    ad_script_abort
}

db_release_unused_handles
ad_returnredirect "version-view?version_id=$version_id"
