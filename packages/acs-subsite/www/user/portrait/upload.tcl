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

set portrait_p [db_0or1row checkportrait {}]

if { $portrait_p } {
    set doc(title) [_ acs-subsite.upload_a_replacement_por]
    set description [db_string getstory {}]
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

if {![db_0or1row get_name {}]} {
    ad_return_error "Account Unavailable" "We can't find you (user #$user_id) in the users table.  Probably your account was deleted for some reason."
    return
}

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
        {Your file is too large.  The publisher of [ad_system_name] has chosen to limit portraits to [util_commify_number $max_bytes] bytes.  You can use PhotoShop or the GIMP (free) to shrink your image}
    }

} -on_submit {

    # this stuff only makes sense to do if we know the file exists
    set tmp_filename [ns_queryget upload_file.tmpfile]

    set file_extension [string tolower [file extension $upload_file]]

    # remove the first . from the file extension
    regsub "\." $file_extension "" file_extension

    set guessed_file_type [ns_guesstype $upload_file]

    set n_bytes [file size $tmp_filename]

    # Sizes we want for the portrait
    set sizename_list {avatar thumbnail}
    array set resized_portrait [list]

    # strip off the C:\directories... crud and just get the file name
    if {![regexp {([^/\\]+)$} $upload_file match client_filename]} {
        # couldn't find a match
        set client_filename $upload_file
    }

    # Wrap the whole creation along with the relationship in a big transaction
    # Just to make sure it really worked.
    
    db_transaction {
        set item_id [content::item::get_id_by_name -name "portrait-of-user-$user_id" -parent_id $user_id]
        if { $item_id eq ""} { 
            # The user doesn't have a portrait relation yet
            set item_id [content::item::new -name "portrait-of-user-$user_id" -parent_id $user_id -content_type image]
        } else {
            foreach sizename $sizename_list {
                set resized_portrait($sizename) [image::get_resized_item_id \
                                                     -item_id $item_id \
                                                     -size_name $sizename]
            }
        }

        # Load the file into the revision
        set revision_id [cr_import_content \
                             -item_id $item_id \
                             -image_only \
                             -storage_type file \
                             -creation_user [ad_conn user_id] \
                             -creation_ip [ad_conn peeraddr] \
                             -description $portrait_comment \
                             $user_id \
                             $tmp_filename \
                             $n_bytes \
                             $guessed_file_type \
                             "portrait-of-user-$user_id"]

        content::item::set_live_revision -revision_id $revision_id
        
        foreach name [array names resized_portrait] {
            if { $resized_portrait($name) ne "" } {
                # Delete the item
                content::item::delete -item_id $resized_portrait($name)

                # Resize the item
                image::resize -item_id $item_id -size_name $name
            }
        }

        # Only create the new relationship if there does not exist one already
        set user_portrait_rel_id [relation::get_id -object_id_one $user_id -object_id_two $item_id -rel_type "user_portrait_rel"]
        if {$user_portrait_rel_id eq ""} {
            db_exec_plsql create_rel {}
        }
    }

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
