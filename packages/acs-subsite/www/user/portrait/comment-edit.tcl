ad_page_contract {
    screen to edit the comment associated with a user's portrait

    @author mbryzek@arsdigita.com
    @creation-date 22 Jun 2000
    @cvs-id $Id$
} {
    {return_url:localurl "" }
    {user_id:naturalnum ""}
} -properties {
    context:onevalue
    export_vars:onevalue
    description:onevalue
    first_names:onevalue
    last_name:onevalue
}

set current_user_id [ad_conn user_id]

if {$user_id eq ""} {
    set user_id $current_user_id
}

permission::require_permission -object_id $user_id -privilege "write"

if {![person::person_p -party_id $user_id]} {
    ad_return_error \
        "Account Unavailable" \
        "We can't find you (user #$user_id) in the users table.  Probably your account was deleted for some reason."
    ad_script_abort
}

set user [acs_user::get -user_id $user_id]
set first_names [dict get $user first_names]
set last_name   [dict get $user last_name]

set portrait_id [acs_user::get_portrait_id -user_id $user_id]

if {$portrait_id == 0} {
    ad_return_complaint 1 "<li>You shouldn't have gotten here; we don't have a portrait on file for you."
    return
}

set description [db_string portrait_info {
    select description from cr_revisions
    where revision_id = (select live_revision from cr_items
                          where item_id = :portrait_id)}]

set doc(title) [_ acs-subsite.Edit_caption]
set context [list \
                 [list [ad_pvt_home] [ad_pvt_home_name]] \
                 [list "./" [_ acs-subsite.Your_Portrait]] \
                 $doc(title)]

if { $return_url eq "" } {
    set return_url [ad_pvt_home]
}

ad_form -name comment_edit -export {user_id return_url} -form {
    {description:text(textarea),optional
        {label "#acs-subsite.Caption#"}
        {value $description}
        {html {rows "6" cols "50"}}
    }
} -on_submit {

    if { [string length $description] > 4000 } {
        ad_return_complaint 1 "Your portrait comment can only be 4000 characters long."
        return
    }

    db_dml comment_update {
        update cr_revisions set
          description = :description
        where revision_id = (select live_revision
                             from cr_items
                             where item_id = :portrait_id)
    }

    ad_returnredirect $return_url
    ad_script_abort
}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
