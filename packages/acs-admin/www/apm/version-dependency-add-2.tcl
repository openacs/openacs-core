ad_page_contract {
    Adds a dependency to a version of a package. 
    @author Bryan Quinn
    @creation-date 17 April 2000
    @cvs-id $Id$
} {
    {dependency_id:naturalnum}
    {version_id:integer}
    dependency_type
    service_uri
    service_version
}

db_transaction {
    switch $dependency_type {
	require {
	    apm_dependency_add -dependency_id $dependency_id $version_id $service_uri $service_version
	}

	provide {
	    apm_interface_add -interface_id $dependency_id $version_id $service_uri $service_version
	}

	default {
	    ad_return_complaint 1 "Entry error: Depenendencies are either provided or required."
	}
    }
    apm_package_install_spec $version_id
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
