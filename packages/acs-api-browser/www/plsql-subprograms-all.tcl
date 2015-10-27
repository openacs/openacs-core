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

#
# Organize the subprograms und types like FUNCTION, PROCEDURE, and
# PACKAGE in oracle or FUNCTION in PostgresSQL
#
db_multirow all_subprograms all_subprograms {}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
