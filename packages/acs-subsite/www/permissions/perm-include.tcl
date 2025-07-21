ad_include_contract {
    Display a permission table for the provided object_id

    @param object_id
    @param return_url
    @param privs
    @param user_add_url URL for adding users
} {
    {object_id:integer}
    {return_url:localurl ""}
    {privs { read create write delete admin }}
    {detailed_permissions_p:boolean,notnull f}
    {user_add_url:localurl ""}
} -validate {
    valid_privs -requires {privs} {
        #
        # Ensure users can only specify valid privileges.
        #
        set n_privs [llength $privs]
        if {$n_privs == 0} {
            return
        }
        set n_valid_privs [db_string get_valid_permissions "
            select count(*) from acs_privileges
             where privilege in ([ns_dbquotelist $privs])"]
        if {$n_privs != $n_valid_privs} {
            ad_complain [_ acs-tcl.lt_name_contains_invalid \
                             [list name privs]]
        }
    }
}

set user_id [ad_conn user_id]
set admin_p [permission::permission_p -object_id $object_id -privilege admin]

set ad_return_url [ad_return_url]
if { $return_url eq "" } {
    set return_url $ad_return_url
}


#
# When "privs" are passed in from the <include...> as empty, take the
# defaults. This way, it is still backward compatible and it does not
# require that the caller needs to know the default privileges.
#
if {$privs eq ""} {
    set privs { read create write delete admin }
}

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

set elements [list]
lappend elements grantee_name {
    label "[_ acs-subsite.Name]"
    link_url_col name_url
    display_template {
        <if @permissions.any_perm_p_@ gt 0>
          @permissions.grantee_name@
        </if>
        <else>
          <span style="color: gray">@permissions.grantee_name@</span>
        </else>
    }
}

set mainsite_p [expr {$object_id eq [subsite::main_site_id]}]

foreach priv $privs {
    lappend select_clauses \
        "sum(ptab.${priv}_p) as ${priv}_p" \
        "(case when sum(ptab.${priv}_p) > 0 then 'checked' else '' end) as ${priv}_checked"
    lappend from_all_clauses "(case when privilege='${priv}' then 2 else 0 end) as ${priv}_p"
    lappend from_direct_clauses "(case when privilege='${priv}' then -1 else 0 end) as ${priv}_p"
    lappend from_dummy_clauses "0 as ${priv}_p"

    lappend elements ${priv}_p \
        [list \
             html { align center } \
             label [string totitle [string map {_ { }} [_ acs-subsite.$priv]]] \
             display_template [subst -nocommands {
               <if @permissions.grantee_id@ eq -1 and $mainsite_p eq 1>
                 <if @permissions.${priv}_p@ eq 1>
                    <adp:icon name="checkbox-checked" title="#acs-subsite.perm_cannot_be_removed#">
                    <input type="hidden" name="perm" value="@permissions.grantee_id@,${priv}"">
                 </if>
               </if><else>
               <if @permissions.${priv}_p@ ge 2>
                 <adp:icon name="checkbox-checked" title="#acs-subsite.Inherited_Permission-helptext#">
               </if>
               <else>
                 <input type="checkbox" name="perm" value="@permissions.grantee_id@,${priv}" @permissions.${priv}_checked@>
               </else></else>
             }] \
            ]
}

# Remove all
lappend elements remove_all {
    html { align center }
    label "[_ acs-subsite.Remove_All]"
    display_template {
        <if @permissions.grantee_id@ eq -1 and $mainsite_p true>
        </if><else>
        <input type="checkbox" name="perm" value="@permissions.grantee_id@,remove">
        </else>
    }
}

#lappend elements grantee_id


set perm_url "[ad_conn subsite_url]permissions/"

if { $user_add_url eq "" } {
    set user_add_url "${perm_url}perm-user-add"
}
set user_add_url [export_vars -base $user_add_url {
    object_id expanded {return_url $ad_return_url}
}]

set actions {}
if {$detailed_permissions_p} {
    lappend actions \
        [_ acs-subsite.Grant_Permission] \
        [export_vars -base "${perm_url}grant" {return_url application_url object_id}] \
        [_ acs-subsite.Grant_Permission]
}
lappend actions \
    [_ acs-subsite.Grant_Permissions_to_Users] \
    $user_add_url \
    [_ acs-subsite.Grant_Permissions_to_Users-helptext]

#
# When there is no context_id given, do not offer to turn
# security_inherit_p on or off.
#
if { $context_id ne "" } {
    #
    # The variable "parent_object_name" is used in the following
    # message keys:
    #
    #    lt_Do_not_inherit_from_p, lt_Inherit_from_parent_o,
    #    lt_Inherit_permissions_f, lt_Stop_inheriting_permi
    #
    set parent_object_name [acs_object_name $context_id]

    if { $security_inherit_p } {
        lappend actions \
            [_ acs-subsite.lt_Do_not_inherit_from_p] \
            [export_vars -base "${perm_url}toggle-inherit" {object_id {return_url $ad_return_url}}] \
            [_ acs-subsite.lt_Stop_inheriting_permi]
    } else {
        lappend actions \
            [_ acs-subsite.lt_Inherit_from_parent_o] \
            [export_vars -base "${perm_url}toggle-inherit" {object_id {return_url $ad_return_url}}] \
            [_ acs-subsite.lt_Inherit_permissions_f]
    }
}


# TODO: Inherit/don't inherit

template::list::create \
    -name permissions \
    -multirow permissions \
    -actions $actions \
    -elements $elements


set perm_form_export_vars [export_vars -form {object_id privs return_url}]
set perm_modify_url "${perm_url}perm-modify"
set application_group_id [application_group::group_id_from_package_id -package_id [ad_conn subsite_id]]

# PERMISSION: yes = 2, no = 0
# DIRECT:     yes = 1, no = -1

# 3 = permission + direct
# 2 = permission, no direct
# 1 = no permission, but direct (can't happen)
# 0 = no permission


# 2 = has permission, not direct => inherited
# 1 = has permission, it's direct => direct
# -1 = no permission

# NOTE:
# We do not include site-wide admins in the list

db_multirow -extend { name_url } permissions permissions {} {
    #
    # In case, the message key resolves to an empty string, show this
    # message key. An example is on my local instance, the
    # automatically generated group title:
    #
    #    #acs-translations.group_title_XXXX#
    #
    if { [string match #*# $grantee_name] } {
        if {[::lang::util::localize $grantee_name] eq ""} {
            set grantee_name [string range $grantee_name 0 end-1]
        }
    }
    if { $object_type eq "user" && $grantee_id != 0 } {
        set name_url [acs_community_member_url -user_id $grantee_id]
    }
}



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
