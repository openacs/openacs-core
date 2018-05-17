ad_page_contract {
    View (and maybe edit) theme parameters
    
    @author Gustaf Neumann
    @creation-date 2017-01-21
} {
    {theme:word,trim}
} -validate {
    theme_valid -requires theme {
	if {![db_string check_exists_theme {
	    select 1 from subsite_themes where key = :theme
	} -default 0]} {
	    ad_complain "Theme with key '$theme' does not exist" 
	}
    }
}

set subsite_id [ad_conn subsite_id]
set instance_name [apm_instance_name_from_id $subsite_id]

set settings {
    template             DefaultMaster
    css                  ThemeCSS
    js                   ThemeJS
    form_template        DefaultFormStyle
    list_template        DefaultListStyle
    list_filter_template DefaultListFilterStyle
    dimensional_template DefaultDimensionalStyle
    resource_dir         ResourceDir
    streaming_head       StreamingHead
}

set subsite_id [ad_conn subsite_id]
set currentThemeKey [parameter::get -parameter ThemeKey -package_id $subsite_id]

#
# Get the default values for the theme from the DB
#
db_1row get_vars_of_selected_theme {select * from  subsite_themes where key = :theme}

#
# Default edit buttons
#
set editButtons {{" Save Parameters " save}}
if {$local_p} {
    #
    # When the local_p flag is set, allow one to overwrite the theme
    # defaults.
    #
    lappend editButtons {" Overwrite Theme Defaults and Save Parameters " overwrite}
}
set page_title "Edit Theme Parameters of Subsite: $instance_name"
set context [list {. #acs-subsite.Themes#} $page_title]

set nr_differs 0
set formSpec {}
set htmlSpecs ""
foreach {var param} $settings {
    if {$var in {css js}} {
        lappend htmlSpecs rows 5 cols 100
        set currentSpec [list ${var}:text(textarea),nospell,optional [list label $param] [list html $htmlSpecs]]
    } else {
        lappend htmlSpecs size 80
        set currentSpec [list ${var}:text,optional [list label $param] [list html $htmlSpecs]]
    }
    
    if {$currentThemeKey eq $key} {
        set currentValue [string trim [parameter::get -parameter $param -package_id $subsite_id]]
        regsub -all {\r\n} $currentValue "\n" currentValue
        set value [string trim [set $var]]
        regsub -all {\r\n} $value "\n" value
        if {$currentValue ne $value} {
            lappend currentSpec [list help_text "differs"]
            ns_log notice "current value \n<$currentValue>\ndiffers from\n<$value>"
            incr nr_differs
        }
        #
        # set the variable in the form to the value obtained from the parameters
        #
        set $var $currentValue
    }
    lappend formSpec $currentSpec
}
lappend formSpec [list theme:text(hidden)]

if {$nr_differs > 0} {
    set sub_title "Subsite uses modified theme parameters based on $theme"
} else {
    set sub_title "Subsite uses theme parameters of $theme"
}

#set return_url [export_vars -base view {theme}]
set return_url "."
ad_form -name theme \
    -cancel_url $return_url \
    -edit_buttons $editButtons \
    -form $formSpec \
    -on_request {
        #ns_log notice "on request"
        
    } -on_submit {
        
        if {[ns_queryget formbutton:save] ne "" || [ns_queryget formbutton:overwrite] ne ""} {
            #ns_log notice "edit theme ====== SAVE form values in actual parameter settings"
            foreach {var param} $settings {
                parameter::set_value -parameter $param -package_id $subsite_id -value [set $var]
            }
        }
        if {[ns_queryget formbutton:overwrite] ne ""} {
            #ns_log notice "edit theme ====== OVERWRITE form values in theme defaults"

            set params {}
            foreach {var param} $settings {
                lappend params -$var [set $var]
            }

            subsite::update_subsite_theme \
                -key      $theme \
                -name     $name \
                -local_p  true \
                {*}$params
        }
        
    } -after_submit {
        ad_returnredirect $return_url
        ad_script_abort
    }

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
