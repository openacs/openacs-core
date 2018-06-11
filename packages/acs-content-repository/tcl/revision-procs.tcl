# upload an item revision from a file

ad_proc -public cr_write_content {
    -string:boolean
    -item_id
    -revision_id
} {
    Write out the specified content to the current HTML connection or return
    it to the caller by using the -string flag.  Only one of
    item_id and revision_id should be passed to this procedure.  If item_id is
    provided the item's live revision will be written, otherwise the specified
    revision.

    This routine was written to centralize the downloading of data from
    the content repository.  Previously, similar code was scattered among
    various packages, not all of which were written to handle both in-database
    and in-filesystem storage of content items.

    Though this routine is written to be fully general in terms of a content
    item's storage type, typically those stored as text aren't simply dumped
    to the user in raw form, but rather ran through the templating system
    in order to surround the content with decorative HTML.

    @param string specifies whether the content should be returned as a string
           or (the default) be written to the HTML connection (ola@polyxena.net)
    @param item_id the item to write
    @param revision_id revision to write
    @author Don Baccus (dhogaza@pacifier.com)

} {

    if { [info exists revision_id] && [info exists item_id] } {
        error "Both revision_id and item_id were specified"
    }

    if { [info exists item_id] } {
        if { ![db_0or1row get_item_info ""] } {
            error "There is no content that matches item_id '$item_id'" {} NOT_FOUND
        }
    } elseif { [info exists revision_id] } {
        if { ![db_0or1row get_revision_info ""] } {
            error "There is no content that matches revision_id '$revision_id'" {} NOT_FOUND
        }
    } else {
        error "Either revision_id or item_id must be specified"
    }

    if { $storage_type ne "file"
         && $storage_type ne "text"
         && $storage_type ne "lob"
     } {
        error "Storage type '$storage_type' is invalid."
    }

    # I set content length to 0 here because otherwise I need to do
    # db-specific queries for get_revision_info
    if {$content_length eq ""} {
        set content_length 0
    }

    switch -- $storage_type {
        text {
            set text [db_string write_text_content ""]
            if { $string_p } {
                return $text
            }
            ns_return 200 $mime_type $text
        }
        file {
            set path [cr_fs_path $storage_area_key]
            set filename [db_string write_file_content ""]
            if {$filename eq ""} {
                error "No content for the revision $revision_id.\
                    This seems to be an error which occurred during the upload of the file"
            } elseif {![file readable $filename]} {
                ns_log Error "Could not read file $filename. Maybe the content repository is (partially) missing?"
                ns_return 404 text/plain {}
            } else {
                if { $string_p } {
                    set fd [open $filename "r"]
                    fconfigure $fd \
                        -translation binary \
                        -encoding [encoding system]
                    set text [read $fd]
                    close $fd
                    return $text
                } else {
                    # JCD: for webdavfs there needs to be a content-length 0 header
                    # but ns_returnfile does not send one.   Also, we need to
                    # ns_return size 0 files since if fastpath is enabled ns_returnfile
                    # simply closes the connection rather than send anything (including
                    # any headers).  This bug is fixed in AOLServer 4.0.6 and later
                    # but work around it for now.
                    set size [file size $filename]
                    if {!$size} {
                        ns_set put [ns_conn outputheaders] "Content-Length" 0
                        ns_return 200 text/plain {}
                    } else {
                        if {[info commands ad_returnfile_background] eq "" || [security::secure_conn_p]} {
                            ns_returnfile 200 $mime_type $filename
                        } else {
                            ad_returnfile_background 200 $mime_type $filename
                        }
                    }
                }
            }
        }
        lob  {

            if { $string_p } {
                return [db_blob_get write_lob_content ""]
            }

            #
            # Need to set content_length header here.
            #
            # Unfortunately, old versions of OpenACS did not set the
            # content_length correctly, so we fix this here locally.
            #
            if {$content_length eq "0" && [db_driverkey ""] eq "postgresql"} {
                set content_length [db_string get_lob_length {
                    select sum(byte_len)
                    from cr_revisions, lob_data
                    where revision_id = :revision_id and lob_id = cr_revisions.lob
                }]
            }

            ns_set put [ns_conn outputheaders] "Content-Length" $content_length

            ReturnHeaders $mime_type $content_length
            #
            # In a HEAD request, just send headers and no content
            #
            if {![string equal -nocase "head" [ns_conn method]]} {
                db_write_blob write_lob_content ""
            } else {
                ns_conn close
            }
        }
    }

    return
}

