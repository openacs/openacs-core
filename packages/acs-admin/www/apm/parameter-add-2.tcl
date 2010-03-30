ad_page_contract {
    Adds a parameter to a version.
    @author Todd Nightingale (tnight@arsdigita.com)
    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date 10 September 2000
    @cvs-id $Id$
} {
    version_id:naturalnum,notnull
    parameter_id:naturalnum,notnull
    package_key:notnull
    parameter_name:notnull
    section_name
    description:notnull,nohtml
    datatype:notnull
    scope:notnull
    {default_value [db_null]}
    {min_n_values:integer 1}
    {max_n_values:integer 1}
} -validate {
    datatype_type_ck {
	if {$datatype != "number" && $datatype != "string" && $datatype != "text"} {
	    ad_complain
	}
    }
    param_name_unique_ck {
	if {[db_string param_name_unique_ck {
	    select decode(count(*), 0, 0, 1) 
	    from apm_parameters
	    where parameter_name = :parameter_name
            and package_key= :package_key
	}]} {
	    ad_complain "The parameter name $parameter_name already exists for this package"	    
	}
    }
} -errors {
    datatype_type_ck {The datatype must be either a number or a string or text.}
}

db_transaction {
    apm_parameter_register -parameter_id $parameter_id -scope $scope $parameter_name $description $package_key \
	$default_value $datatype $section_name $min_n_values $max_n_values
    apm_package_install_spec $version_id
} on_error {
    if {![db_string apm_parameter_register_doubleclick_p {
	select 1 from apm_parameters where parameter_id = :parameter_id
    } -default 0]} {
	ad_return_error "Database Error" "The database is complaining about the parameter you entered:<p>
<blockquote><pre>[ad_quotehtml $errmsg]</pre></blockquote>"
	ad_script_abort
    }
}

# LARS hack
set sections [lindex [lindex [apm_parameter_section_slider $package_key] 0] 3]
foreach section $sections {
    if {$section_name eq [lindex $section 1]} {
        set section_name [lindex $section 0]
        break
    }
}

ad_returnredirect [export_vars -base "version-parameters" { version_id section_name }]
