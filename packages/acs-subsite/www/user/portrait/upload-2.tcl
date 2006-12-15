ad_page_contract {
    adds (or replaces) a user's portrait

    @author philg@mit.edu
    @creation-date 26 Sept 1999
    @cvs-id $Id$
} {
    upload_file
    {user_id ""}
    {portrait_comment ""}
    {return_url ""}
    {title ""}
}

subsite::upload_allowed
set current_user_id [auth::require_login]

if [empty_string_p $user_id] {
    set user_id $current_user_id
}

ad_require_permission $user_id "write"

set exception_text ""
set exception_count 0

if {![info exists upload_file] 
    || [empty_string_p $upload_file] 
} {
    append exception_text "<li>Please specify a file to upload</li>\n"
    incr exception_count
} else {
    # this stuff only makes sense to do if we know the file exists
    set tmp_filename [ns_queryget upload_file.tmpfile]

    set file_extension [string tolower [file extension $upload_file]]

    # remove the first . from the file extension
    regsub "\." $file_extension "" file_extension

    set guessed_file_type [ns_guesstype $upload_file]

    set n_bytes [file size $tmp_filename]

    # check to see if this is one of the favored MIME types,
    # e.g., image/gif or image/jpeg

    # DRB: the code actually depends on our having either gif or jpeg and this was true
    # before I switched this routine to use cr_import_content (i.e. don't believe the
    # generality implicit in the following if statement)

    if { ![empty_string_p [ad_parameter AcceptablePortraitMIMETypes "user-info"]]
         && [lsearch [ad_parameter AcceptablePortraitMIMETypes "user-info"] $guessed_file_type] == -1 } {
	incr exception_count
	append exception_text "<li>Your image wasn't one of the acceptable MIME types: [ad_parameter AcceptablePortraitMIMETypes "user-info"]</li>"
    }

    # strip off the C:\directories... crud and just get the file name
    if {![regexp {([^/\\]+)$} $upload_file match client_filename]} {
	# couldn't find a match
	set client_filename $upload_file
    }
    
    if { ![empty_string_p [ad_parameter MaxPortraitBytes "user-info"]] 
         && $n_bytes > [ad_parameter MaxPortraitBytes "user-info"] } {
	append exception_text "<li>Your file is too large.  The publisher of [ad_system_name] has chosen to limit portraits to [util_commify_number [ad_parameter MaxPortraitBytes "user-info"]] bytes.  You can use PhotoShop or the GIMP (free) to shrink your image.</li>\n"
	incr exception_count
    }
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    ad_script_abort
}

# Wrap the whole creation along with the relationship in a big transaction
# Just to make sure it really worked.

db_transaction {
    set item_id [content::item::get_id_by_name -name "portrait-of-user-$user_id" -parent_id $user_id]
    if { [empty_string_p $item_id]} { 
	# The user doesn't have a portrait relation yet
	set item_id [content::item::new -name "portrait-of-user-$user_id" -parent_id $user_id -content_type image]
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
    # Only create the new relationship if there does not exist one already
   set user_portrait_rel_id [relation::get_id -object_id_one $user_id -object_id_two $item_id -rel_type "user_portrait_rel"]
   if {[empty_string_p $user_portrait_rel_id]} {
	db_exec_plsql create_rel {}
    }
}

if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect [ad_pvt_home]
}
