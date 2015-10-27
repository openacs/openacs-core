# /packages/api-doc/www/api-doc/plsql-subprograms-all.tcl
ad_page_contract {
    Lists all subprograms (packages, procedures, or functions) in the
    database.

    @author Michael Yoon (michael@arsdigita.com)
    @creation-date 2000-08-23
    @cvs-id $Id$
} -properties {
    title:onevalue
    context:onevalue
    all_subprograms:multirow
}

set context [list "All PL/SQL Subprograms"]

# Organize the subprograms under three headings: FUNCTION, PROCEDURE,
# and PACKAGE.

db_multirow all_subprograms all_subprograms {}

db_release_unused_handles
ad_return_template
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
