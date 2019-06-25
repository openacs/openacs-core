ad_page_contract {
    Uploading user portraits

    @cvs-id $Id$
} {
    {user_id:naturalnum ""}
    {return_url:localurl ""}
} -properties {
    first_names:onevalue
    last_name:onevalue
    context:onevalue
    export_vars:onevalue
    
}

set current_user_id [ad_conn user_id]

set portrait_id [acs_user::get_portrait_id -user_id $user_id]
set portrait_p [expr {$portrait_id != 0}]

if { $portrait_p } {
    content::item::get -item_id $portrait_id -array_name portrait
    set doc(title) [_ acs-subsite.upload_a_replacement_por]
    set description $portrait(description)
} else {
    set doc(title) [_ acs-subsite.Upload_Portrait]
    set description ""
    set revision_id ""
}

if {$user_id eq ""} {
    subsite::upload_allowed
    set user_id $current_user_id
    set admin_p 0
} else {
    set admin_p 1
}

permission::require_permission -object_id $user_id -privilege "write"

if {![person::person_p -party_id $user_id]} {
    ad_return_error \
        "Account Unavailable" \
        "We can't find you (user #$user_id) in the users table.  Probably your account was deleted for some reason."
    ad_script_abort
}

acs_user::get -user_id $user_id -array user
set first_names $user(first_names)
set last_name   $user(last_name)

if { $return_url eq "" } {
    set return_url [ad_pvt_home]
}

if {$admin_p} {
    set context [list \
                     [list [export_vars -base ./ user_id] [_ acs-subsite.User_Portrait]] \
                     $doc(title)]
} else {
    set context [list \
                     [list [ad_pvt_home] [ad_pvt_home_name]] \
                     [list [export_vars -base ./ return_url] [_ acs-subsite.Your_Portrait]] \
                     $doc(title)]
}

set help_text [_ acs-subsite.lt_Use_the_Browse_button]

ad_form -name "portrait_upload" -html {enctype "multipart/form-data"} -export {user_id return_url} -form {
    {upload_file:text(file)
        {label "#acs-subsite.Filename#"}
        {help_text $help_text}
    }
}

if { $portrait_p } {
    ad_form -extend -name "portrait_upload" -form {
        {portrait_comment:text(textarea),optional
            {label "#acs-subsite.Caption#"}
            {value $description}
            {html {rows 6 cols 50}}
        }
    }
} else {
    ad_form -extend -name "portrait_upload" -form {
        {portrait_comment:text(textarea),optional
            {label "#acs-subsite.Caption#"}
            {html {rows 6 cols 50}}
        }
    }
}

set mime_types [parameter::get -parameter AcceptablePortraitMIMETypes -default ""]
set max_bytes [parameter::get -parameter MaxPortraitBytes -default ""]

ad_form -extend -name "portrait_upload" -validate {

    # check to see if this is one of the favored MIME types,
    # e.g., image/gif or image/jpeg

    # DRB: the code actually depends on our having either gif or jpeg and this was true
    # before I switched this routine to use cr_import_content (i.e. don't believe the
    # generality implicit in the following if statement)

    {upload_file
        
        { $mime_types eq "" || [lsearch $mime_types [ns_guesstype $upload_file]] > -1 }
        {Your image wasn't one of the acceptable MIME types: $mime_types}
    }
    {upload_file

        { $max_bytes eq "" || [file size [ns_queryget upload_file.tmpfile]] <= $max_bytes } 
        {Your file is too large.  The publisher of [ad_system_name] has chosen to limit portraits to [util::content_size_pretty -size $max_bytes].  You can use PhotoShop or the GIMP (free) to shrink your image}
    }

} -on_submit {

    db_transaction {

        acs_user::create_portrait \
            -user_id $user_id \
            -description $portrait_comment \
            -filename $upload_file \
            -file [ns_queryget upload_file.tmpfile]
        
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
