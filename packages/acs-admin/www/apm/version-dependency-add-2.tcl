ad_page_contract {
    Adds a dependency to a version of a package. 
    @author Bryan Quinn
    @creation-date 17 April 2000
    @cvs-id $Id$
} {
    {dependency_id:naturalnum}
    {version_id:integer}
    dependency_type
    service:notnull
    our_package_key:notnull
}

set service [split $service ";"]
set package_key [lindex $service 0]
set version_name [lindex $service 1]

apm_package_install_spec $version_id

db_transaction {
    switch $dependency_type {
	require {
	    apm_dependency_add -dependency_id $dependency_id ${dependency_type}s $version_id $package_key $version_name
            apm_build_one_package_relationships $our_package_key
	}

        extend {
	    apm_dependency_add -dependency_id $dependency_id ${dependency_type}s $version_id $package_key $version_name
            apm_build_one_package_relationships $our_package_key
            apm_copy_inherited_params $our_package_key [list $package_key $version_name]
	}

        embed {
	    apm_dependency_add -dependency_id $dependency_id ${dependency_type}s $version_id $package_key $version_name
            apm_build_one_package_relationships $our_package_key
            apm_copy_inherited_params $our_package_key [list $package_key $version_name]
	}

	default {
	    ad_return_complaint 1 "Entry error: Allowable dependencies are required, extends and embeds."
	}
    }
} on_error {
    if { ![db_string apm_dependency_doubleclick_check {
	select count(*) from apm_package_dependencies
	where dependency_id = :dependency_id
    } -default 0] } {
	ad_return_complaint 1 "The database returned the following error:
	<blockquote><pre>[ad_quotehtml $errmsg]</pre></blockquote>"
    }
}

ad_returnredirect "version-dependencies?[export_url_vars version_id]"
