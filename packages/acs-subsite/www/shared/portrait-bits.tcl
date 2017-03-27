ad_page_contract {
    spits out correctly MIME-typed bits for a user's portrait

    @author philg@mit.edu
    @creation-date 26 Sept 1999
    @cvs-id $Id$
} {
    user_id:naturalnum,notnull
    {size ""}
}

#
# The size info is a valid geometry as provided for image magicks
# "convert". We provide here a sample list of valid sizes
#
if {$size ne "" && $size ni {x24 x50 x100}} {
    ad_log warning "size '$size' is not supported"
    set size ""
}

set item_id [acs_user::get_portrait_id -user_id $user_id]

if { $item_id != 0} {
    if {$size eq ""} {
        cr_write_content -item_id $item_id
    } else {
        if {[content::item::get -item_id $item_id -array_name itemInfo] == 0} {
            if {[content::item::get -item_id $item_id -array_name itemInfo -revision latest] == 0} {
                ad_log warning "cannot obtain revision info for item_id $item_id user_id $user_id"
                ns_returnnotfound
                ad_script_abort
            }
        }

        #
        # For portraits stored as files in the content repository,
        # we provide cached thumbnails, which use in their cache
        # key the revision id.
        #
            
        set folder [acs_root_dir]/portrait-thumbnails
        if {![file exists $folder]} {
            file mkdir $folder
        }

        set filename $folder/$itemInfo(revision_id).$size
        
        if {![file exists $filename]} {
            switch $itemInfo(storage_type) {
                "file" {
                    set input_file [content::revision::get_cr_file_path -revision_id $itemInfo(revision_id)]
                    exec convert $input_file -resize $size $filename
                }
                "lob" {
                    set input_file [ad_tmpnam]
                    set revision_id $itemInfo(revision_id)
                    # TODO: Oracle query and .xql is missing
                    db_blob_get_file write_lob_content {
                        select lob as content, 'lob' as storage_type
                        from cr_revisions
                        where revision_id = :revision_id
                    } -file $input_file
                    exec convert $input_file -resize $size $filename
                    file delete -- $input_file
                }
                default {
                    ad_log warning "unsupported storage type for portraits: $itemInfo(storage_type)"
                }
            }
        }
        #
        # Test again if the file exists, we might have converted the
        # file by the if-clause above.
        #
        if {[file exists $filename]} {
            ns_setexpires 86400 ;# 1 day
            ad_returnfile_background 200 $itemInfo(mime_type) $filename
        } else {
            ad_log warning "cannot show portrait with item_id $item_id for user $user_id "
            ns_returnnotfound
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