ad_proc -public cr_import_content {
    {-storage_type "file"}
    -creation_user
    -creation_ip
    -image_only:boolean
    {-image_type "image"}
    {-other_type "content_revision"}
    {-title ""}
    {-description ""}
    {-package_id ""}
    -item_id
    parent_id
    tmp_filename
    tmp_size
    mime_type
    object_name
} {

    Import an uploaded file into the content repository.

    @param storage_type Where to store the content (lob or file), defaults to "file" (later
           a system-wide parameter)
    @param creation_user The creating user (defaults to current user)
    @param creation_ip The creating ip (defaults to peeraddr)
    @param image_only Only allow images
    @param image_type The type of content item to create if the file contains an image
    @param other_type The type of content item to create for a non-image file
    @param title The title given to the new revision
    @param description The description of the new revision
    @param package_id Package ID of the package that created the item
    @param item_id If present, make a new revision of this item, otherwise, make a new
           item
    @param parent_id The parent of the content item we create
    @param tmp_filename The name of the temporary file holding the uploaded content
    @param tmp_size The size of tmp_file
    @param mime_type The uploaded file's mime type
    @param object_name The name to give the result content item and revision

    This procedure handles all mime_type details, creating a new item of the appropriate
    type and stuffing the content into either the file system or the database depending
    on "storage_type".  The new revision is set live, and its item_id is returned to the
    caller.

    image_type and other_type should be supplied when the client package
    has extended the image and content_revision types to hold package-specific
    information.   Checking is done to ensure that image_type has been inherited from
    image, and that other_type has been inherited from content_revision.

    Is up to the caller to do any checking on size limitations, etc.

} {

    if { ![info exists creation_user] } {
        set creation_user [ad_conn user_id]
    }

    if { ![info exists creation_ip] } {
        set creation_ip [ad_conn peeraddr]
    }

    # DRB: Eventually we should allow for text storage ... (CLOB for Oracle)

    if { $storage_type ne "file" && $storage_type ne "lob" } {
        return -code error "Imported content must be stored in the file system or as a large object"
    }

    if {$mime_type eq "*/*"} {
        set mime_type "application/octet-stream"
    }

    if {$package_id eq ""} {
        set package_id [ad_conn package_id]
    }

    set old_item_p [info exists item_id]
    if { !$old_item_p } {
        set item_id [db_nextval acs_object_id_seq]
    }

    # use content_type of existing item
    if {$old_item_p} {
        set content_type [db_string get_content_type ""]
    } else {
        # all we really need to know is if the mime type is mapped to image, we
        # actually use the passed in image_type or other_type to create the object
        if {[db_string image_type_p "" -default 0]} {
            set content_type image
        } else {
            set content_type content_revision
        }
    }
    set revision_id [db_nextval acs_object_id_seq]

    db_transaction {

        if { [db_string is_registered "" -default ""] eq "" } {
            db_dml mime_type_insert ""
            db_exec_plsql mime_type_register ""
        }

        switch -- $content_type {
            image {

                if { [db_string image_subclass ""] == "f" } {
                    error "Image file must be stored in an image object"
                }

                set what_nsd_told_us ""
                if {$mime_type eq "image/jpeg"} {
                    catch { set what_nsd_told_us [ns_jpegsize $tmp_filename] }
                } elseif {$mime_type eq "image/gif"} {
                    catch { set what_nsd_told_us [ns_gifsize $tmp_filename] }
                } elseif {$mime_type eq "image/png"} {
                    catch { set what_nsd_told_us [ns_pngsize $tmp_filename] }
                } else {
                    error "Unknown image type"
                }

                # The AOLserver/ jpegsize command has some bugs where the height comes
                # through as 1 or 2, so trust the valuesresult only on larger values.
                if { $what_nsd_told_us ne ""
                     && [lindex $what_nsd_told_us 0] > 10
                     && [lindex $what_nsd_told_us 1] > 10
                } {
                    lassign $what_nsd_told_us original_width original_height
                } else {
                    set original_width ""
                    set original_height ""
                }

                if { !$old_item_p } {
                    db_exec_plsql image_new ""
                } else {
                    db_exec_plsql image_revision_new ""
                }

            }

            default {

                if { $image_only_p } {
                    error "The file you uploaded was not an image (.gif, .jpg or .jpeg) file"
                }

                if { [db_string content_revision_subclass ""] == "f" } {
                    error "Content must be stored in a content revision object"
                }

                if { !$old_item_p } {
                    db_exec_plsql content_item_new ""
                }
                db_exec_plsql content_revision_new ""

            }
        }

        # insert the attachment into the database

        switch -- $storage_type {
            file {
                set filename [cr_create_content_file $item_id $revision_id $tmp_filename]
                db_dml set_file_content ""
            }
            lob {
                db_dml set_lob_content "" -blob_files [list $tmp_filename]
                db_dml set_lob_size ""
            }
        }

    }

    return $revision_id

}

