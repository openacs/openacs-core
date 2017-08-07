ad_library {
    Filter procedures for the ArsDigita Templating System

    @author Karl Goldstein    (karlg@arsdigita.com)
    
    @cvs-id $Id$
}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html


namespace eval template {}

ad_proc -public template::forward { url args } {
    Redirect and abort processing

    if "template::forward your_url t" is used.  The url will be cached

    @see ad_cache_returnredirect

} {
    # DRB: The code that was here before didn't preserve the protocol, always
    # using HTTP even if HTTPS was used to establish the connection.  Besides
    # which ad_returnredirect has funky checks for even funkier browsers, and
    # is therefore not only the standard way to redirect in OpenACS 4 but
    # more robust as well.

    set cache_p [lindex $args 0]

    if {$cache_p == "t"} {
        set persistent_p [lindex $args 1]
	set excluded_vars [lindex $args 2]

        ad_cache_returnredirect $url $persistent_p $excluded_vars
    } else {
	ad_returnredirect $url
    }
    ad_script_abort
}

ad_proc -public template::filter { command args } {
    Run any filter procedures that have been registered with the
    templating system.  The signature of a filter procedure is 
    a reference (not the value) to a variable containing the URL of
    the template to parse.  The filter procedure may modify this.
} {
    variable filter_list

    set arg1 [lindex $args 0]
    set arg2 [lindex $args 1]

    switch -exact $command {

        add { lappend filter_list $arg1 }

        exec {
            upvar $arg1 url $arg2 root_path
            foreach proc_name $filter_list { $proc_name url root_path }
        }

        default { error "Invalid filter command: must be add or exec" }
    }
}

# DRB: The following debugging filters weren't integrated with OpenACS.
# I fixed them but not very elegantly - they assume you're trying to debug
# a template within a package, not at the top www level.  As it turns out
# the query processor makes similar assumptions so making these work for
# "/foo"-style URLs would require fixing it, too.   Also ACS 4.2 had these
# debugging filters enabled by default.  I've turned them off by default.

ad_proc -public cmp_page_filter { why } {
    Show the compiled template (for debugging)
} {
    if { [catch {
        set url [ns_conn url]
        regsub {.cmp} $url {} url_stub
        regexp {^/([^/]*)(.*)} $url_stub all package_key rest
        set file_stub "$::acs::rootdir/packages/$package_key/www$rest"
        set beginTime [clock clicks -milliseconds]

        set output "<pre>[ns_quotehtml [template::adp_compile -file $file_stub.adp]]</pre>"

        set timeElapsed [expr ([clock clicks -milliseconds] - $beginTime)]
        ns_log debug "cmp_page_filter: Time elapsed: $timeElapsed"

    } errMsg] } {
        set output <html><body><pre>[ns_quotehtml $::errorInfo]</pre></body></html>
    }

    ns_return 200 text/html $output

    return filter_return
}

ad_proc -public dat_page_filter { why } {
    Show the comments for the template (for designer)
} {
    if { [catch {
        set url [ns_conn url]
        regsub {.dat} $url {} url_stub
        regexp {^/([^/]*)(.*)} $url_stub all package_key rest
        set code_stub "$::acs::rootdir/packages/$package_key/www$rest"
        set beginTime [clock clicks -milliseconds]

	set file_stub [template::resource_path -type messages -style $datasources]

        set output [template::adp_parse $file_stub [list code_stub $code_stub]]

        set timeElapsed [expr ([clock clicks -milliseconds] - $beginTime)]
        ns_log debug " dat_page_filter: Time elapsed: $timeElapsed"

    } errMsg] } {
        set output <html><body><pre>$::errorInfo</pre></body></html>
    }

    ns_return 200 text/html $output

    return filter_return
}

# Return the auto-generated template for a form


namespace eval template {

    ad_proc -private frm_page_handler { } {
        Build the form information for the form page filter.   This was
        originally handled inline but doing so screwed up the query
        processor.
    } {
        set url [ns_conn url]
        regsub {.frm} $url {} url_stub
        regexp {^/([^/]*)(.*)} $url_stub all package_key rest
        set __adp_stub "$::acs::rootdir/packages/$package_key/www$rest"

        # Set the parse level
        lappend ::templating::parse_level [info level]

        # execute the code to prepare the form(s) for a template
        adp_prepare

        # get the form template
        return [form::template [ns_queryget form_id] [ns_queryget form_style]]
    }
}

ad_proc -private frm_page_filter { why } {
    Return the form data for a request for .frm
} {
    if { [catch {
        set beginTime [clock clicks -milliseconds]

        set output [template::frm_page_handler]

        set timeElapsed [expr ([clock clicks -milliseconds] - $beginTime)]
        ns_log debug "frm_page_filter: Time elapsed: $timeElapsed"

    } errMsg] } {
        set output $::errorInfo
    }

    ns_return 200 text/html "<html><body><pre>[ns_quotehtml $output]</pre></body></html>"

    return filter_return
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
