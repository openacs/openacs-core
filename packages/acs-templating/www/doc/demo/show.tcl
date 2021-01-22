ad_page_contract {
    small demo source viewer

    @author unknown
    @creation-date unknown
    @cvs-id $Id$
} {
    file:trim,notnull
} -validate {
   valid_file -requires file {
       if { [regexp {\.\.|^/} $file] } {
           ad_complain "Only files within this directory may be shown."
       }
       set dir [file dirname [ad_conn file]]
       if {![file readable $dir/$file] || [file isdirectory $dir/$file]} {
           ad_complain "The specified file ist not readable"
       }
   }
}

#
# [ns_url2file [ns_conn url]] fails under request processor, since
# the request processor manges the provided url path.
#
set source [template::util::read_file $dir/$file]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
