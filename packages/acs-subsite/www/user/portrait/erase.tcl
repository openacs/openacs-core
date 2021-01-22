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

    set item_id [db_string get_item_id {} -default ""]

    if {$item_id eq ""} {
        ad_returnredirect $return_url
        ad_script_abort
    }

    set resized_item_id [image::get_resized_item_id -item_id $item_id]

    # Delete the resized version
    if {$resized_item_id ne ""} {
        content::item::delete -item_id $resized_item_id
    }

    # Delete all previous images
    db_foreach get_images {} {
        package_exec_plsql -var_list [list [list delete__object_id $object_id]] acs_object delete
    }

    db_foreach old_item_id {} {
        content::item::delete -item_id $object_id
    }

    # Delete the relationship
    db_dml delete_rel {}

    # Delete the item
    content::item::delete -item_id $item_id

    # Flush the portrait cache
    util_memoize_flush [list acs_user::get_portrait_id_not_cached -user_id $user_id]

    ad_returnredirect $return_url
}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
