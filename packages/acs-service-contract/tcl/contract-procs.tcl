ad_library {
    Support library for acs service contracts.
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-01-14
    @cvs-id $Id$
}

namespace eval acs_sc::contract {}
namespace eval acs_sc::contract::operation {}



#####
#
# Contract
#
#####

ad_proc -public acs_sc::contract::new {
    {-name:required}
    {-description:required}
} {

    Procedure to call to define and new service contract and 
    the message types, implementations and bindings.

    Refer to the Service contract Tcl API discussion at 
    http://openacs.org/forums/message-view?message_id=71799

    @param name Name of the service contract
    @param description Comment/description of the service contract
    @return id of the contract

} {
    return [db_exec_plsql insert_sc_contract {}]
}

ad_proc -public acs_sc::contract::new_from_spec {
    {-spec:required}
} {
    Takes a complete notification spec and parses the 
    name, description and operations
} {

    # Default values
    array set contract { description "" }
    
    # Get the spec
    array set contract $spec

    db_transaction {
	set contract_id [new \
		-name $contract(name) \
		-description $contract(description)]
	
	acs_sc::contract::operation::parse_operations_spec \
                -name $contract(name) \
                -spec $contract(operations) 
    }
    return $contract_id
}

ad_proc -public acs_sc::contract::delete {
    {-contract_id}
    {-name}
    {-no_cascade:boolean}
} {
    Delete a service contract definition. Supply either contract_id or name.

    @param contract_id The ID of the service contract to delete
    @param name Name of the service contract to delete
} {
    if { ![exists_and_not_null contract_id] && ![exists_and_not_null name] } {
        error "You must supply either name or contract_id"
    }

    db_transaction {
        # Need both name and ID below
        if { ![exists_and_not_null name] } {
            set name [db_string get_name_by_id {}]
        } elseif { ![exists_and_not_null contract_id] } {
            set contract_id [db_string get_id_by_name {}]
        }

        if { !$no_cascade_p } {
            
            set operations [list]
            set msg_types [list]
            
            db_foreach select_operations {} {
                # Put them on list of mesage types and operations to delete
                lappend msg_types $operation_inputtype_id
                lappend msg_types $operation_outputtype_id
                lappend operations $operation_id
            }

            # Delete the operations
            foreach operation_id $operations {
                acs_sc::contract::operation::delete -operation_id $operation_id
            }

            # Delete msg types
            foreach msg_type_id $msg_types {
                if { ![empty_string_p $msg_type_id] } {
                    acs_sc::msg_type::delete -msg_type_id $msg_type_id
                }
            }
        }

        # LARS:
        # It seems like delete by ID doesn't work, because our PG bind thing turns all integers into strings
        # by wrapping them in single quotes, causing PG to invoke the function for deleting by name
        db_exec_plsql delete_by_name {}
    }
}




#####
#
# Operations
#
#####

ad_proc -public acs_sc::contract::operation::new {
    {-contract_name:required}
    {-operation:required}
    {-input:required}
    {-output:required}
    {-description:required}
    {-is_cachable_p ""}
} {
 
    Call the service contract function to create the 
    operation in the database. 

} {
    db_transaction {
        # Create the input type
        
        set input_type_name "${contract_name}.${operation}.InputType"
    
        set nargs [acs_sc::msg_type::parse_spec \
                -name $input_type_name \
                -spec $input]
        
        # Create the output type
    
        set output_type_name "${contract_name}.${operation}.OutputType"
    
        acs_sc::msg_type::parse_spec \
                -name $output_type_name \
                -spec $output
    
        # Create the operation
        
        db_exec_plsql insert_operation {}
    }
}

ad_proc -public acs_sc::contract::operation::delete {
    {-operation_id}
    {-contract_name}
    {-operation_name}
} {
    Delete a message type. Supply either ID or name.

    @param msg_type_id The ID of the msg_type to delete.
    @param name Name of the service contract to delete
} {
    if { ![exists_and_not_null operation_id] && ( ![exists_and_not_null contract_name] || ![exists_and_not_null operation_name] ) } {
        error "You must supply either contract_name and operation_name, or operation_id"
    }

    # LARS:
    # It seems like delete by ID doesn't work, because our PG bind thing turns all integers into strings
    # by wrapping them in single quotes, causing PG to invoke the function for deleting by name

    if { ![exists_and_not_null contract_name] || ![exists_and_not_null operation_name] } {
        # get contract_name and operation_name
        db_1row select_names {}
    }

    db_exec_plsql delete_by_name {}
}

ad_proc -public acs_sc::contract::operation::parse_operations_spec {
    {-name:required}
    {-spec:required}
} {
    Parse the operations defined in the operations specification
    @param name Name of the contract
    @spec  spec Specification of all the operations
} {
    foreach { operation subspec } $spec {
	acs_sc::contract::operation::parse_spec \
                -contract_name $name \
                -operation $operation \
                -spec $subspec
    }
}

ad_proc -public acs_sc::contract::operation::parse_spec {
    {-contract_name:required}
    {-operation:required}
    {-spec:required} 
} {
    Parse one operation
} {

    # Default values
    array set attributes {
	description {}
	input {}
	output {} 
	is_cachable_p "f"
    }
    
    # Get the sepc
    array set attributes $spec
    
    # New operation
    acs_sc::contract::operation::new \
	    -contract_name $contract_name \
	    -operation $operation \
	    -description $attributes(description) \
	    -input $attributes(input)   \
	    -output $attributes(output) \
	    -is_cachable_p $attributes(is_cachable_p) 
}

