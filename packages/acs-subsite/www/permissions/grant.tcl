# packages/acs-core-ui/www/acs_object/permissions/grant.tcl

ad_page_contract {

    @author rhs@mit.edu
    @creation-date 2000-08-20
    @cvs-id $Id$
} {
    object_id:naturalnum,notnull
    privileges:multiple,optional
    {application_url ""}
    {return_url ""}
}

permission::require_permission -object_id $object_id -privilege admin

# The object name is used in various localized messages below
set name [acs_object_name $object_id]

set title [_ acs-subsite.lt_Grant_Permission_on_n]

set context [list [list [export_vars -base one {object_id}] "[_ acs-subsite.Permissions_for_name]"] [_ acs-subsite.Grant]]


# Compute a hierarchical tree representation of the contents of
# acs_privileges. Note that nodes can appear more than one time in the
# tree.

set existing_privs [db_list select_privileges_list { }]

# The maximum level that has been reached within the hierarchy.
set maxlevel 1

# Initialize the $hierarchy datastructure which is a list of
# lists. The inner lists consist of two elements: 1. level,
# 2. privilege
set hierarchy [list]
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
    set start_pos_level [lindex $hierarchy $start_pos 0]

    # find the end position up to where the block extends that we have
    # to move
    set end_pos $start_pos
    for { set i [expr {$start_pos + 1}] } { $i <= [llength $hierarchy] } { incr i } {
        set level [lindex $hierarchy $i 0]
        if { $level <= $start_pos_level } {
            break
        }
        incr end_pos
    }

    # define the block
    set block_to_move [lrange $hierarchy $start_pos $end_pos]
    # Only cut out the block if it is on the toplevel, which means it
    # hasn't been moved yet. Otherwise the block will appear in two
    # places intentionally.
    if { [lindex $hierarchy $start_pos 0] == 0 } {
        set hierarchy [lreplace $hierarchy $start_pos $end_pos]
    }

    if { [set target_pos [lsearch -regexp $hierarchy "\\m$privilege\\M"]] == -1 } {
        # target not found, something is broken with the
        # hierarchy. 
        continue
    }
    set target_level [lindex $hierarchy $target_pos 0]

    # remember the starting level in the block
    set offset [lindex $block_to_move 0 0]

    # insert the block to the new position, looping through the block
    foreach element $block_to_move {
        incr target_pos
        set level_to_move [expr {[lindex $element 0] + $target_level + 1 - $offset}]
        set privilege_to_move [lindex $element 1]
        set hierarchy [linsert $hierarchy $target_pos [list $level_to_move $privilege_to_move]]

        if { $maxlevel < $level_to_move } { set maxlevel $level_to_move }
    }
}

incr maxlevel


# The $hierarchy datastructure is ready, fill a select widget options list with it.

foreach element $hierarchy {
    lassign $element level privilege

    lappend select_list [list "[string repeat "&nbsp;&nbsp;&nbsp;" $level] $privilege" $privilege]
}

ad_form -name grant -export {return_url} -form {
    {object_id:text(hidden)
        {value $object_id}
    }
}

element create grant application_url \
    -widget hidden \
    -value $application_url \
    -optional

element create grant party_id \
    -widget party_search \
    -datatype party_search \
    -optional

if { ![info exists privileges] } {
    set privileges [list]
}

# limit the size of the select widget to a number that should fit on a
# 1024x768 screen
if { [llength $select_list] > 23 } {
    set size 23
} else {
    set size [llength $select_list]
}

element create grant privilege \
    -widget multiselect \
    -datatype text \
    -optional \
    -html [list size $size] \
    -options $select_list \
    -value $privileges



if { [form is_valid grant] } {
    # A valid submission - grant accordingly.

    form get_values grant
    set privileges [element get_values grant privilege]

    # grant all selected privs
    foreach privilege $privileges {
        # Lars: For some reason, selecting no privileges returns in a list 
        # containing one element, which is the empty string
        if { $privilege ne "" } {
            permission::grant -party_id $party_id -object_id $object_id -privilege $privilege
        }
    }
    
    if {([info exists return_url] && $return_url ne "")} {
        ad_returnredirect $return_url
    } else {
        ad_returnredirect [export_vars -base one {object_id application_url}]
    }

    ad_script_abort
}
