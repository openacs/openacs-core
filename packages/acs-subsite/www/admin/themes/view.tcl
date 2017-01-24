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

set page_title "View parameters of theme $theme"
set context [list $page_title]

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

db_1row get_vars_of_seleted_theme {select * from  subsite_themes where key = :theme}

set formSpec {}
foreach {var param} $settings {
    if {$var in {css js}} {
        set currentSpec [list ${var}:text(textarea),nospell,optional [list label $var] [list html {rows 5 cols 100 disabled disabled}]]
    } else {
        set currentSpec [list ${var}:text,optional [list label $var] [list html {size 50 disabled disabled}]]
    }
    
    if {$currentThemeKey eq $key} {
        set currentValue [string trim [parameter::get -parameter $param -package_id $subsite_id]]
        regsub -all {\r\n} $currentValue "\n" currentValue
        if {$currentValue ne [string trim [set $var]]} {
            lappend currentSpec [list help_text "differs"]
            ns_log notice "current value \n<$currentValue>\ndiffers from\n<[string trim [set $var]]>"
        }
    }
    lappend formSpec $currentSpec
}
lappend formSpec [list theme:text(hidden)]

#set return_url [export_vars -base view {theme}]
set return_url "."

ad_form -name theme \
    -cancel_url  $return_url \
    -mode display \
    -form $formSpec \
    -on_request {
        ns_log notice "on request"
    } -on_submit {
        ns_log notice "on submit"
    } -after_submit {
        ad_returnredirect $return_url
        ad_script_abort
    }

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
