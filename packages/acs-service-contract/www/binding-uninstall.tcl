ad_page_contract {

    @author Neophytos Demetriou

} {
    contract_id:naturalnum,notnull
    impl_id:naturalnum,notnull
}

db_dml binding_uninstall {
    delete from acs_sc_bindings
    where contract_id = :contract_id
    and impl_id = :impl_id
}

ad_returnredirect ""
ad_script_abort

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
