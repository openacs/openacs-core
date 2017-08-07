# /packages/acs-api-browser/www/api-doc/plsql-subprogram-one.tcl
ad_page_contract {
    Returns the specification for a given PL/SQL subprogram (package,
    procedure, or function).

    @param name
    @param type

    @author Michael Yoon (michael@arsdigita.com)
    @creation-date 2000-03-05
    @cvs-id $Id$
} {
    name:token
    type:token
} -properties {
    title:onevalue
    context:onevalue
}

set title $name
set context [list {"plsql-subprograms-all" "All PL/SQL Subprograms"} "One PL/SQL Subprogram"]

set source_text ""

db_foreach source_text {} {
    append source_text $text \n\n\n
}

switch $type {
    "PACKAGE" {
	set type "PACKAGE BODY"
	set href [export_vars -base [ad_conn url] {type name}]
	set package_slider_list [list "package" [subst {<a href="[ns_quotehtml $href]">package body</a>}]]
    }

    "PACKAGE BODY" {
	set type "PACKAGE"
	set href [export_vars -base [ad_conn url] {type name}]
	set package_slider_list [list [subst {<a href="[ns_quotehtml $href]">package</a>}] "package body"]
    }

    default {
	set package_slider_list [list]
    }
}

# Lowercase looks nicer.
#
set name [string tolower $name]

db_release_unused_handles
ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
