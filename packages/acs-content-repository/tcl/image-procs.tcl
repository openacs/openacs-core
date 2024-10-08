# packages/acs-content-repository/tcl/image-procs.tcl

ad_library {

    Procedures to handle image subtype

    Image magick handling procedures inspired and borrowed from
    photo-album and imagemagick packages

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2006-07-31
    @cvs-id $Id$
}

namespace eval image {}

ad_proc -public image::new {
    {-name ""}
    {-parent_id ""}
    {-item_id ""}
    {-locale ""}
    {-creation_date ""}
    {-creation_user ""}
    {-context_id ""}
    {-package_id ""}
    {-creation_ip ""}
    {-item_subtype "content_item"}
    {-content_type "image"}
    {-title ""}
    {-description ""}
    {-mime_type ""}
    {-relation_tag ""}
    {-is_live ""}
    {-storage_type "file"}
    {-attributes {}}
    {-tmp_filename ""}
    {-width ""}
    {-height ""}
} {
     Create a new image object from a temporary file

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2006-07-31

    @param item_id Item id of the content item for this image. The
                   item_id will be generated from the acs_object_id
                   sequence if not specified.

    @param parent_id Parent object for this image. Context_id will be
                     set to parent_id

    @param name      Name of image item, must be unique per parent_id

    @param tmp_filename Filename in the filesystem, readable by
                        AOLserver user to create image from

    @return          Item_id

    @error
} {
    if {$width eq "" || $height eq ""} {
        lassign [image::get_file_dimensions \
                     -filename $tmp_filename \
                     -mime_type $mime_type] width height
    }
    if {[lsearch -index 0 $attributes "width"] < 0} {
        lappend attributes [list width $width]
    }
    if {[lsearch -index 0 $attributes "height"] < 0} {
        lappend attributes [list height $height]
    }
    return [content::item::new \
                -name $name \
                -parent_id $parent_id \
                -item_id $item_id \
                -locale $locale \
                -creation_date $creation_date \
                -creation_user $creation_user \
                -context_id $context_id \
                -package_id $package_id \
                -creation_ip $creation_ip \
                -item_subtype $item_subtype \
                -content_type $content_type \
                -title $title \
                -description $description \
                -mime_type $mime_type \
                -relation_tag $relation_tag \
                -is_live $is_live \
                -storage_type "file" \
                -attributes $attributes \
                -tmp_filename $tmp_filename]
}

ad_proc -public image::get_file_info {
    -filename
} {
    Get info about an image file, dimensions, mime_type
    The name of this proc tries to make clear that we aren't getting info
    for an image type object, but examinging an image file in the filesystem

    @param filename Full path to file in the filesystem

    @return List of width, height, and mime_type
} {
    # First try to get it via built-in support. If this fails, use
    # image magic.
    set size [image::ns_size -filename $filename]
    if {[lindex $size 0] ne ""} {
        set mime_type [image::mime_type -filename $filename]
        return [concat $size $mime_type]
    }
    return [image::imagemagick_identify -filename $filename]
}

ad_proc -public image::get_file_info_array {
    -filename
    -array_name
} {
    Get info about an image file, dimensions, mime_type into
    an array in the caller's namespace.

    @param filename Full path to file in the filesystem
    @param array_name Array in caller's namespace to populate
    @return List of width height mime_type in array get format

    @author Dave Bauer
    @creation-date 2006-08-27

    @see image::get_info
} {
    upvar $array_name local_array
    lassign [image::get_file_info -filename $filename] \
        local_array(width) local_array(height) local_array(mime_type)
}

ad_proc -public image::get_file_dimensions {
    -filename
    {-mime_type ""}
} {
    Get the width and height of an image from
    a file in the filesystem.

    This tries first to use built-in ns_*-support, and if not available, if talls back to
    imagemagick. We use imagemagick first since it supports many more image formats.

    @param filename full path to file in the filesystem

    @return Returns a list of width and height

    @creation-date 2006-08-28
    @author Dave Bauer (dave@solutiongrove.com)
} {
    set size [image::ns_size -filename $filename -mime_type $mime_type]
    if {[lindex $size 0] eq ""} {
        catch {set size [image::imagemagick_file_dimensions -filename $filename]}
    }
    return $size
}

