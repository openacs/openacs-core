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
set package_url [apm_package_url_from_key "acs-api-browser"]

# AOLserver has dropped documentation, use NaviServer docs instead
#set server_tcl_api_root     "http://www.aolserver.com/docs/devel/tcl/api/"
set server_tcl_api_root      "https://naviserver.sourceforge.io/n/toc.html"

set tcl_docs_root            "http://tcl.tk/man/tcl[info tclversion]/TclCmd/contents.htm"

set openacs_search_url       "${package_url}proc-search"
set openacs_browse_url       "${package_url}proc-browse"
set openacs_plsql_browse_url "${package_url}plsql-subprograms-all"
set aolserver_search_url     "${package_url}tcl-proc-view"
set tcl_search_url           "${package_url}tcl-doc-search"

switch [db_type] {
    postgresql {
        set db_pretty "PostgreSQL [db_version]"
        set db_doc_url "http://www.postgresql.org/docs/[db_version]/interactive/index.html"
        set db_doc_search_url "https://www.postgresql.org/search"
        set db_doc_search_export [export_vars -form { { ul "https://www.postgresql.org/docs/[db_version]/static/%" } }]
        set db_doc_search_query_name "q"
    }
    oracle {
        set db_pretty "Oracle [db_version]"
        # Oracle docs require login, can't offer direct search link
        switch -glob [db_version] {
            8.1.7 {
                set db_doc_url "http://otn.oracle.com/documentation/oracle8i.html"
		set db_doc_search_url "http://otn.oracle.com/pls/tahiti/tahiti.drilldown"
		set db_doc_search_export ""
		set db_doc_search_query_name "word"
            }
            8.1.6 {
                set db_doc_url "http://otn.oracle.com/documentation/oracle8i_arch_816.html"
            }
            9* {
                set db_doc_url "http://otn.oracle.com/documentation/oracle9i.html"
		set db_doc_search_url "http://otn.oracle.com/pls/db92/db92.drilldown"
		set db_doc_search_export ""
		set db_doc_search_query_name "word"	
            }
            10* {
                set db_doc_url ""
                set db_doc_search_url "http://otn.oracle.com/pls/db10g/db10g.drilldown"
                set db_doc_search_export "http://otn.oracle.com/pls/db10g/db10g.homepage"
                set db_doc_search_query_name "word"                
            }
            default {
                set db_doc_url ""
                set db_doc_search_url ""
                set db_doc_search_export ""
                set db_doc_search_query_name ""
            }
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
