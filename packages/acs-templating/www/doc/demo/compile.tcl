set file [ns_queryget file]

if { [regexp {\.\.|^/} $file] } {

  set compiled "Only files within this directory may be shown."

} else {
 
  # [ns_url2file [ns_conn url]]  fails under request processor !
  # the file for URL pkg/page may be in packages/pkg/www/page, not www/pkg/page
  set dir [file dirname [ad_conn file]]
  set compiled [ns_quotehtml [template::adp_compile -file $dir/$file]]
}

ns_return 200 text/html "<pre>$compiled</pre>"
