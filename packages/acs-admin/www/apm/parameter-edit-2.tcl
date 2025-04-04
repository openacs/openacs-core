ad_page_contract {
    Adds a parameter to a version.
    @author Todd Nightingale (tnight@arsdigita.com)
    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date 10 September 2000
    @cvs-id $Id$
} {
    version_id:naturalnum,notnull
    parameter_id:naturalnum,notnull
    package_key:token,notnull
    parameter_name:notnull
    section_name
    description:notnull,nohtml
    datatype:notnull
    {default_value:allhtml ""}
    {min_n_values:integer 1}
    {max_n_values:integer 1}
    {update_info_file:boolean,notnull true}
} -validate {
    datatype_type_ck {
        if {$datatype ne "number" && $datatype ne "string" && $datatype ne "text"} {
            ad_complain
        }
    }
} -errors {
    datatype_type_ck {The datatype must be either a number or a string or text.}
}

db_transaction {
    ns_log Debug "APM: Updating Parameter: $parameter_id, $parameter_name $description, $package_key, $default_value, $datatype, $section_name, $min_n_values, $max_n_values"


    apm_parameter_update $parameter_id $package_key $parameter_name $description \
        $default_value $datatype $section_name $min_n_values $max_n_values

    if {$update_info_file} {
        apm_package_install_spec $version_id
    }
} on_error {
    ad_return_error "Database Error" "The parameter could not be updated.
The database returned the following error:<p>
 <blockquote><pre>[ns_quotehtml $errmsg]</pre></blockquote>"
    ad_script_abort
}

ad_returnredirect [export_vars -base "version-parameters" { version_id section_name }]
ad_script_abort

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
