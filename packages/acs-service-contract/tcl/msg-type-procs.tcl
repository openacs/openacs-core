ad_library {
    Support library for acs service contracts.
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-01-14
    @cvs-id $Id$
}

namespace eval acs_sc::msg_type {}
namespace eval acs_sc::msg_type::element {}

ad_proc -public acs_sc::msg_type::new {
    {-name:required}
    {-specification ""} 
} {
    @param specification Msg type specification in the format required by the SQL proc, namely
    'foo:integer,bar:[string]'
} {
    db_exec_plsql insert_msg_type {}
}

ad_proc -public acs_sc::msg_type::delete {
    {-msg_type_id}
    {-name}
} {
    Delete a message type. Supply either ID or name.

    @param msg_type_id The ID of the msg_type to delete.
    @param name Name of the service contract to delete
} {
    if { ![exists_and_not_null msg_type_id] && ![exists_and_not_null name] } {
        error "You must supply either name or msg_type_id"
    }

    # LARS:
    # It seems like delete by ID doesn't work, because our PG bind thing turns all integers into strings
    # by wrapping them in single quotes, causing PG to invoke the function for deleting by name

    if { ![exists_and_not_null name] } {
        # get msg_type name
        db_1row select_name {}
    }

    db_exec_plsql delete_by_name {}
}

ad_proc -public acs_sc::msg_type::parse_spec {
    {-name:required}
    {-spec:required}
} {
    #The specification for the message type could be like this!
    #case_id:integer
    #foobar:string,multiple

    @param name Name of new msg_type
    @param spec Spec in ad_page_contract style format, namely { foo:integer bar:string,multiple }
} {
    db_transaction { 

        # First, create the msg_type
        acs_sc::msg_type::new -name $name
    
        set nargs 0 
    
        # Then create the elements
        foreach element $spec {
            incr nargs
    
            # element:flag,flag
            set elementv [split $element :]
            set flagsv [split [lindex $elementv 1] ","]
    
            set element_name [string trim [lindex $elementv 0]]
    
            if { [llength $flagsv] > 1 } {
                set idx [lsearch $flagsv "multiple"]
    
                if { [llength $flagsv] > 2 || $idx == -1 } {
                    error "Only one modified flag allowed, and that's multiple as in foo:integer,multiple"
                }
    
                # Remove the 'multiple' flag
                set flagsv [lreplace $flagsv $idx $idx]
                set element_type "[lindex $flagsv 0]"
                set isset_p "t"
            } else {
                set element_type [lindex $flagsv 0]
                set isset_p "f"
            }
    
            acs_sc::msg_type::element::new \
                    -msg_type_name $name \
                    -element_name $element_name \
                    -element_msg_type_name $element_type \
                    -element_msg_type_isset_p $isset_p \
                    -element_pos $nargs
        }
    }

    return $nargs
}

#####
#
# Msg_type Element
#
#####

ad_proc -public acs_sc::msg_type::element::new {
    {-msg_type_name:required}
    {-element_name:required} 
    {-element_msg_type_name:required} 
    {-element_msg_type_isset_p:required} 
    {-element_pos:required} 
} {
    Insert a new msg_type element
} {
    db_exec_plsql insert_msg_type_element {}
}

