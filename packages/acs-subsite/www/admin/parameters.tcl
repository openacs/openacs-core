ad_page_contract {
    Parameters page.
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-13
    @cvs-id $Id$
}

set page_title "Parameters"

set context [list $page_title]

set package_id [ad_conn subsite_id]

ad_require_permission $package_id admin

db_foreach select_params {} {
    if { [empty_string_p $section_name] } {
        set section_name "Main"
    } else {
        set section_name [string map {_ { } - { }} $section_name]
        set section_name "[string toupper [string index $section_name 0]][string range $section_name 1 end]"
    }
    lappend form [list ${parameter_name}:text,optional [list label $parameter_name] [list help_text $description] [list section $section_name] {html {size 50}}]
    set param($parameter_name) $attr_value
}

ad_form -name parameters -cancel_url [ad_conn url] -form $form -on_request {
    foreach name [array names param] {
        set $name $param($name)
    }
} -on_submit {
    db_foreach select_params_set {} {
	if { [info exists $c__parameter_name]} {
	    parameter::set_value \
                -package_id $package_id \
                -parameter $c__parameter_name \
                -value [set $c__parameter_name]
	}
    }
}
