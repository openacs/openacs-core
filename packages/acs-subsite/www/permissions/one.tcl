# packages-core-ui/www/acs_object/permissions/index.tcl
ad_page_contract {
    Display permissions and children for the given object_id

    Templated + cross site scripting holes patched by davis@xarg.net

    @author rhs@mit.edu
    @creation-date 2000-08-20
    @cvs-id $Id$
} {
    object_id:integer,notnull
    {children_p:boolean "f"}
    {application_url ""}
}

set user_id [auth::require_login]
permission::require_permission -object_id $object_id -privilege admin

# RBM: Check if this is the Main Site and prevent the user from being
#      able to remove Read permission on "The Public" and locking
#      him/herself out.
if {$object_id eq [subsite::main_site_id]} {
    set mainsite_p 1
} else {
    set mainsite_p 0
}


acs_object::get -object_id $object_id -array obj
set name               $obj(object_name)
set context_id         $obj(context_id)
set security_inherit_p $obj(security_inherit_p)

set context [list [list "./" [_ acs-subsite.Permissions]] [_ acs-subsite.Permissions_for_name]]

db_multirow inherited inherited_permissions {} {}

db_multirow -extend {grantee_name} acl acl {
    select grantee_id, privilege
    from acs_permissions
    where object_id = :object_id
} {
    set grantee_name [party::name -party_id $grantee_id]
}

set controls [list]
set controlsUrl [export_vars -base grant {application_url object_id}]
lappend controls "<a href=\"[ns_quotehtml $controlsUrl]\">[ns_quotehtml [_ acs-subsite.Grant_Permission]]</a>"

set context_name [lang::util::localize [acs_object_name $context_id]]

set toggleUrl [export_vars -base toggle-inherit {application_url object_id}]
if { $security_inherit_p == "t" && $context_id ne "" } {
    lappend controls "<a href=\"[ns_quotehtml $toggleUrl]\">Don't Inherit Permissions from [ns_quotehtml $context_name]</a>"
} else {
    lappend controls "<a href=\"[ns_quotehtml $toggleUrl]\">Inherit Permissions from [ns_quotehtml $context_name]</a>"
}

set controls "\[ [join $controls { | }] \]"

set export_form_vars [export_vars -form {object_id application_url}]

set show_children_url [export_vars -base one {object_id application_url {children_p t}}]
set hide_children_url [export_vars -base one {object_id application_url {children_p f}}]

if {$children_p == "t"} {
    db_multirow children children {} {
    }
} else {
    db_1row children_count {} 
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
