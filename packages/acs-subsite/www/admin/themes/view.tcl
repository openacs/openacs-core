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

#ns_log notice currentThemeKey=$currentThemeKey
#ns_log notice ACTION=[template::form get_action theme]-[ns_set array [ns_getform]]

db_1row get_vars_of_seleted_theme {select * from  subsite_themes where key = :theme}

#
# Since the standard display mode does not produce good results in our
# case, we try to implement our own management here. Probably, the
# display mode of textarea should be fixed to reduce complexity here.
#
if {1 || [ns_queryget formbutton:edit] ne ""} {
    set htmlSpecs ""
    #ns_log notice "true edit mode"
    set editMode 1
    set editButtons [list [list " Save " save] ]
    set page_title "Edit Theme Parameters of Subsite: $instance_name"
    #
    # Since we are doing our own display/edit modes, we have to tell
    # ad_form, that this request should be treated like a fresh
    # request.
    #
    #ns_set truncate [ns_getform] 0
} else {
    set htmlSpecs [list disabled disabled]
    #ns_log notice "view mode"
    set editMode 0
    set editButtons [list [list Edit edit] ]
    set page_title "View Theme Parameters of Subsite: $instance_name"
}

set context [list {. #acs-subsite.Themes#} $page_title]



set nr_differs 0
set formSpec {}
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
        if {$currentValue ne [string trim [set $var]]} {
            lappend currentSpec [list help_text "differs"]
            #ns_log notice "current value \n<$currentValue>\ndiffers from\n<[string trim [set $var]]>"
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
        #ns_log notice "on submit ====== SAVE?"
        if {[ns_queryget formbutton:save] ne ""} {
            ns_log notice "edit theme ====== SAVE form values in actual parameter settings"
            foreach {var param} $settings {
                parameter::set_value -parameter $param -package_id $subsite_id -value [set $var]
            }
        }
            
    } -after_submit {
        if {1 || !$editMode} {
            ad_returnredirect $return_url
            ad_script_abort
        }
    }

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
