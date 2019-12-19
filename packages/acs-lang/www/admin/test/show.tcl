ad_page_contract {
    This page will read any file in its same local directory and
    display the result as HTML. Apparently a leftover from around 2002
    and the GreenPeace times.
} {
    file:notnull
}

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
