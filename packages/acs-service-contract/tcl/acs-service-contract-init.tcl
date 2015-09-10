# Loop over actual bindings, finding every impl alias for each contract operation
db_foreach impl_operation {
    select ia.impl_contract_name, 
           ia.impl_operation_name,
           ia.impl_name,
           ia.impl_alias,
           ia.impl_pl
    from   acs_sc_bindings b,
           acs_sc_impl_aliases ia
    where  ia.impl_id = b.impl_id
} {
    # This creates the AcsSc.Contract.Operation.Impl wrapper proc for this implementation
    if {[catch {
	acs_sc_proc $impl_contract_name $impl_operation_name $impl_name $impl_alias $impl_pl
    } errorMsg]} {
	ns_log error "Service contract initialization failed, call was:\n\
	acs_sc_proc $impl_contract_name $impl_operation_name $impl_name $impl_alias $impl_pl" 
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
