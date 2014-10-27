# packages/acs-core-ui/www/permissions/index.tcl
ad_page_contract {
    Display all objects that the user has admin on.
    
    Templated and changed to browse heirarchy by davis@xarg.net 
    since all objects can be a *lot* of objects.
    
    @author rhs@mit.edu
    @creation-date 2000-08-29
    @cvs-id $Id$
} { 
    root:trim,integer,optional
}

set user_id [auth::require_login]

set context "Permissions"

if {(![info exists root] || $root eq "")} { 
    set root [ad_conn package_id]
}

db_multirow objects adminable_objects { *SQL* }

set security_context_root [acs_magic_object security_context_root]
set default_context [acs_magic_object default_context]
set admin_p [permission::permission_p -object_id $security_context_root -party_id $user_id -privilege admin]
set subsite [ad_conn package_id]
