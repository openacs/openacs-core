# Filter procedures for the ArsDigita Templating System

# Copyright (C) 1999-2000 ArsDigita Corporation
# Authors: Karl Goldstein    (karlg@arsdigita.com)

# $Id$

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html


# Sample filter for handling pages with the ADP to Tcl compiler

ad_proc -public acs_page_filter { why } {

  # Check for updates to Tcl library files
  # watch_files

  set url [template::util::resolve_directory_url [ns_conn url]]

  if { ! [regsub {.acs$} $url {} url_stub] } { return filter_ok }

  if { [catch {

    #set url [template::util::resolve_directory_url [ad_conn url]]
    set root_path [ns_info pageroot]

    template::filter exec url_stub root_path

    set file_stub $root_path/$url_stub

    ns_log Notice $file_stub

    set beginTime [clock clicks]

    set output [template::adp_parse $file_stub {}]

    set timeElapsed [expr ([clock clicks] - $beginTime) / 1000]
    ns_log Notice "Time elapsed: $timeElapsed"

  } errMsg] } {

    if { [string equal FILTER_ABORT $errMsg] } { return filter_return }

    # truncate ADP buffer
    ns_adp_trunc

    global errorInfo
    # truncate the error trace  (no problem for debugging ?)
    regsub {\(procedure \"code::tcl.*$} $errorInfo {} errorInfo

    set output "<html><body>
      <p>An internal error ocurred while preparing a template $url_stub:</p>
      <pre>$errorInfo</pre>
      </body></html>"
  }

  if { [string length $output] } {
    ns_return 200 text/html $output
  }

  return filter_return
}

# Redirect and abort processing

ad_proc -public template::forward { url } {

  if { ! [string match http://* $url] } {
    
    if { [string index $url 0] != "/" } {
      set url [util::get_url_directory [ns_conn url]]$url
    }
    set host_name [ns_set iget [ns_conn headers] Host]
    set url http://$host_name$url
  }

  global errorInfo

  ns_returnredirect $url

  # (DanW OpenACS, dcwickstrom@earthlink.net) - commented this out since the 
  # rp doesn't seem to support this processing method.  It appears that this 
  # is used as a mechanism to abort further processing of a page, but the rp 
  # doesn't have the catch and continue code as implied by acs_page_filter 
  # example shown above.
  #error FILTER_ABORT
}

# Run any filter procedures that have been registered with the
# templating system.  The signature of a filter procedure is 
# a reference (not the value) to a variable containing the URL of
# the template to parse.  The filter procedure may modify this.

ad_proc -public template::filter { command args } {

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

# Show the compiled template (for debugging)

ad_proc -public cmp_page_filter { why } {

  if { [catch {
    set url [ad_conn url]
    regsub {.cmp$} $url {} url_stub
    set file_stub [ns_url2file $url_stub]

    set beginTime [clock clicks]

    set output "<pre>[ns_quotehtml \
      [template::adp_compile -file $file_stub.adp]]</pre>"

    set timeElapsed [expr ([clock clicks] - $beginTime) / 1000]
    ns_log Notice "Time elapsed: $timeElapsed"

  } errMsg] } {
    global errorInfo
    set output <html><body><pre>$errorInfo</pre></body></html>
  }

  ns_return 200 text/html $output

  return filter_return
}

# Show the comments for the template (for designer)

ad_proc -public dat_page_filter { why } {

  if { [catch {
    set url [ad_conn url]
    regsub {.dat$} $url {} url_stub
    set code_stub [ns_url2file $url_stub]

    set beginTime [clock clicks]

    set file_stub [template::get_resource_path]/messages/datasources

    set output [template::adp_parse $file_stub [list code_stub $code_stub]]

    set timeElapsed [expr ([clock clicks] - $beginTime) / 1000]
    ns_log Notice "Time elapsed: $timeElapsed"

  } errMsg] } {
    global errorInfo
    set output <html><body><pre>$errorInfo</pre></body></html>
  }

  ns_return 200 text/html $output

  return filter_return
}

# Return the auto-generated template for a form

ad_proc -public frm_page_filter { why } {

  namespace eval template {

    if { [catch {
      set url [ns_conn url]
      regsub {.frm} $url {} url_stub
      set __adp_stub [ns_url2file $url_stub]

      set beginTime [clock clicks]

      # Set the parse level
      variable parse_level
      lappend parse_level [info level]

      # execute the code to prepare the form(s) for a template
      adp_prepare

      # get the form template
      set output [form::template \
        [ns_queryget form_id] [ns_queryget form_style]]

      set timeElapsed [expr ([clock clicks] - $beginTime) / 1000.]
      ns_log Notice "Time elapsed: $timeElapsed"

    } errMsg] } {
      global errorInfo
      set output $errorInfo
    }

    ns_return 200 text/html "<html>
     <body>
       <pre>[ns_quotehtml $output]</pre>
     </body></html>"
  }

  return filter_return
}
