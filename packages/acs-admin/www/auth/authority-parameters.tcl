ad_page_contract {
    Set parameters for the service contract implementation of an authority
    (for example authentication or password management).

    @author Peter Marklund
} {
    authority_id:integer
    column_name
}

# Check the column name for validity
if { [lsearch [auth::authority::get_sc_impl_columns] $column_name] == -1 } {
    ad_return_error "Invalid column name" "The specified column name \"$column_name\" is invalid. Valid column names are: [auth::authority::get_sc_impl_columns]"
}

# Get the implementation id and implementation pretty name
db_1row select_impl_id "
    select a.$column_name as impl_id,
           sci.impl_pretty_name
    from auth_authorities a,
         acs_sc_impls sci
    where a.authority_id = :authority_id
      and a.$column_name = sci.impl_id
"

auth::authority::get -authority_id $authority_id -array authority

set page_title "Parameter settings for $impl_pretty_name"
set authority_url [export_vars -base authority { {authority_id $authority(authority_id)} }]
set context [list [list "." "Authentication"] [list $authority_url "$authority(pretty_name)"] $page_title]

# Get the parameters that can be configured
array set parameters [auth::driver::get_parameters -impl_id $impl_id]

set has_parameters_p [expr [llength [array names parameters]] > 0]

set first_param_name ""
if { $has_parameters_p } {

    # Set focus on first param name
    set first_param_name [lindex [array names parameters] 0]

    set form_widgets [list]
    foreach parameter_name [array names parameters] {
        lappend form_widgets [list ${parameter_name}:text,optional [list label $parameter_name] [list help_text $parameters($parameter_name)] {html {size 80}}]
    }

    set hidden_vars {authority_id impl_id column_name}

    ad_form -name parameters \
        -cancel_url $authority_url \
        -form $form_widgets \
        -export $hidden_vars \
        -on_request {

            array set parameter_values [auth::driver::get_parameter_values \
                                            -authority_id $authority_id \
                                            -impl_id $impl_id]

            foreach parameter_name [array names parameter_values] {
                set $parameter_name $parameter_values($parameter_name)
            }

        } -on_submit {
            
            foreach element_name [template::form::get_elements -no_api parameters] {

                # Make sure we have a parameter element
                if { [lsearch $hidden_vars $element_name] == -1 } {

                    auth::driver::set_parameter_value \
                        -authority_id $authority_id \
                        -impl_id $impl_id \
                        -parameter $element_name \
                        -value [element get_property parameters $element_name value]
                }
            }

            ad_returnredirect $authority_url
            ad_script_abort
        }
}
