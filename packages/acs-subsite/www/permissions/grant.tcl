# packages/acs-core-ui/www/acs_object/permissions/grant.tcl

ad_page_contract {

    @author rhs@mit.edu
    @creation-date 2000-08-20
    @cvs-id $Id$
} {
    object_id:integer,notnull
    privileges:multiple,optional
    {application_url ""}
}

ad_require_permission $object_id admin

# The object name is used in various localized messages below
set name [db_string name {select acs_object.name(:object_id) from dual}]

set title [_ acs-subsite.lt_Grant_Permission_on_n]

set context [list [list one?[export_url_vars object_id] "[_ acs-subsite.Permissions_for_name]"] [_ acs-subsite.Grant]]


set existing_privs [list]
set hierarchy [list]
set maxlevel 1


# Fill a multirow that contains a hierarchical tree representation of
# the acs_privileges.

if { [db_type] == "oracle" } {
    # Unfortunately it is not possible to write a query that returns
    # all the desired data with the current datamodel consisting of
    # only the tables acs_privileges and acs_privilege_hierarchy. This
    # is partly due to the restriction that a JOINed query cannot deal
    # with CONNECT BY in oracle 8i. See
    # http://openacs.org/forums/message-view?message_id=125969 for the
    # gory details. That's why this page resorts to a hack and builds
    # the tree structure manually in tcl. (-til)

    set existing_privs [db_list select_privileges_list { }]
    
    # Initialize the $hierarchy datastructure which is a list of
    # lists. The inner lists consist of two elements: 1. level,
    # 2. privilege
    foreach privilege $existing_privs {
        lappend hierarchy [list 0 $privilege]
    }

    # Loop through each row in acs_privilege_hierarchy and shuffle the
    # $hierarchy list accordingly.
    db_foreach select_privileges_hierarchy { } {

        if { [set start_pos [lsearch -regexp $hierarchy "\\m$child_privilege\\M"]] == -1 } {
            # child_privilege of this relation not in privileges - skip.
            continue
        }
        if { [lsearch -regexp $hierarchy "\\m$privilege\\M"] == -1 } {
            # privilege of this relation not in privileges - skip.
            continue
        }

        # the level of the first privilege element that we move
        set start_pos_level [lindex [lindex $hierarchy $start_pos] 0]

        # find the end position up to where the block extends that we have
        # to move
        set end_pos $start_pos
        for { set i [expr $start_pos + 1] } { $i <= [llength $hierarchy] } { incr i } {
            set level [lindex [lindex $hierarchy $i] 0]
            if { $level <= $start_pos_level } {
                break
            }
            incr end_pos
        }

        # cut out the block
        set block_to_move [lrange $hierarchy $start_pos $end_pos]
        set hierarchy [lreplace $hierarchy $start_pos $end_pos]

        if { [set target_pos [lsearch -regexp $hierarchy "\\m$privilege\\M"]] == -1 } {
            # target not found, something is broken with the
            # hierarchy. insert the block back to where it was
            eval "set hierarchy \[linsert \$hierarchy $start_pos $block_to_move\]"
            continue
        }
        set target_level [lindex [lindex $hierarchy $target_pos] 0]

        # insert the block to the new position, looping through the block
        foreach element $block_to_move {
            incr target_pos
            set level_to_move [expr [lindex $element 0] + $target_level + 1]
            set privilege_to_move [lindex $element 1]
            set hierarchy [linsert $hierarchy $target_pos [list $level_to_move $privilege_to_move]]

            if { $maxlevel < $level_to_move } { set maxlevel $level_to_move }
        }
    }

} else {
    # We are not on oracle - use the table
    # acs_privilege_hierarchy_index.

    db_foreach select_privileges_hierarchy { } {
        if { [lsearch $existing_privs $privilege] > -1 } {
            # skip double entries
            continue
        } else {
            lappend existing_privs $privilege
            lappend hierarchy [list $level $privilege]
        }

        if { $level > $maxlevel } {
            set maxlevel $level
        }
    }

    incr maxlevel
}


multirow create mu_privileges privilege level inverted_level selected id

# Preserve checked value of the privilege checkboxes for re-submitted
# form status.

foreach elm $hierarchy {
    foreach { level privilege } $elm {}
    if { [info exists privileges] && [lsearch $privileges $privilege]>-1 } {
        set selected "CHECKED"
    } else {
        set selected ""
    }
    multirow append mu_privileges $privilege [expr $level+1] [expr $maxlevel - $level] $selected $privilege
}

for { set i 0 } { $i < $maxlevel } { incr i } {
    append first_tr "<td>&nbsp;&nbsp;&nbsp;</td>"
}

form create grant

element create grant object_id \
    -widget hidden \
    -value $object_id

element create grant application_url \
    -widget hidden \
    -value $application_url \
    -optional

element create grant party_id \
    -widget party_search \
    -datatype party_search \
    -optional


if { [form is_valid grant] } {
    # A valid submission, grant and revoke accordingly.

    form get_values grant

    if { ![info exists privileges] } {
        # no privilege was selected
        set privileges [list]
    }

    # loop through all privileges, grant checked and revoke un-checked
    # (assuming that there are not too many privs in total, otherwise
    # this would be slow)
    foreach privilege $existing_privs {
        if { [lsearch $privileges $privilege] > -1 } {
            db_exec_plsql grant { }
        } else {
            db_exec_plsql revoke { }
        }
    }
    
    ad_returnredirect "one?[export_url_vars object_id]"
}

