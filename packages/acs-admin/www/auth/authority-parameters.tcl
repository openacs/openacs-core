ad_page_contract {
    Set parameters for the service contract implementation of an authority
    (for example authentication or password management).

    @author Peter Marklund
} {
    authority_id:naturalnum,notnull
}

auth::authority::get -authority_id $authority_id -array authority

set page_title "Configure"
set authority_url [export_vars -base authority { authority_id }]
set context [list [list "." "Authentication"] [list $authority_url $authority(pretty_name)] $page_title]


# Get the implementation id and implementation pretty name
array set parameters [list]
array set parameter_values [list]

# Each element is a list of impl_ids which have this parameter
array set param_impls [list]

foreach element_name [auth::authority::get_sc_impl_columns] {
    set name_column $element_name
    regsub {^.*(_id)$} $element_name {_name} name_column

    set impl_params [auth::driver::get_parameters -impl_id $authority($element_name)]
    
    foreach { param_name dummy } $impl_params {
        lappend param_impls($param_name) $authority($element_name)
    }

    array set parameters $impl_params

    array set parameter_values [auth::driver::get_parameter_values \
                                    -authority_id $authority_id \
                                    -impl_id $authority($element_name)]
    
}

set has_parameters_p [expr {[array size parameters] > 0}]

set first_param_name ""
if { $has_parameters_p } {

    # Set focus on first param name
    set first_param_name [lindex [array names parameters] 0]

    set form_widgets [list]
    foreach parameter_name [array names parameters] {
        lappend form_widgets [list ${parameter_name}:text,optional [list label $parameter_name] [list help_text $parameters($parameter_name)] {html {size 80}}]
    }

    set hidden_vars {authority_id}

    ad_form -name parameters \
        -cancel_url $authority_url \
        -form $form_widgets \
        -export $hidden_vars \
        -on_request {

            foreach parameter_name [array names parameter_values] {
                set $parameter_name $parameter_values($parameter_name)
            }

        } -on_submit {
            
            foreach element_name [template::form::get_elements -no_api parameters] {

                # Make sure we have a parameter element
                if { [info exists param_impls($element_name)] } {
                    foreach impl_id $param_impls($element_name) {
                        auth::driver::set_parameter_value \
                            -authority_id $authority_id \
                            -impl_id $impl_id \
                            -parameter $element_name \
                            -value [element get_value parameters $element_name]
                    }
                }
            }
            
            ad_returnredirect $authority_url
            ad_script_abort
        }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
