# /packages/mbryzek-subsite/www/admin/groups/add.tcl

ad_page_contract {
    Form to add a group type

    @author rhs@mit.edu
    @creation-date 2000-12-04
    @cvs-id $Id$
} {
    { object_type:trim "" }
    { pretty_name:trim "" }
    { pretty_plural:trim "" }
    { supertype:trim "" }
    { approval_policy:trim "" }
} -properties {
    context:onevalue
}

set doc(title) [_ acs-subsite.Add_group_type]
set context [list [list "[ad_conn package_url]admin/group-types/" [_ acs-subsite.Group_Types]] [_ acs-subsite.Add_type]]

template::form create group_type

template::element create group_type object_type \
    -datatype "text" \
    -label [_ acs-subsite.Group_type] \
    -html { size 30 maxlength 30 }

set supertype_options [db_list_of_lists select_group_supertypes {}]
foreach opt $supertype_options {
    lappend supertype_options_i18n [lang::util::localize $opt]
}

template::element create group_type supertype \
    -datatype "text" \
    -widget select \
    -options $supertype_options_i18n \
    -label [_ acs-subsite.Supertype]

template::element create group_type pretty_name \
    -datatype "text" \
    -label [_ acs-subsite.Pretty_name] \
    -html { size 50 maxlength 100 }

template::element create group_type pretty_plural \
    -datatype "text" \
    -label [_ acs-subsite.Pretty_plural] \
    -html { size 50 maxlength 100 }

set approval_policy_options {
    { {Open: Users can create groups of this type} open }
    { {Wait: Users can suggest groups} wait }
    { {Closed: Only administrators can create groups} closed }
}

if { [template::form is_valid group_type] } {

    set exception_count 0
    
    # Verify that the object type (in safe oracle format) is unique
    
    set safe_object_type [plsql_utility::generate_oracle_name -max_length 29 $object_type]
    if { [plsql_utility::object_type_exists_p $safe_object_type] } {
        incr exception_count
        append exception_text \
            "<li>The specified object type, $object_type, already exists. " \
            [ad_decode $safe_object_type $object_type "" \
                 "Note that we converted the object type to \"$safe_object_type\" to ensure that the name would be safe for the database."] \
            "Please back up and choose another.</li>"
    } else {
        # let's make sure the names are unique
        if { [db_string pretty_name_unique {}] } {
            incr exception_count
            append exception_text \
                "<li>The specified pretty name, $pretty_name, already exists. Please enter another </li>"
        }

        if { [db_string pretty_name_unique {}] } {
            incr exception_count
            append exception_text \
                "<li>The specified pretty plural, $pretty_plural, already exists. Please enter another </li>"
        }
    }

    if { $exception_count > 0 } {
        ad_return_complaint $exception_count $exception_text
        ad_script_abort
    }

    db_transaction {
        group_type::new -group_type $object_type -supertype $supertype $pretty_name $pretty_plural
    }
    ad_returnredirect ""
    return 
}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
