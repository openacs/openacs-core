ad_page_contract {

    Deletes a group type

    @author mbryzek@arsdigita.com
    @creation-date Wed Nov  8 18:29:11 2000
    @cvs-id $Id$

} {
    group_type
    { return_url:localurl "" }
    { operation "" }
} -properties {
    context:onevalue
} -validate {
    user_can_delete_group -requires {group_type:notnull} {
        if { ![group_type::drop_all_groups_p $group_type] } {
            ad_complain "Groups exist that you do not have permission to delete. All groups must be deleted before you can remove a group type. Please contact the site administrator."
        }
    }
}

if { $operation ne "Yes, I really want to delete this group type" } {
    if { $return_url eq "" } {
        ad_returnredirect [export_vars -base one {group_type}]
    } else {
        ad_returnredirect $return_url
    }
    ad_script_abort
}

if {[catch {
    group_type::delete -group_type $group_type
} errmsg]} {
    ad_return_error "Error deleting group type" "We got the following error trying to delete this group type:<pre>$errmsg</pre>"
    ad_script_abort
}

ad_returnredirect $return_url
ad_script_abort

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
