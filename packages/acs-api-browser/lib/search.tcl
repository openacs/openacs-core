#
# API Browser search widget
#
# @cvs-id $Id$
#
# Expects: query_string:optional
#

if { ![info exists query_string] } {
    set query_string {}
}

set aolserver_tcl_api_root "http://www.aolserver.com/docs/devel/tcl/api/"

set tcl_docs_root "http://dev.scriptics.com/man/tcl[info tclversion]/TclCmd/contents.htm"

set package_url [apm_package_url_from_key "acs-api-browser"]

set openacs_search_url "${package_url}proc-search"

set openacs_browse_url "${package_url}proc-browse"

set openacs_plsql_browse_url "${package_url}plsql-subprograms-all"

set aolserver_search_url "${package_url}tcl-proc-view"

set tcl_search_url "${package_url}tcl-doc-search"
