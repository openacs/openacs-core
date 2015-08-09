ad_page_contract {
    small demp

    @author unknown
    @creation-date unknown
    @cvs-id $Id$
} {
    {file:token ""}
}

if { $file eq "" } {

    set output "no file specified"

} elseif { [regexp {\.\.|^/} $file] } {

    set output "Only files within this directory may be shown."

} else {
    #
    # [ns_url2file [ns_conn url]] fails under request processor, since
    # the request processor manges the provided url path.
    #
    set dir [file dirname [ad_conn file]]
    if {[file readable $dir/$file]} {
	#
	# Probably, one should in real life the file with
	# ns_returnfile, since the file might contain binary
	# characters... but for this sample script, we return
	# everything as html.
	#
	set text [ns_quotehtml [template::util::read_file $dir/$file]]
	set output "<pre>$text</pre>"
    } else {
	set output "The specified file not readable"
	# probably, we should return a 404 error, not a success status code
    }
}

ns_return 200 text/html $output
