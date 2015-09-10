ad_page_contract { 
    Display a given service contract
} { 
    id:integer,notnull
}

set contract_name [db_string contract_name {select contract_name from acs_sc_contracts where contract_id = :id}]

db_multirow contract contract {select o.contract_name, o.operation_name, o.operation_desc, (case when t.msg_type_id = o.operation_inputtype_id then 'input' else 'output' end) as inout,
        e.element_name as param, e.element_msg_type_isset_p as set_p, et.msg_type_name as param_type
  from acs_sc_operations o, 
       acs_sc_msg_types t, 
       acs_sc_msg_type_elements e, 
       acs_sc_msg_types et
  where contract_id = :id
    and t.msg_type_id in (o.operation_inputtype_id, operation_outputtype_id) 
    and e.msg_type_id = t.msg_type_id
    and et.msg_type_id = e.element_msg_type_id
    order by o.contract_name, o.operation_name, t.msg_type_name, e.element_pos }


template::list::create \
    -name bindings \
    -multirow valid_installed_binding \
    -elements {
        impl_name {
            label "Implementation Name"
        }
        impl_pretty_name {
            label "Label"
        }
        impl_owner_name {
            label "Owner"
        }
        uninstall {
            label {}
            link_url_eval {[export_vars -base binding-uninstall { contract_id impl_id }]}
            link_html { title "Uninstall binding" }
            display_template {Uninstall}
            sub_class narrow
        }
        display {
            label {}
            link_url_eval {[export_vars -base binding-display { {id $contract_id} impl_name }]}
            link_html { title "View this contracts implementation details" }
            display_template {view}
            sub_class narrow
        }
    }

db_multirow valid_installed_binding valid_installed_binding {}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