ad_proc -public image::get_info {
    {-filename:required}
    {-array:required}
} {
    Get the width and height of an image file.
    The width and height are returned as 'height' and 'width' entries in the array named in the parameter.
    Uses ImageMagick instead of AOLserver function because it can handle more than
    just gifs and jpegs. The plan is to add the ability to get more details later.

    This proc duplicates and seems somehow superseded by
    image::imagemagick_identify, it might be a good idea to deprecate
    it in the future. One important difference is this proc won't fail
    in case of error.

    @param filename Name of the image file in the filesystem.
    @param array   Name of an array where you want the information returned.

    @see image::imagemagick_identify
} {
    upvar 1 $array row
    array set row {
        height {}
        width {}
    }

    catch {
        set identify_string [exec [image::identify_binary] $filename]
        regexp {[ ]+([0-9]+)[x]([0-9]+)[\+]*} $identify_string x width height
        set row(width) $width
        set row(height) $height
    }
}

ad_proc -public image::imagemagick_identify {
    -filename
} {
    Get width height and mime type from imagemagick

    @param filename Full path to an image file in the filesystem

    @return List of width height mime_type

    @author Dave Bauer (dave@solutiongrove.com)
    @creation-date 2006-08-27
} {
    if { [ catch {set out [exec [image::identify_binary] \
                               -format "%w %h %m %k %q %#" $filename]} errMsg]} {
        return -code error $errMsg
    }
    lassign $out width height type
    switch -- $type {
        JPG - JPEG {
            set mime_type image/jpeg
        }
        GIF - GIF87 {
            set mime_type image/gif
        }
        PNG {
            set mime_type image/png
        }
        TIF - TIFF {
            set mime_type image/tiff
        }
        default {
            set mime_type {}
        }
    }
    return [list $width $height $mime_type]
}

ad_proc -public image::imagemagick_file_dimensions {
    -filename
} {
    Get the dimensions of an image from imagemagick

    @param filename Full path to an image file in the filesystem

    @author Dave Bauer (dave@solutiongrove.com)
    @creation-date 2006-08-27
} {
    set geometry [exec [image::identify_binary] -size %w $filename]
    set width ""
    set height ""
    regexp {(\d+)x(\d+)} $geometry x width height
    return [list $width $height]
}

ad_proc -public image::identify_binary {
} {
    Find imagemagick identify binary

    @author Dave Bauer (dave@solutiongrove.com)
    @creation-date 2006-08-27
} {
    return [::util::which [parameter::get \
                               -parameter ImageMagickIdentifyBinary \
                               -package_id [apm_package_id_from_key acs-content-repository] \
                               -default "identify"]]
}

ad_proc -public image::convert_binary {
} {
    Find imagemagick convert binary

    @author Dave Bauer (dave@solutiongrove.com)
    @creation-date 2006-08-27
} {
    return [::util::which [parameter::get \
                               -parameter ImageMagickConvertBinary \
                               -package_id [apm_package_id_from_key acs-content-repository] \
                               -default "convert"]]
}

if {[ns_info name] eq "NaviServer"} {
    ad_proc -public image::ns_size {
        -filename
        {-mime_type ""}
    } {
        Use ns_gifsize/ns_jpegsize to try to get the size of an image

        @param filename Full path to file in the filesystem
        @return List containing width and height
    } {
        set w ""
        set h ""
        if {[file exists $filename] && [ns_imgtype $filename] ne "unknown"} {
            lassign [ns_imgsize $filename] w h
        }
        return [list $w $h]
    }
} else {
    ad_proc -public image::ns_size {
        -filename
        {-mime_type ""}
    } {
        Use ns_gifsize/ns_jpegsize to try to get the size of an image

        @param filename Full path to file in the filesystem
        @return List containing width and height
        @author Dave Bauer (dave@solutiongrove.com)
        @creation-date 2006-08-27
    } {
        switch -glob -- \
            [image::filename_mime_type \
                 -filename $filename \
                 -mime_type $mime_type] {
                     *gif {
                         set size [ns_gifsize $filename]
                     }
                     *jpg -
                     *jpeg {
                         set size [ns_jpegsize $filename]
                     }
                     default {
                         set size [list "" ""]
                     }
                 }
        return $size
    }
}

