# upload an item revision from a file

ad_proc -public cr_revision_upload { title item_id path } {

    set revision_id [db_exec_plsql get_revision_id "begin
    :1 := content_revision.new(title     => :title, 
                               item_id   => :item_id, 
                               v_content => null);
     end;"]

    db_dml dml_revision_from_file "update 
                            cr_revisions 
                          set
                            content = empty_blob()
                          where
                            revision_id = :revision_id
                          returning content into :1" -blob_files [list $path]

  return $revision_id
}

ad_proc -public cr_write_content {
    -item_id
    -revision_id
} {

    @param item_id the item to write
    @param revision_id revision to write
    @author Don Baccus (dhogaza@pacifier.com)

    Write out the specified content to the current HTML connection.  Only one of 
    item_id and revision_id should be passed to this procedure.  If item_id is
    provided the item's live revision will be written, otherwise the specified
    revision.

    This routine was was written to centralize the downloading of data from
    the content repository.  Previously, similar code was scattered among
    various packages, not all of which were written to handle both in-database
    and in-filesystem storage of content items.

    Though this routine is written to be fully general in terms of a content 
    item's storage type, typically those stored as text aren't simply dumped
    to the user in raw form, but rather ran through the templating system
    in order to surround the content with decorative HTML.

} {

    if { [info exists revision_id] && [info exists item_id] } {
        return -code error "Both revision_id and item_id were specfied"
    }

    if { [info exists item_id] } {
        if { ![db_0or1row get_item_info ""] } {
            return -code error "There is no content that matches item_id '$item_id'"
        }
    } elseif { [info exists revision_id] } {
        if { ![db_0or1row get_revision_info ""] } {
            return -code error "There is no content that matches revision_id '$revision_id'"
        }
    } else {
        return -code error "Either revision_id or item_id must be specified"
    }

    if { ![string equal $storage_type "file"] && \
         ![string equal $storage_type "text"] && \
         ![string equal $storage_type "lob"] } {
        return -code error "Storage type '$storage_type' is invalid."
    }

    ReturnHeaders $mime_type

    switch $storage_type {
        text { 
            ns_write [db_string write_text_content]
        }
        file {
            set path [cr_fs_path $storage_area_key]
            db_write_blob write_file_content ""         
        }
        lob  {
            db_write_blob write_lob_content ""
        }
    }

    return
}
