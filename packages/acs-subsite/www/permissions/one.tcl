ad_page_contract {
    Display permissions and children for the given object_id

    Templated + cross site scripting holes patched by davis@xarg.net

    @author rhs@mit.edu
    @creation-date 2000-08-20
} {
    object_id:object_id,notnull
    {children_p:boolean,notnull "f"}
    {detail_p:boolean,notnull "f"}
    {privs:nohtml ""}
    {inherited_permissions_p:boolean,notnull "f"}
    {application_url:localurl ""}
}

set user_id [auth::require_login]
permission::require_permission -object_id $object_id -privilege admin

set show_inherited_permissions_href [export_vars -base one {object_id children_p {inherited_permissions_p t}}]
set hide_inherited_permissions_href [export_vars -base one {object_id children_p {inherited_permissions_p f}}]

# Check if this is the Main Site and prevent the user from being
# able to remove Read permission on "The Public" and locking
# everybody (including him/herself) out.

set mainsite_p [expr {$object_id eq [subsite::main_site_id]}]

set object_info [acs_object::get -object_id $object_id]
set name               [dict get $object_info object_name]
set security_inherit_p [dict get $object_info security_inherit_p]
set context_id         [dict get $object_info context_id]
if {$context_id == -3} {
    #
    # Legacy installations have #acs-kernel.Default_Context# set in
    # cases, where newer instances have a NULL value.
    #
    set context_id ""
}

set context [list [list "./" [_ acs-subsite.Permissions]] [_ acs-subsite.Permissions_for_name]]
set toggle_view_vars {object_id privs children_p inherited_permissions_p}
if {$detail_p} {
    lappend toggle_view_vars {detail_p 0}
    set toggle_view_label "Show permissions as table"
} else {
    lappend toggle_view_vars {detail_p 1}
    set toggle_view_label "Show permissions as list"
}
set toggle_view_href [export_vars -base one $toggle_view_vars]

set nr_inherited_permissions [db_string nr_inherited_permissions {}]

db_multirow inherited inherited_permissions {} {}
db_multirow -extend {grantee_name} acl acl {
    select grantee_id, privilege
    from acs_permissions
    where object_id = :object_id
} {
    set grantee_name [acs_object_name $grantee_id]
}

set controls [list]
set controlsUrl [export_vars -base grant {application_url object_id}]
lappend controls "<a href=\"[ns_quotehtml $controlsUrl]\">[ns_quotehtml [_ acs-subsite.Grant_Permission]]</a>"


if {$context_id ne ""} {
    set context_name [lang::util::localize [acs_object_name $context_id]]
    set toggleUrl [export_vars -base toggle-inherit {application_url object_id}]
    if { $security_inherit_p == "t" && $context_id ne "" } {
        lappend controls "<a href='[ns_quotehtml $toggleUrl]'>Don't Inherit Permissions from [ns_quotehtml $context_name]</a>"
    } else {
        lappend controls "<a href='[ns_quotehtml $toggleUrl]'>Inherit Permissions from [ns_quotehtml $context_name]</a>"
    }
}

set controls "\[ [join $controls { | }] \]"

set export_form_vars [export_vars -form {object_id application_url}]

set show_children_url [export_vars -base one {object_id application_url {children_p t}}]
set hide_children_url [export_vars -base one {object_id application_url {children_p f}}]

if {$children_p == "t"} {
    db_multirow children children {} {}
} else {
    db_1row children_count {} 
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
