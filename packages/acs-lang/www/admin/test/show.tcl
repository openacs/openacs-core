set file [ns_queryget file]

if { [regexp {\.\.|^/} $file] } {

  set output "Only files within this directory may be shown."

} else {
 
  # [ns_url2file [ns_conn url]]  fails under request processor !
  # the file for URL pkg/page may be in packages/pkg/www/page, not www/pkg/page
  set dir [file dirname [ad_conn file]]
  set text [ns_quotehtml [template::util::read_file $dir/$file]]
  set output "<pre>$text</pre>"
}

ns_return 200 text/html $output

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
