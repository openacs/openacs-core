# /packages/api-doc/www/api-doc/plsql-subprograms-all.tcl
ad_page_contract {
    Lists all subprograms (packages, procedures, or functions) in the
    database.

    @author Michael Yoon (michael@arsdigita.com)
    @creation-date 2000-08-23
    @cvs-id $Id$
} -properties {
    all_subprograms:multirow
    pretty_plurals:onerow
}

# Organize the subprograms under three headings: FUNCTION, PROCEDURE,
# and PACKAGE.

# We use this array to prettify the headings.
#
set pretty_plurals(PACKAGE) "Packages"
set pretty_plurals(PROCEDURE) "Procedures"
set pretty_plurals(FUNCTION) "Functions"

db_multirow all_subprograms all_subprograms {
    select object_type as type, object_name as name
    from user_objects
    where object_type in ('PACKAGE', 'PROCEDURE', 'FUNCTION')
    order by
    decode(object_type, 'PACKAGE', 0, 'PROCEDURE', 1, 'FUNCTION', 2) asc
}

db_release_unused_handles
ad_return_template