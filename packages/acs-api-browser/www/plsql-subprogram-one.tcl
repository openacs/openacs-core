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
    name
    type
} -properties {
    title:onevalue
    context:onevalue
}

set title $name
set context [list {"plsql-subprograms-all" "All PL/SQL Subprograms"} "One PL/SQL Subprogram"]

set source_text ""

db_foreach source_text "select text
from user_source
where name = upper(:name)
and type = upper(:type)
order by line" {
    append source_text $text
}

switch $type {
    "PACKAGE" {
	set type "PACKAGE BODY"
	set package_slider_list [list "package" "<a href=\"[ad_conn url]?[export_url_vars type name]\">package body</a>"]
    }

    "PACKAGE BODY" {
	set type "PACKAGE"
	set package_slider_list [list "<a href=\"[ad_conn url]?[export_url_vars type name]\">package</a>" "package body"]
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
