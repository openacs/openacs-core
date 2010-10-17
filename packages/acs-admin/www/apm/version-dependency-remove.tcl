ad_page_contract {
    Adds a dependency to a version of a package. 
    @author Jon Salz (jsalz@arsdigita.com)
    @creation-date 17 April 2000
    @cvs-id $Id$
} {
    {version_id:integer}
    {dependency_id:integer}
    dependency_type:notnull
    package_key:notnull
}

db_transaction {
    switch $dependency_type {

	provide - require {
	    apm_dependency_remove $dependency_id
        }
        embed - extend {
            apm_unregister_disinherited_params $package_key $dependency_id
	    apm_dependency_remove $dependency_id
            apm_build_one_package_relationships $package_key
	}

	default {
	    ad_return complaint 1 "Dependency Entry Error: Depenendencies are either interfaces or requirements."
	}
    }
    apm_package_install_spec $version_id
} on_error {
    ad_return_complaint 1 "Database Error: The database returned the following error:
	<blockquote><pre>[ad_quotehtml $errmsg]</pre></blockquote>"
}

ad_returnredirect "version-dependencies?[export_url_vars version_id]"

