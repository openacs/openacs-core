ad_page_contract {
    Configuration home page.
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-13
    @cvs-id $Id$
}

set page_title "Subsite Configuration"

set context [list "Configuration"]


# TODO: Add join policy


ad_form -name name -cancel_url [ad_conn url] -mode display -form {
    {instance_name:text
        {label "Subsite name"}
        {html {size 50}}
    }
} -on_request {
    set instance_name [ad_conn instance_name]
} -on_submit {
    apm_package_rename -instance_name $instance_name
} -after_submit {
    ad_returnredirect [ad_conn url]
    ad_script_abort
}
