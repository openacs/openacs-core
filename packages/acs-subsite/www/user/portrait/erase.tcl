ad_page_contract {
    Erases a portrait

    @cvs-id $Id$
} {
    {return_url:localurl "" }
    {user_id:naturalnum ""}
} -properties {
    context:onevalue
    export_vars:onevalue
    admin_p:onevalue
}

set current_user_id [ad_conn user_id]

if {$user_id eq "" || $user_id eq $current_user_id} {
    set user_id $current_user_id
    set admin_p 0
} else {
    set admin_p 1
}

permission::require_permission -object_id $user_id -privilege "write"

set doc(title) [_ acs-subsite.Erase]
if {$admin_p} {
    set context [list \
                     [list [ad_pvt_home] [ad_pvt_home_name]] \
                     [list [export_vars -base ./ user_id] [_ acs-subsite.User_Portrait]] \
                     $doc(title)]
} else {
    set context [list \
                     [list [ad_pvt_home] [ad_pvt_home_name]] \
                     [list "./" [_ acs-subsite.Your_Portrait]] \
                     $doc(title)]
}

if { $return_url eq "" } {
    set return_url [ad_pvt_home]
}

ad_form -name "portrait_erase" -export {user_id return_url} -form {} -on_submit {

    acs_user::erase_portrait -user_id $user_id
    
    ad_returnredirect $return_url
    ad_script_abort
    
}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
