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

ReturnHeaders "image/gif"

if { [catch {
    set file [open "[acs_package_root_dir "acs-subsite"]/www/shared/1pixel.header"]
    ns_writefp $file
    close $file

    # Can't figure out how to write binary data using AOLserver 3 (it
    # insist on UTF8-encoding it). So we write to a file, then dump
    # the file's contents.

    set file_name [ns_tmpnam]
    ns_log "Notice" "logging to $file_name"
    set file [open $file_name w+]
    fconfigure $file -encoding binary -translation binary
    puts -nonewline $file "[format "%c%c%c" $r $g $b]"
    seek $file 0
    ns_writefp $file
    close $file
    ns_unlink $file_name

    set file [open "[acs_package_root_dir "acs-subsite"]/www/shared/1pixel.footer"]
    ns_writefp $file
    close $file

} errMsg] } {
    # Ignore simple i/o errors, which probably just mean that the user surfed on 
    # to some other page before we finished serving 
    if { ![string equal $errMsg {i/o failed}] } {
        global errorInfo
        ns_log Error "$errMsg\n$errorInfo"
    }
}
