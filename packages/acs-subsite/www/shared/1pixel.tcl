# 1pixel.tcl,v 1.1.2.2 2000/02/03 10:00:24 ron Exp

ad_page_contract {
    Generates a 1-pixel GIF image with a certain color.

    @author Jon Salz <jsalz@mit.edu>
    @creation-date 28 Nov 1999
    @cvs-id $Id$
} {
    r:integer
    g:integer
    b:integer
}

util_return_headers "image/gif"

if { [catch {
    set file [open [acs_package_root_dir "acs-subsite"]/www/shared/1pixel.header]
    ns_writefp $file
    close $file

    # Can't figure out how to write binary data using AOLserver 3 (it
    # insist on UTF8-encoding it). So we write to a file, then dump
    # the file's contents.

    set file [file tempfile file_name]
    ns_log "Notice" "logging to $file_name"
    fconfigure $file -encoding binary -translation binary
    puts -nonewline $file [format "%c%c%c" $r $g $b]
    seek $file 0
    ns_writefp $file
    close $file
    file delete -- $file_name

    set file [open [acs_package_root_dir "acs-subsite"]/www/shared/1pixel.footer]
    ns_writefp $file
    close $file

} errMsg] } {
    # Ignore simple i/o errors, which probably just mean that the user surfed on 
    # to some other page before we finished serving 
    if { ![string equal $errMsg {i/o failed}] } {
        ns_log Error "$errMsg\n$::errorInfo"
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