ad_proc cr_set_imported_content_live {
    -image_sql
    -other_sql
    mime_type
    revision_id
} {
    @param image_sql Optional SQL to extend the base image type
    @param other_sql Optional SQL to extend the base content revision type
    @param mime_type Mime type of the new revision
    @param revision_id The revision we're setting live

    If provided execute the appropriate SQL in the caller's context, then
    set the given revision live.

    The idea is to give the caller a clean way of setting the additional information
    needed for its private type.   This is a hack.   Executing this SQL can't be done
    within cr_import_content because the caller can't see the new revision's key...
} {
    if { [cr_registered_type_for_mime_type $mime_type] eq "image" } {
        if { [info exists image_sql] } {
            uplevel 1 [list db_dml dynamic_query $image_sql]
        }
    } elseif { [info exists other_sql] } {
            uplevel 1 [list db_dml dynamic_query $other_sql]
    }
    db_exec_plsql set_live ""
}


ad_proc cr_registered_type_for_mime_type {
    mime_type
} {
    Return the type registered for this mime type.

    @param mime_type param The mime type
} {
    return [db_string registered_type_for_mime_type "" -default ""]
}

ad_proc cr_check_mime_type {
    -mime_type
    {-filename ""}
    {-file ""}
} {
    Check whether the mimetype is registered. If not, check whether it
    can be guessed from the filename. If guessed mimetype is not
    registered optionally insert it.

    @param mime_type param The mime type
    @param filename the filename
    @param file the actual file being saved. This option currently
           doesn't have any effect, but in the future would be better
           to inspect the actual file content instead of trusting the user.

    @return the mapped mimetype
} {
    #
    # Check if the provided mime_type is already in our cr_mime_types
    # table. If so, accept it.
    #
    if {$mime_type ne "*/*" && [db_0or1row check_given_mime_type {
        select 1 from cr_mime_types where mime_type = :mime_type
    }]} {
        return $mime_type
    }

    # TODO: we use only the extension to get the mimetype. Something
    # better should be done, like inspecting the actual content of the
    # file and never trust the user on this regard, but as this
    # involves changes also in the data model, we leave this for the
    # future. Usages of this proc in the systems are already set to
    # give us the path to the file here.
    set extension [string tolower [string trimleft [file extension $filename] "."]]
    if {[db_0or1row lookup_mimetype {}]} {
        return $mime_type
    }
    set mime_type [string tolower [ns_guesstype $filename]]
    if {[db_0or1row lookup_mimetype {}]} {
        return $mime_type
    }
    set allow_mimetype_creation_p \
        [parameter::get \
             -parameter AllowMimeTypeCreationP -default 0]
    return [cr_filename_to_mime_type -create=$allow_mimetype_creation_p \
                $filename]
}

ad_proc -public cr_filename_to_mime_type {
    -create:boolean
    filename
} {
    given a filename, returns the mime type.  If the -create flag is
    given the mime type will be created; this assumes there is some
    other way such as ns_guesstype to find the filename

    @param create flag whether to create the mime type the routine picks for filename
    @param filename the filename to try to guess a mime type for (the file need not
           exist, the routine does not attempt to access the file in any way)

    @return mimetype (or */* of unknown)

    @author Jeff Davis (davis@xarg.net)
} {
    set extension [string tolower [string trimleft [file extension $filename] "."]]

    if {$extension eq ""} {
        return "*/*"
    }

    if {[db_0or1row lookup_mimetype {}]} {
        return $mime_type
    } else {
        set mime_type [string tolower [ns_guesstype $filename]]

        ns_log Debug "guessed mime \"$mime_type\" create_p $create_p"
        if {(!$create_p) || $mime_type eq "*/*" || $mime_type eq ""} {
            # we don't have anything meaningful for this mimetype
            # so just */* it.

            return "*/*"
        }

        # We guessed a type but there was no mapping
        # create it and map it.  We know the extension
        cr_create_mime_type -extension $extension -mime_type $mime_type -description {}

        return $mime_type
    }
}

ad_proc -public cr_create_mime_type {
    -mime_type:required
    {-extension ""}
    {-description ""}
} {

    Creates a mime type if it does not exist.  Also maps extension to
    mime_type (unless the extension is already mapped to another mime
    type or extension is empty).

    @param mime_type the mime_type to create
    @param extension the default extension for the given mime type
    @param description a plain text description of the mime type (< 200 characters)

    @author Jeff Davis (davis@xarg.net)
} {
    # make both lower since that is the convention.
    # should never pass in anything that is not lower cased
    # already but just be safe.

    set mime_type [string tolower $mime_type]
    set extension [string tolower $extension]

    db_dml maybe_create_mime {
        insert into cr_mime_types (label, mime_type, file_extension)
        select :description, :mime_type, :extension
        from dual
        where not exists (select 1
                          from cr_mime_types
                          where mime_type = :mime_type)
    }

    if { $extension ne "" } {
        db_dml maybe_map_extension {
            insert into cr_extension_mime_type_map (extension, mime_type)
            select :extension, :mime_type
            from dual
            where not exists (select 1
                          from cr_extension_mime_type_map
                          where extension = :extension)
        }
    }
}



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
