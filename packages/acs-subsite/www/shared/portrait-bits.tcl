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
if {$size ni {x24 x50 x100}} {
    ad_log warning "size '$size' is not supported"
    set size ""
}

set item_id [acs_user::get_portrait_id -user_id $user_id]

if { $item_id != 0} {
    if {$size eq ""} {
        cr_write_content -item_id $item_id
    } else {
        content::item::get -item_id $item_id -array_name itemInfo

        if {$itemInfo(storage_type) eq "file"} {
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
                set input_file [content::revision::get_cr_file_path -revision_id $itemInfo(revision_id)]
                exec convert $input_file -resize $size $filename
            }

            ad_returnfile_background 200 $itemInfo(mime_type) $filename
        } else {
            ad_log warning "Storage_type lob not handled"
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
