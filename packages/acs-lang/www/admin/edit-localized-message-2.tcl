# /packages/gp-lang/www/gpadmin/edit-localized-message-2.tcl
ad_page_contract {

    When editing a localized message, if the user chooses to upload a new
    image to replace the current one, this is the script that handles the
    upload.

    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
    @creation-date 27 May 2002
    @cvs-id $Id$

} {
    upload_file:trim
    return_url
    key
    locales
} -properties {
}

# check the permission
set package_id [ad_conn package_id]
set permission_p [ad_permission_p $package_id nro_admin]

if { !$permission_p } {
    ad_returnredirect "/gp-admin"
}

if { [exists_and_not_null locales] } {
    set locale_user $locales
} else {
    set locale_user [ad_locale_locale_from_lang [ad_locale user language]]
}

# TODO: make the error processing better ... I don't really like these 
# ad_return_warning errors. BEM

if { ![info exists upload_file] || [empty_string_p $upload_file] } {

    # Oops. There is no file beeing uploaded.
    ad_return_warning "error" "You should select a file to upload..."
    ad_script_abort

} else {

    set tmp_filename [ns_queryget upload_file.tmpfile]
    set file_extension [string tolower [file extension $upload_file]]
    # remove the first "." from the file extension
    regsub "\." $file_extension "" file_extension

    # TODO: Support more graphic file formats. For the time being
    # we only work with jpg, gif or png
    if { ![regexp {^(jpeg|jpg|gif|png)$} $file_extension] } {
        append error_message "The only file formats supported are JPG, GIF or PNG.
        <br />Use the BACK button to submit another file"
        ad_return_warning "Error" $error_message
        ad_script_abort
    }

    set guessed_file_type [ns_guesstype $upload_file]
    set n_bytes [file size $tmp_filename]

    # TODO: Make some parameter for the maximum size (in bytes) for these
    # images. For the time being, we use a hardwired 100k
    if { $n_bytes > ( 100 * 1024 ) } {

        # The size is too big!
        set error_message "The size of the image you are uploading is too big.
            The maximum size allowed is 100KB."
        ad_return_warning "Error" $error_message
        ad_script_abort

    }

    # strip off the C:\directories... crud and just get the file name
    if ![regexp {([^/\\]+)$} $upload_file match client_filename] {
        # couldn't find a match
        set client_filename $upload_file
    }

    # We keep the following few lines just in case we need to do some
    # size checks in the future.

    set what_aolserver_told_us ""
    if { $file_extension == "jpeg" || $file_extension == "jpg" } {
        catch { set what_aolserver_told_us [ns_jpegsize $tmp_filename] }
    } elseif { $file_extension == "gif" } {
        catch { set what_aolserver_told_us [ns_gifsize $tmp_filename] }
    }

    # the AOLserver jpegsize command has some bugs where the height comes
    # through as 1 or 2

    if { ![empty_string_p $what_aolserver_told_us] && [lindex $what_aolserver_told_us 0] > 10 && \
        [lindex $what_aolserver_told_us 1] > 10 } {

        set original_width [lindex $what_aolserver_told_us 0]
        set original_height [lindex $what_aolserver_told_us 1]

    } else {

        set original_width ""
        set original_height ""

    }

    # The name of the file is the message created by the user
    set localized_message [_ $locale_user $key]
    set message_file_extension [file extension $localized_message]
    regsub "\." $message_file_extension "" message_file_extension
    if { $file_extension != $message_file_extension } {
        set error_message "You have to upload a file with the <strong>same extension</strong>
            as the one you stated in the message."
        ad_return_warning "Error" $error_message
        ad_script_abort
    }
     

    set apm_package_id [util_memoize {get_acs_object_id apm_service} 900]
    set ImageFolderPath [ad_parameter -package_id $apm_package_id ImageFolderPath]

    set destination_path "${ImageFolderPath}/${localized_message}"

    # Copy the file uploaded to its location in the filesystem
    # If there was another version of the file there, overwrite it without
    # any notice.
    file copy -force -- $tmp_filename $destination_path

}

db_release_unused_handles

# If we get here it's because everything went fine... Do we really believe that? ;)

ns_returnredirect $return_url
