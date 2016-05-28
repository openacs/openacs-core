ad_page_contract {

    View compiled file
    (Part of demo pages)

} {
    file:trim,notnull
} -validate {
   valid_file -requires file {
      if { [regexp {\.\.|^/} $file] } {
         ad_complain "Only files within this directory may be shown."
      }
       set dir [file dirname [ad_conn file]]
       if {![file readable $dir/$file] || [file isdirectory $dir/$file]} {
           ad_complain "requested file is not readable."
      }
   }
}
 
# [ns_url2file [ns_conn url]]  fails under request processor !
# the file for URL pkg/page may be in packages/pkg/www/page, not www/pkg/page

set compiled [template::adp_compile -file $dir/$file]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
