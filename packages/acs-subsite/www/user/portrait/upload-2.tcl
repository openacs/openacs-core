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

set current_user_id [ad_verify_and_get_user_id]

if [empty_string_p $user_id] {
    set user_id $current_user_id
} 

ad_require_permission $user_id "write"

set exception_text ""
set exception_count 0

if { ![info exists upload_file] || [empty_string_p $upload_file] } {
    append exception_text "<li>Please specify a file to upload\n"
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
    if { ![empty_string_p [ad_parameter AcceptablePortraitMIMETypes "user-info"]] && [lsearch [ad_parameter AcceptablePortraitMIMETypes "user-info"] $guessed_file_type] == -1 } {
	incr exception_count
	append exception_text "<li>Your image wasn't one of the acceptable MIME types:   [ad_parameter AcceptablePortraitMIMETypes "user-info"]"
    }

    # strip off the C:\directories... crud and just get the file name
    if ![regexp {([^/\\]+)$} $upload_file match client_filename] {
	# couldn't find a match
	set client_filename $upload_file
    }

    if { ![empty_string_p [ad_parameter MaxPortraitBytes "user-info"]] && $n_bytes > [ad_parameter MaxPortraitBytes "user-info"] } {
	append exception_text "<li>Your file is too large.  The publisher of [ad_system_name] has chosen to limit portraits to [util_commify_number [ad_parameter MaxPortraitBytes "user-info"]] bytes.  You can use PhotoShop or the GIMP (free) to shrink your image.\n"
	incr exception_count
    }
}


if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

set what_aolserver_told_us ""
if { $file_extension == "jpeg" || $file_extension == "jpg" } {
    catch { set what_aolserver_told_us [ns_jpegsize $tmp_filename] }
} elseif { $file_extension == "gif" } {
    catch { set what_aolserver_told_us [ns_gifsize $tmp_filename] }
}

# the AOLserver jpegsize command has some bugs where the height comes 
# through as 1 or 2 
if { ![empty_string_p $what_aolserver_told_us] && [lindex $what_aolserver_told_us 0] > 10 && [lindex $what_aolserver_told_us 1] > 10 } {
    set original_width [lindex $what_aolserver_told_us 0]
    set original_height [lindex $what_aolserver_told_us 1]
} else {
    set original_width ""
    set original_height ""
}

## The portrait is ready. Let's now figure out how to insert into the system

set creation_ip [ad_conn peeraddr]
set name "portrait-of-user-$user_id"

set create_item "
begin
  :1 := content_item.new(
         name => :name,
         creation_ip => :creation_ip);
end;"

set create_rel "
begin
  :1 := acs_rel.new (
         rel_type => 'user_portrait_rel',
         object_id_one => :user_id,
         object_id_two => :item_id);
end;
"

set create_revision "
begin
  :1 := content_revision.new(
     title => :title,
     description => :portrait_comment,
     text => 'not_important',
     mime_type => :guessed_file_type,
     item_id => :item_id,
     creation_user => :user_id,
     creation_ip => :creation_ip
  );

  update cr_items
  set live_revision = :1
  where item_id = :item_id;
end;"

set update_photo "
update cr_revisions
set content = empty_blob()
where revision_id = :revision_id
returning content into :1
"

set upload_image_info "
insert into images
(image_id, width, height)
values
(:revision_id, :original_width, :original_height)
"

# let's figure out if this person has a portrait yet

if { ![db_0or1row get_item_id "select object_id_two as item_id
from acs_rels
where object_id_one = :user_id
and rel_type = 'user_portrait_rel'"] } {
    # The user doesn't have a portrait relation yet
    db_transaction {
	set item_id [db_exec_plsql create_item $create_item]
	set rel_id [db_exec_plsql create_rel $create_rel]
	set revision_id [db_exec_plsql create_revision $create_revision]
	db_dml update_photo $update_photo -blob_files [list $tmp_filename]
	db_dml upload_image_info $upload_image_info
    }
        
} else {
    #already has a portrait, so all we have to do is to make a new revision for it

    #Let's check if a current revision exists:
    if {![db_0or1row get_revision_id "select live_revision as revision_id
    from cr_items
    where item_id = :item_id"] || [empty_string_p $revision_id]} {
	# It's an insert rather than an update
	db_transaction {
	    set revision_id [db_exec_plsql create_revision $create_revision]
	    db_dml update_photo $update_photo -blob_files [list $tmp_filename]
	    db_dml upload_image_info $upload_image_info
	}
    } else {
	# it's merely an update
        db_transaction {
	    db_dml update_photo $update_photo -blob_files [list $tmp_filename]
	    db_dml update_image_info "
	    update images
	    set width = :original_width, height = :original_height
	    where image_id = :revision_id"

	    db_dml update_photo_info "
	    update cr_revisions
	    set description = :portrait_comment,
	        publish_date = sysdate,
	        mime_type = :guessed_file_type,
	        title = :title
	    where revision_id = :revision_id"

	    db_dml update_object_title "
	    update acs_objects
	    set title = :title
	    where object_id = :revision_id"
        }
    }
}

if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect [ad_pvt_home]
}
