ad_page_contract { 
    Generates a package spec.

    @param version_id The package to be processed.
    @param write_p Set to 1 if you want the specification file written to disk.
    @author Jon Salz [jsalz@arsdigita.com]
    @creation-date 9 May 2000
    @cvs-id $Id$
} {
    {version_id:integer}
    {write_p 0}
}

if { $write_p } {
    if { [catch { apm_package_install_spec $version_id } error] } {
	ad_return_error "Error" "Unable to create the specification file:
<blockquote><pre>$error</pre></blockquote>
"
        return
    }

    ad_returnredirect "version-view?version_id=$version_id"
    ad_script_abort
} else {
    ns_return 200 text/plain [apm_generate_package_spec $version_id]
}


