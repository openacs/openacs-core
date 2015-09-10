ad_page_contract {
    Parameters page.
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-13
    @cvs-id $Id$
} {
    {package_id:naturalnum "[ad_conn package_id]"}
    package_key:optional
    {scope "instance"}
    {return_url:optional "[ad_conn url]?[ad_conn query]"}
    {section ""}
}

if { $scope eq "global" } {
    permission::require_permission \
        -object_id [acs_lookup_magic_object security_context_root] \
        -privilege admin
    db_1row select_pretty_name {}

    set page_title "$instance_name Global Parameters"
    set package_url [site_node::get_url_from_object_id -object_id $package_id]

    if { $package_url eq [subsite::get_element -element url] } {
        set context [list [list "${package_url}admin/" "Administration"] $page_title]
    } elseif { $package_url ne "" } {
        set context [list [list $package_url $instance_name] [list "${package_url}admin/" "Administration"] $page_title]
    } else {
        set context [list $page_title]
    }

} else {
    permission::require_permission -object_id $package_id -privilege admin
    db_1row select_instance_name {}

    set page_title "$instance_name Instance Parameters"
    set package_url [site_node::get_url_from_object_id -object_id $package_id]
}

if { $package_url eq [subsite::get_element -element url] } {
    set context [list [list "${package_url}admin/" "Administration"] $page_title]
} elseif { $package_url ne "" } {
    set context [list [list $package_url $instance_name] [list "${package_url}admin/" "Administration"] $page_title]
} else {
    set context [list $page_title]
}

if { $scope ne "global" } {

    if {![info exists package_key] || $package_key eq ""} {
	set package_key [apm_package_key_from_id $package_id]
    }
    set global_parameters [db_list get_global_parameters {
	select parameter_name from apm_parameters where package_key = :package_key and scope = 'global'
    }] 
    if {[llength $global_parameters] > 0} {
	#
	# Just provide a link to the global parameters in case these exist
	#
	set global_parameter_label [join [lsort $global_parameters] ", "]
	set global_param_url [export_vars -base /shared/parameters {package_key return_url package_id {scope global}}]
    }
}

ad_form -name parameters -export {section} -cancel_url $return_url -form {
    {return_url:text(hidden)}
    {scope:text(hidden)}
    {package_id:integer(hidden),optional}
    {package_key:text(hidden),optional}
}

set display_warning_p 0
set counter 0
set focus_elm {}
if {$section ne ""} {
    set section_where_clause [db_map section_where_clause]
} else {
    set section_where_clause ""
}


array set sections {}

db_foreach select_params {} {
    if { $section_name eq "" } {
        set section_name "main"
        set section_pretty "Main"
    } else {
        set section_name [string map {- {_} " " {_}} $section_name]
        set section_pretty [string map {_ { }} $section_name]
        set section_pretty "[string toupper [string index $section_pretty 0]][string range $section_pretty 1 end]"
    }
    
    if { ![info exists sections($section_name)] } {
        set sec [list "-section" $section_name {legendtext "$section_pretty"}]
        ad_form -extend -name parameters -form [list $sec]
        set sections($section_name) "$section_pretty"
    }

    if { $counter == 0 } {
        set focus_elm $parameter_name
    }

    switch $datatype {
        text {
            set widget textarea
            set html [list cols 100 rows 15]
        }
        default {
            set widget text
            set html [list size 50]
        }
    }
    set elm [list ${parameter_name}:text($widget),optional,nospell \
                 {label {$parameter_name}} \
                 {help_text {$description}} \
                 [list html $html]]

    set file_val [ad_parameter_from_file $parameter_name $package_key]
    if { $file_val ne "" } { 
        set display_warning_p 1 
        lappend elm [list after_html "<br><span style=\"color: red; font-weight: bold;\">$file_val (*)</span>"]
    }
    
    ad_form -extend -name parameters -form [list $elm]

    set param($parameter_name) $attr_value
    
    incr counter
}

set focus "parameters.$focus_elm"

if { $counter > 0 } {
    # Close last section
    ad_form -extend -name parameters -form [list "-section"]
    ad_form -extend -name parameters -on_request {
        foreach name [array names param] {
            set $name $param($name)
        }
    } -on_submit {
        db_foreach select_params_set {} {
            if { [info exists $c__parameter_name] } {
                if { $scope eq "instance" } {
                    parameter::set_value \
	                -package_id $package_id \
	                -parameter $c__parameter_name \
	                -value [set $c__parameter_name]
                    callback subsite::parameter_changed -package_id $package_id -parameter $c__parameter_name -value [set $c__parameter_name]
                } else {
                    parameter::set_global_value \
                        -package_key $package_key \
                        -parameter $c__parameter_name \
                        -value [set $c__parameter_name]
                    callback subsite::global_parameter_changed -package_key $package_key -parameter $c__parameter_name -value [set $c__parameter_name]
                }
            }
        }
    } -after_submit {
        ad_returnredirect $return_url
        ad_script_abort
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
