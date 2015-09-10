ad_page_contract {

    @author Neophytos Demetriou

} {
    contract_id:naturalnum,notnull
    impl_id:naturalnum,notnull
}


db_exec_plsql binding_uninstall "select acs_sc_binding__delete($contract_id,$impl_id)"

ad_returnredirect ""

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
