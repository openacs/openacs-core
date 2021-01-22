ad_library {
    Procedures to manage image files.

    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-10-29
    @cvs-id $Id$
}

namespace eval image {}

ad_proc -public image::get_info {
    {-filename:required}
    {-array:required}
} {
    Get the width and height of an image file. 
    The width and height are returned as 'height' and 'width' entries in the array named in the parameter.
    Uses ImageMagick instead of AOLserver function because it can handle more than
    just gifs and jpegs. The plan is to add the ability to get more details later.

    @param filename Name of the image file in the file system.
    @param array   Name of an array where you want the information returned.
} {
    upvar 1 $array row
    array set row {
        height {}
        width {}
    }

    catch {
        set identify_string [exec identify $filename]
        regexp {[ ]+([0-9]+)[x]([0-9]+)[\+]*} $identify_string x width height
        set row(width) $width
        set row(height) $height
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
