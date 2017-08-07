# 

ad_library {
    
    These should probably just use the regular old
    permission procedures
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-09
    @arch-tag: da21d1e8-0729-4f3b-8bef-3b847a979fec
    @cvs-id $Id$
}

namespace eval ::content::permission {}

ad_proc -public content::permission::cm_admin_exists {
} {

    @return VARCHAR2
} {
    return [package_exec_plsql -var_list [list \
    ] content_permission cm_admin_exists]
}


ad_proc -public content::permission::grant_permission {
    -object_id:required
    -holder_id:required
    -privilege:required
    -recipient_id:required
    {-is_recursive ""}
    {-object_type ""}
} {
    @param object_id
    @param holder_id
    @param privilege
    @param recipient_id
    @param is_recursive
    @param object_type
} {
    return [package_exec_plsql -var_list [list \
        [list object_id $object_id ] \
        [list holder_id $holder_id ] \
        [list privilege $privilege ] \
        [list recipient_id $recipient_id ] \
        [list is_recursive $is_recursive ] \
        [list object_type $object_type ] \
    ] content_permission grant_permission]
}


ad_proc -public content::permission::grant_permission_h {
    -object_id:required
    -grantee_id:required
    -privilege:required
} {
    @param object_id
    @param grantee_id
    @param privilege
} {
    return [package_exec_plsql -var_list [list \
        [list object_id $object_id ] \
        [list grantee_id $grantee_id ] \
        [list privilege $privilege ] \
    ] content_permission grant_permission_h]
}


ad_proc -public content::permission::has_grant_authority {
    -object_id:required
    -holder_id:required
    -privilege:required
} {
    @param object_id
    @param holder_id
    @param privilege

    @return VARCHAR2
} {
    return [package_exec_plsql -var_list [list \
        [list object_id $object_id ] \
        [list holder_id $holder_id ] \
        [list privilege $privilege ] \
    ] content_permission has_grant_authority]
}


ad_proc -public content::permission::has_revoke_authority {
    -object_id:required
    -holder_id:required
    -privilege:required
    -revokee_id:required
} {
    @param object_id
    @param holder_id
    @param privilege
    @param revokee_id

    @return VARCHAR2
} {
    return [package_exec_plsql -var_list [list \
        [list object_id $object_id ] \
        [list holder_id $holder_id ] \
        [list privilege $privilege ] \
        [list revokee_id $revokee_id ] \
    ] content_permission has_revoke_authority]
}


ad_proc -public content::permission::inherit_permissions {
    -parent_object_id:required
    -child_object_id:required
    {-child_creator_id ""}
} {
    @param parent_object_id
    @param child_object_id
    @param child_creator_id
} {
    return [package_exec_plsql -var_list [list \
        [list parent_object_id $parent_object_id ] \
        [list child_object_id $child_object_id ] \
        [list child_creator_id $child_creator_id ] \
    ] content_permission inherit_permissions]
}


ad_proc -public content::permission::permission_p {
    -object_id:required
    -holder_id:required
    -privilege:required
} {
    @param object_id
    @param holder_id
    @param privilege

    @return VARCHAR2
} {
    return [package_exec_plsql -var_list [list \
        [list object_id $object_id ] \
        [list holder_id $holder_id ] \
        [list privilege $privilege ] \
    ] content_permission permission_p]
}


ad_proc -public content::permission::revoke_permission {
    -object_id:required
    -holder_id:required
    -privilege:required
    -revokee_id:required
    {-is_recursive ""}
    {-object_type ""}
} {
    @param object_id
    @param holder_id
    @param privilege
    @param revokee_id
    @param is_recursive
    @param object_type
} {
    return [package_exec_plsql -var_list [list \
        [list object_id $object_id ] \
        [list holder_id $holder_id ] \
        [list privilege $privilege ] \
        [list revokee_id $revokee_id ] \
        [list is_recursive $is_recursive ] \
        [list object_type $object_type ] \
    ] content_permission revoke_permission]
}


ad_proc -public content::permission::revoke_permission_h {
    -object_id:required
    -revokee_id:required
    -privilege:required
} {
    @param object_id
    @param revokee_id
    @param privilege
} {
    return [package_exec_plsql -var_list [list \
        [list object_id $object_id ] \
        [list revokee_id $revokee_id ] \
        [list privilege $privilege ] \
    ] content_permission revoke_permission_h]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
