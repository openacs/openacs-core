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

db_multirow all_subprograms all_subprograms {
    select object_type as type, object_name as name
    from user_objects
    where object_type in ('PACKAGE', 'PROCEDURE', 'FUNCTION')
    order by
    decode(object_type, 'PACKAGE', 0, 'PROCEDURE', 1, 'FUNCTION', 2) asc
}

db_release_unused_handles
ad_return_template