ad_proc -public image::mime_type {
    -filename
} {
    Use ns-built-in mimetype or image magick if not available

    @param filename Filename of image file
} {
    if {[namespace which ns_imgmime] ne ""} {
        set mime_type [ns_imgmime $filename]
        if {$mime_type ne "image/unknown"} {
            return $mime_type
        }
    }
    lassign [image::imagemagick_identify] . . mime_type
    return $mime_type
}

ad_proc -public image::filename_mime_type {
    -filename
    {-mime_type ""}
} {
    Use ns_guesstype if we don't know the mime_type

    @param filename Filename of image file
    @param mime_type If known, the mime type of the file

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2006-08-27
} {
    if {$mime_type eq ""} {
        set mime_type [ns_guesstype $filename]
    }
    return $mime_type
}

ad_proc -private image::get_convert_to_sizes {
} {
    List of sizes to convert an image to. List of maximum width x height.

    @author Dave Bauer (dave@solutiongrove.com)
    @creation-date 2006-08-27

} {
    #TODO make a parameter in content repository
        # avatar size to match gravatar.com
    return [list thumbnail 150x150 view 500x500 avatar 80x80]
}

ad_proc -public image::resize {
    -item_id
    {-revision_id ""}
    {-size_name "thumbnail"}
} {
    Create a thumbnail of an image in the content repository

    @param item_id item_id of image
    @return image item_id of the thumbnail

    @author Dave Bauer (dave@solutiongrove.com)
    @creation-date 2006-08-27
} {
    if {$revision_id eq ""} {
        set revision_id [content::item::get_best_revision -item_id $item_id]
    }
    set original_filename [content::revision::get_cr_file_path -revision_id $revision_id]
    set tmp_filename [ad_tmpnam "[ad_tmpdir]/XXXXXX"]
    array set sizes [image::get_convert_to_sizes]

    if {[catch {exec [image::convert_binary] -resize $sizes($size_name) $original_filename $tmp_filename} errmsg]} {
        # maybe imagemagick isn't installed?
        file delete -- $tmp_filename
        return ""
    }
    if {[set resize_item_id \
             [image::get_size_item_id \
                  -item_id $item_id \
                  -size_name $size_name]] eq ""} {

        set resize_item_id \
            [image::new \
                 -item_id $resize_item_id \
                 -name "${item_id}_${size_name}" \
                 -parent_id $item_id \
                 -relation_tag "image-${size_name}" \
                 -tmp_filename $tmp_filename]
    } else {
        content::revision::new \
            -item_id $resize_item_id \
            -tmp_filename $tmp_filename
    }
    file delete -- $tmp_filename
    return $resize_item_id
}

ad_proc -private image::get_size_item_id {
    -item_id
    -size_name
} {
    Get the item_id of a resized version of an image

    @param item_id Original image item_id
    @param size_name Name of the size to get

    @author Dave Bauer (dave@solutiongrove.com)
    @creation-date 2006-08-27

    @see image::get_convert_to_sizes
} {
    return [content::item::get_id \
                -item_path ${item_id}_${size_name} \
                -root_folder_id $item_id]
}

ad_proc -public image::get_resized_item_id {
    -item_id
    {-size_name "thumbnail"}
} {
    Get the item id of a related resized image, usually the thumbnail size

    @param item_id Item_id of the original image

    @return item_id of the resized image, empty string if it doeesn't exist

    @author Dave Bauer (dave@solutiongrove.com)
    @creation-date 2006-08-29
} {
    return [db_string get_resized_item_id "" -default ""]
}

ad_proc -private image::resize_existing_images {
} {
    Generate thumbnails for images already in the CR
} {
    foreach {size_name dimensions} [image::get_convert_to_sizes] {

        foreach item_id [db_list get_items {
            select item_id from cr_items
            where content_type='image' and latest_revision is not null
        }] {
        image::resize \
            -item_id $item_id \
            -size_name $size_name
        }
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
