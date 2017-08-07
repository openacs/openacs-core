set context [list]

db_multirow defined_contracts defined_contracts {
    select contract_id,
           contract_name,
           contract_desc 
    from   acs_sc_contracts 
    order  by upper(contract_name), contract_name
}

template::list::create \
    -name contracts \
    -multirow defined_contracts \
    -elements {
        contract_name {
            label "Name"
            link_url_eval {[export_vars -base contract-display { { id $contract_id } }]}
            link_html { title "View contract" }
        }
        contract_desc {
            label "Description"
        }
    }




db_multirow valid_installed_bindings valid_installed_binding {}

template::list::create \
    -name valid_installed_bindings \
    -multirow valid_installed_bindings \
    -elements {
        contract_name {
            label "Contract"
            link_url_eval {[export_vars -base contract-display { { id $contract_id } }]}
            link_html { title "View contract" }
        }
        impl_name {
            label "Implementation"
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
    }



db_multirow valid_uninstalled_bindings valid_uninstalled_binding {}

template::list::create \
    -name valid_uninstalled_bindings \
    -multirow valid_uninstalled_bindings \
    -elements {
        contract_name {
            label "Contract"
            link_url_eval {[export_vars -base contract-display { { id $contract_id } }]}
            link_html { title "View contract" }
        }
        impl_name {
            label "Implementation"
        }
        impl_pretty_name {
            label "Label"
        }
        impl_owner_name {
            label "Owner"
        }
        install {
            label {}
            link_url_eval {[export_vars -base binding-install { contract_id impl_id }]}
            link_html { title "Install binding" }
            display_template {Install}
            sub_class narrow
        }
    }




db_multirow invalid_uninstalled_bindings invalid_uninstalled_binding {}

template::list::create \
    -name invalid_uninstalled_bindings \
    -multirow invalid_uninstalled_bindings \
    -elements {
        contract_name {
            label "Contract"
            link_url_eval {[export_vars -base contract-display { { id $contract_id } }]}
            link_html { title "View contract" }
        }
        impl_name {
            label "Implementation"
        }
        impl_pretty_name {
            label "Label"
        }
        impl_owner_name {
            label "Owner"
        }
    }




db_multirow orphan_implementations orphan_implementation {}

template::list::create \
    -name orphan_implementations \
    -multirow orphan_implementations \
    -elements {
        impl_contract_name {
            label "Contract"
        }
        impl_name {
            label "Implementation"
        }
        impl_pretty_name {
            label "Label"
        }
    }
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
