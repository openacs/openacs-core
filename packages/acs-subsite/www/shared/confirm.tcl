ad_page_contract {
    General confirmation script

    @author lars@pinds.com
    @creation-date 5 Jun 2000
    @cvs-id $Id$
} {
    { header "Confirm" } 
    message
    yes_url
    no_url 
    { yes_label "Yes, Proceed" }
    { no_label "No, Cancel" }
} -properties {
    export_vars_yes:onevalue
    export_vars_no:onevalue
    title:onevalue
    message:onevalue
    yes_path:onevalue
    yes_label:onevalue
    no_path:onevalue
    no_label:onevalue
}

set title $header

set yes_list [split $yes_url "?"]
set yes_path [lindex $yes_list 0]
set yes_args_set [ns_parsequery [lindex $yes_list 1]]

set no_list [split $no_url "?"]
set no_path [lindex $no_list 0]
set no_args_set [ns_parsequery [lindex $no_list 1]]

set export_vars_yes [export_ns_set_vars form {} $yes_args_set]
set export_vars_no [export_ns_set_vars form {} $no_args_set]

ad_return_template
